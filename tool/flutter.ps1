# Development helper: use a writable SDK copy without changing the installed SDK.
$runtimePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\.tooling'))
$sdkPath = Join-Path $runtimePath 'flutter-sdk'
if (-not (Test-Path -LiteralPath (Join-Path $sdkPath 'bin\cache\flutter_tools.snapshot'))) {
    Write-Error 'Writable Flutter SDK not found. Use your installed flutter command, or copy the SDK to the path described in README.md.'
    exit 1
}
$env:FLUTTER_ROOT = $sdkPath
$env:PUB_CACHE = Join-Path $runtimePath 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $runtimePath 'gradle'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:DASH__SUPPRESS_ANALYTICS = 'true'
$toolTempPath = Join-Path $runtimePath 'temp'
New-Item -ItemType Directory -Path $toolTempPath -Force | Out-Null
$env:TEMP = $toolTempPath
$env:TMP = $toolTempPath
& (Join-Path $sdkPath 'bin\cache\dart-sdk\bin\dart.exe') (Join-Path $sdkPath 'bin\cache\flutter_tools.snapshot') --suppress-analytics --no-version-check @args
exit $LASTEXITCODE
