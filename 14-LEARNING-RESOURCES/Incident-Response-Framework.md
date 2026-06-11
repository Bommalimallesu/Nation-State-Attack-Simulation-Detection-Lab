# Incident Response Framework – Nation-State Lab

This document defines an Incident Response (IR) framework tailored to the Nation-State Lab environment. It aligns with the principles of **NIST SP 800-61 Rev. 2** and leverages the lab's monitoring and response tools, including Elasticsearch, Kibana, Winlogbeat, Filebeat, and Velociraptor.

Although designed for a training environment, this framework can be adapted for production deployments.

---

# 1. Incident Response Lifecycle

The framework follows the four phases defined in NIST SP 800-61.

| Phase                                   | Objective                                    | Lab Implementation                                                            |
| --------------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------- |
| **Preparation**                         | Establish tools, procedures, and readiness   | Deploy Winlogbeat, Filebeat, Elastic Stack, Velociraptor, and detection rules |
| **Detection & Analysis**                | Identify and investigate suspicious activity | Kibana alerts, log analysis, Velociraptor hunts                               |
| **Containment, Eradication & Recovery** | Stop the attack and restore systems          | Process termination, malware removal, snapshot restoration                    |
| **Post-Incident Activity**              | Improve defenses and document findings       | Detection tuning, reporting, lessons learned                                  |

---

# 2. Incident Response Roles

In the lab environment, a single person performs all responsibilities. The roles are separated conceptually to mirror real-world incident response teams.

| Role                   | Responsibility                                         |
| ---------------------- | ------------------------------------------------------ |
| **Security Analyst**   | Monitor alerts, triage events, initiate investigations |
| **Threat Hunter**      | Run Velociraptor hunts and collect evidence            |
| **Incident Responder** | Contain affected systems and remove threats            |
| **Incident Manager**   | Review findings and approve improvements               |

---

# 3. Preparation Phase

## 3.1 Tooling and Infrastructure

The following tools provide detection and response capabilities.

| Tool             | Purpose                                |
| ---------------- | -------------------------------------- |
| Elasticsearch    | Centralized log storage                |
| Kibana           | Visualization, alerting, investigation |
| Winlogbeat       | Windows event collection               |
| Filebeat         | Linux log collection                   |
| Velociraptor     | Endpoint visibility and response       |
| VMware Snapshots | System recovery                        |

---

## 3.2 Detection Rules

Detection rules should be created before conducting attack simulations.

Examples:

* Reverse shell execution
* Scheduled task persistence
* LSASS access
* Service installation
* Lateral movement
* Beacon activity

---

## 3.3 Velociraptor Hunt Templates

Maintain pre-configured hunts for rapid investigation.

Examples:

```text
Windows.System.Pslist
Windows.System.Services
Windows.System.ScheduledTasks
Windows.EventLogs.Security
Windows.Forensics.Registry
```

---

## 3.4 Environment Baseline

Document normal behavior for:

* Running processes
* Scheduled tasks
* Authentication activity
* Network connections
* Services

This baseline helps reduce false positives and identify anomalies quickly.

---

# 4. Detection and Analysis Phase

## 4.1 Detection Sources

| Source             | Detection Capability                  | Example                         |
| ------------------ | ------------------------------------- | ------------------------------- |
| Kibana Rules       | Process creation, logons, persistence | Event ID 4688                   |
| Filebeat           | Attacker activity on Kali Linux       | Nmap, Hydra                     |
| Velociraptor Hunts | Live endpoint investigation           | Process and artifact collection |
| Sysmon             | Network and process telemetry         | Event IDs 1, 3, 10              |

---

## 4.2 Alert Triage Workflow

When an alert is generated:

### Step 1 – Review the Alert

Examine:

* Rule name
* Timestamp
* Hostname
* User account
* Event details

---

### Step 2 – Correlate Events

Search for:

* Related process executions
* Network connections
* Authentication events
* Scheduled task creation

---

### Step 3 – Hunt for Additional Evidence

Run a targeted Velociraptor hunt.

Examples:

```text
Windows.System.Pslist
Windows.EventLogs.Security
Windows.System.Services
```

---

### Step 4 – Determine Severity

Factors:

| Factor                     | Impact   |
| -------------------------- | -------- |
| Domain Controller affected | Critical |
| Workstation affected       | Medium   |
| Credential access observed | High     |
| Persistence established    | High     |
| Failed attack attempt      | Low      |

---

# 5. Example Investigation – Reverse Shell Detection

## Detection

Kibana Rule:

```kql
winlog.event_id:4688 AND process.executable:*shell.exe
```

---

## Investigation Steps

### Review Process Creation Event

Determine:

* User context
* Parent process
* Execution path

Example:

```text
Parent Process: explorer.exe
User: normaluser
```

---

### Search for Network Connections

Check Sysmon Event ID 3:

```kql
event.code:3 AND process.name:shell.exe
```

Identify:

* Destination IP
* Destination Port

---

### Hunt the Host

Run:

```text
Windows.System.Pslist
```

Verify whether the process remains active.

---

### Incident Declaration

If:

* Process exists
* Reverse connection is confirmed

Then declare a security incident and begin containment.

---

# 6. Containment Phase

## 6.1 Immediate Actions

### Isolate the Host

Options:

