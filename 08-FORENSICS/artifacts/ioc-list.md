# Indicators of Compromise (IOC) – APT Attack Chain Simulation

This document consolidates all indicators observed during the simulated APT attack chain across WS1, DC, and supporting infrastructure. These IOCs can be used for threat hunting, detection engineering, and incident response validation in SIEM and EDR environments.

---

## 1. Network Indicators

| Type | Value | Direction | Description |
|------|-------|-----------|-------------|
| IPv4 | 192.168.1.5 | Source / Destination | Attacker (Kali Linux) |
| IPv4 | 192.168.1.20 | Destination | WS1 (initial compromise target) |
| IPv4 | 192.168.1.10 | Destination | Domain Controller (lateral movement target) |
| Port | 4444 | WS1 → 192.168.1.5 | Reverse shell (initial access) |
| Port | 4445 | WS1 → 192.168.1.5 | Alternate shell channel |
| Port | 8080 | 192.168.1.5 → WS1/DC | Payload delivery (HTTP) |
| Port | 8081 | DC → 192.168.1.5 | C2 beacon communication |
| Port | 445 | 192.168.1.5 → DC | SMB lateral movement (PsExec) |
| Protocol | NTLM | Authentication | Pass-the-hash authentication |

---

## 2. File System Indicators

| Path | Host | File | Description |
|------|------|------|-------------|
| C:\Users\Public\shell.exe | WS1 | shell.exe | Reverse shell payload |
| C:\Users\Public\beacon.exe | DC | beacon.exe | C2 beacon executable |
| C:\Windows\Temp\PSEXESVC.exe | DC | PSEXESVC.exe | PsExec service binary |
| C:\Users\Public\*.exe | WS1/DC | Multiple | Suspicious staging directory usage |
| C:\Temp\*.exe | WS1/DC | Multiple | Temporary payload execution |

---

## 3. Process Indicators

| Process | Parent | Host | Description |
|----------|--------|------|-------------|
| shell.exe | cmd.exe | WS1 | Reverse shell execution |
| beacon.exe | cmd.exe | DC | C2 beacon process |
| certutil.exe | cmd.exe | DC | LOLBin download activity |
| PSEXESVC.exe | cmd.exe | DC | PsExec service execution |
| eventvwr.exe | explorer.exe | WS1 | UAC bypass chain |
| sdclt.exe | explorer.exe | WS1 | UAC bypass chain |
| fodhelper.exe | explorer.exe | WS1 | UAC bypass chain |

---

## 4. Scheduled Task Indicators

| Task Name | Host | Action | Trigger |
|-----------|------|--------|---------|
| Updater | WS1 | C:\Users\Public\shell.exe | Daily 09:00 |

---

## 5. Windows Event Log Indicators

| Event ID | Source | Description | Key Fields |
|----------|--------|-------------|------------|
| 4688 | Security | Process creation | shell.exe, beacon.exe, certutil.exe |
| 4698 | Security | Scheduled task creation | TaskName: Updater |
| 4624 | Security | Successful logon | LogonType: 3, Source: 192.168.1.5 |
| 4672 | Security | Privileged logon | Administrator privileges |
| 4663 | Security | Object access | lsass.exe access |
| 5140 | Security | Network share access | ADMIN$ usage |
| 3 | Sysmon | Network connection | beacon.exe → 192.168.1.5:8081 |
| 10 | Sysmon | Process access | LSASS credential access |

---

## 6. Registry Indicators

| Registry Path | Value | Description |
|---------------|-------|-------------|
| HKLM\...\Run\Updater | shell.exe | Persistence attempt (if used) |
| HKLM\...\PSEXESVC | ImagePath in Temp | PsExec service artifact |
| HKLM\...\Policies\System\EnableLUA | 0/1 | UAC tampering indicator |
| HKLM\...\Image File Execution Options | Debugger hijack | Process injection technique |

---

## 7. Authentication Indicators

| Field | Value |
|------|------|
| Domain | NATION |
| Username | Administrator |
| Logon Type | 3 (Network) |
| Auth Method | NTLM |
| Source Host | KALI (192.168.1.5) |

---

## 8. Command-Line Indicators

| Command Pattern | Description |
|----------------|-------------|
| certutil -urlcache -f http:// | LOLBin file download |
| powershell -enc | Encoded PowerShell execution |
| IEX (New-Object Net.WebClient) | Download cradle |
| Invoke-WebRequest | File retrieval |
| base64 decode patterns | Obfuscated payload execution |

---

## 9. MITRE ATT&CK Mapping

| Technique | ID | Example IOC |
|-----------|----|-------------|
| Execution | T1059 | shell.exe, powershell.exe |
| Persistence | T1053.005 | Scheduled Task: Updater |
| Privilege Escalation | T1548.002 | UAC bypass via fodhelper.exe |
| Credential Access | T1003.001 | LSASS memory access |
| Lateral Movement | T1550.002 | Pass-the-hash via SMB |
| Command & Control | T1071.001 | HTTP beacon to 8081 |
| Defense Evasion | T1218 | certutil.exe LOLBin |

---

## 10. Detection Use Cases

### SIEM (KQL)
```
process.name: "shell.exe" OR process.name: "beacon.exe"
```

```
event.code: 4624 AND winlog.event_data.LogonType: 3 AND source.ip: 192.168.1.5
```

```
event.code: 4698 AND winlog.event_data.TaskName: "Updater"
```

---

### Velociraptor Hunt Targets
- shell.exe
- beacon.exe
- certutil.exe
- PSEXESVC.exe
- C:\Users\Public\*.exe
- Network connections to 192.168.1.5

---

### Sigma Detection Focus
- Process execution anomalies
- Scheduled task creation
- LSASS access patterns
- SMB lateral movement
- HTTP beaconing behavior

---

## 11. False Positive Considerations

| Indicator | Risk | Mitigation |
|----------|------|------------|
| certutil.exe usage | Medium | Whitelist admin usage |
| Logon Type 3 | Medium | Restrict trusted IPs |
| Scheduled tasks | Low | Validate task origin |
| Public folder executables | High | Treat as suspicious by default |

---

## 12. Operational Notes

- This IOC set is derived from a controlled APT simulation environment.
- Intended for SOC training, purple team exercises, and detection engineering.
- Should not be used as-is in production without tuning for environment baseline behavior.

---
