# =============================================================================
# install-winlogbeat.ps1
# Nation-State Lab – Winlogbeat Automated Deployment Script
#
# Purpose:
#   - Installs Winlogbeat 8.14.0 silently
#   - Creates a production-ready configuration
#   - Registers and starts the Winlogbeat service
#   - Validates Elasticsearch connectivity
#
# Supported Systems:
#   - Windows Server 2019 / 2022
#   - Windows 10 / 11
#
# Usage:
#   Run PowerShell as Administrator
#
# Example:
#   .\install-winlogbeat.ps1
#
#   OR
#
#   .\install-winlogbeat.ps1 -ElasticsearchHost "http://192.168.1.100:9200"
#
# =============================================================================

[CmdletBinding()]
param(
    [string]$ElasticsearchHost = "http://192.168.1.100:9200",
    [string]$InstallerPath = "C:\Temp\winlogbeat-8.14.0-windows-x86_64.msi",
    [string]$InstallDirectory = "C:\Winlogbeat"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "      Nation-State Lab - Winlogbeat Deployment Script       " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# Verify Administrator Privileges
# -----------------------------------------------------------------------------

$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# Verify Installer Exists
# -----------------------------------------------------------------------------

if (-not (Test-Path $InstallerPath)) {
    Write-Host "[ERROR] Winlogbeat installer not found:" -ForegroundColor Red
    Write-Host "        $InstallerPath" -ForegroundColor Yellow
    exit 1
}

# -----------------------------------------------------------------------------
# Stop Existing Service
# -----------------------------------------------------------------------------

Write-Host "[*] Checking for existing Winlogbeat service..." -ForegroundColor Cyan

if (Get-Service Winlogbeat -ErrorAction SilentlyContinue) {

    Write-Host "[*] Stopping existing Winlogbeat service..." -ForegroundColor Cyan

    Stop-Service Winlogbeat -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 3
}

# -----------------------------------------------------------------------------
# Create Installation Directory
# -----------------------------------------------------------------------------

Write-Host "[*] Preparing installation directory..." -ForegroundColor Cyan

New-Item `
    -Path $InstallDirectory `
    -ItemType Directory `
    -Force | Out-Null

# -----------------------------------------------------------------------------
# Install Winlogbeat
# -----------------------------------------------------------------------------

Write-Host "[*] Installing Winlogbeat 8.14.0..." -ForegroundColor Cyan

$InstallArgs = @(
    "/i"
    "`"$InstallerPath`""
    "TARGETDIR=`"$InstallDirectory`""
    "/qn"
    "/norestart"
)

Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList $InstallArgs `
    -Wait

Write-Host "[+] Installation completed." -ForegroundColor Green

# -----------------------------------------------------------------------------
# Create Configuration File
# -----------------------------------------------------------------------------

Write-Host "[*] Creating Winlogbeat configuration..." -ForegroundColor Cyan

$ConfigFile = Join-Path $InstallDirectory "winlogbeat.yml"

$ConfigContent = @"
# =============================================================================
# Winlogbeat Configuration
# Nation-State Lab
# =============================================================================

winlogbeat.event_logs:
  - name: Application
    ignore_older: 72h

  - name: System

  - name: Security

setup.template.enabled: true
setup.template.name: "winlogbeat"
setup.template.pattern: "winlogbeat-*"

output.elasticsearch:
  hosts: ["$ElasticsearchHost"]

logging.level: info

logging.to_files: true

logging.files:
  path: $InstallDirectory\logs
  name: winlogbeat
  keepfiles: 7

"@

$ConfigContent | Out-File `
    -FilePath $ConfigFile `
    -Encoding utf8 `
    -Force

Write-Host "[+] Configuration written successfully." -ForegroundColor Green

# -----------------------------------------------------------------------------
# Install Service
# -----------------------------------------------------------------------------

Write-Host "[*] Installing Winlogbeat Windows Service..." -ForegroundColor Cyan

Push-Location $InstallDirectory

if (Test-Path ".\install-service-winlogbeat.ps1") {

    powershell.exe `
        -ExecutionPolicy Bypass `
        -File ".\install-service-winlogbeat.ps1"

} else {

    Write-Host "[ERROR] install-service-winlogbeat.ps1 not found." -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# -----------------------------------------------------------------------------
# Start Service
# -----------------------------------------------------------------------------

Write-Host "[*] Starting Winlogbeat service..." -ForegroundColor Cyan

Start-Service Winlogbeat

Start-Sleep -Seconds 5

# -----------------------------------------------------------------------------
# Verify Service
# -----------------------------------------------------------------------------

$Service = Get-Service Winlogbeat

if ($Service.Status -eq "Running") {

    Write-Host "[+] Winlogbeat service is running." -ForegroundColor Green

} else {

    Write-Host "[ERROR] Winlogbeat service failed to start." -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# Connectivity Test
# -----------------------------------------------------------------------------

Write-Host "[*] Testing Elasticsearch connectivity..." -ForegroundColor Cyan

try {

    $Uri = $ElasticsearchHost.Replace("9200","9200")

    Invoke-WebRequest `
        -Uri $Uri `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 10 | Out-Null

    Write-Host "[+] Elasticsearch is reachable." -ForegroundColor Green

}
catch {

    Write-Host "[WARNING] Unable to reach Elasticsearch." -ForegroundColor Yellow
    Write-Host "          Verify network connectivity and firewall rules." -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# Service Information
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                   Deployment Complete                      " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Get-Service Winlogbeat

Write-Host ""
Write-Host "Installation Directory : $InstallDirectory"
Write-Host "Configuration File     : $ConfigFile"
Write-Host "Elasticsearch Endpoint : $ElasticsearchHost"
Write-Host ""

Write-Host "[SUCCESS] Winlogbeat deployment completed successfully." -ForegroundColor Green