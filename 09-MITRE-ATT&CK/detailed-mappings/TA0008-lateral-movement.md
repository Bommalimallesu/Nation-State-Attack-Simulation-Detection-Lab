# TA0008 – Lateral Movement (MITRE ATT&CK)

## Tactic

**TA0008 – Lateral Movement**

### Objective

The objective of the Lateral Movement tactic is to move from one compromised system to another within a network while maintaining access and expanding control over enterprise resources.

**Simulated Techniques:**

- **T1550.002 – Pass the Hash**
- **T1021.002 – Remote Services: SMB/Windows Admin Shares (PsExec)**

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|-----------------------------------------------|--------------------------------------------|
| **T1550.002** | Pass the Hash | Authenticate using an NTLM hash instead of a plaintext password |
| **T1021.002** | SMB/Windows Admin Shares | Execute commands remotely using SMB administrative shares |

---

# Attack Description

After obtaining the NTLM hash of the `NATION\Administrator` account during the Credential Access phase, the attacker used the hash to authenticate to the Domain Controller without knowing the user's plaintext password.

Using an SMB-based remote administration technique, the attacker uploaded a service executable, created the **PSEXESVC** service, and obtained an interactive command shell on the remote system.

---

# Technique Overview – Pass the Hash (T1550.002)

Pass the Hash (PtH) allows attackers to authenticate using a captured NTLM hash rather than the actual password.

Typical attacker workflow:

1. Extract NTLM credentials from a compromised machine.
2. Authenticate to another Windows system using the hash.
3. Obtain remote administrative access.
4. Continue post-exploitation activities.

---

# Technique Overview – SMB / PsExec (T1021.002)

SMB administrative shares such as **ADMIN$** are commonly abused for remote execution.

PsExec-style tools typically:

- Connect to the ADMIN$ share.
- Upload a service executable.
- Create a temporary Windows service.
- Start the service.
- Execute attacker-controlled commands remotely.

---

# Attack Simulation Workflow

1. Extract Administrator NTLM hash from WS1.
2. Connect from Kali to the Domain Controller using SMB.
3. Authenticate using Pass the Hash.
4. Access the ADMIN$ share.
5. Upload `PSEXESVC.exe`.
6. Create the `PSEXESVC` service.
7. Start the service.
8. Obtain a remote command shell on the Domain Controller.

---

# Detection Opportunities

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Security Event ID 4624 | Network logon using NTLM | Logon Type 3 |
| Security Event ID 4672 | Special privileges assigned | Administrative logon |
| Security Event ID 5140 | Access to ADMIN$ share | Remote SMB activity |
| Security Event ID 7045 | Service installation | New `PSEXESVC` service |
| Security Event ID 4688 | Process creation | Execution of `PSEXESVC.exe` |
| Sysmon Event ID 11 | File creation | `PSEXESVC.exe` written to disk |
| Sysmon Event ID 1 | Process creation | Suspicious remote execution |

---

# MITRE ATT&CK Mapping – Pass the Hash

| Field | Value |
|---------|--------------------------------------------|
| **Tactic** | Lateral Movement (TA0008) |
| **Technique** | Use Alternate Authentication Material |
| **Sub-technique** | T1550.002 – Pass the Hash |
| **Platform** | Windows |
| **Permissions Required** | Administrative credentials |
| **Detection Difficulty** | High |

---

# MITRE ATT&CK Mapping – SMB/Admin Shares

| Field | Value |
|---------|--------------------------------------------|
| **Tactic** | Lateral Movement (TA0008) |
| **Technique** | Remote Services |
| **Sub-technique** | T1021.002 – SMB/Windows Admin Shares |
| **Platform** | Windows |
| **Permissions Required** | Administrator |
| **Detection Difficulty** | High |

---

# Example Kibana KQL Queries

## Detect NTLM network logons

```kql
event.code:4624 AND winlog.event_data.LogonType:3 AND winlog.event_data.AuthenticationPackageName:NTLM
```

