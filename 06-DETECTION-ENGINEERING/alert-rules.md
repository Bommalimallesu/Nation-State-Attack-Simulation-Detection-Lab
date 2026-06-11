# Detection Alert Rules – APT Attack Chain Simulation

This document consolidates all detection rules created for the APT simulation.  
Rules are written in **KQL (Kibana Query Language)** for Elastic SIEM correlation.

---

# 1. Initial Access – Reverse Shell

## Suspicious Process Execution from Public/Temp Directories

```kql
event.code: 4688
and winlog.event_data.ProcessName: (*shell.exe or *beacon.exe)
and winlog.event_data.ParentProcessName: (cmd.exe or powershell.exe)
and winlog.event_data.ProcessName: (*\Users\Public\* or *\Temp\*)
```

- MITRE: TA0002 – Execution (T1059, T1204)  
- Severity: High  

---

# 2. Persistence – Scheduled Task

```kql
event.code: 4698
and winlog.event_data.TaskName: *
and winlog.event_data.TaskContent: (*shell.exe or *beacon.exe or *C:\\Users\\Public\\* or *C:\\Temp\\*)
```

- MITRE: TA0003 – Persistence (T1053.005)  
- Severity: Medium  

---

# 3. Privilege Escalation – UAC Bypass

```kql
(event.code: 4688 and winlog.event_data.ProcessName: (eventvwr.exe or sdclt.exe or fodhelper.exe or computerdefaults.exe))
or
(event.code: 4688 and winlog.event_data.ParentProcessName: (eventvwr.exe or sdclt.exe or fodhelper.exe)
and winlog.event_data.ProcessName: (cmd.exe or powershell.exe))
```

- MITRE: TA0004 – Privilege Escalation (T1548.002)  
- Severity: High  

---

# 4. Credential Access – LSASS Dumping

```kql
(event.code: 10 and winlog.event_data.TargetImage: *\lsass.exe and winlog.event_data.CallTrace: *mimikatz*)
or
(event.code: 4663 and winlog.event_data.ObjectName: *\lsass.exe and winlog.event_data.AccessMask: 0x1FFFFF)
or
(event.code: 4688 and winlog.event_data.ProcessName: (mimikatz.exe or procdump.exe or sqlmigrator.exe))
```

- MITRE: TA0006 – Credential Access (T1003.001)  
- Severity: Critical  

---

# 5. Lateral Movement – Pass-the-Hash

```kql
(event.code: 4624 and winlog.event_data.LogonType: 3
and winlog.event_data.AuthenticationPackageName: NTLM
and not winlog.event_data.WorkstationName: *$)
or
(event.code: 5140 and winlog.event_data.ShareName: *ADMIN$)
or
(event.code: 4688 and winlog.event_data.ProcessName: *PSEXESVC*.exe)
```

- MITRE: TA0008 – Lateral Movement (T1550.002, T1021.002)  
- Severity: High  

---

# 6. Command & Control – HTTP Beacon

```kql
(event.code: 3 and destination.port: (8080 or 8081 or 4444 or 4445)
and process.name: (beacon.exe or shell.exe))
or
(event.code: 3 and destination.ip: 192.168.1.5 and destination.port: 8081)
```

- MITRE: TA0011 – Command & Control (T1071.001)  
- Severity: High  

---

# 7. Defense Evasion – certutil LOLBin

```kql
event.code: 4688
and winlog.event_data.ProcessName: *\certutil.exe*
and winlog.event_data.CommandLine: (*-urlcache* and *http://* and *.exe)
```

- MITRE: TA0005 – Defense Evasion (T1218)  
- Severity: Medium  

---

# 8. Process Lineage Anomaly

```kql
winlog.event_id: 4688
and winlog.event_data.ParentProcess: *certutil.exe*
and winlog.event_data.ProcessName: *.exe*
```

- MITRE: TA0005 / TA0008  
- Severity: High  

---

# Severity Summary

| Severity | Detection Types |
|----------|----------------|
| Critical | LSASS Dumping (Mimikatz / Kiwi) |
| High | Reverse shell, UAC bypass, lateral movement, C2 beacon |
| Medium | Persistence, certutil download |

---

# Notes

- Use in Kibana Elastic Security Rules
- Correlate with Sysmon Events: 1, 3, 10, 4624, 4688
- Validate with Velociraptor hunts
- Suitable for SOC internship / portfolio project

---