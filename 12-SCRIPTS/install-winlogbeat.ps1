<#
.SYNOPSIS
    Install and configure Winlogbeat on Windows Server/Workstation.
.DESCRIPTION
    Downloads Winlogbeat from Elastic, configures it to ship Windows Event Logs
    to Elasticsearch (192.168.1.100:9200), installs as a Windows service, and starts it.
.NOTES
    Run as Administrator.
    Elasticsearch server IP: 192.168.1.100 (adjust if needed).
    Version: 8.8.0 (can be changed below).
#>

param(
    [string]$ElasticsearchHost = "192.168.1.100",
    [int]$ElasticsearchPort = 9200,
    [string]$KibanaHost = "192.168.1.100",
    [int]$KibanaPort = 5601,
    [string]$WinlogbeatVersion = "8.8.0",
    [string]$InstallPath = "C:\Program Files\Winlogbeat"
)

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Write-Host "[+] Starting Winlogbeat installation (version $WinlogbeatVersion)..."

# Create install directory if not exists
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

$downloadUrl = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-${WinlogbeatVersion}-windows-x86_64.zip"
$zipFile = "$env:TEMP\winlogbeat.zip"

# Download Winlogbeat
Write-Host "[+] Downloading Winlogbeat from $downloadUrl ..."
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
} catch {
    Write-Error "Failed to download Winlogbeat. Check network and URL."
    exit 1
}

# Extract ZIP
Write-Host "[+] Extracting to $InstallPath ..."
try {
    Expand-Archive -Path $zipFile -DestinationPath $InstallPath -Force
    # Move contents from subfolder up one level
    $extractedFolder = Get-ChildItem -Path $InstallPath -Directory | Where-Object { $_.Name -like "winlogbeat-*" } | Select-Object -First 1
    if ($extractedFolder) {
        Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $InstallPath -Force
        Remove-Item -Path $extractedFolder.FullName -Recurse -Force
    }
} catch {
    Write-Error "Extraction failed."
    exit 1
}
Remove-Item $zipFile -Force

# Configure winlogbeat.yml
Write-Host "[+] Configuring Winlogbeat..."
$configFile = Join-Path $InstallPath "winlogbeat.yml"
$backupConfig = Join-Path $InstallPath "winlogbeat.yml.bak"
if (Test-Path $configFile) {
    Copy-Item $configFile $backupConfig -Force
}

$configContent = @"
winlogbeat.event_logs:
  - name: Application
    ignore_older: 72h
  - name: Security
    ignore_older: 72h
  - name: System
    ignore_older: 72h
  - name: Microsoft-Windows-Sysmon/Operational
    ignore_older: 72h

output.elasticsearch:
  hosts: ["${ElasticsearchHost}:${ElasticsearchPort}"]
  # If Elasticsearch requires authentication, uncomment and set:
  # username: "elastic"
  # password: "changeme"

setup.kibana:
  host: "http://${KibanaHost}:${KibanaPort}"

logging.level: info
logging.to_files: true
logging.files:
  path: C:\ProgramData\winlogbeat\Logs
  name: winlogbeat
  keepfiles: 7
"@

Set-Content -Path $configFile -Value $configContent -Force

# Install and start the service
Write-Host "[+] Installing Winlogbeat as a Windows service..."
Push-Location $InstallPath
try {
    .\install-service-winlogbeat.ps1 -Force
    Start-Sleep -Seconds 2
    Start-Service winlogbeat
    Set-Service winlogbeat -StartupType Automatic
} catch {
    Write-Error "Failed to install/start service."
    Pop-Location
    exit 1
}
Pop-Location

# Verify service status
$service = Get-Service winlogbeat -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq 'Running') {
    Write-Host "[+] Winlogbeat service is running."
} else {
    Write-Warning "Winlogbeat service not running. Check logs: $InstallPath\logs\winlogbeat"
}

# Test connectivity
Write-Host "[+] Testing connectivity to Elasticsearch..."
Push-Location $InstallPath
$testOutput = .\winlogbeat.exe test output 2>&1
if ($testOutput -match "OK") {
    Write-Host "[+] Connection to Elasticsearch successful."
} else {
    Write-Warning "Connection test failed. Verify Elasticsearch is reachable and firewall allows port $ElasticsearchPort."
}
Pop-Location

Write-Host ""
Write-Host "========================================="
Write-Host "Winlogbeat installation complete."
Write-Host "Config file: $configFile"
Write-Host "Service: winlogbeat"
Write-Host "Logs: C:\ProgramData\winlogbeat\Logs\winlogbeat"
Write-Host ""
Write-Host "To verify data in Kibana:"
Write-Host "  Index pattern: winlogbeat-*"
Write-Host "  Query: host.name: `"$env:COMPUTERNAME`""
Write-Host "========================================="

exit 0