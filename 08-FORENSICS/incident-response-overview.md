# Incident Response Overview – APT Attack Chain Simulation

**Incident ID:** IR-2026-06-10-APT  
**Detection Date:** 2026-06-10  
**Status:** Resolved (Lab Simulation)  
**Affected Assets:**
- **WS1:** `192.168.1.20`
- **Domain Controller (DC):** `192.168.1.10`

**Attacker Infrastructure (Lab):**
- **Kali Linux:** `192.168.1.5`

---

# 1. Incident Summary

An Advanced Persistent Threat (APT)-style attack was simulated in a controlled laboratory environment to validate endpoint detection, centralized logging, and incident response capabilities.

The attack sequence consisted of:

1. Initial execution of `shell.exe` on **WS1**
2. Reverse shell connection established to the attacker system
3. Persistence through a scheduled task named **Updater**
4. Privilege escalation and credential access activity targeting LSASS
5. Lateral movement to the Domain Controller using SMB and administrative credentials
6. Deployment of `beacon.exe`
7. HTTP Command-and-Control (C2) communications over port **8081**

The simulation successfully generated telemetry across Windows Security logs, Sysmon (where available), Winlogbeat, Kibana, and Velociraptor hunts.

**Attack Window:** `06:13 UTC – 06:26 UTC`  
**Approximate Duration:** `12 minutes`

---

# 2. Detection Summary

| Detection Source | Event | Detection Time |
|------------------|-------|----------------|
| Winlogbeat | Event ID 4688 (`shell.exe`) | 06:13:49 |
| Winlogbeat | Event ID 4698 (`Updater` task created) | 06:15:00 |
| Winlogbeat | Event ID 4663 (LSASS access) | 06:15:11 |
| Winlogbeat | Event ID 4624 (Network logon) | 06:15:23 |
| Sysmon | Event ID 3 (`beacon.exe` network connection) | 06:25:10 |
| Velociraptor Hunt | `shell.exe` process detection | Post-analysis |
| Velociraptor Hunt | `beacon.exe` process detection | Post-analysis |

---

# 3. Attack Timeline

| Time (UTC) | Host | Activity |
|------------|------|----------|
| 06:13:49 | WS1 | `shell.exe` executed |
| 06:13:49 | WS1 | Reverse shell established to `192.168.1.5:4444` |
| 06:15:00 | WS1 | Scheduled task `Updater` created |
| 06:15:05 | WS1 | Elevated execution observed |
| 06:15:10 | WS1 | LSASS access initiated |
| 06:15:23 | DC | NTLM network logon from attacker infrastructure |
| 06:15:24 | DC | `PSEXESVC.exe` executed |
| 06:25:09 | DC | `certutil.exe` downloaded `beacon.exe` |
| 06:25:10 | DC | `beacon.exe` executed |
| 06:25:10 | DC | HTTP beacon initiated to `192.168.1.5:8081` |

---

# 4. Incident Response Lifecycle

## 4.1 Preparation

Before the simulation:

- Winlogbeat agents were configured on Windows hosts.
- Logs were forwarded to Elasticsearch.
- Kibana dashboards were operational.
- Velociraptor clients were enrolled.
- Windows Security logging was enabled.
- Detection rules for process creation and scheduled tasks were available.

---

## 4.2 Detection and Analysis

The first alert originated from a process creation event indicating execution of:

```text
C:\Users\Public\shell.exe
```

Analysts confirmed:

- Execution from an unusual directory
- Parent process `cmd.exe`
- Subsequent outbound network activity
- Creation of persistence mechanisms
- Credential access attempts
- Lateral movement indicators
- Additional payload deployment on the Domain Controller

Correlation across Kibana and Velociraptor established the complete attack chain.

---

## 4.3 Containment

Immediate containment actions included:

| Action | Target |
|---------|--------|
| Terminate `shell.exe` | WS1 |
| Terminate `beacon.exe` | Domain Controller |
| Block communications with `192.168.1.5` | Firewall |
| Disable scheduled task `Updater` | WS1 |
| Remove malicious payloads | WS1 and DC |

Example commands:

```cmd
taskkill /IM shell.exe /F
taskkill /IM beacon.exe /F

schtasks /change /tn "Updater" /disable

del C:\Users\Public\shell.exe
del C:\Users\Public\beacon.exe
```

---

## 4.4 Eradication