* Disconnect VMware network adapter
* Disable network interface
* Apply firewall restrictions

---

### Terminate Malicious Processes

```cmd
taskkill /f /im shell.exe
```

Additional examples:

```cmd
taskkill /f /im beacon.exe
taskkill /f /im mimikatz.exe
```

---

### Block Communication

Example Windows Firewall Rule:

```cmd
netsh advfirewall firewall add rule ^
name="Block Reverse Shell" ^
dir=out ^
action=block ^
protocol=TCP ^
remoteport=4444
```

---

# 7. Eradication Phase

## Remove Malicious Files

```cmd
del C:\Users\Public\shell.exe
del C:\Users\Public\beacon.exe
```

---

## Remove Persistence

Delete scheduled tasks:

```cmd
schtasks /delete /tn "Updater" /f
```

---

## Remove Unauthorized Services

```cmd
sc delete PSEXESVC
```

---

## Verify Registry Modifications

Use Velociraptor:

```text
Windows.Forensics.Registry
```

Compare findings against known-good baselines.

---

# 8. Recovery Phase

## Preferred Recovery Method

Restore from VMware snapshot.

Benefits:

* Fast
* Reliable
* Consistent

---

## Manual Recovery

If snapshots are unavailable:

### Run Antivirus Scan

```cmd
MpCmdRun.exe -Scan -ScanType 2
```

---

### Verify Persistence Locations

Inspect:

* Scheduled Tasks
* Services
* Startup folders
* Registry Run Keys

---

### Reboot System

Confirm:

* No malware processes
* No unexpected network activity
* No persistence mechanisms

---

# 9. Post-Incident Activities

## Documentation

Create an incident report containing:

* Timeline
* Detection details
* Investigation findings
* Containment actions
* Recovery actions
* Lessons learned

---

## Detection Improvement

Review:

* Missed detections
* False positives
* Alert quality

Update:

* Kibana rules
* Dashboards
* Velociraptor hunts

---

## Environment Reset

Prepare the lab for future exercises.

Tasks:

* Revert snapshots
* Archive logs
* Store screenshots
* Backup hunt results

---

# 10. Tool Mapping Across the IR Lifecycle

| IR Phase      | Primary Tool           | Purpose             |
| ------------- | ---------------------- | ------------------- |
| Detection     | Kibana                 | Alert generation    |
| Analysis      | Kibana Discover        | Event investigation |
| Analysis      | Velociraptor           | Evidence collection |
| Containment   | VMware                 | Host isolation      |
| Containment   | Velociraptor           | Process termination |
| Eradication   | Velociraptor           | Artifact removal    |
| Recovery      | VMware Snapshots       | System restoration  |
| Post-Incident | GitHub / Documentation | Knowledge retention |

---

# 11. Sample Incident Timeline

## Reverse Shell Scenario

| Time     | Activity                  | Tool            |
| -------- | ------------------------- | --------------- |
| 09:00:00 | shell.exe executed        | Attack          |
| 09:00:05 | Detection rule triggered  | Kibana          |
| 09:00:10 | Alert reviewed            | Kibana Discover |
| 09:00:20 | Process hunt initiated    | Velociraptor    |
| 09:00:30 | Host isolated             | VMware          |
| 09:00:35 | Process terminated        | Velociraptor    |
| 09:00:45 | Persistence removed       | Windows Tools   |
| 09:05:00 | Snapshot restored         | VMware          |
| 09:15:00 | Incident report completed | Documentation   |

---

# 12. Production Recommendations

For real-world deployments:

## Security Automation

Implement:

* Elastic Security Response Actions
* Automated host isolation
* Automated process termination

---

## Case Management

Integrate:

* TheHive
* Jira
* ServiceNow

---

## Threat Hunting

Schedule recurring Velociraptor hunts:

* Daily
* Weekly
* Monthly

---

## Purple Team Validation

Regularly test controls using:

* Atomic Red Team
* Caldera
* MITRE ATT&CK Evaluations

---

## Immutable Recovery

Adopt:

* Golden Images
* Infrastructure as Code
* Automated rebuilds

---

# 13. Key Performance Metrics

Track incident response effectiveness.

| Metric                          | Goal         |
| ------------------------------- | ------------ |
| Mean Time to Detect (MTTD)      | < 5 minutes  |
| Mean Time to Investigate (MTTI) | < 15 minutes |
| Mean Time to Contain (MTTC)     | < 30 minutes |
| Mean Time to Recover (MTTR)     | < 1 hour     |
| False Positive Rate             | < 10%        |

---

# 14. References

## NIST SP 800-61 Rev. 2

Computer Security Incident Handling Guide

https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf

---

## Elastic Security Incident Response

https://www.elastic.co/guide/en/security/current/incident-response-guide.html

---

## Velociraptor Documentation

https://docs.velociraptor.app/docs/incident-response/

---

# Conclusion

The Nation-State Lab Incident Response Framework provides a structured approach for detecting, investigating, containing, eradicating, and recovering from cyber incidents.

By combining:

* Elasticsearch
* Kibana
* Winlogbeat
* Filebeat
* Sysmon
* Velociraptor
* VMware Snapshots

the lab delivers an end-to-end incident response workflow aligned with industry best practices and suitable for cybersecurity training, threat hunting, and detection engineering exercises.
