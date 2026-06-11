# Group Policy  – Nation-State Lab

## 1. Overview

Group Policy was used to centrally manage and enforce security settings across the `nation.local` domain. The primary objective was to ensure consistent audit logging for attack detection and monitoring.

A custom Group Policy Object (GPO) named `Nation_Lab_Audit_Policy` was created to enforce Advanced Audit Policies on all domain-joined computers.

No Group Policies were created for:

- Software deployment
- Windows Defender configuration
- Firewall management
- Desktop hardening

The focus of this configuration was security auditing and event visibility.

---

## 2. Group Policy Objects (GPOs)

| GPO Name | Scope | Linked Location | Status |
|-----------|---------|----------------|--------|
| Default Domain Policy | Domain | nation.local | Enabled |
| Default Domain Controllers Policy | Domain Controllers OU | Domain Controllers | Enabled |
| Nation_Lab_Audit_Policy | Domain | nation.local | Enabled |

---

## 3. Default Domain Policy

### Scope

```text
nation.local
```

### Purpose

Provides default domain security settings including:

- Password Policy
- Account Lockout Policy
- Kerberos Policy

### Password Policy Settings

| Setting | Value |
|----------|---------|
| Enforce Password History | 24 Passwords |
| Maximum Password Age | 42 Days |
| Minimum Password Age | 1 Day |
| Minimum Password Length | 7 Characters |
| Password Complexity | Enabled |
| Reversible Encryption | Disabled |

### Account Lockout Policy

| Setting | Value |
|----------|---------|
| Account Lockout Threshold | 0 |
| Lockout Duration | Not Defined |
| Reset Lockout Counter | Not Defined |

### Kerberos Policy

Default Windows Server 2019 settings were retained.

No modifications were made to the Default Domain Policy.

---

## 4. Default Domain Controllers Policy

### Scope

```text
Domain Controllers OU
```

### Applies To

```text
DC.nation.local
```

### Purpose

Provides default security settings for Domain Controllers.

Includes:

- Directory Service Auditing
- User Rights Assignment
- Security Options
- Authentication Policies

No modifications were made to this policy.

---

## 5. Custom Group Policy Object

## Nation_Lab_Audit_Policy

### Purpose

The objective of this policy is to ensure that all domain-joined systems generate the security events required for attack detection.

Examples include:

- Failed Logons (4625)
- Successful Logons (4624)
- User Account Changes (4720, 4722, 4726)

---

## 6. GPO Creation

### Management Console

```text
gpmc.msc
```

### Steps

1. Open Group Policy Management.
2. Expand:

```text
Forest
└── Domains
    └── nation.local
```

3. Right-click:

```text
Group Policy Objects
```

4. Select:

```text
New
```

5. Create GPO:

```text
Nation_Lab_Audit_Policy
```

---

## 7. GPO Link Configuration

### Linked Location

```text
nation.local
```

### Link Status

```text
Enabled
```

### Link Order

```text
1
```

### Enforcement

```text
Not Enforced
```

No additional audit-related GPOs exist in the environment.

---

## 8. Advanced Audit Policy Configuration

Navigate to:

```text
Computer Configuration
└── Policies
    └── Windows Settings
        └── Security Settings
            └── Advanced Audit Policy Configuration
                └── Audit Policies
```

### Configured Settings

| Audit Subcategory | Setting |
|-------------------|----------|
| Audit Logon | Success, Failure |
| Audit Other Logon/Logoff Events | Success, Failure |
| Audit User Account Management | Success, Failure |

---

## 9. Audit Coverage

| Audit Category | Event IDs |
|---------------|-----------|
| Successful Logon | 4624 |
| Failed Logon | 4625 |
| Special Privileges Assigned | 4672 |
| User Account Created | 4720 |
| User Account Enabled | 4722 |
| User Account Deleted | 4726 |

---

## 10. Why Advanced Audit Policy Was Used

Advanced Audit Policy was selected because it provides:

- More granular control
- Consistent deployment
- Domain-wide enforcement
- Better compatibility with SIEM detection rules

Important:

```text
Advanced Audit Policy overrides legacy audit settings.
```

Therefore all audit settings were configured through Group Policy rather than relying solely on local `auditpol` commands.

---

## 11. Verification

### Check Applied Audit Policy

```cmd
auditpol /get /subcategory:"Logon"
```

Expected Output:

```text
System audit policy

Category/Subcategory
Logon/Logoff

Logon
Success and Failure
```

### Check Applied GPOs

```cmd
gpresult /r
```

### Generate Detailed Report

```cmd
gpresult /h gpresult.html
```

Verify that:

```text
Nation_Lab_Audit_Policy
```

appears in the applied GPO list.

---

## 12. Group Policy Processing Order

Windows applies Group Policy in the following order:

```text
Local Policy
    ↓
Site Policy
    ↓
Domain Policy
    ↓
OU Policy
```

In this lab:

```text
Nation_Lab_Audit_Policy
```

is linked at the domain level and therefore applies to all domain computers.

---

## 13. Impact on Attack Detection

| Attack Activity | Event ID | Detection Result |
|---------------|-----------|------------------|
| Brute Force Login | 4625 | Detected |
| Successful Login | 4624 | Detected |
| Lateral Movement | 4624 | Detected |
| User Account Creation | 4720 | Detected |
| User Account Deletion | 4726 | Detected |

These events were forwarded to Elasticsearch using Winlogbeat and visualized in Kibana dashboards.

---

## 14. Security Filtering

### Security Filter

```text
Authenticated Users
```

### Permissions

| Principal | Permission |
|------------|------------|
| Domain Admins | Full Control |
| Authenticated Users | Read, Apply Group Policy |

No custom delegation settings were configured.

---

## 15. Troubleshooting

| Issue | Verification Command | Resolution |
|---------|---------------------|------------|
| Missing Logon Events | auditpol /get /subcategory:"Logon" | Verify GPO application |
| GPO Not Applied | gpresult /r | Confirm computer location and permissions |
| Missing Event ID 4625 | auditpol /get /category:* | Ensure Advanced Audit Policy is configured |
| Kibana Missing Events | Check Winlogbeat Service | Verify Elasticsearch connectivity |

---

## 16. Validation Results

The policy was validated on:

- DC
- WS1
- WS2
- FILESERVER
- WEBSERVER

Validation confirmed:

- Event ID 4624 generated
- Event ID 4625 generated
- Event ID 4720 generated
- Events forwarded to Elasticsearch
- Events visible in Kibana

---

## 17. Summary

| GPO Name | Purpose | Status |
|-----------|----------|--------|
| Default Domain Policy | Password and Account Security | Enabled |
| Default Domain Controllers Policy | Domain Controller Security | Enabled |
| Nation_Lab_Audit_Policy | Advanced Audit Configuration | Enabled |

---

## 18. Additional Notes

### Windows Defender

No GPO was created for Windows Defender exclusions.

Exclusions were configured locally using:

```powershell
Add-MpPreference -ExclusionPath "C:\Winlogbeat"
```

### Windows Firewall

No firewall-related GPOs were configured.

Firewall settings were managed locally.

### Software Deployment

No software deployment GPOs were used.

The following software was installed manually:

- Winlogbeat
- Velociraptor
- Atomic Red Team

---

## Conclusion

The Group Policy configuration provided centralized audit enforcement across the `nation.local` domain. The custom `Nation_Lab_Audit_Policy` ensured reliable generation of critical security events required for attack detection, threat hunting, and SIEM monitoring. Combined with Winlogbeat, Elasticsearch, and Kibana, the policy enabled complete visibility into authentication activity and account management events throughout the Nation-State Lab environment.