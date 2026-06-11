# Winlogbeat Configuration – Nation-State Lab

## 1. Overview

Winlogbeat is a lightweight log shipper from Elastic that reads Windows event logs (Security, System, Application, etc.) and forwards them to Elasticsearch. In this lab, Winlogbeat is installed on all domain-joined Windows VMs (DC, WS1, FILESERVER, WEBSERVER) and configured to send events to the central Elasticsearch container on Ubuntu (`192.168.1.100:9200`).

The data is then visualised in Kibana for detection and hunting.

Winlogbeat was chosen over the built-in Windows Event Forwarding because it integrates seamlessly with the Elastic Stack, supports silent installation, and requires minimal configuration.

All Windows VMs use the same Winlogbeat configuration. The only difference is the hostname automatically reported in the `agent.hostname` field.

---

## 2. Installation

The MSI installer for Winlogbeat version **8.14.0** was used to match the Elasticsearch and Kibana versions.

Installation was performed silently and installed into `C:\Winlogbeat` instead of `C:\Program Files\Winlogbeat`.

### 2.1 Copy Installer to VM

The MSI installer was transferred through the VMware shared folder:

```text
\\vmware-host\Shared Folders\share
```

The installer was then copied locally to:

```text
C:\Temp
```

### 2.2 Silent Installation Command

```cmd
msiexec /i "C:\Temp\winlogbeat-8.14.0-windows-x86_64.msi" TARGETDIR="C:\Winlogbeat" /qn
```

### Installation Parameters

| Parameter | Purpose |
|------------|------------|
| `/qn` | Silent installation without GUI |
| `TARGETDIR="C:\Winlogbeat"` | Custom installation directory |

### Why `C:\Winlogbeat`?

The default `Program Files` path contains spaces which may cause issues with scripts and service paths.

Using `C:\Winlogbeat` simplifies configuration and troubleshooting.

---

## 3. Configuration File

The configuration file is located at:

```text
C:\Winlogbeat\winlogbeat.yml
```

### 3.1 Configuration

```yaml
winlogbeat.event_logs:
  - name: Application
    ignore_older: 72h

  - name: System

  - name: Security

setup.template.enabled: true
setup.template.name: "winlogbeat"
setup.template.pattern: "winlogbeat-*"

output.elasticsearch:
  hosts:
    - "http://192.168.1.100:9200"

logging.level: info

logging.to_files: true

logging.files:
  path: C:\Winlogbeat\logs
  name: winlogbeat
  keepfiles: 7
```

### 3.2 Configuration Explanation

| Setting | Value | Purpose |
|----------|----------|----------|
| `winlogbeat.event_logs` | Application, System, Security | Collects Windows event logs |
| `ignore_older` | 72h | Ignores events older than 72 hours |
| `setup.template.enabled` | true | Loads index template automatically |
| `output.elasticsearch.hosts` | 192.168.1.100:9200 | Sends logs to Elasticsearch |
| `logging.level` | info | Standard logging level |

No Security log query filters were configured.

All Security events are collected, including:

- Event ID 4624
- Event ID 4625
- Event ID 4663
- Event ID 4672
- Event ID 4688
- Event ID 4698

---

## 4. Service Installation

### 4.1 Install Winlogbeat Service

Open PowerShell as Administrator:

```powershell
cd C:\Winlogbeat
.\install-service-winlogbeat.ps1
```

If execution policy blocks the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-service-winlogbeat.ps1
```

Start the service:

```cmd
net start winlogbeat
```

### 4.2 Verify Service Status

```cmd
sc query winlogbeat
```

Expected output:

```text
STATE : 4 RUNNING
```

---

## 5. Audit Policy Requirements

Winlogbeat can only forward events that Windows generates.

The following audit policies were enabled:

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable

auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

Verify configuration:

```cmd
auditpol /get /subcategory:"Logon"
```

Expected output:

```text
Success and Failure
```

---

## 6. Testing

### Generate Test Events

```cmd
net user testuser P@ssw0rd /add
net user testuser /delete
```

This generates:

- Event ID 4720 (User Created)
- Event ID 4726 (User Deleted)

### Verify in Elasticsearch

```bash
curl -X GET "http://192.168.1.100:9200/winlogbeat-*/_search?q=winlog.event_id:4720&pretty"
```

### Verify in Kibana

1. Open Kibana.
2. Navigate to Discover.
3. Select `winlogbeat-*`.
4. Set time range to Last 30 Minutes.
5. Search:

```text
winlog.event_id: 4720
```

---

## 7. Troubleshooting

| Problem | Cause | Solution |
|----------|----------|----------|
| Service not installed | Install script not executed | Run `install-service-winlogbeat.ps1` |
| No events in Kibana | Elasticsearch unreachable | Verify network connectivity |
| Configuration missing | Empty winlogbeat.yml | Create configuration manually |
| Connection refused | Firewall blocking port 9200 | Allow outbound TCP 9200 |
| Missing Security events | Audit policy disabled | Enable audit policies |

---

## 8. Attack Chain Detection

| Attack Phase | Event IDs | Detection Query |
|-------------|------------|----------------|
| Reverse Shell | 4688 | `winlog.event_id:4688 AND process.executable:*shell.exe` |
| Persistence | 4698 | `winlog.event_id:4698` |
| UAC Bypass | 4688 | `process.executable:*eventvwr.exe` |
| Credential Theft | 4663 | `process.name:mimikatz.exe` |
| Pass-the-Hash | 4624, 4672 | `LogonType:3` |
| HTTP Beacon | 4688 | `process.executable:*beacon.exe` |

---

## 9. Summary

| Component | Status | Details |
|------------|------------|------------|
| Installation | Complete | `C:\Winlogbeat` |
| Configuration | Complete | `winlogbeat.yml` |
| Service | Running | Auto-start enabled |
| Elasticsearch Connectivity | Verified | Port 9200 reachable |
| Event Collection | Verified | Security events indexed |
| Kibana Integration | Verified | `winlogbeat-*` pattern created |

Winlogbeat served as the primary Windows log collection agent within the Nation-State Lab and successfully forwarded all attack-related events to Elasticsearch for analysis and detection.

---
