# Kibana Queries – APT Attack Chain Simulation

This document provides all **Kibana Query Language (KQL)** queries used to detect and analyze the APT attack chain. Queries are organized by attack phase and mapped to MITRE ATT&CK tactics.

**Index Pattern:** `winlogbeat-*`  
**Alternative Index Pattern:** `logs-windows.*`

---

# 1. Initial Access (Phase 2) – Reverse Shell

## Detect `shell.exe` Execution

```kql
event.code:4688 AND process.name:shell.exe
```

## Detect Outbound Reverse Shell Connection (Sysmon Event ID 3)

```kql
event.code:3 AND process.name:shell.exe AND destination.port:4444
```

## Detect Payload Download via PowerShell

```kql
event.code:4104 AND winlog.event_data.ScriptBlockText:(Invoke-WebRequest AND -OutFile)
```

---

# 2. Persistence (Phase 3) – Scheduled Task

## Scheduled Task Creation (Event ID 4698)

```kql
event.code:4698 AND winlog.event_data.TaskName:Updater
```

## Task Creation Using Public Folder Path

```kql
event.code:4698 AND winlog.event_data.TaskContent:*C:\\Users\\Public*
```

## Scheduled Task Creation via `schtasks.exe`

```kql
event.code:4688 AND process.name:schtasks.exe AND command.line:*Updater*
```

---

# 3. Privilege Escalation (Phase 4) – UAC Bypass

## `eventvwr.exe` Spawning `cmd.exe`

```kql
event.code:4688 AND winlog.event_data.ParentProcessName:*eventvwr.exe AND winlog.event_data.ProcessName:cmd.exe
```

## Common UAC Bypass Binaries

```kql
event.code:4688 AND process.name:(sdclt.exe OR fodhelper.exe OR computerdefaults.exe)
```

## Privilege Abuse / Token Impersonation

```kql
event.code:4673 AND winlog.event_data.PrivilegeList:*SeDebugPrivilege*
```

---

# 4. Credential Access (Phase 5) – LSASS Dumping

## Access to LSASS Process (Event ID 4663)

```kql
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe AND winlog.event_data.AccessMask:0x1FFFFF
```

## LSASS Process Access (Sysmon Event ID 10)

```kql
event.code:10 AND winlog.event_data.TargetImage:*lsass.exe
```

## Known Credential Dumping Tools

```kql
event.code:4688 AND process.name:(mimikatz.exe OR procdump.exe OR sqlmigrator.exe)
```

## PowerShell Mimikatz Detection

```kql
event.code:4104 AND winlog.event_data.ScriptBlockText:*sekurlsa::logonpasswords*
```

---

# 5. Lateral Movement (Phase 6) – Pass-the-Hash & PsExec

## Network Logon (Type 3) from Attacker IP

```kql
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5
```

## Administrative Logon

```kql
event.code:4672 AND winlog.event_data.TargetUserName:Administrator
```

## Access to ADMIN$ Share

```kql
event.code:5140 AND winlog.event_data.ShareName:*ADMIN$* AND source.ip:192.168.1.5
```

## PsExec Service Installation

```kql
event.code:7045 AND winlog.event_data.ServiceName:PSEXESVC
```

## PsExec Service Execution

```kql
event.code:4688 AND process.name:PSEXESVC.exe
```

---

# 6. Command & Control (Phase 7) – HTTP Beacon

## Beacon Process Execution

```kql
event.code:4688 AND process.name:beacon.exe
```

## Outbound HTTP Beacon Traffic

```kql
event.code:3 AND destination.ip:192.168.1.5 AND destination.port:8081
```

## Certutil Downloading an Executable

```kql
event.code:4688 AND process.name:certutil.exe AND command.line:*-urlcache* AND command.line:*.exe
```

## Parent-Child Process Anomaly

```kql
event.code:4688 AND winlog.event_data.ParentProcessName:*certutil.exe AND winlog.event_data.ProcessName:beacon.exe
```

---

# 7. Defense Evasion (Phase 2 & Phase 7)

## Disable Microsoft Defender via PowerShell

```kql
event.code:4104 AND winlog.event_data.ScriptBlockText:*Set-MpPreference* AND *DisableRealtimeMonitoring*
```

## Disable Windows Firewall

```kql
event.code:4104 AND winlog.event_data.ScriptBlockText:*Set-NetFirewallProfile* AND *-Enabled False*
```

## Microsoft Defender Configuration Changes

```kql
event.code:5007 AND winlog.event_data.NewValue:true
```

## Firewall Profile Disabled

```kql
event.code:2004 AND winlog.event_data.ModifiedProfile:"All Profiles" AND winlog.event_data.Enabled:false
```

---

# 8. Correlation & Timeline Queries

## Complete Attack Chain Activity

```kql
host.name:(WS1 OR DC) AND event.code:(4688 OR 4698 OR 4663 OR 4624 OR 4672 OR 5140 OR 7045 OR 3)
```

## Suspicious Process Lineage

```kql
event.code:4688 AND winlog.event_data.ParentProcessName:cmd.exe AND NOT winlog.event_data.ProcessName:(conhost.exe OR find.exe OR sort.exe)
```

## LSASS Access Followed by Lateral Movement

```kql
(event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe) OR (event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5)
```

---

# 9. Utility Queries

## All Events from a Specific Host (Last 2 Hours)

```kql
host.name:WS1 AND @timestamp >= now-2h
```

## Process Creation Events with Command Lines

```kql
event.code:4688 AND winlog.event_data.CommandLine:*
```

## Top Source IPs for Network Logons

> Note: The following uses Elasticsearch aggregations and is not valid in standard KQL Discover searches.

```text
event.code:4624 AND winlog.event_data.LogonType:3
| stats count by source.ip
| sort count desc
| limit 10
```

## Scheduled Tasks Created Per Hour

> Best used in Lens or TSVB visualizations.

```text
event.code:4698
| timechart count by host.name
```

---

# 10. Query Performance & Tuning Tips

## Use Specific Fields

Prefer:

```kql
winlog.event_data.ProcessName:cmd.exe
```

Instead of:

```kql
process.name:cmd.exe
```

when your Windows logs provide detailed event data fields.

## Restrict Time Range

Always apply a time filter to avoid scanning all indices.

Example:

```kql
@timestamp >= now-24h
```

## Avoid Excessive Wildcards

Prefer:

```kql
process.name:shell.exe
```

Over:

```kql
process.name:*shell.exe
```

Use wildcards only when necessary.

## Combine Filters Early

Example:

```kql
event.code:4688 AND host.name:WS1 AND process.name:shell.exe
```

This improves query performance and reduces noise.

---

# MITRE ATT&CK Mapping Summary

| Phase | Tactic | Technique |
|---------|---------|------------|
| Initial Access | Execution | T1059 |
| Persistence | Scheduled Task | T1053.005 |
| Privilege Escalation | UAC Bypass | T1548.002 |
| Credential Access | OS Credential Dumping | T1003.001 |
| Lateral Movement | Pass-the-Hash / PsExec | T1550.002, T1569 |
| Command & Control | Application Layer Protocol | T1071.001 |
| Defense Evasion | Impair Defenses | T1562.001 |

---