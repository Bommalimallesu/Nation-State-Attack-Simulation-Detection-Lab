# TA0011 – Command & Control (MITRE ATT&CK)

## Tactic

**TA0011 – Command & Control (C2)**

### Objective

The objective of the Command and Control tactic is to establish and maintain communication between a compromised host and attacker-controlled infrastructure. This communication channel enables attackers to send commands, receive results, and continue post-exploitation activities remotely.

**Simulated Techniques:**

- **T1071.001 – Application Layer Protocol: Web Protocols (HTTP)**
- **T1071 – Application Layer Protocol (Reverse TCP Communication)**

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|---------------------------------------------|--------------------------------------------|
| **T1071.001** | Web Protocols | Use HTTP for command and control communications |
| **T1071** | Application Layer Protocol | Communicate using common network protocols |

---

# Attack Description

Following successful lateral movement to the Domain Controller, the attacker established a Command and Control (C2) channel by executing a beacon payload. The beacon periodically communicated with an attacker-controlled server over HTTP, allowing remote tasking and data exchange.

Earlier in the attack chain, an initial reverse TCP payload created a direct outbound connection from the compromised workstation to the attacker infrastructure.

---

# Technique Overview – HTTP Beacon (T1071.001)

HTTP-based beacons blend malicious communications with legitimate web traffic by using standard web protocols.

Typical attacker workflow:

1. Execute beacon payload.
2. Establish outbound HTTP connection.
3. Periodically contact the C2 server.
4. Receive commands.
5. Send execution results back to the attacker.

---

# Reverse TCP Communication

Before the HTTP beacon was deployed, the initial compromise used a reverse TCP payload that established a direct outbound session from the workstation to the attacker's listener.

Characteristics include:

- Outbound connection initiated by the victim.
- No inbound firewall exceptions required.
- Interactive remote control session.
- Immediate attacker access after execution.

---

# Attack Simulation Workflow

1. Execute `shell.exe` on WS1.
2. Establish outbound reverse TCP connection.
3. Obtain interactive access.
4. Move laterally to the Domain Controller.
5. Deploy `beacon.exe`.
6. Execute the beacon.
7. Beacon periodically communicates with the C2 server over HTTP.

---

# Detection Opportunities

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Sysmon Event ID 3 | Outbound network connections | Unexpected external communications |
| Security Event ID 4688 | Process creation | Execution of `beacon.exe` |
| Sysmon Event ID 1 | Process creation | Suspicious executable launched |
| Network Monitoring | Repeated HTTP callbacks | Beaconing behavior |
| Firewall Logs | Outbound traffic on unusual ports | Connections to attacker infrastructure |
| EDR Telemetry | Behavioral detection | Persistent network communications |

---

# MITRE ATT&CK Mapping Summary

| Field | Value |
|---------|--------------------------------------------|
| **Tactic** | Command & Control (TA0011) |
| **Technique** | Application Layer Protocol |
| **Sub-technique** | T1071.001 – Web Protocols |
| **Platform** | Windows |
| **Permissions Required** | User |
| **Primary Data Sources** | Network Logs, Sysmon, Process Monitoring |
| **Detection Difficulty** | Moderate |

---

# Example Kibana KQL Queries

## Detect beacon network connections

```kql
event.code:3 AND process.name:beacon.exe
```

## Detect beacon process execution

```kql
event.code:4688 AND process.name:beacon.exe
```

## Detect reverse TCP payload activity

```kql
event.code:3 AND process.name:shell.exe
```

## Detect repeated outbound network events

```kql
event.code:3
```

---

# Example Network Event

```
Image:
C:\Users\Public\beacon.exe

Protocol:
TCP

Direction:
Outbound

Destination:
Attacker Infrastructure
```

---

# Example Process Creation Event

```
Process Name:
C:\Users\Public\beacon.exe

Parent Process:
cmd.exe

Command Line:
beacon.exe
```

---

# Correlated Attack Timeline

| Time | Activity |
|--------|------------------------------------------|
| Phase 2 | Reverse TCP session established |
| Phase 6 | Lateral movement completed |
| Phase 7 | Beacon deployed |
| Phase 7 | HTTP communications begin |
| Ongoing | Periodic callback traffic observed |

---

# Indicators of Compromise (IOCs)

| IOC Type | Value |
|-----------|-----------------------------------|
| Executable | `beacon.exe` |
| Executable | `shell.exe` |
| Process | Unexpected outbound network activity |
| Behavior | Repeated callback intervals |
| Event IDs | 3, 4688 |

---

# Forensic Artifacts

Investigators should review:

| Artifact | Description |
|-----------|----------------------------------------------|
| Sysmon Network Logs | Outbound connection records |
| Security Event Logs | Process creation events |
| Prefetch Files | Evidence of executable launches |
| Memory Dumps | In-memory beacon configuration |
| Firewall Logs | External communications |
| Network Captures | HTTP callback traffic |

---

# Example Sigma Rule

```yaml
title: Suspicious Beacon Process

id: detect-http-beacon

status: experimental

logsource:
  product: windows
  service: sysmon

detection:
  selection:
    EventID: 3
    Image|endswith: '\beacon.exe'

  condition: selection

level: high
```

---

# Correlation with Previous Phases

The Command and Control phase follows successful execution and lateral movement. After obtaining access to the Domain Controller, the attacker deployed a beacon to maintain remote communication and execute additional commands without requiring repeated exploitation.

---

# Detection Recommendations

- Monitor Sysmon Event ID 3 for unusual outbound network connections.
- Alert on execution of unknown binaries from user-writable directories.
- Correlate process creation with immediate outbound communications.
- Detect regular callback intervals that may indicate automated beaconing.
- Inspect HTTP traffic for suspicious or repetitive communication patterns.
- Deploy endpoint detection capable of identifying malicious command-and-control behavior.

---

# Mitigation and Prevention

- Restrict outbound network communications to approved destinations.
- Block execution of unauthorized binaries using application control policies.
- Monitor for unexpected processes initiating network connections.
- Deploy network intrusion detection systems to identify suspicious traffic patterns.
- Use endpoint protection solutions that detect beaconing behavior.
- Segment networks to limit attacker communications after compromise.

---

# Key Takeaways

Command and Control channels enable attackers to maintain persistent access and remotely manage compromised systems. Detecting unusual outbound communications, monitoring suspicious process execution, and correlating network activity with endpoint telemetry are essential for identifying and disrupting C2 operations.

---

# References

- MITRE ATT&CK – TA0011: Command & Control
- MITRE ATT&CK – T1071: Application Layer Protocol
- MITRE ATT&CK – T1071.001: Web Protocols
- Lab Simulation: Phase 7 – Command & Control