# Credential Dumping Phase Analysis

## Objective
After obtaining `SYSTEM` privileges on WS1, the attacker dumps NTLM password hashes from the Local Security Authority Subsystem Service (LSASS) process memory. The extracted hashes include the domain administrator’s NTLM hash, which is then used for pass-the-hash attacks and lateral movement to the Domain Controller.

**MITRE ATT&CK Mapping:**  
- **Tactic:** TA0006 – Credential Access  
- **Technique:** T1003.001 – OS Credential Dumping: LSASS Memory  

**Note:** WS2 (`192.168.1.30`) was not targeted in this phase; the attack focused solely on WS1.

---

## Attack Execution

From the elevated Meterpreter session (`SYSTEM`) on WS1, the attacker loads the Kiwi (Mimikatz) extension and dumps credentials.

```text
meterpreter > load kiwi
meterpreter > creds_all
```

### Extracted NTLM Hash (Example)

```text
Administrator   NATION   aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0
```

The second part (after the colon) is the NTLM hash of the domain administrator.

---

## Detection in Kibana

The LSASS memory access by mimikatz.exe (or Kiwi module) generates Windows Security and Sysmon events.

### Key Event IDs

| Event ID | Source            | Description |
|----------|------------------|-------------|
| 4663     | Windows Security | Handle requested to LSASS |
| 10       | Sysmon           | Process accessed lsass.exe |
| 4688     | Windows Security | Process creation (mimikatz.exe) |
| 1        | Sysmon           | Process creation (detailed) |

---

### Kibana Queries

**Detect Mimikatz execution**
```text
winlog.event_id: 4688 AND process.name: mimikatz.exe
```

**Detect LSASS handle access**
```text
winlog.event_id: 4663 AND winlog.event_data.ObjectName: *lsass.exe
```

**Detect Sysmon LSASS access**
```text
event.code: 10 AND winlog.event_data.TargetImage: *lsass.exe AND winlog.event_data.CallTrace: *mimikatz*
```

---

### Example Event (WS1 - Sysmon 10)

| Field | Value |
|------|------|
| event.code | 10 |
| SourceImage | C:\Users\Public\mimikatz.exe |
| TargetImage | C:\Windows\System32\lsass.exe |
| host.name | WS1 |

---

## Recommended Detection Rules

### Rule 1: Mimikatz Execution
```text
winlog.event_id: 4688 AND process.name: mimikatz.exe
```

### Rule 2: LSASS Handle Request
```text
event.code: 10 AND winlog.event_data.TargetImage: *lsass.exe
```

### Rule 3: Security Event LSASS Access
```text
winlog.event_id: 4663 AND winlog.event_data.ObjectName: *lsass.exe
```

---

## Post-Attack Hunting (Velociraptor)

**Artifact:** Windows.Sys.Processes

```sql
SELECT Name, Pid, CommandLine, Exe
FROM hunt_results()
WHERE Name =~ '(?i)mimikatz.exe'
```

### Findings
- WS1: mimikatz.exe detected (or artifacts present)
- WS2: No evidence found

---

**Artifact:** Windows.EventLogs.Security  
Used for Event ID 4663 correlation.

---

## Cleanup

```cmd
del C:\Users\Public\mimikatz.exe
```

```text
sessions -k 2
```

---

## Screenshot Evidence

- Meterpreter Kiwi output showing `creds_all`
- Kibana Discover (Event ID 4688 / 10)
- Sysmon event showing LSASS access
- Velociraptor hunt results

---

## Conclusion

The credential dumping phase successfully extracted NTLM hashes from LSASS memory on WS1. The activity was detected via Sysmon (Event ID 10), Security logs (4663, 4688), and validated in Kibana. The captured credentials were later used for lateral movement across the domain.