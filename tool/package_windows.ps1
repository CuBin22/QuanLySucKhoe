param([string]$OutputRoot='', [string]$ReleasePath='')
$ErrorActionPreference='Stop'
$projectPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $ReleasePath){$ReleasePath=Join-Path $projectPath 'build\windows\x64\runner\Release'}
if(-not $OutputRoot){$OutputRoot=Join-Path $projectPath 'deliverables'}
if(-not (Test-Path -LiteralPath (Join-Path $ReleasePath 'suc_khoe_ca_nhan.exe') -PathType Leaf)){throw 'Windows Release build is missing.'}
$portableOutput=Join-Path $OutputRoot 'windows_sqlserver'
if(Test-Path -LiteralPath $portableOutput){throw "Output already exists: $portableOutput. Preserve it and choose a new -OutputRoot."}
New-Item -ItemType Directory -Path $portableOutput -Force | Out-Null
function Copy-Runtime([string]$From,[string]$To) {
 foreach($sourceFile in Get-ChildItem -LiteralPath $From -Recurse -File){
  # Databases and sidecars are user data, never runtime assets.
  if($sourceFile.Name -match '(?i)\.(db|sqlite|sqlite3|db3)(-|$)' -or $sourceFile.Extension -eq '.pdb'){continue}
  $relative=$sourceFile.FullName.Substring([IO.Path]::GetFullPath($From).TrimEnd('\').Length+1)
  $destination=Join-Path $To $relative
  New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force | Out-Null
  Copy-Item -LiteralPath $sourceFile.FullName -Destination $destination -Force
 }
}
Copy-Runtime $ReleasePath $portableOutput
$redistPath='C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT'
foreach($dllName in @('msvcp140.dll','vcruntime140.dll','vcruntime140_1.dll')) {if(Test-Path -LiteralPath (Join-Path $redistPath $dllName)){Copy-Item -LiteralPath (Join-Path $redistPath $dllName) -Destination $portableOutput -Force}}
$launcher=@'
param([string]$ApiBaseUrl='http://127.0.0.1:5080/api/')
$ErrorActionPreference='Stop'
if(-not $env:HEALTH_API_KEY){
 $keyPath=Join-Path $PSScriptRoot '..\..\.local\api-key.txt'
 if(Test-Path -LiteralPath $keyPath){$env:HEALTH_API_KEY=(Get-Content -LiteralPath $keyPath -Raw).Trim()}
}
if(-not $env:HEALTH_API_KEY){throw 'Start the API first, or set HEALTH_API_KEY.'}
$env:HEALTH_API_URL=$ApiBaseUrl
& (Join-Path $PSScriptRoot 'suc_khoe_ca_nhan.exe')
'@
[IO.File]::WriteAllText((Join-Path $portableOutput 'Chay_Ung_Dung.ps1'),$launcher,[Text.UTF8Encoding]::new($false))
$cmd='@echo off' + "`r`n" + 'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Chay_Ung_Dung.ps1" %*' + "`r`n"
[IO.File]::WriteAllText((Join-Path $portableOutput 'Chay_Ung_Dung.cmd'),$cmd,[Text.Encoding]::ASCII)
Write-Output "PORTABLE_OUTPUT=$portableOutput"
Write-Output 'Start the API first. No SQL credentials or API key are embedded in the package.'

