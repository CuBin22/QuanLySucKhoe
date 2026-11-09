param([string[]]$Tests = @('test'))
$projectPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testFiles = foreach ($testPath in $Tests) {
    $resolvedTestPath = Join-Path $projectPath $testPath
    if (Test-Path -LiteralPath $resolvedTestPath -PathType Container) {
        Get-ChildItem -LiteralPath $resolvedTestPath -Filter '*_test.dart' -Recurse -File
    } else { Get-Item -LiteralPath $resolvedTestPath }
}
$testFiles = @($testFiles | Sort-Object FullName -Unique)
if ($testFiles.Count -eq 0) { Write-Error 'No test files selected.'; exit 1 }
$lines = @("import '../tool/native_test_runner.dart';")
for ($testIndex = 0; $testIndex -lt $testFiles.Count; $testIndex++) {
    $testUri = ([System.Uri]$testFiles[$testIndex].FullName).AbsoluteUri
    $lines += "import '$testUri' as suite$testIndex;"
}
$calls = (0..($testFiles.Count-1) | ForEach-Object { "suite$_.main" }) -join ', '
$lines += "Future<void> main() async { await runNativeTests([$calls]); }"
$driverPath = Join-Path $projectPath '.dart_tool\native_suite.dart'
[System.IO.File]::WriteAllLines($driverPath, $lines, [System.Text.UTF8Encoding]::new($false))
$buildLog = Join-Path $projectPath '.dart_tool\native-suite-build.log'
& (Join-Path $PSScriptRoot 'flutter.ps1') assemble '--output=build/native_checks' '-dTargetFile=.dart_tool/native_suite.dart' '-dTargetPlatform=windows-x64' '-dBuildMode=debug' debug_bundle_windows-x64_assets *> $buildLog
if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $buildLog -Tail 45; exit 1 }
$enginePath = Join-Path $projectPath '.tooling\flutter-sdk\bin\cache\artifacts\engine\windows-x64'
$assetsPath = Join-Path $projectPath 'build\native_checks\flutter_assets'
& (Join-Path $enginePath 'flutter_tester.exe') --non-interactive --disable-vm-service "--icu-data-file-path=$enginePath\icudtl.dat" "--flutter-assets-dir=$assetsPath" (Join-Path $assetsPath 'kernel_blob.bin')
exit $LASTEXITCODE
