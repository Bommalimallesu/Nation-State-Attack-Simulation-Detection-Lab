# Persistence Phase Analysis

## Objective
After establishing a reverse shell on WS1, the attacker installs persistence to ensure the foothold survives a system reboot. A scheduled task named **“Updater”** is created to execute the reverse shell payload (`C:\Users\Public\shell.exe`) daily at 09:00.

**MITRE ATT&CK Mapping:**  
- **Tactic:** TA0003 – Persistence  
- **Technique:** T1053.005 – Scheduled Task  

---

## Attack Execution

All commands were executed from within the Meterpreter session (or a standard Windows shell) on WS1 (`192.168.1.20`) after the reverse shell was established.

### 1. Create Scheduled Task

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

### Explanation of Parameters
- `/create` → Creates a new scheduled task  
- `/tn "Updater"` → Task name  
- `/tr "C:\Users\Public\shell.exe"` → Payload to execute  
- `/sc daily` → Runs daily  
- `/st 09:00` → Start time  
- `/f` → Force overwrite if task exists  

---

### 2. Verify Task

```cmd
schtasks /query /tn "Updater"
```

Expected output:

```
Folder: \
TaskName                                 Next Run Time          Status
======================================== ====================== ===============
Updater                                  09:00:00, 10/06/2026   Ready
```

---

## Detection in Kibana

The scheduled task creation generates **Windows Security Event ID 4698**, captured via Winlogbeat.

### Kibana Query

```text
winlog.event_id: 4698 AND winlog.event_data.TaskName: Updater
```

### Example Event Fields

| Field | Value |
|------|------|
| winlog.event_id | 4698 |
| winlog.event_data.TaskName | Updater |
| winlog.event_data.TaskContent | C:\Users\Public\shell.exe |
| winlog.event_data.UserContext | NATION\Administrator |
| host.name | WS1 |

---

## Additional Detection – Process Creation

```text
winlog.event_id: 4688 AND process.executable: *schtasks.exe AND process.command_line: *Updater*
```

This detects the creation of the scheduled task process itself.

---

## Recommended Kibana Alert Rules

### Rule 1: Suspicious Task Name
- **Name:** Persistence – Suspicious Task Name "Updater"  
- **Query:**  
  ```text
  winlog.event_id: 4698 AND winlog.event_data.TaskName: Updater
  ```

---

### Rule 2: Task Executing from Public Directory
- **Name:** Persistence – Task from Public Directory  
- **Query:**  
  ```text
  winlog.event_id: 4698 AND winlog.event_data.TaskContent: *Users\Public*
  ```

---

### Rule 3: Suspicious schtasks Execution
- **Name:** Persistence – schtasks.exe Anomaly  
- **Query:**  
  ```text
  winlog.event_id: 4688 AND process.executable: *schtasks.exe AND NOT winlog.event_data.ParentProcessName: *explorer.exe
  ```

---

## Post-Attack Hunting (Velociraptor)

### Artifact
- `Windows.Sys.ScheduledTasks`

### Hunt Query
```sql
SELECT * FROM hunt_results()
WHERE Name =~ '(?i)Updater'
```

### Result
- Task **Updater** confirmed on WS1  
- Trigger, action, and user context visible  

---

## Cleanup (Optional)

```cmd
schtasks /delete /tn "Updater" /f
```

---

## Screenshot Evidence

- Meterpreter: `schtasks /create` success output  
- Kibana: Event ID 4698 showing task creation  
- Velociraptor: Scheduled task “Updater” in hunt results  

---

## Conclusion

The persistence phase successfully established a scheduled task on WS1 that ensures the reverse shell executes daily. The activity was logged via **Event ID 4698**, enabling detection through Kibana.

Velociraptor confirmed the presence of the scheduled task, validating endpoint-level forensic visibility of persistence mechanisms.