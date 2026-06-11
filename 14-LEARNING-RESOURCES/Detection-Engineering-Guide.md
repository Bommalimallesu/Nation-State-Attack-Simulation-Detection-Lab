# Detection Engineering Guide – Nation-State Lab

This guide documents the detection engineering practices used throughout the Nation-State Lab. It demonstrates how Windows and Linux telemetry can be transformed into actionable detections and alerts using Elasticsearch, Kibana, Winlogbeat, Sysmon, and Filebeat.

The guide focuses on the MITRE ATT&CK techniques observed during the simulated Advanced Persistent Threat (APT) attack chain.

---

# 1. Detection Engineering Philosophy

The following principles guided detection development in the lab.

## Assume Compromise

Design detections for post-exploitation activities rather than relying solely on prevention controls.

Examples:

* Credential dumping
* Persistence mechanisms
* Lateral movement
* Command and Control (C2)

---

## Use Layered Detection

Combine multiple telemetry sources for stronger detection confidence.

Example:

| Activity            | Data Source                    |
| ------------------- | ------------------------------ |
| Process Execution   | Event ID 4688 / Sysmon Event 1 |
| Network Connections | Sysmon Event 3                 |
| Scheduled Tasks     | Event ID 4698                  |
| Authentication      | Event IDs 4624, 4672           |

---

## Baseline Normal Activity

Understand legitimate system behavior before creating detection rules.

Questions to answer:

* What processes normally run?
* Which scheduled tasks are expected?
* What network connections are common?
* Which users regularly log in?

---

## Map Detections to MITRE ATT&CK

Each rule should reference:

* ATT&CK Tactic
* ATT&CK Technique
* Technique ID

Benefits:

* Coverage tracking
* Threat-hunting alignment
* Reporting consistency

---

## Validate Detections

Use:

* Atomic Red Team
* Caldera
* Metasploit
* Manual testing

to ensure detections trigger correctly.

---

# 2. Data Sources Used in the Lab

| Source                     | Events Collected                         | Key Fields                                                          |
| -------------------------- | ---------------------------------------- | ------------------------------------------------------------------- |
| Winlogbeat (Security Logs) | 4624, 4625, 4663, 4672, 4688, 4698, 7045 | `winlog.event_id`, `process.executable`, `winlog.event_data.*`      |
| Sysmon                     | 1, 3, 10                                 | `event.code`, `process.executable`, `destination.ip`, `TargetImage` |
| Filebeat (Kali Linux)      | Nmap, Hydra, command execution logs      | `message`, `process.name`                                           |

---

## Elasticsearch Indices

```text
winlogbeat-*
filebeat-*
```

---

## Time Field

```text
@timestamp
```

---

# 3. Building KQL Detection Queries

## 3.1 Process Creation (Event ID 4688)

### Suspicious Executable Execution

```kql
winlog.event_id:4688 AND process.executable:*shell.exe
```

### UAC Bypass Process Chain

```kql
winlog.event_id:4688
AND process.executable:*eventvwr.exe
AND winlog.event_data.ParentProcessName:*cmd.exe
```

MITRE:

* TA0004 – Privilege Escalation
* T1548.002 – Bypass User Account Control

---

## 3.2 Scheduled Task Creation (Event ID 4698)

### Detect Specific Task Name

```kql
winlog.event_id:4698
AND winlog.event_data.TaskName:Updater
```

### Detect Payloads in Public Directory

```kql
winlog.event_id:4698
AND winlog.event_data.TaskContent:*Users\\Public*
```

MITRE:

* TA0003 – Persistence
* T1053.005 – Scheduled Task

---

## 3.3 Network Logons (Event ID 4624)

### Detect Lateral Movement from Attacker Host

```kql
winlog.event_id:4624
AND winlog.event_data.LogonType:3
AND winlog.event_data.IpAddress:192.168.1.5
```

MITRE:

* TA0008 – Lateral Movement
* T1550.002 – Pass-the-Hash

---

## 3.4 LSASS Access (Credential Dumping)

### Sysmon Event 10

```kql
event.code:10
AND winlog.event_data.TargetImage:*lsass.exe
```

### Security Event 4663

```kql
winlog.event_id:4663
AND winlog.event_data.ObjectName:*lsass.exe
```

MITRE:

* TA0006 – Credential Access
* T1003.001 – LSASS Memory

---

## 3.5 Suspicious Service Installation

### PsExec Service

```kql
winlog.event_id:7045
AND winlog.event_data.ServiceName:PSEXESVC
```

MITRE:

* TA0008 – Lateral Movement
* T1569.002 – Service Execution

---

# 4. Creating Kibana Alerting Rules

Because the lab uses:

```yaml
xpack.security.enabled=false
```

detections were created using Kibana Search Rules.

---

## Rule Creation Workflow

1. Navigate to:

```text
Stack Management → Rules
```

2. Select:

```text
Create Rule
```

3. Choose:

```text
Search
```

4. Select Index Pattern:

```text
winlogbeat-*
```

5. Paste KQL query.

6. Configure schedule.

Example:

```text
Run every 5 minutes
```

7. Configure threshold:

```text
Count > 0
```

8. Add actions:

* Kibana Log
* Email
* Webhook

9. Save and enable.

---

## Example Rule Configuration

