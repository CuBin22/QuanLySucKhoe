param([string]$Device='windows',[string]$ApiBaseUrl='')
$ErrorActionPreference='Stop'
$projectPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtimeTemp=Join-Path $projectPath '.local\flutter-temp'
New-Item -ItemType Directory -Path $runtimeTemp -Force | Out-Null
$env:TEMP=$runtimeTemp
$env:TMP=$runtimeTemp
if(-not $ApiBaseUrl){$ApiBaseUrl=if($Device -eq 'windows'){'http://127.0.0.1:5080/api/'}else{'http://10.0.2.2:5080/api/'}}
$keyPath=Join-Path $projectPath '.local\api-key.txt'
if(-not $env:HEALTH_API_KEY -and (Test-Path -LiteralPath $keyPath)){$env:HEALTH_API_KEY=(Get-Content -LiteralPath $keyPath -Raw).Trim()}
if(-not $env:HEALTH_API_KEY){throw 'Start the API first or set HEALTH_API_KEY.'}
$env:HEALTH_API_URL=$ApiBaseUrl
Push-Location $projectPath
try {
 if($Device -eq 'windows'){& flutter run -d $Device "--dart-define=API_BASE_URL=$ApiBaseUrl"}
 else{& flutter run -d $Device "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=API_KEY=$env:HEALTH_API_KEY"}
 $appExit=$LASTEXITCODE
}finally{Pop-Location}
exit $appExit
