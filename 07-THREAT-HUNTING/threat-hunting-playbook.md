# Threat Hunting Playbook – APT Attack Chain Simulation

This playbook provides step-by-step procedures for proactively hunting indicators of compromise (IOCs) across the lab environment using Velociraptor, Kibana, and Sigma-based SIEM rules. It is designed for blue/purple team exercises to detect, validate, and respond to the simulated APT attack.

---

## 1. Playbook Overview

| Attack Phase | Hunting Focus | Tools | Artefacts / IOCs |
|--------------|---------------|-------|-------------------|
| Initial Access | Reverse shell payload execution | Kibana, Velociraptor | `shell.exe` process, network connection to Kali:4444 |
| Persistence | Scheduled task `Updater` | Kibana, Velociraptor | Task name `Updater`, action `C:\Users\Public\shell.exe` |
| Credential Dumping | LSASS access | Kibana, Velociraptor | Event 4663/10, Mimikatz, `lsass.exe` handle |
| Lateral Movement | Pass-the-hash, remote service | Kibana, Velociraptor | 4624 (Logon Type 3) from Kali, `PSEXESVC` |
| C2 Communication | HTTP beacon outbound | Kibana, Velociraptor | `beacon.exe`, outbound to `192.168.1.5:8081` |
| Defense Evasion | LOLBin certutil download | Kibana, Velociraptor | `certutil.exe -urlcache http://...` |

---

## 2. Pre-requisites

- **Velociraptor** server accessible at `https://192.168.1.100:8889`
- **Kibana** accessible at `http://192.168.1.100:5601`
- **Sysmon** installed (recommended) with Event ID 3, 10 enabled
- **Winlogbeat** running on WS1, DC, File Server

---

## 3. Hunting Procedures

### 3.1 Reverse Shell (Phase 2)

**Kibana (KQL)**
```kql
event.code:4688 AND process.name:shell.exe AND process.parent.name:(cmd.exe OR powershell.exe)
```

**Velociraptor (VQL)**
```sql
SELECT Name, Pid, Exe, CommandLine, CreateTime, ParentExe, Username
FROM hunt_results()
WHERE Exe =~ '(?i)shell\.exe$'
```

**Response:**
- Kill process
- Quarantine `C:\Users\Public\shell.exe`

---

### 3.2 Scheduled Task Persistence (Phase 3)

**KQL**
```kql
event.code:4698 AND winlog.event_data.TaskName:Updater
```

**VQL**
```sql
SELECT Name, State, CreateTime, Action, RunAsUser
FROM hunt_results()
WHERE Name =~ '(?i)^Updater$'
```

**Response:**
```bash
schtasks /delete /tn "Updater" /f
```

---

### 3.3 UAC Bypass (Phase 4)

**KQL**
```kql
(event.code:4688 AND process.name:(eventvwr.exe OR sdclt.exe OR fodhelper.exe))
OR (event.code:4688 AND parent.process.name:eventvwr.exe AND process.name:cmd.exe)
```

**VQL**
```sql
SELECT * FROM hunt_results()
WHERE KeyPath =~ '(?i)Microsoft\\Windows\\CurrentVersion\\Policies\\System'
```

**Response:**
- Restore UAC defaults
- Investigate privilege escalation

---

### 3.4 Credential Dumping (Phase 5)

**KQL**
```kql
(event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe)
OR (event.code:10 AND winlog.event_data.TargetImage:*lsass.exe)
```

**VQL**
```sql
SELECT * FROM hunt_results()
WHERE Exe =~ '(?i)mimikatz\.exe$'
   OR CommandLine =~ '(?i)sekurlsa::logonpasswords'
```

**Response:**
- Isolate host
- Rotate credentials

---

### 3.5 Lateral Movement (Phase 6)

**KQL**
```kql
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5
```

**VQL**
```sql
SELECT * FROM hunt_results()
WHERE RemoteAddress =~ '192\.168\.1\.5'
  AND LocalPort = 445
```

**Response:**
- Block IP
- Terminate sessions

---

### 3.6 C2 Beacon (Phase 7)

**KQL**
```kql
event.code:3 AND destination.ip:192.168.1.5 AND destination.port:8081
```

**VQL**
```sql
SELECT * FROM hunt_results(artifact="Windows.EventLogs.Sysmon")
WHERE EventID = 3
  AND EventData.DestinationIp =~ '192\.168\.1\.5'
```

**Response:**
- Kill beacon.exe
- Remove payload

---

### 3.7 LOLBin certutil (Defense Evasion)

**KQL**
```kql
event.code:4688 AND process.name:certutil.exe AND command.line:*-urlcache*
```

**VQL**
```sql
SELECT * FROM hunt_results()
WHERE Exe =~ '(?i)certutil\.exe$'
```

**Response:**
- Block certutil if unnecessary
- Investigate parent process

---

## 4. Sigma Rules

| Rule | Severity | MITRE |
|------|----------|-------|
| malware-execution.yaml | High | Execution |
| persistence-task.yaml | Medium | Persistence |
| privilege-escalation.yaml | High | Priv Esc |
| credential-access.yaml | Critical | Credential Access |
| lateral-movement.yaml | High | Lateral Movement |
| command-control.yaml | High | C2 |

---

## 5. Post-Hunt Actions

- Capture Kibana screenshots
- Export Velociraptor results
- Kill malicious processes
- Delete persistence artifacts
- Block attacker IPs
- Re-run hunts for validation

---

## 6. Quick Reference Card

| Hunt | Tool | Query |
|------|------|------|
| Reverse shell | Kibana | `shell.exe` |
| Persistence | Velociraptor | `Updater` |
| LSASS access | Kibana | `4663 + lsass.exe` |
| Lateral movement | Kibana | `4624 Type 3` |
| C2 beacon | Velociraptor | `DestinationPort:8081` |

---

## 7. Runbook Example

1. Alert: 4624 from `192.168.1.5`
2. Validate: Kali attacker confirmed
3. Hunt: Velociraptor process-hunting
4. Contain: Kill beacon.exe
5. Eradicate: Remove scheduled task
6. Report: Export logs