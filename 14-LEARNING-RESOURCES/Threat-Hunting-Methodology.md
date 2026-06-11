# Threat Hunting Methodology – Nation-State Lab

Threat hunting is a proactive search for malicious activity that evades automated detection rules. In the Nation-State Lab, we used Velociraptor, Kibana, and Elasticsearch to hunt for artifacts left behind by the APT attack chain.

This document outlines the methodology, tools, and techniques employed.

---

# 1. Threat Hunting Lifecycle

| Phase               | Description                                                        | Lab Implementation                                                                                                     |
| ------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| **Hypothesis**      | Define what to hunt based on threat intelligence or observed gaps. | After executing the attack chain, hunt for specific indicators such as `shell.exe`, `beacon.exe`, and scheduled tasks. |
| **Data Collection** | Gather relevant telemetry from endpoints and central logs.         | Velociraptor hunts (Pslist, ScheduledTasks, EventLogs, FileFinder) and Kibana searches.                                |
| **Analysis**        | Examine collected data for anomalies or known IOCs.                | VQL filtering, timeline correlation, and process lineage review.                                                       |
| **Response**        | Contain, eradicate, and document findings.                         | Kill processes, delete files, remove scheduled tasks, and update detection rules.                                      |

---

# 2. Tools Used for Hunting

| Tool                  | Purpose                             | Key Artifacts Collected                                      |
| --------------------- | ----------------------------------- | ------------------------------------------------------------ |
| **Velociraptor**      | Endpoint hunting across Windows VMs | Processes, scheduled tasks, event logs, files, registry      |
| **Kibana (Discover)** | Centralized log hunting             | Winlogbeat events (4688, 4698, 4624, 4663) and Sysmon events |
| **Elasticsearch API** | Bulk analysis and querying          | `winlogbeat-*` and `filebeat-*` indices                      |

---

# 3. Pre-Hunt Preparation

Before starting a hunt:

* Ensure Velociraptor clients are online.
* Verify all target VMs appear healthy in the **Deployments** page.
* Set Kibana time range to the attack window or previous 24 hours.
* Define a clear hunting hypothesis.

### Example Hypothesis

> The attacker created a scheduled task named **Updater** on WS1.

---

# 4. Hypothesis-Driven Hunting Examples

## 4.1 Reverse Shell Payload (`shell.exe`)

### Hunt Steps

1. Run **Windows.System.Pslist** in Velociraptor.
2. Filter using:

```text
ProcessRegex: (?i)shell.exe
```

3. Search Kibana:

```kql
winlog.event_id:4688 AND process.executable:*shell.exe
```

4. Review:

   * Parent process
   * User context
   * Network connections (Sysmon Event ID 3)

### VQL Query

```sql
SELECT
    Name,
    Pid,
    ParentPid,
    CommandLine,
    CreateTime
FROM hunt_results()
WHERE Name =~ '(?i)shell.exe'
```

---

## 4.2 Persistence via Scheduled Task

### Hunt Steps

1. Run **Windows.Sys.ScheduledTasks**
2. Search Kibana:

```kql
winlog.event_id:4698 AND winlog.event_data.TaskName:Updater
```

3. Review:

   * Task content
   * Payload path
   * Creation time

### VQL Query

```sql
SELECT *
FROM hunt_results()
WHERE Name =~ '(?i)Updater'
```

---

## 4.3 LSASS Access (Credential Dumping)

### Hunt Steps

1. Search Security Event ID 4663 in Velociraptor.
2. Search Kibana:

```kql
event.code:10 AND winlog.event_data.TargetImage:*lsass.exe
```

3. Identify:

   * Source process
   * User context
   * Access type

### VQL Query

```sql
SELECT
    System.EventID,
    EventData.Data
FROM hunt_results()
WHERE System.EventID = 4663
    AND EventData.Data =~ '(?i)lsass'
```

---

## 4.4 Pass-the-Hash Lateral Movement

### Hunt Steps

1. Search for Event ID 4624.

2. Filter:

   * Logon Type = 3
   * Source IP = `192.168.1.5`

3. Kibana Query:

```kql
winlog.event_id:4624
AND winlog.event_data.LogonType:3
AND winlog.event_data.IpAddress:192.168.1.5
```

