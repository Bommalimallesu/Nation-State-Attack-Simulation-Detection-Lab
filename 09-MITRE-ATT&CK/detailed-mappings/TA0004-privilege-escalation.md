# TA0004 – Privilege Escalation (MITRE ATT&CK)

## Tactic

**TA0004 – Privilege Escalation**

### Objective

The objective of the Privilege Escalation tactic is to obtain higher-level permissions on a compromised system, such as Administrator or `NT AUTHORITY\SYSTEM`, allowing the attacker to bypass security restrictions and access protected resources.

In this laboratory simulation, privilege escalation was demonstrated through:

- **T1548.002 – Abuse Elevation Control Mechanism: Bypass User Account Control (UAC)**
- **T1134.001 – Access Token Manipulation: Token Impersonation/Theft**

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|------------------------------------------------------|----------------------------------------------|
| **T1548.002** | Bypass User Account Control | Abuse trusted Windows components to obtain elevated execution |
| **T1134.001** | Token Impersonation/Theft | Obtain or impersonate a privileged security token |
| **TA0004** | Privilege Escalation | Gain higher permissions on the target system |

---

# Attack Description

After establishing an initial foothold on workstation **WS1**, the attacker elevated privileges using a User Account Control (UAC) bypass technique. A trusted Windows executable (`eventvwr.exe`) was abused to spawn an elevated command shell without displaying a UAC prompt.

Following successful elevation, the attacker obtained **SYSTEM-level privileges** using a token impersonation technique, allowing unrestricted access to sensitive operating system resources and enabling subsequent credential dumping activities.

---

# Technique 1 – UAC Bypass (T1548.002)

## Overview

User Account Control (UAC) is designed to prevent unauthorized privilege elevation by requiring user approval before administrative actions are performed. Attackers may abuse trusted Microsoft-signed binaries that auto-elevate to bypass these protections.

In this simulation, `eventvwr.exe` was used to launch an elevated command prompt, effectively bypassing UAC and granting high-integrity execution.

---

# Attack Simulation Workflow

1. Obtain code execution as a standard or medium-integrity user.
2. Invoke `eventvwr.exe`.
3. `eventvwr.exe` launches an elevated process.
4. An elevated `cmd.exe` becomes available.
5. The attacker continues operations with administrative privileges.

---

# Detection Opportunities – UAC Bypass

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Event ID 4688 | `eventvwr.exe` spawning `cmd.exe` | Suspicious parent-child relationship |
| Event ID 4688 | `fodhelper.exe` or `sdclt.exe` spawning shells | Possible UAC bypass |
| Sysmon Event ID 1 | Elevated process creation | High-integrity `cmd.exe` |
| Registry Monitoring | Changes to auto-elevation registry keys | Unexpected registry modifications |
| EDR Telemetry | Abnormal elevation without user interaction | Behavioral detection |

---

# Example Kibana KQL Queries

## Detect eventvwr spawning cmd.exe

```kql
event.code:4688 and process.parent.name:"eventvwr.exe" and process.name:"cmd.exe"
```

## Detect common UAC bypass binaries

```kql
event.code:4688 and process.name:(eventvwr.exe or fodhelper.exe or sdclt.exe)
```

## Detect elevated command shells

```kql
event.code:4688 and process.name:"cmd.exe"
```

---

# MITRE ATT&CK Mapping – UAC Bypass

| Field | Value |
|---------|---------------------------------------------|
| **Tactic** | Privilege Escalation (TA0004) |
| **Technique** | Abuse Elevation Control Mechanism |
| **Sub-technique** | T1548.002 – Bypass User Account Control |
| **Platform** | Windows |
| **Permissions Required** | Standard User |
| **Primary Data Sources** | Process Creation, Registry Monitoring, EDR |
| **Detection Difficulty** | Moderate |

---

# Technique 2 – Token Impersonation (T1134.001)

## Overview

After obtaining administrative execution, the attacker elevated privileges further by impersonating a privileged security token to acquire **NT AUTHORITY\SYSTEM** privileges.

Token impersonation enables attackers to execute processes under the security context of another account, often granting unrestricted access to protected resources.

