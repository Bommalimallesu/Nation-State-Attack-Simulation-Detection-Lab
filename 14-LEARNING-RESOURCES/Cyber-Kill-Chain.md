# Cyber Kill Chain – Nation-State Lab

The **Cyber Kill Chain** is a model developed by Lockheed Martin to describe the stages of a targeted cyber attack. It complements the MITRE ATT&CK framework by focusing on high-level attack phases, whereas MITRE ATT&CK provides detailed tactics, techniques, and procedures (TTPs).

This document maps the attack simulation performed in the Nation-State Lab to the Cyber Kill Chain and demonstrates how each phase was detected.

---

# 1. The Seven Phases of the Cyber Kill Chain

| Phase                        | Description                                                                                     | MITRE ATT&CK Tactic (Primary) |
| ---------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------- |
| **Reconnaissance**           | Gathering information about the target environment, systems, users, and network infrastructure. | TA0043 – Reconnaissance       |
| **Weaponization**            | Creating or preparing malicious payloads, exploits, and attack infrastructure.                  | Not directly mapped           |
| **Delivery**                 | Delivering the malicious payload to the target system.                                          | TA0001 – Initial Access       |
| **Exploitation**             | Triggering the payload or exploit to execute malicious code.                                    | TA0002 – Execution            |
| **Installation**             | Establishing persistence through malware, backdoors, or scheduled tasks.                        | TA0003 – Persistence          |
| **Command and Control (C2)** | Creating communication channels between attacker and compromised host.                          | TA0011 – Command and Control  |
| **Actions on Objectives**    | Achieving attacker goals such as credential theft, lateral movement, or data exfiltration.      | TA0006, TA0008, TA0010        |

---

# 2. Mapping the Nation-State Lab Attack Chain

The Advanced Persistent Threat (APT) simulation conducted in the lab aligns with the Cyber Kill Chain as shown below.

| Kill Chain Phase          | Lab Activity                                                        | MITRE ATT&CK Technique(s)                 | Detection Source                     |
| ------------------------- | ------------------------------------------------------------------- | ----------------------------------------- | ------------------------------------ |
| **Reconnaissance**        | `nmap -sV -O 192.168.1.0/24`                                        | T1595 – Active Scanning                   | Filebeat (Kali Syslog)               |
| **Weaponization**         | Generate reverse shell payload using `msfvenom`                     | T1203 – Exploitation for Client Execution | Not directly detected                |
| **Delivery**              | Transfer and execute `shell.exe` via HTTP or shared folder          | T1203                                     | Winlogbeat Event ID 4688             |
| **Exploitation**          | Reverse shell connects back to Kali Linux                           | T1203                                     | Sysmon Event IDs 1 and 3             |
| **Installation**          | Create persistence using scheduled task (`schtasks`)                | T1053.005 – Scheduled Task                | Event ID 4698                        |
| **Command & Control**     | HTTP beacon (`beacon.exe`) communicates with attacker               | T1071.001 – Web Protocols                 | Sysmon Event ID 3, Event ID 4688     |
| **Actions on Objectives** | LSASS dumping, Pass-the-Hash, lateral movement to Domain Controller | T1003.001, T1550.002                      | Event IDs 4663, 10, 4624, 4672, 7045 |

---

# 3. Attack Flow Overview

```text
Reconnaissance
      │
      ▼
Weaponization
      │
      ▼
Delivery
(shell.exe transferred)
      │
      ▼
Exploitation
(reverse shell established)
      │
      ▼
Installation
(scheduled task persistence)
      │
      ▼
Command & Control
(HTTP beacon)
      │
      ▼
Actions on Objectives
(credential theft and lateral movement)
```

---

# 4. Comparison with MITRE ATT&CK

## Cyber Kill Chain

Characteristics:

* High-level attack lifecycle model
* Linear attack progression
* Useful for executive reporting and attack storytelling
* Easy to understand and communicate

### Example

The attacker:

1. Performs reconnaissance
2. Delivers a payload
3. Gains access
4. Establishes persistence
5. Achieves objectives

---

## MITRE ATT&CK

Characteristics:

* Detailed adversary behavior framework
* Matrix-based structure
* Thousands of techniques and sub-techniques
* Designed for detection engineering and threat hunting

