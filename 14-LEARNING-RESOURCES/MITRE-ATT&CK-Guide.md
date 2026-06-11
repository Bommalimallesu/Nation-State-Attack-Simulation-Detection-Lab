# MITRE ATT&CK Guide – Nation-State Lab

This guide maps the attack techniques used throughout the Nation-State Lab to the MITRE ATT&CK framework. It helps analysts understand adversary behavior, improve detection coverage, and align security monitoring with industry-standard threat models.

---

# 1. Introduction to MITRE ATT&CK

MITRE ATT&CK (Adversarial Tactics, Techniques, and Common Knowledge) is a globally recognized knowledge base of real-world adversary behaviors.

The framework is organized into:

* **Tactics** – The attacker's objective.
* **Techniques** – How the attacker achieves that objective.
* **Sub-techniques** – Specific implementations of a technique.

---

## Why MITRE ATT&CK Matters

MITRE ATT&CK is commonly used for:

* Detection Engineering
* Threat Hunting
* Threat Intelligence
* Purple Team Exercises
* Red Team Operations
* Security Control Validation
* Incident Response

---

# 2. Nation-State Lab Attack Overview

The attack simulation follows a realistic Advanced Persistent Threat (APT) progression.

```text
Reconnaissance
      ↓
Initial Access
      ↓
Persistence
      ↓
Privilege Escalation
      ↓
Credential Access
      ↓
Lateral Movement
      ↓
Command & Control
```

The lab covers:

* 7 ATT&CK Tactics
* 7 Primary Techniques
* Multiple Windows Event IDs
* Sysmon telemetry
* Detection engineering workflows

---

# 3. Reconnaissance (TA0043)

## Objective

Gather information about the target environment before compromise.

---

### Technique: Active Scanning

| Item             | Value                        |
| ---------------- | ---------------------------- |
| Technique        | Active Scanning              |
| ATT&CK ID        | T1595                        |
| Command          | `nmap -sV -O 192.168.1.0/24` |
| Detection Source | Filebeat (Kali Syslog)       |

---

### Detection Query

```kql
message:nmap
```

---

### Data Source

```text
filebeat-*
```

---

### Evidence Collected

* Source host
* Scan targets
* Open ports
* Service versions

---

# 4. Initial Access (TA0001)

## Objective

Gain initial execution on a target workstation.

---

### Technique: Exploitation for Client Execution

| Item             | Value                             |
| ---------------- | --------------------------------- |
| Technique        | Exploitation for Client Execution |
| ATT&CK ID        | T1203                             |
| Payload          | shell.exe                         |
| Detection Source | Winlogbeat, Sysmon                |

---

### Attack Example

```text
User executes shell.exe
```

The payload creates a reverse shell connection back to the attacker.

---

### Detection Query

```kql
winlog.event_id:4688
AND process.executable:*shell.exe
```

---

### Data Sources

* Event ID 4688
* Sysmon Event ID 1

---

# 5. Persistence (TA0003)

## Objective

Maintain access after reboot or user logoff.

---

### Technique: Scheduled Task

| Item             | Value          |
| ---------------- | -------------- |
| Technique        | Scheduled Task |
| ATT&CK ID        | T1053.005      |
| Tool             | schtasks.exe   |
| Detection Source | Event ID 4698  |

---

### Attack Example

```cmd
schtasks /create /tn "Updater" ^
/tr "C:\Users\Public\shell.exe"
```

---

### Detection Query

```kql
winlog.event_id:4698
AND winlog.event_data.TaskName:Updater
```

---

### Event Coverage

| Event ID | Description            |
| -------- | ---------------------- |
| 4698     | Scheduled Task Created |

---

# 6. Privilege Escalation (TA0004)

## Objective

Elevate privileges from standard user to administrator or SYSTEM.

---

### Technique: Bypass User Account Control

| Item             | Value                       |
| ---------------- | --------------------------- |
| Technique        | Bypass User Account Control |
| ATT&CK ID        | T1548.002                   |
| Tool             | Metasploit UAC Bypass       |
| Detection Source | Event ID 4688               |

---

### Attack Indicators

Suspicious execution of:

```text
eventvwr.exe
sdclt.exe
fodhelper.exe
computerdefaults.exe
```

---

### Detection Query

```kql
winlog.event_id:4688
AND process.executable:*eventvwr.exe
AND winlog.event_data.ParentProcessName:*cmd.exe
```

---

### Additional Detection

```kql
winlog.event_id:4688
AND process.name:(sdclt.exe OR fodhelper.exe OR computerdefaults.exe)
```

---

# 7. Credential Access (TA0006)

## Objective

Steal credentials from memory.

---

### Technique: OS Credential Dumping

| Item      | Value                 |
| --------- | --------------------- |
| Technique | OS Credential Dumping |
| ATT&CK ID | T1003.001             |
| Tool      | Mimikatz              |
| Target    | lsass.exe             |

---

### Attack Example

```text
load kiwi
creds_all
```

---

### Detection Query

```kql
(
  winlog.event_id:4663
  AND winlog.event_data.ObjectName:*lsass.exe
)
OR
(
  event.code:10
  AND winlog.event_data.TargetImage:*lsass.exe
)
```

---

### Event Coverage

| Event ID | Purpose                 |
| -------- | ----------------------- |
| 4663     | Object Access           |
| 10       | Process Access (Sysmon) |

---