---

# Attack Simulation Workflow

1. Obtain administrative privileges.
2. Invoke the privilege escalation mechanism.
3. Duplicate or impersonate a SYSTEM token.
4. Execute processes with SYSTEM integrity.
5. Verify elevated context before proceeding to credential access.

---

# Detection Opportunities – Token Impersonation

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Security Event 4672 | Special privileges assigned | Elevated privileges |
| Sysmon Event 8 | Remote thread creation | Injection behavior |
| Sysmon Event 10 | Sensitive process access | Access to protected processes |
| EDR Telemetry | Token duplication or impersonation | Privilege escalation behavior |
| API Monitoring | Calls related to token manipulation | Unusual token operations |

---

# MITRE ATT&CK Mapping – Token Impersonation

| Field | Value |
|---------|---------------------------------------------|
| **Tactic** | Privilege Escalation (TA0004) |
| **Technique** | Access Token Manipulation |
| **Sub-technique** | T1134.001 – Token Impersonation/Theft |
| **Platform** | Windows |
| **Permissions Required** | Administrator |
| **Primary Data Sources** | Process Monitoring, EDR, Sysmon |
| **Detection Difficulty** | High |

---

# Combined Privilege Escalation Timeline

| Time | Activity | MITRE Technique |
|--------|---------------------------------------------|----------------|
| 06:15:05 | `eventvwr.exe` launched | T1548.002 |
| 06:15:05 | Elevated `cmd.exe` created | T1548.002 |
| 06:15:06 | Administrative session obtained | T1548.002 |
| 06:15:09 | SYSTEM token acquired | T1134.001 |
| 06:15:10 | Process running as SYSTEM | T1134.001 |

---

# Kibana Evidence

## Event ID 4688 – eventvwr.exe

```
Process Name:
C:\Windows\System32\eventvwr.exe
```

---

## Event ID 4688 – Elevated cmd.exe

```
Process Name:
C:\Windows\System32\cmd.exe

Parent Process:
eventvwr.exe
```

---

## Event ID 4672

```
Special privileges assigned to new logon
```

This event indicates assignment of elevated privileges and may accompany successful privilege escalation.

---

# Correlated Detection Logic

| Detection | Purpose |
|------------|-----------------------------------------------|
| `eventvwr.exe → cmd.exe` | Detect UAC bypass |
| Elevated `cmd.exe` | Identify high-integrity shells |
| Privileged token assignment | Detect privilege escalation |
| Sensitive process access | Identify post-escalation behavior |
| Rapid transition from User to SYSTEM | Behavioral correlation |

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|---------------------------------------|
| Parent Process | `eventvwr.exe` |
| Child Process | `cmd.exe` |
| Integrity Level | High or SYSTEM |
| Suspicious Utility | `eventvwr.exe` |
| Privilege Change | User → Administrator → SYSTEM |
| Behavior | Unexpected privilege elevation |

---

# Mitigation and Prevention

- Keep Windows systems fully updated to reduce exposure to known UAC bypass techniques.
- Configure UAC to the highest notification level where operationally appropriate.
- Monitor parent-child relationships involving `eventvwr.exe`, `fodhelper.exe`, and `sdclt.exe`.
- Enable detailed process creation auditing and Sysmon process logging.
- Deploy Endpoint Detection and Response (EDR) solutions capable of detecting abnormal privilege escalation and token manipulation.
- Alert when high-integrity processes are created without expected administrative workflows.

---

# Key Takeaways

Privilege escalation enables attackers to move beyond the limitations of standard user accounts and gain unrestricted control over a compromised system. Monitoring unusual process relationships, unexpected elevated shells, and rapid privilege transitions provides valuable opportunities for defenders to detect escalation attempts before they lead to credential theft or lateral movement.

---

# References

- MITRE ATT&CK – TA0004: Privilege Escalation
- MITRE ATT&CK – T1548.002: Bypass User Account Control
- MITRE ATT&CK – T1134.001: Token Impersonation/Theft
- Lab Simulation: UAC Bypass and Privilege Escalation on WS1