### Example

The Cyber Kill Chain phase:

```text
Actions on Objectives
```

is broken into multiple ATT&CK tactics:

| ATT&CK Tactic       | Technique                        |
| ------------------- | -------------------------------- |
| Credential Access   | T1003.001 – LSASS Memory Dumping |
| Lateral Movement    | T1550.002 – Pass-the-Hash        |
| Command and Control | T1071.001 – Web Protocols        |

---

## Why Both Models Matter

The Nation-State Lab uses:

* **MITRE ATT&CK** for detection engineering and rule development
* **Cyber Kill Chain** for attack narratives, reporting, and executive communication

Together they provide both strategic and operational visibility.

---

# 5. Detection Coverage by Kill Chain Phase

| Phase                 | Detection Method                                | Coverage |
| --------------------- | ----------------------------------------------- | -------- |
| Reconnaissance        | Filebeat captures Nmap activity from Kali Linux | ✅ 100%   |
| Delivery              | Event ID 4688 (Process Creation)                | ✅ 100%   |
| Exploitation          | Sysmon Event IDs 1 and 3                        | ✅ 100%   |
| Installation          | Event ID 4698 (Scheduled Task Creation)         | ✅ 100%   |
| Command & Control     | Sysmon Event ID 3 and Event ID 4688             | ✅ 100%   |
| Actions on Objectives | Event IDs 4663, 10, 4624, 4672, 7045            | ✅ 100%   |

---

## Coverage Summary

```text
Reconnaissance      ██████████ 100%
Delivery            ██████████ 100%
Exploitation        ██████████ 100%
Installation        ██████████ 100%
Command & Control   ██████████ 100%
Actions on Obj.     ██████████ 100%
```

All attack phases were successfully detected and correlated through Kibana dashboards and log analysis.

---

# 6. Limitations of the Cyber Kill Chain

While valuable, the Cyber Kill Chain has several limitations.

## Linear Attack Model

Modern adversaries may not follow a strict sequence.

Example:

```text
Persistence may occur before full C2 establishment.
```

---

## No Feedback Loops

Attackers frequently revisit earlier phases.

Examples:

* Re-establish persistence
* Deploy additional payloads
* Expand lateral movement

---

## Limited Coverage of Modern Threats

The model does not adequately address:

* Insider threats
* Supply-chain compromises
* Cloud-native attacks
* Identity-based attacks

---

## MITRE ATT&CK Complements These Gaps

MITRE ATT&CK provides:

* More granular detection opportunities
* Better threat-hunting capabilities
* Comprehensive adversary behavior mapping

---

# 7. Applying the Cyber Kill Chain in the Lab

## During Attack Simulation

Track each stage as the attack progresses:

1. Reconnaissance
2. Delivery
3. Exploitation
4. Persistence
5. Command & Control
6. Objectives

---

## During Incident Response

Use the Kill Chain to:

* Build attack timelines
* Explain attacker progression
* Identify containment opportunities

---

## During Detection Engineering

Identify gaps by asking:

```text
Which Kill Chain phase lacks sufficient visibility?
```

Examples:

* No reconnaissance telemetry?
* No C2 detection?
* No persistence monitoring?

These gaps become priorities for future detections.

---

# 8. Key Takeaways

* The Cyber Kill Chain provides a simple and effective method for describing attacker behavior.
* MITRE ATT&CK provides the detailed techniques used within each phase.
* The Nation-State Lab successfully demonstrated all major Kill Chain phases.
* Detection coverage was achieved through:

  * Winlogbeat
  * Sysmon
  * Filebeat
  * Velociraptor
  * Elasticsearch
  * Kibana
* Combining Cyber Kill Chain and MITRE ATT&CK provides stronger threat visibility and more effective reporting.

---

# 9. References

## Lockheed Martin Cyber Kill Chain

https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html

---

## MITRE ATT&CK

https://attack.mitre.org

---

## SANS – MITRE ATT&CK vs Cyber Kill Chain

https://www.sans.org/blog/mitre-attack-framework-vs-cyber-kill-chain

---

*This document is part of the Nation-State Lab Learning Resources and Detection Engineering Documentation.*
