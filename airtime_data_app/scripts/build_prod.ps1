<#
.SYNOPSIS
  Build the Flutter web app for production.
.DESCRIPTION
  Selects the prod AppConfig via --dart-define=PROD=true so the app targets
  the production API instead of localhost. Override the host with -ApiBaseUrl.
.EXAMPLE
  ./scripts/build_prod.ps1
.EXAMPLE
  ./scripts/build_prod.ps1 -ApiBaseUrl "https://example.com/api/v1"
#>
param(
  [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$flutterArgs = @("build", "web", "--release", "--dart-define=PROD=true")
if ($ApiBaseUrl -ne "") {
  $flutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"
}

flutter @flutterArgs

Write-Host "Built build/web for production. Deploy with: firebase deploy --only hosting"
