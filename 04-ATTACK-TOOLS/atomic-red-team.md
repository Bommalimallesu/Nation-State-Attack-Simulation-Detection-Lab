# Atomic Red Team – Nation-State Lab

## 1. Overview

Atomic Red Team (ART) is a library of small, focused, executable "atomic tests" that simulate adversary techniques mapped to the MITRE ATT&CK framework. Each test is self-contained and can be run on a target system to validate detection coverage.

In this lab, ART was installed **offline** on the Domain Controller (DC) to avoid internet dependencies and to remain inside the isolated host-only network. The goal was to be able to trigger specific techniques (e.g., credential dumping, persistence) and verify that Winlogbeat + Elasticsearch + Kibana generated corresponding alerts.

**Why ART on DC only?**

The DC is the most critical system and the final target of the attack chain (pass-the-hash, C2 beacon). Validating that detection works on the DC is a high-value test. Additionally, disk space was limited; installing ART on all Windows VMs would have consumed extra storage.

---

## 2. Preparation – Offline Package (on Host PC)

Since the lab VMs have no direct internet access, the ART framework was prepared on an internet-connected machine (the host PC) and then transferred to the DC.

### 2.1 Download Required Repositories

On the host PC (Windows), the following components were downloaded and extracted into a folder named `C:\AtomicRedTeam`:

| Repository | Purpose |
|------------|---------|
| atomic-red-team | Contains the atomics folder with all test definitions (YAML files). |
| invoke-atomicredteam | PowerShell module that runs the tests. |

### 2.2 Obtain the powershell-yaml Module

ART depends on the powershell-yaml module to parse YAML test files. The module was downloaded from the PowerShell Gallery and saved to:

`C:\AtomicRedTeam\powershell-yaml`

### 2.3 Create the ZIP Package

```powershell
Compress-Archive -Path "C:\AtomicRedTeam" `
-DestinationPath "$env:USERPROFILE\Desktop\AtomicRedTeam_Offline.zip" `
-Force
```

The ZIP file contains:

```text
AtomicRedTeam/
├── atomic-red-team/
├── invoke-atomicredteam/
└── powershell-yaml/
```

---

## 3. Transfer to Domain Controller

The ZIP file was transferred to the Domain Controller using the VMware shared folder:

```text
\\vmware-host\Shared Folders\share
```

After transfer, it was extracted to:

```text
C:\AtomicRedTeam
```

Folder structure:

```text
C:\AtomicRedTeam\
├── atomic-red-team\
│   └── atomics\
├── invoke-atomicredteam\
└── powershell-yaml\
```

---

## 4. Installation on the Domain Controller

All commands were executed in PowerShell as Administrator.

### 4.1 Add Windows Defender Exclusion

```powershell
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"
```

### 4.2 Install powershell-yaml Module

```powershell
Copy-Item `
-Path "C:\AtomicRedTeam\powershell-yaml" `
-Destination "C:\Program Files\WindowsPowerShell\Modules\" `
-Recurse -Force
```

### 4.3 Import Atomic Red Team Module

```powershell
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
```

Verification:

```powershell
Get-AtomicTest -ShowDetails | Select-Object -First 5
```

Expected output:

```text
T1003
T1053
T1548
...
```

---

## 5. Running an Atomic Test

### Example: T1033 – System Owner/User Discovery

```powershell
Invoke-AtomicTest T1033 -TestNumbers 1
```

This executes:

```cmd
whoami
```

Detection Validation:

- Event ID 4688 generated
- Winlogbeat forwards event
- Elasticsearch indexes event
- Kibana displays event

Example Kibana query:

```text
process.executable: whoami.exe
```

### Example: T1003 – Credential Dumping

```powershell
Invoke-AtomicTest T1003 -TestNumbers 1
```

Expected detections:

- Event ID 4663
- Sysmon Event ID 10 (if installed)

### Cleanup

```powershell
Invoke-AtomicTest T1003 -Cleanup
```

---

## 6. Kibana Detection Validation

| Technique | Event ID | Query |
|------------|-----------|--------|
| T1033 | 4688 | process.executable: whoami.exe |
| T1003 | 4663 / 10 | process.name: mimikatz.exe |
| T1053.005 | 4698 | winlog.event_data.TaskName:*Updater* |

These queries were converted into Kibana alerting rules.

---

## 7. Why Atomic Red Team Was Not Used for the Full Attack Chain

The complete attack chain was executed manually using:

- Metasploit
- Impacket
- Custom Payloads
- Scheduled Tasks
- Pass-the-Hash Techniques

Atomic Red Team was used only for detection validation because:

- ART tests are single-technique focused
- Full attack chains require multiple stages
- Some tests require internet connectivity
- Manual execution provides greater realism

---

## 8. Troubleshooting

### Module Import Failure

Problem:

```text
powershell-yaml not found
```

Solution:

```text
Copy module to:
C:\Program Files\WindowsPowerShell\Modules
```

### No Atomics Folder Found

Problem:

```text
Invoke-AtomicTest cannot locate atomics
```

Solution:

```text
Ensure atomics is located under:
C:\AtomicRedTeam\atomic-red-team\atomics
```

### Windows Defender Blocks Test

Solution:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```

Re-enable after testing:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

### No Alerts in Kibana

Verify:

```text
winlogbeat-* index pattern exists
```

Check time range:

```text
Last 24 Hours
```

---

## 9. Summary

| Component | Status |
|------------|---------|
| Offline package prepared | ✅ |
| Copied to DC | ✅ |
| powershell-yaml installed | ✅ |
| Module imported | ✅ |
| Atomic test executed | ✅ |
| Detection validated | ✅ |
| Cleanup verified | ✅ |

Atomic Red Team successfully validated the detection capabilities of the Nation-State Lab. Tests generated the expected Windows events, which were forwarded by Winlogbeat, indexed by Elasticsearch, and visualized in Kibana.