```yaml
name: "Reverse Shell Detection"
index_pattern: "winlogbeat-*"

kql: >
  winlog.event_id:4688
  AND process.executable:*shell.exe

schedule: "*/5 * * * *"

threshold: 1

actions:
  - type: log
    level: info
```

---

# 5. Testing Detection Rules

## 5.1 Reverse Shell Detection

### Test

```cmd
echo test > C:\Users\Public\shell.exe
C:\Users\Public\shell.exe
```

### Expected Result

Rule triggers within configured interval.

---

## 5.2 Scheduled Task Detection

### Test

```cmd
schtasks /create ^
/tn "TestTask" ^
/tr "C:\Windows\System32\calc.exe" ^
/sc once ^
/st 00:00 ^
/f
```

### Detection Query

```kql
winlog.event_id:4698
AND winlog.event_data.TaskContent:*calc.exe
```

---

## 5.3 LSASS Access Detection

### Test

```cmd
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
```

### Expected Result

Sysmon Event ID 10 generated.

---

# 6. Detection Tuning & False Positives

| Rule            | Potential False Positives               | Recommended Tuning              |
| --------------- | --------------------------------------- | ------------------------------- |
| `*shell.exe`    | Legitimate applications named shell.exe | Exclude known paths             |
| Scheduled Tasks | Administrative automation               | Whitelist approved tasks        |
| Network Logons  | Legitimate Kali administration          | Correlate with process activity |
| LSASS Access    | Antivirus products                      | Exclude trusted tools           |

---

## General Tuning Guidelines

### Start Broad

Begin with:

* High severity
* Low threshold

Then tune gradually.

### Use Exclusions

Example:

```kql
AND NOT process.executable:"C:\\Program Files\\TrustedApp\\shell.exe"
```

### Correlate Multiple Fields

Useful fields:

* `user.name`
* `host.name`
* `process.command_line`
* `source.ip`
* `parent.process.name`

---

# 7. Mapping Rules to MITRE ATT&CK

| Detection Rule                  | ATT&CK Tactic        | ATT&CK Technique                  | ID        |
| ------------------------------- | -------------------- | --------------------------------- | --------- |
| `process.executable:*shell.exe` | Initial Access       | Exploitation for Client Execution | T1203     |
| `TaskName:Updater`              | Persistence          | Scheduled Task                    | T1053.005 |
| `eventvwr.exe + cmd.exe`        | Privilege Escalation | Bypass UAC                        | T1548.002 |
| `lsass.exe access`              | Credential Access    | OS Credential Dumping             | T1003.001 |
| `4624 Type 3 from Kali`         | Lateral Movement     | Pass-the-Hash                     | T1550.002 |
| `beacon.exe execution`          | Command and Control  | Application Layer Protocol        | T1071.001 |

---

## Recommended Metadata

Include:

```yaml
severity: High
tactic: Credential Access
technique: T1003.001
data_source: Sysmon
```

---

# 8. Production Detection Engineering

For production deployments:

## Enable Elastic Security

```yaml
xpack.security.enabled=true
```

Benefits:

* ATT&CK tagging
* Detection rules
* Cases
* Timelines

---

## Threat Intelligence

Integrate:

* AbuseIPDB
* AlienVault OTX
* MISP
* Recorded Future

---

## SOAR Integration

Examples:

* TheHive
* Cortex
* Shuffle
* Splunk SOAR

---

## Alert Delivery

Configure:

* Email
* Slack
* Microsoft Teams
* PagerDuty
* Webhooks

---

# 9. Reverse Shell Detection Playbook

## Rule

```text
Initial Access – Reverse Shell (shell.exe)
```

---

## Query

```kql
winlog.event_id:4688
AND process.executable:*shell.exe
```

---

## Severity

```text
High
```

---

## MITRE Mapping

| Tactic                  | Technique |
| ----------------------- | --------- |
| TA0001 – Initial Access | T1203     |

---

## Investigation Steps

1. Identify affected host (`host.name`)
2. Determine user context
3. Identify parent process
4. Correlate with Sysmon Event ID 3
5. Identify destination IP and port
6. Review Filebeat logs from Kali
7. Isolate host
8. Terminate malicious process
9. Preserve evidence

---

# 10. Continuous Improvement

Detection engineering is an iterative process.

After every simulation:

### Review

* Missed detections
* False positives
* Alert quality

### Improve

* Create additional rules
* Add ATT&CK coverage
* Refine thresholds

### Share

Convert detections into:

* Sigma Rules
* Elastic Detection Rules
* Community content

---

# 11. References

## Elastic Security

https://www.elastic.co/guide/en/security/current/detection-engine-overview.html

---

## Sigma Rules

https://github.com/SigmaHQ/sigma

---

## MITRE ATT&CK

https://attack.mitre.org

---

## Atomic Red Team

https://github.com/redcanaryco/atomic-red-team

---

# Conclusion

The Nation-State Lab demonstrates how raw endpoint and network telemetry can be transformed into actionable detections through a structured detection engineering process.

Using Winlogbeat, Sysmon, Filebeat, Elasticsearch, and Kibana, defenders can:

* Detect adversary behavior
* Validate coverage against MITRE ATT&CK
* Build automated alerts
* Continuously improve detection quality

The techniques and detections described in this guide were tested and validated within the Nation-State Lab and provide a foundation for building production-grade detection programs.
