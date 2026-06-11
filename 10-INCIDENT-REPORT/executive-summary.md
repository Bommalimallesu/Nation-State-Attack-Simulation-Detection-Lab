# Executive Summary – APT Attack Chain Simulation

**Incident ID:** IR-2026-06-6-APT
**Date of Incident:** 6 June 2026
**Report Prepared For:** SOC / Purple Team / Leadership
**Simulation Environment:** Kali Linux, Windows Workstation (WS1), Domain Controller (DC), Winlogbeat, Elasticsearch, Kibana, and Velociraptor

---

## 1. Incident Overview

A controlled Advanced Persistent Threat (APT) simulation was conducted in a laboratory environment to evaluate endpoint visibility, log collection, detection capabilities, and threat hunting effectiveness. The simulated attacker obtained initial code execution on a Windows workstation (WS1), established persistence, escalated privileges to SYSTEM, extracted administrative credentials, performed lateral movement to the Domain Controller (DC), and established a secondary HTTP-based command and control (C2) channel.

The objective of this exercise was to validate security monitoring using Winlogbeat, Elasticsearch, Kibana dashboards, and Velociraptor hunts while mapping adversary behavior to the MITRE ATT&CK framework.

The complete simulated attack chain was executed in approximately 12 minutes and generated observable security events throughout the environment.

---

## 2. Attack Chain Summary

| Phase   | Activity                              | Target            | Primary Objective               |
| ------- | ------------------------------------- | ----------------- | ------------------------------- |
| Phase 2 | Reverse shell execution (`shell.exe`) | WS1               | Initial code execution          |
| Phase 3 | Scheduled task creation (`Updater`)   | WS1               | Persistence                     |
| Phase 4 | Privilege escalation                  | WS1               | SYSTEM privileges               |
| Phase 5 | LSASS credential dumping              | WS1               | Administrator credential access |
| Phase 6 | Pass-the-Hash authentication          | Domain Controller | Lateral movement                |
| Phase 7 | HTTP beacon deployment (`beacon.exe`) | Domain Controller | Command and Control             |

The attacker infrastructure originated from the Kali Linux system (`192.168.1.5`), which served payloads and received reverse connections throughout the exercise.

---

## 3. Detection Performance

Security monitoring successfully identified every major stage of the simulated compromise.

### Key detections included:

* Process creation events indicating execution of suspicious binaries.
* Reverse shell activity initiated from `C:\Users\Public`.
* Scheduled task creation used for persistence.
* Privilege escalation behavior leading to SYSTEM access.
* Credential dumping attempts involving LSASS.
* NTLM network logons associated with Pass-the-Hash activity.
* Remote service creation during lateral movement.
* HTTP beacon traffic establishing outbound command-and-control communications.

### Representative Windows Events

| Activity                       | Event ID |
| ------------------------------ | -------- |
| Process Creation               | 4688     |
| Scheduled Task Creation        | 4698     |
| Network Logon                  | 4624     |
| Special Privileges Assigned    | 4672     |
| File Share Access              | 5140     |
| Service Installation           | 7045     |
| LSASS Access (where available) | 4663     |
| Network Connection (Sysmon)    | 3        |

Average event visibility through Winlogbeat and Kibana occurred within a few seconds, enabling near real-time monitoring.

---

## 4. Threat Hunting Results

Velociraptor hunts successfully located:

* Suspicious processes (`shell.exe`, `beacon.exe`)
* Persistence mechanisms (`Updater` scheduled task)
* Suspicious executable files stored under `C:\Users\Public`
* Network connections associated with command-and-control traffic
* Artifacts related to lateral movement and execution

These hunts confirmed that endpoint artifacts remained available for investigation after attack execution.

---

## 5. MITRE ATT&CK Coverage

The simulation exercised multiple ATT&CK tactics spanning the intrusion lifecycle.

| Tactic               | Example Technique                          | Detection Status |
| -------------------- | ------------------------------------------ | ---------------- |
| Initial Access       | User Execution                             | Detected         |
| Execution            | Windows Command Shell                      | Detected         |
| Persistence          | Scheduled Task                             | Detected         |
| Privilege Escalation | UAC Bypass                                 | Detected         |
| Defense Evasion      | Signed Binary Proxy Execution (`certutil`) | Detected         |
| Credential Access    | LSASS Credential Dumping                   | Detected         |
| Lateral Movement     | Pass-the-Hash                              | Detected         |
| Command and Control  | HTTP Beacon                                | Detected         |

Overall, the simulation demonstrated coverage across eight ATT&CK tactics and multiple associated techniques.

---

## 6. Response Actions

Following detection of malicious activity, the following containment and remediation measures were performed within the lab environment:

* Reverse shell processes were terminated.
* Persistence mechanisms were removed.
* Payload files were deleted.
* Firewall rules were updated to prevent further communications.
* Test virtual machines were restored to clean snapshots.
* Hunting activities verified removal of malicious artifacts.

---

## 7. Key Findings

* Endpoint process creation logging provides strong visibility into malware execution.
* Scheduled task auditing effectively identifies persistence attempts.
* Credential dumping activities can be correlated through process access and security events.
* Network authentication logs are valuable for detecting Pass-the-Hash attacks.
* HTTP beacon traffic can be identified using endpoint network telemetry.
* Combining SIEM monitoring with endpoint threat hunting significantly improves investigation capability.

---

## 8. Recommendations

| Priority | Recommendation                                                                               |
| -------- | -------------------------------------------------------------------------------------------- |
| High     | Deploy Sysmon across all Windows endpoints.                                                  |
| High     | Enable detailed command-line auditing for process creation events.                           |
| High     | Restrict execution from public and temporary directories using application control policies. |
| High     | Monitor and alert on suspicious scheduled task creation.                                     |
| Medium   | Limit NTLM authentication where operationally feasible.                                      |
| Medium   | Harden LSASS protections using available platform security features.                         |
| Medium   | Continuously hunt for persistence mechanisms using endpoint telemetry.                       |
| Low      | Regularly validate SIEM detection rules through purple-team exercises.                       |

---

## 9. Overall Assessment

The APT simulation demonstrated that comprehensive endpoint logging combined with centralized analysis and proactive hunting can provide excellent visibility into advanced attack behavior. Process execution, persistence, privilege escalation, credential access, lateral movement, and command-and-control activities were all observable through collected telemetry.

The exercise reinforces the importance of robust logging, continuous monitoring, and periodic adversary simulations for strengthening detection engineering and incident response capabilities.
