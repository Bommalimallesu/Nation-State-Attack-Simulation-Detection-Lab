# Active Directory Domain Structure – Nation-State Lab

## 1. Forest and Domain

- **Forest Name:** `nation.local`
- **Domain Name:** `nation.local`
- **Forest Type:** Single Forest
- **Domain Type:** Single Domain
- **Forest Functional Level:** Windows Server 2016
- **Domain Functional Level:** Windows Server 2016
- **NetBIOS Name:** `NATION`
- **Primary Domain Controller:** `DC.nation.local`
- **Domain Controller IP Address:** `192.168.1.10`
- **DNS Zone:** `nation.local`
- **Dynamic DNS Updates:** Enabled

All Windows systems within the lab environment are joined to the `nation.local` domain.

---

## 2. Organizational Unit (OU) Structure

The following Organizational Units (OUs) were created to logically organize users, computers, and servers.

```text
nation.local
├── Computers
├── Users
├── Servers
└── Groups
```

### 2.1 Computers OU

**Purpose:** Store workstation computer objects.

**Computer Objects:**

- WS1
- WS2
- WS3

### 2.2 Users OU

**Purpose:** Store domain user accounts.

**User Objects:**

- normaluser
- developer
- service_account

### 2.3 Servers OU

**Purpose:** Store member server computer accounts.

**Server Objects:**

- FILESERVER
- WEBSERVER

### 2.4 Groups OU

**Purpose:** Store custom security groups.

No custom groups were created during the project.

---

## 3. Domain User Accounts

| Username | UPN | Group Membership | Purpose |
|-----------|------|-----------------|----------|
| Administrator | Administrator@nation.local | Domain Admins | Domain Administration |
| normaluser | normaluser@nation.local | Domain Users | Standard User |
| developer | developer@nation.local | Domain Users | Development Workstation User |
| service_account | service_account@nation.local | Domain Users | Service Account |

### Built-in Accounts

The following default Active Directory accounts remain present:

- Administrator
- Guest (Disabled)
- krbtgt

---

## 4. Computer Objects

| Computer Name | Operating System | IP Address | OU | Status |
|---------------|------------------|------------|------|--------|
| DC | Windows Server 2019 | 192.168.1.10 | Default Computers Container | Active |
| WS1 | Windows 10 Pro | 192.168.1.20 | Computers | Active |
| WS2 | Windows 10 Pro | 192.168.1.30 | Computers | Active |
| FILESERVER | Windows Server 2019 | 192.168.1.50 | Servers | Active |
| WEBSERVER | Windows Server 2019 | 192.168.1.60 | Servers | Active |

---

## 5. Group Policy Objects (GPOs)

### 5.1 Default Domain Policy

**Scope:** Entire Domain

Provides:

- Password Policy
- Account Lockout Policy
- Kerberos Policy

Default settings were retained.

### 5.2 Nation_Lab_Audit_Policy

**Scope:** Entire Domain

**Purpose:** Enforce Advanced Audit Policies.

#### Configured Audit Settings

| Category | Setting |
|------------|-----------|
| Audit Logon | Success, Failure |
| Audit Other Logon/Logoff Events | Success, Failure |
| Audit User Account Management | Success, Failure |

#### Verification Commands

```cmd
gpresult /r
```

```cmd
auditpol /get /category:*
```

### 5.3 Default Domain Controllers Policy

The default Domain Controllers Policy was retained without modification.

---

## 6. DNS Configuration

### DNS Server

- Hosted on Domain Controller
- Active Directory Integrated

### Forward Lookup Zone

```text
nation.local
```

### Dynamic Updates

```text
Secure Only
```

### Reverse Lookup Zone

Not configured.

### DNS Forwarders

Not configured because the lab environment is fully isolated.

All domain systems use:

```text
192.168.1.10
```

as their DNS server.

---

## 7. Trust Relationships

### External Trusts

None

### Forest Trusts

None

### Child Domains

None

### Replication

Not applicable because only one Domain Controller exists.

### FSMO Roles

All FSMO roles are held by:

```text
DC.nation.local
```

---

## 8. Security Configuration

### Delegation

No custom delegations were configured.

### Privileged Accounts

Protected using default Active Directory mechanisms.

### Kerberos Encryption

Default encryption settings retained.

Supported encryption types:

- AES256
- AES128
- RC4

---

## 9. Attack Simulation Relevance

The Active Directory structure was intentionally designed to support attack simulation and detection validation.

### Initial Access

Target User:

```text
normaluser
```

### Privilege Escalation

Target Account:

```text
Administrator
```

### Lateral Movement Targets

- WS1
- FILESERVER
- WEBSERVER

### Credential Access

Domain credentials stored within the Active Directory environment enabled realistic credential theft and lateral movement testing.

---

## 10. Verification Commands

### List Organizational Units

```cmd
dsquery ou -name *
```

### List Domain Users

```cmd
dsquery user -name * -limit 0
```

### List Domain Computers

```cmd
netdom query /domain:nation.local computer
```

### View Applied Group Policies

```cmd
gpresult /r
```

### View Audit Policies

```cmd
auditpol /get /category:*
```

---

## 11. Active Directory Structure Diagram

```text
nation.local
│
├── DC (Domain Controller)
│
├── Organizational Units
│   ├── Computers
│   │   ├── WS1
│   │   ├── WS2
│   │   └── WS3
│   │
│   ├── Users
│   │   ├── normaluser
│   │   ├── developer
│   │   └── service_account
│   │
│   ├── Servers
│   │   ├── FILESERVER
│   │   └── WEBSERVER
│   │
│   └── Groups
│
├── Built-in Containers
│   ├── Users
│   │   ├── Administrator
│   │   ├── Guest
│   │   └── krbtgt
│   │
│   └── Computers
│       └── DC
│
└── Group Policies
    ├── Default Domain Policy
    ├── Default Domain Controllers Policy
    └── Nation_Lab_Audit_Policy
```

---

## 12. Environment Summary

| Component | Configuration |
|------------|---------------|
| Forest | nation.local |
| Domain | nation.local |
| Domain Controllers | 1 |
| Organizational Units | 4 |
| Domain Users | 4 |
| Domain Computers | 5 |
| Custom GPOs | 1 |
| External Trusts | None |
| Child Domains | None |

---

## Conclusion

The Active Directory environment provides a realistic enterprise identity infrastructure suitable for attack-path analysis, credential theft simulation, privilege escalation testing, lateral movement exercises, and detection engineering validation. The simplified design allows clear visibility of attack activity while maintaining sufficient complexity for cybersecurity monitoring and threat-hunting exercises.