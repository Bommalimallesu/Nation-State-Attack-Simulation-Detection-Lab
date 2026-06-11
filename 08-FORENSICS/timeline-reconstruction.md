# Timeline Reconstruction – APT Attack Chain Simulation

This document reconstructs the complete sequence of events observed during the simulated Advanced Persistent Threat (APT) attack, beginning with initial access and continuing through persistence, privilege escalation, credential dumping, lateral movement, and command-and-control (C2) communication. The reconstruction is based on Windows Security Logs, Sysmon telemetry, and memory forensic analysis. All timestamps are in UTC and correspond to the lab environment.

---

# 1. Event Summary Table

| Timestamp | Host | Event ID | Description | MITRE ATT&CK Tactic |
|-----------|------|----------|-------------|---------------------|
| 06:13:49.123 | WS1 | 4688 | `shell.exe` executed from `C:\Users\Public` | Execution (T1059) |
| 06:13:49.456 | WS1 | Sysmon 3 | Reverse TCP connection to `192.168.1.5:4444` | Command & Control (T1071) |
| 06:15:00.456 | WS1 | 4698 | Scheduled task `Updater` created | Persistence (T1053.005) |
| 06:15:05.234 | WS1 | 4688 | `eventvwr.exe` launched elevated `cmd.exe` | Privilege Escalation (T1548.002) |
| 06:15:10.456 | WS1 | Sysmon 10 | `shell.exe` accessed `lsass.exe` | Credential Access (T1003.001) |
| 06:15:11.200 | WS1 | 4663 | Full-access handle to `lsass.exe` granted | Credential Access |
| 06:15:23.456 | DC | 4624 | Network Logon (Type 3) from `192.168.1.5` | Lateral Movement (T1550.002) |
| 06:15:23.457 | DC | 4672 | Administrative privileges assigned | Lateral Movement |
| 06:15:23.458 | DC | 5140 | `ADMIN$` share accessed | Lateral Movement |
| 06:15:23.800 | DC | 7045 | `PSEXESVC` service installed | Lateral Movement (T1021.002) |
| 06:15:24.123 | DC | 4688 | `PSEXESVC.exe` executed | Lateral Movement |
| 06:25:09.123 | DC | 4688 | `certutil.exe` downloaded `beacon.exe` | Defense Evasion (T1218) |
| 06:25:10.123 | DC | 4688 | `beacon.exe` executed | Execution |
| 06:25:10.456 | DC | Sysmon 3 | Outbound HTTP connection to `192.168.1.5:8081` | Command & Control (T1071.001) |
| 06:25:15.789 | DC | Sysmon 3 | Beacon check-in | Command & Control |
| 06:25:20.012 | DC | Sysmon 3 | Beacon check-in | Command & Control |

---

# 2. Attack Narrative

## Phase 1 – Initial Access

At **06:13:49 UTC**, the attacker executed `shell.exe` from `C:\Users\Public` on workstation **WS1**. Windows generated **Event ID 4688**, recording the creation of the malicious process.

Within milliseconds, the payload established a reverse TCP connection to the Kali Linux attack machine (`192.168.1.5`) on port **4444**, providing remote shell access to the attacker.

---

## Phase 2 – Persistence

At **06:15:00 UTC**, the attacker created a scheduled task named **Updater** using **Event ID 4698**. The task was configured to execute `C:\Users\Public\shell.exe` every day at **09:00**, ensuring persistence across reboots.

---

## Phase 3 – Privilege Escalation

At **06:15:05 UTC**, the attacker bypassed User Account Control (UAC) by abusing `eventvwr.exe`, which automatically launched an elevated `cmd.exe`. This granted administrative privileges without prompting for user consent.

---

## Phase 4 – Credential Dumping

At **06:15:10 UTC**, the elevated `shell.exe` process accessed `lsass.exe`, generating **Sysmon Event ID 10**. Shortly afterward, **Event ID 4663** confirmed that a high-privilege handle (`0x1FFFFF`) had been obtained.

Using an LSASS credential dumping technique, the attacker extracted cached authentication material, including the NTLM hash of the domain administrator account.

---

## Phase 5 – Lateral Movement

At **06:15:23 UTC**, the attacker authenticated to the Domain Controller using a pass-the-hash technique. Windows recorded:

