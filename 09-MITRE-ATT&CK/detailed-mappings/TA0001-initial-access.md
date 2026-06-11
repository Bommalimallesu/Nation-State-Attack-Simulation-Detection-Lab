# TA0001 – Initial Access (MITRE ATT&CK)

## Tactic

**TA0001 – Initial Access**

### Objective

The objective of the Initial Access tactic is to gain an initial foothold within the target environment and establish the first stage of compromise. In this laboratory simulation, the attacker manually executed a malicious reverse shell payload on the workstation **WS1**, simulating either an insider threat or physical access to the machine.

Although no external exploit or phishing campaign was used, the activity closely aligns with **User Execution** and **Windows Command Shell** techniques within the MITRE ATT&CK framework.

---

# MITRE ATT&CK Technique Mapping

| ATT&CK ID | Technique | Description |
|------------|-------------------------------|----------------------------------------------|
| **T1204.002** | User Execution – Malicious File | User executes a malicious executable |
| **T1059.003** | Windows Command Shell | `cmd.exe` used to launch the payload |
| **T1059.001** | PowerShell *(Optional)* | Applicable if PowerShell is used for execution or download |
| **T1203** | Exploitation for Client Execution *(Alternative)* | Applicable in phishing or exploit-based scenarios |

For this simulation, **T1204.002** and **T1059.003** provide the most accurate representation of the observed activity.

---

# Attack Description

The attacker generated a reverse TCP payload (`shell.exe`) and transferred it to the victim workstation. The payload was stored under `C:\Users\Public`, a location that is often abused because it is writable by standard users and may evade casual inspection.

The executable was then launched through the Windows Command Prompt (`cmd.exe`). Upon execution, the payload established a reverse connection to the attacker's Kali Linux system, providing remote interactive access.

---

# Attack Simulation Workflow

1. Generate the malicious payload using `msfvenom`.
2. Host the payload on a local HTTP server.
3. Transfer the payload to the target workstation.
4. Save the executable as:

```
C:\Users\Public\shell.exe
```

5. Open an administrative Command Prompt.
6. Execute:

```cmd
C:\Users\Public\shell.exe
```

7. The payload initiates a reverse TCP connection to the attacker's listener on port **4444**, establishing the initial compromise.

---

# Detection Opportunities

| Data Source | Detection Logic | Indicator |
|-------------|----------------|-----------|
| Windows Event ID 4688 | Monitor process creation from unusual directories | `C:\Users\Public\shell.exe` |
| Command Line Logging | Detect suspicious payload downloads | `certutil -urlcache`, `Invoke-WebRequest`, `bitsadmin` |
| Sysmon Event ID 3 | Monitor outbound connections to uncommon ports | Destination Port `4444` |
| Parent-Child Process Analysis | `cmd.exe` or `powershell.exe` spawning unknown executables | `cmd.exe → shell.exe` |
| File Monitoring | Detect executable creation in Public or Temp folders | `shell.exe` written to `C:\Users\Public` |

---

# MITRE ATT&CK Mapping Summary

| Field | Value |
|---------|-----------------------------------------------|
| **Tactic** | Initial Access (TA0001) |
| **Primary Technique** | T1204.002 – User Execution |
| **Supporting Technique** | T1059.003 – Windows Command Shell |
| **Platforms** | Windows |
| **Required Privileges** | User |
| **Primary Data Sources** | Process Creation, Command Line, File Monitoring, Network Connections |
| **Detection Difficulty** | Moderate |
| **Lab Indicators** | `shell.exe` execution, reverse shell connection, suspicious process tree |

---

# Kibana Evidence

During the simulation, Kibana recorded multiple artifacts associated with the initial compromise.

## Windows Security Event 4688

```
Process Name:
C:\Users\Public\shell.exe

Parent Process:
C:\Windows\System32\cmd.exe
```

This confirms execution of the malicious payload from the Windows Command Shell.

## Sysmon Event ID 3

```
Source IP:
192.168.1.20

Destination IP:
192.168.1.5

Destination Port:
4444
```

This network event confirms establishment of the reverse TCP connection to the attacker.

## File Creation Evidence

If file creation monitoring is enabled, security logs may also record:

```
File:
C:\Users\Public\shell.exe
```

indicating when the payload was written to disk.

---

# Example Kibana KQL Queries

### Detect execution of the malicious payload

```kql
event.code:4688 and process.name:"shell.exe"
```

### Detect payload launched from Command Prompt

```kql
event.code:4688 and process.parent.name:"cmd.exe"
```

### Detect outbound reverse shell traffic

```kql
event.code:3 and destination.port:4444
```

### Detect executables launched from Public folder

```kql
process.executable:"C:\\Users\\Public\\*"
```

---

# Indicators of Compromise (IOCs)

| Indicator Type | Value |
|----------------|-----------------------------------|
| Executable | `shell.exe` |
| Location | `C:\Users\Public\shell.exe` |
| Parent Process | `cmd.exe` |
| Network Protocol | TCP |
| Destination Port | `4444` |
| Destination IP | `192.168.1.5` |
| Behavior | Reverse shell establishment |

---

# Mitigation and Prevention

- Block execution from `C:\Users\Public`, `%TEMP%`, and user-writable directories using **AppLocker** or **Windows Defender Application Control (WDAC)**.
- Enable advanced process creation auditing (Event ID 4688) with full command-line logging.
- Deploy Sysmon to monitor suspicious network connections and process relationships.
- Restrict or monitor utilities commonly abused for payload delivery, such as `certutil`, `bitsadmin`, and PowerShell download functions.
- Use Endpoint Detection and Response (EDR) solutions capable of identifying unsigned executables launched from non-standard locations.
- Provide security awareness training to reduce the likelihood of users executing untrusted files.

---

# Key Takeaways

The initial access phase demonstrates how a seemingly simple executable launched from a user-writable directory can provide attackers with complete remote access. Even without exploiting a software vulnerability, monitoring process creation, parent-child relationships, and outbound network connections enables defenders to identify and investigate suspicious behavior quickly.

---

# References

- MITRE ATT&CK – TA0001: Initial Access
- MITRE ATT&CK – T1204.002: User Execution (Malicious File)
- MITRE ATT&CK – T1059.003: Windows Command Shell
- Lab Scenario: Reverse TCP Shell Initial Compromise on WS1