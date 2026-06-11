# Detection Overview – APT Attack Chain Simulation

This document provides a high-level summary of all detection rules, relevant Windows event IDs, Sysmon events, and MITRE ATT&CK mappings generated throughout the attack simulation. It serves as the central reference for the detection engineering phase.

---

## 1. Detection Coverage by Attack Phase

| Phase | Attack Action | Event IDs (Windows / Sysmon) | Kibana / Sigma Rule | MITRE Tactic & Technique |
|-------|---------------|-------------------------------|---------------------|--------------------------|
| Phase 1 | Reconnaissance (Nmap) | Sysmon 3 (network connection) | `event.code:3 AND source.ip:192.168.1.5` | TA0043 – Reconnaissance (T1595) |
| Phase 2 | Reverse shell execution (shell.exe) | 4688, Sysmon 1 | `rule-01-reverse-shell.kql` | TA0002 – Execution (T1059, T1204) |
| Phase 3 | Scheduled task persistence (Updater) | 4698 | `rule-02-persistence-task.kql` | TA0003 – Persistence (T1053.005) |
| Phase 4 | UAC bypass (eventvwr, fodhelper, sdclt) | 4688 | `rule-03-uac-bypass.kql` | TA0004 – Privilege Escalation (T1548.002) |
| Phase 5 | Credential dumping (LSASS access) | 4663, 10 (Sysmon), 4688 | `rule-04-credential-dumping.kql` | TA0006 – Credential Access (T1003.001) |
| Phase 6 | Lateral movement (pass-the-hash, psexec) | 4624, 4672, 5140, 4688 | `rule-05-lateral-movement.kql` | TA0008 – Lateral Movement (T1550.002, T1021.002) |
| Phase 7 | C2 HTTP beacon (beacon.exe) | 4688, Sysmon 3 | `rule-06-c2-beacon.kql` | TA0011 – Command & Control (T1071.001) |
| Phase 7 | LOLBin certutil download | 4688 | `command-control.yaml (LOLBin section)` | TA0005 – Defense Evasion (T1218) |
| Phase 8 | Process lineage anomaly (certutil → beacon.exe) | 4688 (parent-child) | Custom KQL / Sigma | TA0005 / TA0008 |

---

## 2. Windows Event IDs Used

| Event ID | Description | Attack Phase(s) |
|----------|-------------|----------------|
| 4624 | Successful logon (Logon Type 3 = network) | Phase 6 |
| 4672 | Admin logon (special privileges) | Phase 6 |
| 4688 | Process creation | Phases 2, 4, 5, 6, 7 |
| 4698 | Scheduled task creation | Phase 3 |
| 4663 | Handle to object (LSASS access) | Phase 5 |
| 5140 | Network share access (ADMIN$) | Phase 6 |

---

## 3. Sysmon Event IDs Used

| Event ID | Description | Attack Phase(s) |
|----------|-------------|----------------|
| 1 | Process creation | Phases 2, 7 |
| 3 | Network connection | Phases 1, 7 |
| 10 | Process access (LSASS) | Phase 5 |

---

## 4. Kibana Queries (KQL) – Quick Reference

```kql
// Reverse shell
event.code:4688 AND process.name:shell.exe

// Scheduled task
event.code:4698 AND winlog.event_data.TaskName:Updater

// LSASS access
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe

// Lateral movement (network logon)
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5

// C2 beacon network
event.code:3 AND destination.port:8081 AND process.name:beacon.exe

// LOLBin certutil
event.code:4688 AND winlog.event_data.ProcessName:*certutil.exe AND winlog.event_data.CommandLine:*-urlcache*

// Process lineage
winlog.event_id:4688 AND winlog.event_data.ParentProcess:*certutil.exe*
```

---

## 5. Sigma Rules Created

| Rule File | Location |
|-----------|----------|
| malware-execution.yaml | sigma-rules/ |
| persistence-task.yaml | sigma-rules/ |
| privilege-escalation.yaml | sigma-rules/ |
| credential-access.yaml | sigma-rules/ |
| lateral-movement.yaml | sigma-rules/ |
| command-control.yaml | sigma-rules/ |

Each Sigma rule includes:
- Detection logic
- Log source mapping
- False positives
- Severity level

---

## 6. Alert Severity Matrix

| Severity | Rule / Event |
|----------|-------------|
| Critical | LSASS access via non-system process, Mimikatz execution |
| High | Reverse shell, UAC bypass, pass-the-hash, C2 beacon, certutil download |
| Medium | Scheduled task persistence |
| Low | Reconnaissance (Nmap) |

---

## 7. Detection Engineering Notes

- Winlogbeat must be installed on all Windows hosts (WS1, DC, File Server)
- Sysmon required for Event IDs 1, 3, 10
- Enable command-line logging for Event 4688
- Use time correlation (Kibana Timeline / Velociraptor hunts)
- Tune false positives (exclude trusted admin IPs and tools)

---

## 8. Velociraptor Artifact Cross-Reference

| Kibana Event | Velociraptor Artifact | Purpose |
|--------------|----------------------|---------|
| 4688 shell.exe | Windows.Sys.Processes | Confirm execution |
| 4698 task | Windows.Sys.ScheduledTasks | Verify persistence |
| 4663 / 10 LSASS | Windows.EventLogs.Security | Credential access validation |
| 4624 logon | Windows.EventLogs.Security | Lateral movement check |
| beacon.exe file | Windows.Search.FileFinder | Malware presence on disk |

---