- **Event ID 4624** – Successful Network Logon (Type 3)
- **Event ID 4672** – Special privileges assigned
- **Event ID 5140** – Access to the `ADMIN$` administrative share

The attacker then copied `PSEXESVC.exe` to the target system, installed the PsExec service (**Event ID 7045**), and executed it (**Event ID 4688**) to obtain remote command execution on the Domain Controller.

---

## Phase 6 – Command and Control

At **06:25:09 UTC**, the attacker used the legitimate Windows binary `certutil.exe` to download `beacon.exe` from:

```
http://192.168.1.5:8080/beacon.exe
```

One second later, `beacon.exe` was executed and immediately initiated outbound HTTP communication to:

```
192.168.1.5:8081
```

Sysmon network events showed beacon traffic approximately every **five seconds**, indicating an active command-and-control channel.

---

## Optional Cleanup Activity

At approximately **06:26:00 UTC**, the attacker briefly created a scheduled task named `MicrosoftUpdate` pointing to `beacon.exe` but removed it almost immediately. This action appears to have been experimental and was not essential to persistence.

---

# 3. Simplified Timeline

```text
WS1

06:13:49  shell.exe executed
      │
      ├── Reverse shell established
      │
06:15:00  Scheduled task created
      │
06:15:05  UAC bypass
      │
06:15:10  LSASS accessed
      │
06:15:11  NTLM hash extracted
      │
      ▼

DC

06:15:23  Pass-the-Hash authentication
      │
      ├── 4624 Network Logon
      ├── 4672 Admin privileges
      ├── 5140 ADMIN$ access
      ├── 7045 PSEXESVC installed
      └── 4688 PSEXESVC executed
      │
06:25:09  certutil downloads beacon.exe
      │
06:25:10  beacon.exe executed
      │
06:25:10  HTTP beacon established
      │
06:25:15  Beacon check-in
      │
06:25:20  Beacon check-in
```

---

# 4. Correlation with Monitoring Tools

## Kibana

Kibana successfully captured and visualized key Windows Security and Sysmon events throughout the attack lifecycle, including process creation, scheduled task creation, LSASS access, network logons, service installation, and outbound network connections.

## Velociraptor

Velociraptor artifact collection confirmed:

- Malicious process execution
- Scheduled task persistence
- Active network connections
- Process metadata
- Historical endpoint artifacts supporting forensic investigation

## Memory Forensics

Memory analysis validated unauthorized LSASS access and confirmed that credential material was resident in memory at the time of acquisition, supporting the findings from Windows event logs.

---

# 5. Key Observations

- Credential dumping and lateral movement occurred within seconds of one another, demonstrating rapid attacker progression.
- Privilege escalation preceded LSASS access, indicating elevated permissions were required before credential extraction.
- Beacon communications followed a predictable interval of approximately five seconds, providing a strong network indicator of compromise.
- The simulation compromised only WS1 and the Domain Controller, but the attacker had sufficient privileges to pivot further within the environment.

---

# 6. Detection Recommendations

| Detection Strategy | Relevant Event | Expected Detection Time |
|--------------------|---------------|-------------------------|
| Execution from `C:\Users\Public` | Event ID 4688 | < 1 second |
| Scheduled task creation | Event ID 4698 | < 1 second |
| LSASS access | Event ID 4663 / Sysmon 10 | < 1 second |
| Unusual network logon | Event ID 4624 | < 2 seconds |
| Outbound HTTP beacon | Sysmon Event 3 | < 2 seconds |
| `certutil.exe` downloading executables | Event ID 4688 | < 1 second |

## Example Correlation Rule

Generate a **Critical Security Alert** if the same endpoint exhibits all of the following within five minutes:

1. LSASS access by a non-standard process.
2. Creation of a new scheduled task.
3. Successful privileged network logon to another host.
4. Outbound communication to an external command-and-control endpoint.

---

# 7. Conclusion

The reconstructed timeline demonstrates a complete attack sequence, beginning with malicious code execution and progressing through persistence, privilege escalation, credential theft, lateral movement, and command-and-control communication. Each phase generated observable forensic artifacts within Windows Event Logs, Sysmon telemetry, and memory analysis, allowing investigators to reconstruct the intrusion with high confidence.

By correlating endpoint logs, centralized monitoring platforms such as Kibana, memory forensic evidence, and threat hunting with Velociraptor, defenders can rapidly identify similar attack patterns and significantly improve incident response capabilities.