The following remediation steps were performed:

- Deleted the `Updater` scheduled task.
- Verified removal of `PSEXESVC`.
- Removed malicious executables.
- Conducted enterprise-wide hunting using Velociraptor.
- Reviewed authentication events for additional compromise.
- Planned credential rotation for exposed administrative accounts.

---

## 4.5 Recovery

Recovery activities included:

- Restoring affected virtual machines from trusted snapshots.
- Re-enabling endpoint protection.
- Verifying Windows Defender status.
- Confirming no remaining persistence mechanisms.
- Validating successful log forwarding to Elasticsearch.
- Confirming normal system operation.

---

## 4.6 Post-Incident Improvements

Recommended enhancements:

- Enable command-line auditing for Event ID 4688.
- Deploy Sysmon across all endpoints.
- Create automated Elastic detection rules.
- Schedule recurring Velociraptor hunts.
- Restrict execution from user-writable directories.
- Improve segmentation between workstations and critical servers.

---

# 5. Confirmed Indicators of Compromise (IOCs)

## Network Indicators

| Indicator | Value |
|----------|-------|
| Attacker IP | `192.168.1.5` |
| Reverse Shell Port | `4444` |
| HTTP Download Port | `8080` |
| HTTP Beacon Port | `8081` |
| SMB Port | `445` |

## File Indicators

| File | Location |
|------|----------|
| `shell.exe` | `C:\Users\Public\shell.exe` |
| `beacon.exe` | `C:\Users\Public\beacon.exe` |
| `PSEXESVC.exe` | `C:\Windows\Temp\PSEXESVC.exe` |

## Persistence

| Mechanism | Value |
|-----------|-------|
| Scheduled Task | `Updater` |

## Suspicious Processes

- `shell.exe`
- `beacon.exe`
- `certutil.exe`
- `PSEXESVC.exe`

---

# 6. MITRE ATT&CK Mapping

| Tactic | Technique | Technique ID |
|---------|-----------|--------------|
| Execution | Command and Scripting Interpreter | T1059 |
| Persistence | Scheduled Task | T1053.005 |
| Privilege Escalation | Abuse Elevation Control Mechanism | T1548.002 |
| Credential Access | OS Credential Dumping | T1003.001 |
| Lateral Movement | Pass the Hash | T1550.002 |
| Lateral Movement | SMB/Remote Services | T1021.002 |
| Defense Evasion | Signed Binary Proxy Execution (`certutil`) | T1218 |
| Command and Control | Application Layer Protocol (HTTP) | T1071.001 |

---

# 7. Forensic Evidence Collected

The following artefacts were preserved:

- Windows Security Event Logs (`Security.evtx`)
- Sysmon Event Logs
- `shell.exe`
- `beacon.exe`
- Scheduled Task (`Updater`) metadata
- Velociraptor hunt exports
- Kibana dashboards and timeline screenshots
- Process execution records
- Network connection records

---

# 8. Detection Engineering Recommendations

| Recommendation | Priority |
|---------------|----------|
| Deploy Sysmon to all endpoints | High |
| Enable process command-line logging | High |
| Block execution from `C:\Users\Public` using AppLocker or WDAC | High |
| Reduce NTLM usage in favor of Kerberos | Medium |
| Enforce SMB signing | Medium |
| Limit local administrator privileges | High |
| Schedule periodic threat hunts | Medium |
| Continuously validate detections through purple-team exercises | Medium |

---

# 9. Lessons Learned

The exercise demonstrated that combining centralized log collection with endpoint hunting significantly improves visibility across the attack lifecycle.

Key observations include:

- Process creation telemetry quickly identified malicious execution.
- Scheduled task monitoring successfully detected persistence.
- Network authentication logs revealed lateral movement.
- HTTP-based beaconing was observable through network telemetry.
- Velociraptor hunts complemented SIEM detections by validating endpoint artefacts.

Additional telemetry, particularly Sysmon deployment and command-line auditing, would further strengthen detection coverage.

---

# 10. Conclusion

The simulated attack chain progressed from initial execution through persistence, credential access, lateral movement, and command-and-control communications. Existing logging infrastructure successfully captured the majority of significant events, while endpoint hunts confirmed the associated artefacts.

The incident was contained and remediated within the laboratory environment, and the findings provide a practical baseline for improving monitoring, threat hunting, and incident response processes in future exercises.

---

