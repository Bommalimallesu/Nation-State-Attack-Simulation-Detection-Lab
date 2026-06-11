# TA0003 – Persistence (MITRE ATT&CK)

## Tactic

**TA0003 – Persistence**

### Objective

The objective of the Persistence tactic is to ensure continued access to a compromised system even after reboots, user logoffs, or temporary interruptions. In this laboratory simulation, persistence was achieved by creating a scheduled task named **Updater** that automatically executes the malicious payload `shell.exe` every day at **09:00 AM**.

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|-------------------------------------------|-----------------------------------------------|
| **T1053.005** | Scheduled Task | Create a scheduled task to automatically execute malware |
| **TA0003** | Persistence | Maintain long-term access to the compromised host |

---

# Attack Description

The attacker leveraged the Windows Task Scheduler to create a scheduled task named **Updater**. The task was configured to execute:

```
C:\Users\Public\shell.exe
```

every day at **09:00 AM**. If the reverse shell process terminated or the system rebooted, the task would automatically relaunch the malware and re-establish attacker access.

Using scheduled tasks is a common persistence mechanism because it relies on legitimate Windows functionality and often blends with administrative activity.

---

# Attack Simulation Workflow

1. Gain command execution on WS1.
2. Open a Command Prompt.
3. Create the scheduled task:

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

4. Windows registers the task in Task Scheduler.
5. Every day at **09:00**, `shell.exe` executes automatically.

---

# Technique Overview – Scheduled Task (T1053.005)

The Windows Task Scheduler enables programs or scripts to execute automatically based on predefined schedules or system events. Attackers frequently abuse this feature to maintain persistence because it survives reboots and appears similar to legitimate administrative tasks.

In this simulation:

- **Task Name:** `Updater`
- **Trigger:** Daily at `09:00`
- **Action:** Execute `C:\Users\Public\shell.exe`

---

# Detection Opportunities

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Security Event ID 4698 | Monitor creation of scheduled tasks | `TaskName: Updater` |
| Security Event ID 4688 | Detect execution of `schtasks.exe` | `/create` command |
| Sysmon Event ID 1 | Process creation with full command line | `schtasks /create` |
| Task Scheduler Operational Log | Task registration events | Event ID 106 |
| File Monitoring | Monitor XML task files | `Windows\System32\Tasks\Updater` |

---

# MITRE ATT&CK Mapping Summary

| Field | Value |
|---------|--------------------------------------------|
| **Tactic** | Persistence (TA0003) |
| **Technique** | Scheduled Task / Job |
| **Sub-technique** | T1053.005 – Scheduled Task |
| **Platform** | Windows |
| **Permissions Required** | Administrator |
| **Primary Data Sources** | Process Creation, Command Line, Windows Event Logs |
| **Detection Difficulty** | Low to Moderate |

---

# Kibana Evidence

## Security Event ID 4698

```
Task Name:
Updater

Task Action:
C:\Users\Public\shell.exe
```

This event confirms the creation of a new scheduled task.

---

## Security Event ID 4688

```
Process Name:
C:\Windows\System32\schtasks.exe

Command Line:
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

This event records execution of the `schtasks.exe` utility with suspicious arguments.

---

# Example Kibana KQL Queries

## Detect scheduled task creation

```kql
event.code:4698
```

## Detect the Updater task

```kql
event.code:4698 and winlog.event_data.TaskName:"Updater"
```

## Detect schtasks execution

```kql
event.code:4688 and process.name:"schtasks.exe"
```

## Detect scheduled tasks executing binaries from Public folder

```kql
event.code:4688 and process.name:"schtasks.exe" and process.command_line:*C:\\Users\\Public\\*
```

---

# Example Sigma Rule

```yaml
title: Suspicious Scheduled Task Creation
id: persistence-schtasks-public-folder
status: experimental

logsource:
  product: windows
  category: process_creation

detection:
  selection:
    Image|endswith: '\schtasks.exe'
    CommandLine|contains:
      - '/create'
      - 'C:\Users\Public'
      - '.exe'

  condition: selection

level: high
```

---

# Additional Persistence Techniques Considered

The following persistence mechanisms were **not used** in this simulation but are commonly observed in real-world attacks:

| ATT&CK ID | Technique | Used |
|------------|-----------------------------|------|
| T1547.001 | Registry Run Keys | No |
| T1543.003 | Windows Service | No |
| T1098 | Account Manipulation | No |
| T1546 | Event Triggered Execution | No |

Although **PSEXESVC** was created during lateral movement, it functioned as a temporary service rather than a long-term persistence mechanism.

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|-------------------------------------------|
| Scheduled Task | `Updater` |
| Executable | `shell.exe` |
| Execution Path | `C:\Users\Public\shell.exe` |
| Utility | `schtasks.exe` |
| Trigger | Daily at `09:00` |
| Task File | `C:\Windows\System32\Tasks\Updater` |

---

# Forensic Artifacts

Investigators can validate persistence using the following artifacts:

| Artifact | Location |
|-----------|----------------------------------------------------|
| Task Definition | `C:\Windows\System32\Tasks\Updater` |
| Security Log | Event ID 4698 |
| Process Creation | Event ID 4688 |
| Sysmon Process Log | Event ID 1 |
| Task Scheduler Log | Microsoft-Windows-TaskScheduler/Operational |

---

# Example Forensic Command

Export the scheduled task definition:

```cmd
schtasks /query /tn "Updater" /xml > C:\Forensics\Updater.xml
```

List all scheduled tasks:

```cmd
schtasks /query /fo LIST /v
```

---

# Mitigation and Prevention

- Restrict scheduled task creation to authorized administrators.
- Enable command-line auditing for `schtasks.exe`.
- Monitor Security Event ID **4698** and Task Scheduler Operational logs.
- Deploy Sysmon to capture process creation with full command-line arguments.
- Use AppLocker or Windows Defender Application Control (WDAC) to prevent execution of binaries from user-writable directories such as `C:\Users\Public`.
- Alert on scheduled tasks that launch unsigned executables or reference non-standard directories.

---

# Key Takeaways

Scheduled Tasks provide attackers with a simple yet highly effective persistence mechanism that survives system restarts and blends into legitimate administrative activity. Monitoring task creation events, suspicious command-line arguments, and tasks pointing to user-writable directories significantly improves the likelihood of detecting persistence before it is leveraged in subsequent attack stages.

---

# References

- MITRE ATT&CK – TA0003: Persistence
- MITRE ATT&CK – T1053.005: Scheduled Task
- Windows Task Scheduler Documentation
- Lab Simulation: Phase 3 – Scheduled Task Persistence