# 8. Lateral Movement (TA0008)

## Objective

Move from a compromised workstation to the Domain Controller.

---

### Technique: Pass-the-Hash

| Item             | Value           |
| ---------------- | --------------- |
| Technique        | Pass-the-Hash   |
| ATT&CK ID        | T1550.002       |
| Tool             | Impacket PsExec |
| Detection Source | Event ID 4624   |

---

### Attack Example

```bash
impacket-psexec \
-hashes :<NT_HASH> \
nation/administrator@192.168.1.10
```

---

### Detection Query

```kql
winlog.event_id:4624
AND winlog.event_data.LogonType:3
AND winlog.event_data.IpAddress:192.168.1.5
```

---

### Event Coverage

| Event ID | Description                 |
| -------- | --------------------------- |
| 4624     | Successful Logon            |
| 4672     | Special Privileges Assigned |
| 7045     | Service Installed           |

---

# 9. Command and Control (TA0011)

## Objective

Maintain communication with compromised systems.

---

### Technique: Application Layer Protocol (Web)

| Item      | Value                      |
| --------- | -------------------------- |
| Technique | Application Layer Protocol |
| ATT&CK ID | T1071.001                  |
| Protocol  | HTTP                       |
| Payload   | beacon.exe                 |

---

### Detection Query

```kql
winlog.event_id:4688
AND process.executable:*beacon.exe
```

---

### Additional Network Detection

```kql
event.code:3
AND destination.port:8081
```

---

### Event Coverage

| Event ID | Purpose            |
| -------- | ------------------ |
| 4688     | Process Creation   |
| 3        | Network Connection |

---

# 10. Complete ATT&CK Mapping Matrix

| Phase                | ATT&CK Tactic | Technique ID | Technique Name                    | Detection          |
| -------------------- | ------------- | ------------ | --------------------------------- | ------------------ |
| Reconnaissance       | TA0043        | T1595        | Active Scanning                   | `message:nmap`     |
| Initial Access       | TA0001        | T1203        | Exploitation for Client Execution | `shell.exe`        |
| Persistence          | TA0003        | T1053.005    | Scheduled Task                    | `TaskName:Updater` |
| Privilege Escalation | TA0004        | T1548.002    | Bypass UAC                        | `eventvwr.exe`     |
| Credential Access    | TA0006        | T1003.001    | LSASS Memory Dumping              | `lsass.exe access` |
| Lateral Movement     | TA0008        | T1550.002    | Pass-the-Hash                     | `4624 Type 3`      |
| Command & Control    | TA0011        | T1071.001    | Application Layer Protocol        | `beacon.exe`       |

---

# 11. Detection Coverage Summary

| Tactic               | Coverage   |
| -------------------- | ---------- |
| Reconnaissance       | ✅ Detected |
| Initial Access       | ✅ Detected |
| Persistence          | ✅ Detected |
| Privilege Escalation | ✅ Detected |
| Credential Access    | ✅ Detected |
| Lateral Movement     | ✅ Detected |
| Command & Control    | ✅ Detected |

---

## Coverage Visualization

```text
Reconnaissance         ██████████
Initial Access         ██████████
Persistence            ██████████
Privilege Escalation   ██████████
Credential Access      ██████████
Lateral Movement       ██████████
Command & Control      ██████████
```

---

# 12. Using ATT&CK in the Nation-State Lab

## Detection Engineering

Create a Kibana rule for each ATT&CK technique.

Example:

```yaml
name: Credential Access - LSASS Dumping

technique: T1003.001
tactic: Credential Access

query: >
  event.code:10
  AND winlog.event_data.TargetImage:*lsass.exe
```

---

## Incident Reporting

Reference ATT&CK IDs in reports.

Example:

```text
The attacker performed OS Credential Dumping
(T1003.001) against LSASS.
```

---

## Gap Analysis

After each simulation:

1. Identify missed techniques.
2. Review available telemetry.
3. Create additional rules.
4. Improve logging coverage.

---

## Purple Team Exercises

Validate detections using:

* Atomic Red Team
* Caldera
* Manual attack simulations

Example:

```powershell
Invoke-AtomicTest T1003
```

---

# 13. Additional Resources

## ATT&CK Navigator

https://mitre-attack.github.io/attack-navigator/

Used to visualize ATT&CK coverage.

---

## Elastic Security

Built-in ATT&CK mapping and detection workflows.

https://www.elastic.co/security

---

## Sigma Rules

Community detection rule repository.

https://github.com/SigmaHQ/sigma

---

# 14. References

## MITRE ATT&CK

https://attack.mitre.org

---

## ATT&CK Enterprise Matrix

https://attack.mitre.org/matrices/enterprise/

---

## ATT&CK Data Sources

https://attack.mitre.org/datasources/

---

## Wazuh MITRE Mapping

https://wazuh.com/use-cases/mitre-attack/

---

# Conclusion

The Nation-State Lab demonstrates how MITRE ATT&CK can be used to map adversary behavior, design detections, and measure defensive coverage.

Through Winlogbeat, Sysmon, Filebeat, Elasticsearch, Kibana, and Velociraptor, every major phase of the simulated attack chain was successfully mapped to ATT&CK tactics and techniques.

This framework provides a practical foundation for:

* Detection Engineering
* Threat Hunting
* Purple Team Operations
* Incident Response
* Security Monitoring

and serves as a blueprint for building ATT&CK-aligned security operations.