## Detect administrative privilege assignment

```kql
event.code:4672
```

## Detect ADMIN$ share access

```kql
event.code:5140 AND winlog.event_data.ShareName:*ADMIN$*
```

## Detect PSEXESVC service installation

```kql
event.code:7045 AND winlog.event_data.ServiceName:PSEXESVC
```

## Detect execution of PSEXESVC

```kql
event.code:4688 AND process.name:PSEXESVC.exe
```

---

# Example Security Events

## Event ID 4624

```
Logon Type:
3

Authentication Package:
NTLM

Target User:
Administrator
```

## Event ID 5140

```
Share Name:
ADMIN$

Access:
Remote SMB Connection
```

## Event ID 7045

```
Service Name:
PSEXESVC

Service Type:
Own Process
```

---

# Correlated Attack Timeline

| Time | Activity |
|--------|--------------------------------------------|
| 06:15:11 | NTLM hash extracted from WS1 |
| 06:15:23 | NTLM authentication to Domain Controller |
| 06:15:23 | ADMIN$ share accessed |
| 06:15:23 | PSEXESVC service installed |
| 06:15:24 | Remote shell established |

---

# Indicators of Compromise (IOCs)

| IOC Type | Value |
|-----------|--------------------------------------|
| Authentication | NTLM Network Logon |
| Share Access | ADMIN$ |
| Service Name | PSEXESVC |
| Executable | PSEXESVC.exe |
| Event IDs | 4624, 4672, 5140, 7045, 4688 |

---

# Forensic Artifacts

Investigators should examine:

| Artifact | Description |
|-----------|----------------------------------------------|
| Security.evtx | Logon and service creation events |
| System.evtx | Service start and stop events |
| Sysmon Logs | Process and file creation |
| Windows Temp Directory | Presence of `PSEXESVC.exe` |
| SMB Logs | Administrative share access |

---

# Example Sigma Rule

```yaml
title: Suspicious PsExec Service Installation

id: detect-psexec-service

status: experimental

logsource:
  product: windows
  service: security

detection:
  selection:
    EventID: 7045
    ServiceName|contains: 'PSEXESVC'

  condition: selection

level: high
```

---

# Correlation with Previous Attack Phases

The Credential Access phase produced reusable NTLM authentication material. Within seconds, that credential was used to authenticate remotely and move laterally to the Domain Controller using SMB administrative shares.

This sequence demonstrates how credential theft can rapidly enable expansion of attacker access across the network.

---

# Detection Recommendations

- Monitor Event ID 4624 for NTLM network logons.
- Alert on new service installations (Event ID 7045).
- Monitor access to ADMIN$ and other administrative shares.
- Detect execution of `PSEXESVC.exe` or similar service binaries.
- Correlate credential dumping activity with subsequent remote logons.
- Enable Sysmon process and file creation logging.

---

# Mitigation and Prevention

- Prefer Kerberos over NTLM authentication where possible.
- Restrict or disable NTLM if operationally feasible.
- Limit access to administrative SMB shares.
- Implement unique local administrator passwords using solutions such as LAPS.
- Monitor and restrict remote service creation.
- Enable SMB signing and strong authentication controls.
- Use endpoint detection solutions capable of identifying PsExec-like behavior.

---

# Key Takeaways

Pass-the-Hash attacks allow adversaries to authenticate without possessing plaintext passwords, making stolen NTLM hashes highly valuable. When combined with SMB administrative shares and remote service creation, attackers can rapidly move between systems. Monitoring authentication events, share access, service installation, and process execution provides strong visibility into this form of lateral movement.

---

# References

- MITRE ATT&CK – TA0008: Lateral Movement
- MITRE ATT&CK – T1550.002: Pass the Hash
- MITRE ATT&CK – T1021.002: SMB/Windows Admin Shares
- Lab Simulation: Phase 6 – Lateral Movement