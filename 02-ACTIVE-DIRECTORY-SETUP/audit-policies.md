# Active Directory Audit Policies – Nation-State Lab

## Overview

To ensure full visibility into adversary actions, Windows Advanced Audit Policy was configured on all domain-joined Windows VMs (DC, WS1, WS2, FILESERVER, and WEBSERVER). The policies were initially applied using `auditpol` and later enforced through a Domain Group Policy Object (GPO) to prevent local overrides.

These audit settings generated critical Windows Security Event IDs such as 4624, 4625, 4672, 4688, 4698, 4663, and 4720. Winlogbeat collected these events and forwarded them to Elasticsearch, where they were visualized through Kibana dashboards.

Without these audit policies, attack activities such as brute-force attacks, reverse shells, persistence mechanisms, credential theft, privilege escalation, and lateral movement would not have generated sufficient telemetry for detection.

---

## Why Audit Policies Are Required for Detection

| Attack Phase | Windows Event ID | Audit Subcategory |
|-------------|------------------|-------------------|
| Failed Logon (Brute Force) | 4625 | Logon |
| Successful Logon | 4624 | Logon |
| Administrative Logon | 4672 | Sensitive Privilege Use |
| Process Execution | 4688 | Process Creation |
| Scheduled Task Persistence | 4698 | Task Scheduler |
| Credential Dumping Activity | 4663 | Handle Manipulation / Object Access |
| User Account Creation | 4720 | User Account Management |

> **Note:** SQL injection activity on the web server was detected through IIS logs rather than Windows Security logs. However, any post-exploitation activity resulting from the compromise was captured through the audit policies configured below.

---

## Applied Audit Policies

The following audit settings were enabled on all domain-joined Windows systems.

| Audit Subcategory | Configuration | Related MITRE ATT&CK Technique |
|------------------|---------------|-------------------------------|
| Logon | Success, Failure | TA0001, TA0008 |
| Other Logon/Logoff Events | Success, Failure | Multiple |
| User Account Management | Success, Failure | T1136 |
| Sensitive Privilege Use | Success | T1078 |
| Process Creation | Enabled via Sysmon | T1059 |
| Handle Manipulation | Enabled via Sysmon | T1003.001 |

---

## Audit Policy Implementation

The following commands were executed with administrative privileges on each Windows system.

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable

auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

---

## Verification

To verify the configuration, the following command was executed:

```cmd
auditpol /get /subcategory:"Logon"
```

### Expected Output

```text
System audit policy

Category/Subcategory              Setting

Logon/Logoff
  Logon                           Success and Failure
```

---

## Group Policy Enforcement (Domain-Wide)

To ensure that audit settings persisted across reboots and could not be overridden locally, a domain-level Group Policy Object was created.

### GPO Name

```text
Nation_Lab_Audit_Policy
```

### Configuration Steps

1. Open **Group Policy Management Console (GPMC)**.
2. Navigate to:

```text
nation.local
```

3. Create a new Group Policy Object named:

```text
Nation_Lab_Audit_Policy
```

4. Edit the GPO and navigate to:

```text
Computer Configuration
 └── Policies
     └── Windows Settings
         └── Security Settings
             └── Advanced Audit Policy Configuration
                 └── Audit Policies
```

### Configure the Following Settings

#### Logon/Logoff

```text
Audit Logon
Success, Failure
```

#### Account Management

```text
Audit User Account Management
Success, Failure
```

5. Link the GPO to the domain.
6. Apply policy updates on all systems:

```cmd
gpupdate /force
```

7. Reboot affected systems if necessary.

---

## Troubleshooting Event ID 4625

### Issue

Failed logon events (Event ID 4625) were not appearing even though local audit policies displayed "Success and Failure."

### Root Cause

Advanced Audit Policy settings override legacy audit policy settings. Local configuration alone was insufficient because the domain policy had not been configured.

### Resolution

- Configure Advanced Audit Policies through Group Policy.
- Apply policy updates.
- Reboot systems if required.

After policy deployment, Event ID 4625 appeared correctly in both Event Viewer and Kibana.

---

## Integration with Monitoring Infrastructure

### Winlogbeat

Winlogbeat was configured to collect Windows Security logs and forward them directly to Elasticsearch.

### Elasticsearch

Received all forwarded Security Event logs from monitored endpoints.

### Kibana

Index Pattern:

```text
winlogbeat-*
```

Time Field:

```text
@timestamp
```

### Example Detection Rule

```kql
winlog.event_id: 4625 AND winlog.event_data.TargetUserName: "normaluser"
```

---

## Audit Policy Validation Status

| System | Policy Source | auditpol Applied | GPO Applied | Validation Result |
|----------|--------------|------------------|-------------|------------------|
| DC | Local + GPO | Yes | Yes | 4624, 4625, 4672 visible |
| WS1 | Local + GPO | Yes | Yes | 4625, 4688, 4698 visible |
| WS2 | Local + GPO | Yes | Yes | 4625, 4688, 4698 visible |
| FILESERVER | Local + GPO | Yes | Yes | 4624 visible |
| WEBSERVER | Local + GPO | Yes | Yes | 4688 visible |
| WS3 | Local + GPO | Yes | Yes | Decommissioned |

---

## Validation Procedure

The audit configuration was validated by generating failed authentication attempts and verifying the resulting events.

Example test:

```cmd
net use \\localhost\c$ /user:fakeuser wrongpassword
```

Validation Steps:

1. Execute the command.
2. Open Event Viewer.
3. Confirm Event ID 4625 is generated.
4. Verify ingestion into Elasticsearch.
5. Confirm visibility within Kibana dashboards.

---

## Conclusion

The implemented audit policy configuration provided comprehensive visibility across the enterprise simulation environment. The generated telemetry enabled reliable detection of brute-force attacks, reverse shells, persistence mechanisms, privilege escalation attempts, credential access techniques, lateral movement activity, and command-and-control communications.

Combined with Winlogbeat, Elasticsearch, Kibana, and Velociraptor, the audit policies formed the foundation of the monitoring and detection architecture used throughout the Nation-State Lab project.