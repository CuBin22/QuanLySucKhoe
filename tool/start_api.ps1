param([string]$Server='.',[string]$Database='PersonalHealth',[switch]$Initialize,[string]$Urls='http://127.0.0.1:5080')
$ErrorActionPreference='Stop'
$projectPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if($Database -notmatch '^[A-Za-z][A-Za-z0-9_]{0,63}$'){throw 'Use a simple dedicated database name.'}
$privatePath=Join-Path $projectPath '.local'
New-Item -ItemType Directory -Path $privatePath -Force | Out-Null
$keyPath=Join-Path $privatePath 'api-key.txt'
if(-not $env:HEALTH_API_KEY){
 if(Test-Path -LiteralPath $keyPath){$env:HEALTH_API_KEY=(Get-Content -LiteralPath $keyPath -Raw).Trim()}
 else {
  $keyBytes=New-Object byte[] 32
  $random=[Security.Cryptography.RandomNumberGenerator]::Create();$random.GetBytes($keyBytes);$random.Dispose()
  $env:HEALTH_API_KEY=([BitConverter]::ToString($keyBytes)).Replace('-','').ToLowerInvariant()
  [IO.File]::WriteAllText($keyPath,$env:HEALTH_API_KEY)
 }
}
$usesDefaultConnection=-not $env:ConnectionStrings__Health
if($usesDefaultConnection){$env:ConnectionStrings__Health="Server=$Server;Database=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Connect Timeout=10"}
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:ASPNETCORE_URLS=$Urls
if($Initialize){
 # Explicit initialization creates a new database if absent; never resets data.
 if($usesDefaultConnection){
  & sqlcmd -S $Server -E -C -b -Q "IF DB_ID(N'$Database') IS NULL CREATE DATABASE [$Database]"
  if($LASTEXITCODE -ne 0){throw 'Cannot create/connect database. Check your SQL Server instance.'}
 }
 & dotnet run --project (Join-Path $projectPath 'server\Health.Api') -- --init
 if($LASTEXITCODE -ne 0){throw 'Schema initialization failed'}
}
Write-Output "API URL: $Urls/api/ (private development only)"
& dotnet run --project (Join-Path $projectPath 'server\Health.Api')
exit $LASTEXITCODE
