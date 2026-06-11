# Quick Start Guide

## Nation-State Lab

### Deploy, Validate, and Begin Security Operations

This guide provides the fastest path to deploying a functional Nation-State Lab environment. It covers the minimum infrastructure required to validate centralized logging, endpoint visibility, and detection workflows. For full deployment instructions, architecture details, and attack simulations, refer to the documentation within the repository.

---

## Overview

The Nation-State Lab is a self-contained cybersecurity training and research environment that simulates a modern enterprise network. It combines Active Directory infrastructure, Windows endpoints, centralized monitoring, endpoint telemetry, threat hunting capabilities, and adversary emulation tooling.

The platform is designed for:

* Detection Engineering
* Threat Hunting
* Incident Response
* Purple Team Exercises
* Security Operations Training
* MITRE ATT&CK Mapping
* Adversary Emulation

---

## Minimum Deployment Requirements

| Component             | Requirement                                             |
| --------------------- | ------------------------------------------------------- |
| Hypervisor            | VMware Workstation Player 17+ or VMware Workstation Pro |
| Host Memory           | 16 GB RAM minimum                                       |
| Storage               | 100 GB available disk space                             |
| Network               | VMware Host-Only Network                                |
| Host Operating System | Windows 10 or Windows 11                                |

### Required Virtual Machines

| System            | IP Address    | Purpose                   |
| ----------------- | ------------- | ------------------------- |
| Domain Controller | 192.168.1.10  | Active Directory Services |
| Workstation (WS1) | 192.168.1.20  | Endpoint Monitoring       |
| Kali Linux        | 192.168.1.5   | Adversary Platform        |
| Ubuntu Server     | 192.168.1.100 | Monitoring Infrastructure |

---

## Deployment Workflow

The recommended deployment sequence is shown below:

```text
Create Virtual Machines
        ↓
Configure Networking
        ↓
Deploy Active Directory
        ↓
Deploy Monitoring Stack
        ↓
Install Endpoint Agents
        ↓
Validate Data Collection
        ↓
Validate Detection Rules
        ↓
Begin Attack Simulations
```

---

## Step 1 — Build the Environment

Create the required virtual machines and configure static IP addresses according to the architecture documentation.

Reference:

```text
docs/vm-configuration.md
docs/network-design.md
ARCHITECTURE.md
```

---

## Step 2 — Deploy Active Directory

Configure the Domain Controller with:

* Active Directory Domain Services
* DNS Services
* Organizational Units
* Domain Users
* Windows Auditing Policies

Domain Name:

```text
nation.local
```

Reference:

```text
docs/active-directory-setup.md
```

---

## Step 3 — Deploy the Monitoring Stack

Install and configure the monitoring infrastructure on the Ubuntu Server.

### Core Components

| Component     | Function                               |
| ------------- | -------------------------------------- |
| Elasticsearch | Centralized Log Storage                |
| Kibana        | Dashboards and Alerting                |
| Velociraptor  | Endpoint Visibility and Threat Hunting |
| Docker        | Container Runtime                      |

### Verify Service Availability

| Service       | URL                        |
| ------------- | -------------------------- |
| Elasticsearch | http://192.168.1.100:9200  |
| Kibana        | http://192.168.1.100:5601  |
| Velociraptor  | https://192.168.1.100:8889 |

Reference:

```text
monitoring/
velociraptor/
```

---

## Step 4 — Deploy Endpoint Agents

Install telemetry agents on all monitored systems.

### Windows Endpoints

Deploy:

* Winlogbeat
* Velociraptor Client

### Kali Linux

Deploy:

* Filebeat

After installation, verify successful communication with Elasticsearch and Velociraptor.

Reference:

```text
monitoring/winlogbeat/
monitoring/filebeat/
velociraptor/
```

---

## Step 5 — Validate Data Collection

Open Kibana and confirm that telemetry is being ingested.

### Windows Events

Index:

```text
winlogbeat-*
```

Expected event categories:

* Authentication Events
* Process Creation Events
* Scheduled Task Events
* Object Access Events
* System Events

### Linux Events

Index:

```text
filebeat-*
```

Expected event categories:

* Authentication Logs
* System Logs
* Service Activity

---

## Step 6 — Validate Detection Coverage

Import the provided detection rules and confirm that alerts are generated successfully.

Coverage includes:

| ATT&CK Tactic        | Example Detection     |
| -------------------- | --------------------- |
| Reconnaissance       | Network Scanning      |
| Initial Access       | Payload Execution     |
| Persistence          | Scheduled Tasks       |
| Privilege Escalation | UAC Bypass Indicators |
| Credential Access    | LSASS Access          |
| Lateral Movement     | Remote Authentication |
| Command and Control  | Beacon Activity       |

Reference:

```text
detection-rules/
```

---

## Verification Checklist

Before proceeding to advanced exercises, confirm the following:

* Active Directory is operational
* DNS resolution is functioning
* Elasticsearch is healthy
* Kibana is accessible
* Endpoint agents are connected
* Windows events are visible
* Linux events are visible
* Detection rules are imported
* Alerts are triggering correctly
* Velociraptor clients are online

---

## Recommended Next Steps

After completing the initial deployment, explore the following areas:

### Detection Engineering

```text
learning-resources/detection-engineering.md
```

### Threat Hunting

```text
learning-resources/threat-hunting-methodology.md
```

### MITRE ATT&CK Mapping

```text
learning-resources/mitre-attack-guide.md
```

### Attack Simulation

```text
attack-chain/
```

### Incident Response

```text
incident-response/
```

---

## Troubleshooting

| Issue                            | Recommended Action                                        |
| -------------------------------- | --------------------------------------------------------- |
| No logs visible in Kibana        | Verify agent configuration and Elasticsearch connectivity |
| Endpoint offline in Velociraptor | Confirm client registration and network connectivity      |
| Elasticsearch unavailable        | Verify Docker containers and resource allocation          |
| Missing Windows events           | Review audit policy configuration                         |
| Detection rules not triggering   | Confirm event ingestion and rule scope                    |

For detailed troubleshooting procedures, see:

```text
docs/troubleshooting.md
```

---

## Learning Objectives

By completing this deployment, users will gain practical experience with:

* Enterprise Network Architecture
* Security Monitoring
* Endpoint Telemetry Collection
* Detection Engineering
* Threat Hunting Methodologies
* Incident Response Workflows
* MITRE ATT&CK Mapping
* Purple Team Operations

---

## Additional Documentation

| Document                      | Purpose                    |
| ----------------------------- | -------------------------- |
| README.md                     | Project Introduction       |
| PROJECT-OVERVIEW.md           | Executive Summary          |
| ARCHITECTURE.md               | Architecture and Data Flow |
| MITRE-ATTACK-GUIDE.md         | ATT&CK Mapping             |
| THREAT-HUNTING-METHODOLOGY.md | Hunting Procedures         |
| TOOLS-VERSION-REFERENCE.md    | Version Compatibility      |

---

## License

This project is released under the MIT License. See the LICENSE file for details.

---

**Nation-State Lab** provides a reproducible environment for studying adversary behavior, validating defensive controls, developing detection content, and practicing modern blue-team and purple-team operations in a controlled enterprise simulation.
