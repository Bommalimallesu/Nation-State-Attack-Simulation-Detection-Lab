# MITRE ATT&CK Framework Overview – APT Attack Chain Simulation

This document provides a high-level overview of the MITRE ATT&CK framework (Enterprise – Windows) as applied to the simulated APT attack chain. It summarizes the tactics, techniques, procedures (TTPs), detection opportunities, and defensive recommendations observed throughout the lab.

---

# 1. What is MITRE ATT&CK?

MITRE ATT&CK (Adversarial Tactics, Techniques, and Common Knowledge) is a publicly available knowledge base that documents adversary behavior based on real-world observations. It organizes attacks into:

- **Tactics** – The attacker's objective at each stage.
- **Techniques** – The methods used to accomplish those objectives.
- **Sub-techniques** – More specific implementations of techniques.

This lab maps each attack phase to the appropriate ATT&CK techniques for Windows environments.

---

# 2. ATT&CK Tactics Used in the Simulation

| Tactic ID | Tactic | Description |
|-----------|---------|-------------|
| TA0001 | Initial Access | Malicious executable (`shell.exe`) executed on WS1. |
| TA0002 | Execution | Commands executed using `cmd.exe` and malicious binaries. |
| TA0003 | Persistence | Scheduled task created to relaunch malware automatically. |
| TA0004 | Privilege Escalation | UAC bypass and SYSTEM token impersonation. |
| TA0005 | Defense Evasion | Windows Defender and Firewall disabled; `certutil.exe` abused. |
| TA0006 | Credential Access | LSASS memory accessed to obtain NTLM credentials. |
| TA0008 | Lateral Movement | Pass-the-Hash authentication and SMB-based remote execution. |
| TA0011 | Command and Control | HTTP beacon communicated with attacker infrastructure. |

---

# 3. Techniques Used

| Technique ID | Technique | Attack Phase |
|--------------|-----------|--------------|
| T1204.002 | User Execution – Malicious File | Initial Access / Execution |
| T1059.003 | Windows Command Shell | Execution |
| T1053.005 | Scheduled Task | Persistence |
| T1548.002 | Bypass User Account Control | Privilege Escalation |
| T1134.001 | Token Impersonation / Theft | Privilege Escalation |
| T1562.001 | Disable Security Tools | Defense Evasion |
| T1562.004 | Disable Firewall | Defense Evasion |
| T1218.008 | Signed Binary Proxy Execution (`certutil`) | Defense Evasion |
| T1003.001 | LSASS Memory Dumping | Credential Access |
| T1550.002 | Pass the Hash | Lateral Movement |
| T1021.002 | SMB / Windows Admin Shares | Lateral Movement |
| T1071.001 | Application Layer Protocol (HTTP) | Command and Control |

---

# 4. Detection Coverage

| Tactic | Primary Events |
|---------|----------------|
| Initial Access | Event ID 4688 |
| Execution | Event ID 4688 |
| Persistence | Event ID 4698 |
| Privilege Escalation | Event ID 4688, Sysmon Event 10 |
| Defense Evasion | Event ID 5007, Event ID 2004, Event ID 4688 |
| Credential Access | Event ID 4663, Sysmon Event 10 |
| Lateral Movement | Event IDs 4624, 4672, 5140, 7045 |
| Command and Control | Sysmon Event 3 |

---

# 5. ATT&CK Matrix Summary

```
TA0001  Initial Access
  └── T1204.002  User Execution

TA0002  Execution
  ├── T1059.003  Windows Command Shell
  └── T1204.002  User Execution

TA0003  Persistence
  └── T1053.005  Scheduled Task

TA0004  Privilege Escalation
  ├── T1548.002  UAC Bypass
  └── T1134.001  Token Impersonation

TA0005  Defense Evasion
  ├── T1562.001  Disable Security Tools
  ├── T1562.004  Disable Firewall
  └── T1218.008  Certutil Proxy Execution

TA0006  Credential Access
  └── T1003.001  LSASS Memory Dumping

TA0008  Lateral Movement
  ├── T1550.002  Pass the Hash
  └── T1021.002  SMB / Admin Shares

TA0011  Command and Control
  └── T1071.001  HTTP Beacon
```

---

# 6. Required Log Sources

| Technique | Log Source |
|-----------|------------|
| User Execution | Security Event 4688 |
| Command Shell | Security Event 4688 |
| Scheduled Task | Security Event 4698 |
| UAC Bypass | Security Event 4688 |
| Token Manipulation | Sysmon Event 10 |
| Defender Disable | Windows Defender Operational Log |
| Firewall Disable | Windows Firewall Logs |
| Certutil Execution | Security Event 4688 |
| LSASS Access | Security Event 4663, Sysmon Event 10 |
| Pass the Hash | Security Event 4624 |
| SMB Lateral Movement | Events 5140 and 7045 |
| HTTP Beacon | Sysmon Event 3 |

---

# 7. Defensive Recommendations

- Enable Sysmon with process creation, network connection, and process access logging.
- Enable command-line auditing for Event ID 4688.
- Forward Windows Defender and Firewall logs to the SIEM.
- Monitor scheduled task creation (Event ID 4698).
- Alert on access to `lsass.exe` by non-system processes.
- Monitor NTLM network logons from unusual source hosts.
- Detect service creation events such as `PSEXESVC`.
- Alert on execution of `certutil.exe` with `-urlcache` or HTTP URLs.
- Monitor outbound connections to uncommon ports such as 4444 and 8081.
- Block execution of unsigned binaries from `C:\Users\Public` using application control.

---

# 8. Overall Attack Flow

```
Initial Access
        │
        ▼
User executes shell.exe
        │
        ▼
Windows Command Shell
        │
        ▼
Scheduled Task Persistence
        │
        ▼
UAC Bypass
        │
        ▼
SYSTEM Privileges
        │
        ▼
LSASS Credential Dumping
        │
        ▼
Pass-the-Hash Authentication
        │
        ▼
SMB / PsExec Lateral Movement
        │
        ▼
Beacon Deployment
        │
        ▼
HTTP Command and Control
```

---

# 9. Conclusion

The simulated attack chain demonstrates a realistic progression across multiple MITRE ATT&CK tactics and techniques, including execution, persistence, privilege escalation, defense evasion, credential access, lateral movement, and command and control. With Windows Security logs, Sysmon telemetry, and SIEM correlation, defenders can detect each stage of the attack lifecycle and respond before adversaries achieve their objectives.