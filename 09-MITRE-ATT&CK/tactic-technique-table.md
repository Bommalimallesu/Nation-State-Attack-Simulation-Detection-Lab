# MITRE ATT&CK Tactic & Technique Table – APT Attack Chain Simulation

This table maps each attack phase to MITRE ATT&CK tactics, techniques, detection methods, and lab evidence observed during the simulation.

| Tactic ID | Tactic Name | Technique ID | Technique Name | Detection Method | Lab Evidence (Event ID / Log) |
|-----------|-------------|--------------|----------------|------------------|-------------------------------|
| TA0001 | Initial Access | T1204.002 | User Execution: Malicious File | Process creation from suspicious path | Event 4688: `C:\Users\Public\shell.exe` executed |
| TA0002 | Execution | T1059.003 | Windows Command Shell | Command-line logging of `cmd.exe` | `cmd.exe /c "C:\Users\Public\shell.exe"` |
| TA0002 | Execution | T1204.002 | User Execution: Malicious File | Manual execution monitoring | `shell.exe` launched by the user |
| TA0003 | Persistence | T1053.005 | Scheduled Task | Scheduled task creation (Event 4698) | Task `Updater` configured to execute `shell.exe` |
| TA0004 | Privilege Escalation | T1548.002 | Bypass User Account Control | Parent-child process analysis | `eventvwr.exe` spawning elevated `cmd.exe` |
| TA0004 | Privilege Escalation | T1134.001 | Token Impersonation/Theft | Process access monitoring | Sysmon Event 10 showing access to `lsass.exe` |
| TA0005 | Defense Evasion | T1562.001 | Disable Windows Defender | PowerShell logging / Event 5007 | `Set-MpPreference -DisableRealtimeMonitoring $true` |
| TA0005 | Defense Evasion | T1562.004 | Disable Windows Firewall | PowerShell logging / Firewall events | `Set-NetFirewallProfile -All -Enabled False` |
| TA0005 | Defense Evasion | T1218.008 | Signed Binary Proxy Execution (`certutil`) | Process creation and command-line monitoring | `certutil -urlcache -f http://... beacon.exe` |
| TA0006 | Credential Access | T1003.001 | OS Credential Dumping: LSASS Memory | LSASS handle monitoring | Event 4663 / Sysmon Event 10 accessing `lsass.exe` |
| TA0008 | Lateral Movement | T1550.002 | Pass the Hash | Network logon analysis | Event 4624 (Logon Type 3, NTLM authentication) |
| TA0008 | Lateral Movement | T1021.002 | Remote Services: SMB / Windows Admin Shares | Service installation monitoring | Event 7045 showing `PSEXESVC` installation |
| TA0011 | Command & Control | T1071.001 | Application Layer Protocol (HTTP) | Network connection monitoring | Sysmon Event 3 showing `beacon.exe` communicating with `192.168.1.5:8081` |

---

## Coverage Summary

- **MITRE ATT&CK Tactics Covered:** 8
  - Initial Access (TA0001)
  - Execution (TA0002)
  - Persistence (TA0003)
  - Privilege Escalation (TA0004)
  - Defense Evasion (TA0005)
  - Credential Access (TA0006)
  - Lateral Movement (TA0008)
  - Command and Control (TA0011)

- **Techniques/Sub-techniques Demonstrated:** 12

- **Detection Coverage:** All simulated techniques generated observable Windows Security logs, Sysmon events, or PowerShell logs when the required auditing was enabled.