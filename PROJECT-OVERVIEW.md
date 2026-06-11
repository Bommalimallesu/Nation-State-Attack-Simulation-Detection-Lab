# Nation-State Lab

## Enterprise Attack Simulation, Detection Engineering, and Threat Hunting Environment

The Nation-State Lab is a fully isolated cybersecurity research and training environment designed to emulate a modern enterprise network under attack from an advanced adversary. The project combines offensive security operations, detection engineering, threat hunting, incident response, and security monitoring into a single reproducible platform.

Built using VMware, Active Directory, Elastic Stack, Velociraptor, and industry-standard adversary emulation tools, the lab demonstrates the complete lifecycle of a cyber intrusion—from reconnaissance and initial access through persistence, credential theft, lateral movement, command and control, detection, investigation, and remediation.

The environment was developed to provide hands-on experience with real-world attack techniques while simultaneously validating defensive controls and monitoring capabilities.

---

# Project Objectives

This lab was created to:

* Simulate realistic enterprise attack scenarios in a controlled environment
* Develop and validate detection engineering capabilities
* Practice threat hunting and incident response workflows
* Map adversary activity to the MITRE ATT&CK framework
* Build practical experience with security monitoring technologies
* Create a reproducible purple-team training platform

---

# Environment Overview

The lab consists of a fully segmented enterprise network operating within an isolated VMware host-only environment.

### Core Infrastructure

| System                   | Role                                        |
| ------------------------ | ------------------------------------------- |
| Domain Controller        | Active Directory, DNS, Identity Services    |
| Windows Workstations     | User endpoints and attack targets           |
| File Server              | Shared corporate resources                  |
| Web Server               | Internet-facing application simulation      |
| Kali Linux               | Adversary platform                          |
| Ubuntu Monitoring Server | Security monitoring and endpoint visibility |

### Network Architecture

| Network                     | Address Space                      |
| --------------------------- | ---------------------------------- |
| Internal Enterprise Network | 192.168.1.0/24                     |
| Deployment Model            | VMware Host-Only Network           |
| Internet Connectivity       | Disabled during attack simulations |

---

# Security Monitoring Platform

The defensive architecture provides centralized visibility across all systems.

| Technology    | Purpose                                |
| ------------- | -------------------------------------- |
| Elasticsearch | Centralized log storage and search     |
| Kibana        | Dashboards, analytics, and alerting    |
| Winlogbeat    | Windows telemetry collection           |
| Filebeat      | Linux telemetry collection             |
| Velociraptor  | Endpoint visibility and threat hunting |
| Sysmon        | Advanced endpoint telemetry            |

Collected telemetry includes:

* Authentication events
* Process creation activity
* Scheduled task creation
* Service installation events
* Network connections
* File system activity
* Privileged access operations

---

# Adversary Emulation Capabilities

The attack platform includes multiple industry-standard offensive security tools.

| Tool                 | Purpose                               |
| -------------------- | ------------------------------------- |
| Metasploit Framework | Exploitation and post-exploitation    |
| Impacket             | Lateral movement and credential abuse |
| BloodHound           | Active Directory attack path analysis |
| MITRE Caldera        | Automated adversary emulation         |
| Atomic Red Team      | Detection validation                  |
| Nmap                 | Network reconnaissance                |
| Hydra                | Credential attacks                    |
| Responder            | Credential interception               |

---

# Simulated Attack Chain

The lab executes a complete Advanced Persistent Threat (APT) attack scenario aligned to the MITRE ATT&CK framework.

| Attack Phase         | ATT&CK Technique                          |
| -------------------- | ----------------------------------------- |
| Reconnaissance       | Active Scanning (T1595)                   |
| Initial Access       | Exploitation for Client Execution (T1203) |
| Persistence          | Scheduled Tasks (T1053.005)               |
| Privilege Escalation | UAC Bypass (T1548.002)                    |
| Credential Access    | LSASS Memory Dumping (T1003.001)          |
| Lateral Movement     | Pass-the-Hash (T1550.002)                 |
| Command & Control    | Application Layer Protocol (T1071.001)    |

Each phase generates telemetry that is collected, indexed, detected, investigated, and documented.

---

# Detection Engineering

Custom detection content was developed using Kibana Query Language (KQL) and mapped directly to MITRE ATT&CK techniques.

Detection coverage includes:

* Suspicious process execution
* Scheduled task persistence
* UAC bypass activity
* LSASS access attempts
* Lateral movement indicators
* Command and control activity
* Network reconnaissance

All detections were validated through controlled attack simulation and testing.

---

# Threat Hunting & Incident Response

Following each attack simulation, endpoint investigations are performed using Velociraptor.

Threat hunting activities include:

* Process analysis
* Scheduled task review
* Event log investigation
* Persistence identification
* File system artefact collection
* Attack timeline reconstruction

The project also includes a complete Incident Response Framework aligned with NIST SP 800-61.

---

# Key Deliverables

* Enterprise Active Directory Lab Environment
* Elastic Stack Security Monitoring Platform
* Detection Engineering Playbooks
* Threat Hunting Methodology
* Incident Response Framework
* MITRE ATT&CK Mapping Guide
* Velociraptor Hunt Library
* Attack Simulation Documentation
* Version Compatibility Matrix
* Reproducible Infrastructure Documentation

---

# Technologies

VMware • Windows Server • Windows 10 • Ubuntu Server • Kali Linux • Active Directory • Elasticsearch • Kibana • Winlogbeat • Filebeat • Velociraptor • Sysmon • Metasploit • BloodHound • Caldera • Impacket • Atomic Red Team • PowerShell • Docker

---

# Skills Demonstrated

* Detection Engineering
* Threat Hunting
* Incident Response
* Security Monitoring
* Endpoint Visibility
* SIEM Administration
* Active Directory Security
* Purple Team Operations
* Adversary Emulation
* MITRE ATT&CK Mapping
* Log Analysis
* Windows Security Monitoring
* Security Operations (SOC)

---

# Repository Structure

```text
nation-state-lab/
├── docs/
├── monitoring/
├── attack-tools/
├── detection-rules/
├── velociraptor/
├── attack-chain/
├── evidence/
├── learning-resources/
├── tools-version-reference/
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

# Disclaimer

This project is intended exclusively for cybersecurity education, security research, detection validation, and authorized testing within isolated environments. All techniques demonstrated in this repository must only be executed against systems for which explicit authorization has been granted.
