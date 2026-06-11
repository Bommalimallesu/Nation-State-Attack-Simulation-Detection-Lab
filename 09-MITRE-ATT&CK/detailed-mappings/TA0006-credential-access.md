# TA0006 – Credential Access (MITRE ATT&CK)

## Tactic

**TA0006 – Credential Access**

### Objective

The objective of the Credential Access tactic is to obtain user credentials, password hashes, or authentication material that can be used for privilege escalation or lateral movement. In this laboratory simulation, the attacker extracted credentials from the Local Security Authority Subsystem Service (LSASS) memory after obtaining elevated privileges.

**Simulated Technique:**

- **T1003.001 – OS Credential Dumping: LSASS Memory**

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|-----------------------------------------|--------------------------------------------|
| **T1003.001** | LSASS Memory | Dump credentials stored in the LSASS process |
| **TA0006** | Credential Access | Obtain authentication material from a compromised host |

---

# Attack Description

The Local Security Authority Subsystem Service (**LSASS**) stores authentication-related information such as NTLM password hashes, Kerberos tickets, and cached credentials for logged-on users.

After successfully escalating privileges to **SYSTEM**, the attacker accessed LSASS memory and extracted the NTLM hash belonging to the `NATION\Administrator` account. The recovered credential material could then be reused in later attack stages, including lateral movement or pass-the-hash authentication.

---

# Technique Overview – LSASS Memory (T1003.001)

Credential dumping targets the LSASS process because it contains sensitive authentication information required by Windows to manage user logons.

Typical attacker objectives include:

- Extract NTLM password hashes
- Obtain Kerberos tickets
- Recover cached credentials
- Enable pass-the-hash attacks
- Facilitate lateral movement

---

# Attack Simulation Workflow

1. Gain access to WS1.
2. Escalate privileges to Administrator or SYSTEM.
3. Access the LSASS process.
4. Read authentication material stored in memory.
5. Extract the NTLM hash for the domain administrator account.
6. Reuse the credential in subsequent attack stages.

---

# Detection Opportunities

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Security Event ID 4663 | Detect access to LSASS-related objects | Access to `lsass.exe` |
| Sysmon Event ID 10 | Monitor process access to LSASS | Target image is `lsass.exe` |
| Sysmon Event ID 1 | Detect execution of credential dumping tools | Suspicious process creation |
| Security Event ID 4688 | Monitor process creation | Processes interacting with LSASS |
| PowerShell Event ID 4104 | Detect PowerShell-based dumping activity | Suspicious script blocks |
| EDR Telemetry | Behavioral detection | Unauthorized LSASS memory access |

---

# MITRE ATT&CK Mapping Summary

| Field | Value |
|---------|---------------------------------------------|
| **Tactic** | Credential Access (TA0006) |
| **Technique** | OS Credential Dumping |
| **Sub-technique** | T1003.001 – LSASS Memory |
| **Platform** | Windows |
| **Permissions Required** | Administrator or SYSTEM |
| **Primary Data Sources** | Security Logs, Sysmon, Process Monitoring, EDR |
| **Detection Difficulty** | High |

---

# Example Kibana KQL Queries

## Detect LSASS access using Sysmon

```kql
event.code:10 and winlog.event_data.TargetImage:*lsass.exe
```

## Detect Security Event 4663 involving LSASS

```kql
event.code:4663 and winlog.event_data.ObjectName:*lsass.exe
```

## Detect execution of common credential dumping tools

```kql
event.code:4688 and process.name:(mimikatz.exe or procdump.exe)
```

## Detect PowerShell credential dumping activity

```kql
event.code:4104 and winlog.event_data.ScriptBlockText:*sekurlsa*
```

---

# Example Security Event 4663

```
Object Name:
\lsass.exe

Access Mask:
0x1FFFFF

Process Name:
C:\Users\Public\shell.exe
```

---

# Example Sysmon Event 10

```
Target Image:
C:\Windows\System32\lsass.exe

Source Image:
C:\Users\Public\shell.exe

Granted Access:
0x1FFFFF
```

---

# Extracted Credential Evidence

| Account | Domain | Credential Type |
|----------|---------|----------------|
| Administrator | NATION | NTLM Hash |

> **Note:** Replace placeholder values with the actual evidence collected in your own lab environment. Avoid publishing sensitive credential material in reports unless necessary.

---

# Correlated Detection Timeline

| Stage | Detection Opportunity |
|---------|---------------------------------------------|
| Privilege Escalation | Elevated process creation |
| LSASS Access | Sysmon Event 10 |
| Object Handle Access | Security Event 4663 |
| Credential Extraction | EDR behavioral detection |
| Subsequent Authentication | Correlation with lateral movement events |

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|------------------------------------|
| Target Process | `lsass.exe` |
| Suspicious Source Process | `shell.exe` |
| Event ID | 4663 |
| Sysmon Event | 10 |
| Behavior | Unauthorized LSASS memory access |

---

# Forensic Artifacts

Investigators should review the following artifacts:

| Artifact | Description |
|-----------|------------------------------------------------|
| Security Event Log | Event ID 4663 |
| Sysmon Log | Event ID 10 |
| Process Creation Log | Event ID 4688 |
| PowerShell Operational Log | Event ID 4104 |
| EDR Alerts | Memory credential access detections |
| Memory Image | Volatile memory for forensic analysis |

---

# Example Sigma Rule

```yaml
title: Suspicious LSASS Access

id: suspicious-lsass-access

status: experimental

logsource:
  product: windows
  service: sysmon

detection:
  selection:
    EventID: 10
    TargetImage|endswith: '\lsass.exe'

  condition: selection

level: high
```

---

# Detection Recommendations

- Enable Sysmon Process Access logging (Event ID 10).
- Monitor Security Event ID 4663 for unauthorized access to `lsass.exe`.
- Alert when non-system processes access LSASS memory.
- Correlate privilege escalation events with subsequent LSASS access.
- Deploy Endpoint Detection and Response (EDR) tools capable of detecting credential dumping behavior.
- Investigate unusual process access rights targeting sensitive security processes.

---

# Mitigation and Prevention

- Enable Windows Defender Credential Guard where supported.
- Restrict administrative privileges to authorized users only.
- Enable detailed process and object access auditing.
- Deploy behavioral detections for unauthorized LSASS access.
- Minimize privileged account usage on workstations.
- Regularly patch systems and monitor access to protected security processes.

---

# Key Takeaways

Credential dumping from LSASS is a widely used post-exploitation technique that enables attackers to obtain reusable authentication material for privilege escalation and lateral movement. Comprehensive monitoring of process creation, object access, Sysmon telemetry, and behavioral indicators significantly improves detection and response capabilities.

---

# References

- MITRE ATT&CK – TA0006: Credential Access
- MITRE ATT&CK – T1003.001: OS Credential Dumping – LSASS Memory
- Microsoft Sysmon Documentation
- Lab Simulation: Phase 5 – Credential Access