4. Correlate with:

```text
Event ID 7045
Service Name = PSEXESVC
```

---

# 5. Data-Driven Hunting (Baseline Anomaly Detection)

## Establish a Baseline

Collect normal:

* Running processes
* Scheduled tasks
* Network connections

over a period of one week.

## Compare Current State

Look for:

* New executables in `C:\Users\Public\`
* Unexpected scheduled tasks
* Unusual outbound connections

## Example Baseline Query

```sql
SELECT
    Name,
    Exe,
    CreateTime
FROM pslist()
WHERE CreateTime > now() - 7
ORDER BY CreateTime DESC
```

---

# 6. Centralized Hunting with Kibana

Useful hunting searches:

### Suspicious Executables

```kql
winlog.event_id:4688
AND process.executable:(*shell.exe OR *beacon.exe OR *mimikatz.exe)
```

### Suspicious Scheduled Tasks

```kql
winlog.event_id:4698
AND winlog.event_data.TaskName:*Update*
```

### Network Logons from Kali

```kql
winlog.event_id:4624
AND winlog.event_data.LogonType:3
AND winlog.event_data.IpAddress:192.168.1.5
```

### LSASS Access

```kql
event.code:10
AND winlog.event_data.TargetImage:*lsass.exe
```

### Timeline Correlation

Apply identical time filters across all searches to reconstruct the attack timeline.

---

# 7. Common Velociraptor Artifacts

| Artifact                   | Purpose              | Typical Filter                       |
| -------------------------- | -------------------- | ------------------------------------ |
| Windows.System.Pslist      | Running processes    | `Name =~ 'shell.exe'`                |
| Windows.Sys.ScheduledTasks | Persistence          | `Name =~ 'Updater'`                  |
| Windows.EventLogs.Security | Security events      | `System.EventID IN (4624,4688,4698)` |
| Windows.Search.FileFinder  | File hunting         | `C:\Users\Public\*.exe`              |
| Windows.Sys.Persistence    | Registry persistence | Optional                             |

---

# 8. Post-Hunt Analysis & Documentation

After completing the hunt:

* Export results to CSV.
* Correlate findings with the attack timeline.
* Update detection rules.
* Create a hunt report containing:

  * Screenshots
  * VQL queries
  * Findings
  * Remediation actions

---

# 9. Proactive Hunting Schedule

| Frequency              | Focus                     | Artifacts                         |
| ---------------------- | ------------------------- | --------------------------------- |
| After every simulation | Malware artifacts         | Pslist, ScheduledTasks, EventLogs |
| Weekly                 | New executables and tasks | FileFinder, ScheduledTasks        |
| Monthly                | Baseline review           | Process creation and logon events |

---

# 10. Example Full Hunt After the APT Attack

### Hypothesis

The attacker left artifacts on WS1 and DC.

| Target | Artifact                   | Parameter                   | Finding               |
| ------ | -------------------------- | --------------------------- | --------------------- |
| WS1    | Windows.System.Pslist      | `shell.exe`                 | Process terminated    |
| WS1    | Windows.Sys.ScheduledTasks | None                        | Updater task found    |
| WS1    | Windows.EventLogs.Security | Event ID 4663               | LSASS access detected |
| WS1    | Windows.Search.FileFinder  | `C:\Users\Public\shell.exe` | File present          |
| DC     | Windows.System.Pslist      | `beacon.exe`                | Process running       |
| DC     | Windows.EventLogs.Security | Event ID 4624               | Logon from Kali IP    |

### Conclusion

All attack artifacts were successfully identified through threat hunting activities.

---

# 11. Tips for Effective Hunting

* Always use VQL filters instead of manually scrolling through results.
* Correlate multiple artifacts together.
* Save successful hunts as reusable templates.
* Schedule recurring baseline hunts.
* Continuously refine hunting hypotheses.

---

# 12. References

## Velociraptor

https://docs.velociraptor.app/docs/hunts/

## Elastic Security Hunting

https://www.elastic.co/guide/en/security/current/hunting.html

## MITRE ATT&CK Threat Hunting

https://attack.mitre.org/resources/hunting/

---

*This document is part of the Nation-State Lab Learning Resources.*
