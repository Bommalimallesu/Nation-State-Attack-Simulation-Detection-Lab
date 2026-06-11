# Domain Controller (DC) Configuration – Nation-State Lab

## 1. Overview

The Domain Controller (DC) serves as the central authentication and authorization system for the `nation.local` Active Directory environment.

The server provides:

- Active Directory Domain Services (AD DS)
- DNS Services
- Kerberos Authentication
- NTLM Authentication
- Group Policy Management
- Security Event Logging
- Centralized User and Computer Management

All security events generated on the Domain Controller are collected by Winlogbeat and forwarded to Elasticsearch for visualization and detection in Kibana.

---

## 2. VM Hardware and Network Configuration

| Parameter | Value |
|------------|---------|
| Hostname | `DC` |
| Operating System | Windows Server 2019 Datacenter Evaluation |
| vCPU | 2 Cores |
| RAM | 2 GB |
| Disk | 50 GB |
| Network Type | VMware Host-Only (VMnet1) |
| IP Address | `192.168.1.10` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | None |
| DNS Server | `127.0.0.1` |
| VMware Tools | Installed |

---

## 3. Operating System Installation

### Installation Steps

1. Mount Windows Server 2019 ISO.
2. Select Windows Server 2019 Datacenter Evaluation (Desktop Experience).
3. Complete installation.
4. Configure Administrator password.
5. Log in for the first time.

### Computer Rename

Open:

```powershell
System Properties → Computer Name → Change
```

Set hostname:

```text
DC
```

Restart the server.

---

## 4. Static IP Configuration

Navigate to:

```text
Control Panel
→ Network and Sharing Center
→ Change Adapter Settings
→ Ethernet
→ Internet Protocol Version 4 (TCP/IPv4)
```

Configure:

| Setting | Value |
|----------|---------|
| IP Address | 192.168.1.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | Leave Blank |
| Preferred DNS | 127.0.0.1 |

Verify:

```cmd
ipconfig /all
```

---

## 5. Active Directory Domain Services Installation

### Install AD DS Role

Open:

```text
Server Manager
→ Add Roles and Features
```

Select:

```text
Active Directory Domain Services
```

Install required management tools when prompted.

Complete installation.

---

## 6. Promote Server to Domain Controller

Open:

```text
Server Manager
→ Notification Flag
→ Promote this server to a domain controller
```

### Deployment Configuration

```text
Add a new forest
```

Root Domain Name:

```text
nation.local
```

### Domain Controller Options

| Setting | Value |
|----------|---------|
| Forest Functional Level | Windows Server 2016 |
| Domain Functional Level | Windows Server 2016 |
| DNS Server | Enabled |
| Global Catalog | Enabled |

Configure Directory Services Restore Mode (DSRM) password.

### NetBIOS Name

```text
NATION
```

Keep default paths and install.

The server automatically restarts after promotion.

---

## 7. Active Directory Structure

### Organizational Units (OUs)

| OU Name | Purpose |
|----------|----------|
| Computers | Domain Workstations |
| Users | User Accounts |
| Servers | Member Servers |
| Groups | Security Groups |

Create OUs using:

```text
Active Directory Users and Computers
```

---

## 8. Domain User Accounts

| Username | Purpose |
|------------|----------|
| Administrator | Domain Administrator |
| normaluser | Standard User |
| developer | Developer Account |
| service_account | Service Account |

Create users:

```text
Active Directory Users and Computers
→ Users OU
→ New
→ User
```

---

## 9. DNS Configuration

Verify DNS service installation:

```powershell
Get-Service DNS
```

Verify domain resolution:

```cmd
nslookup nation.local
```

Expected result:

```text
192.168.1.10
```

---

## 10. Audit Policy Configuration

### Enable Logon Auditing

Execute as Administrator:

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

### Enable Other Logon Events

```cmd
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable
```

### Enable User Account Management

```cmd
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

---

## 11. Verify Audit Policies

Run:

```cmd
auditpol /get /subcategory:"Logon"
```

Expected Output:

```text
Logon
Success and Failure
```

---

## 12. Group Policy Audit Enforcement

Create GPO:

```text
Nation_Lab_Audit_Policy
```

Navigate:

```text
Computer Configuration
 └── Policies
      └── Windows Settings
           └── Security Settings
                └── Advanced Audit Policy Configuration
                     └── Audit Policies
```

Configure:

### Audit Logon

```text
Success
Failure
```

### Audit User Account Management

```text
Success
Failure
```

Apply policy:

```cmd
gpupdate /force
```

---

## 13. Winlogbeat Installation

### Install Package

```cmd
msiexec /i winlogbeat-8.14.0-windows-x86_64.msi TARGETDIR="C:\Winlogbeat" /qn
```

### Configuration

File:

```text
C:\Winlogbeat\winlogbeat.yml
```

Configuration:

```yaml
winlogbeat.event_logs:
  - name: Application
  - name: System
  - name: Security

output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

### Install Service

```powershell
cd C:\Winlogbeat
.\install-service-winlogbeat.ps1
```

Start Service:

```powershell
Start-Service winlogbeat
```

Verify:

```cmd
sc query winlogbeat
```

---

## 14. Velociraptor Client Installation

Transfer MSI package to the server.

Install silently:

```cmd
msiexec /i velociraptor_client.msi /qn
```

Verify connection through:

```text
https://192.168.1.100:8889
```

Confirm the Domain Controller appears online.

---

## 15. Windows Firewall Configuration

Allow outbound communication:

| Destination | Port | Purpose |
|------------|--------|---------|
| Elasticsearch | 9200 | Log Forwarding |
| Velociraptor | 8000 | Agent Communication |

Temporary firewall disable during troubleshooting:

```cmd
netsh advfirewall set allprofiles state off
```

Enable firewall again after testing.

---

## 16. Windows Defender Exclusions

Add exclusions:

```powershell
Add-MpPreference -ExclusionPath "C:\Winlogbeat"
```

```powershell
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"
```

---

## 17. Validation Procedures

### Domain Validation

```cmd
nslookup nation.local
```

Expected:

```text
192.168.1.10
```

### Audit Validation

Generate failed authentication:

```cmd
net use \\localhost\c$ /user:fakeuser wrongpassword
```

Verify:

- Event ID 4625
- Event Viewer → Security Log
- Kibana Dashboard

### Elasticsearch Connectivity

```powershell
Test-NetConnection 192.168.1.100 -Port 9200
```

Expected:

```text
TcpTestSucceeded : True
```

---

## 18. Troubleshooting

| Issue | Cause | Resolution |
|---------|---------|------------|
| Domain Join Failure | Incorrect DNS | Set DNS to 192.168.1.10 |
| Missing Event 4625 | Audit Policy Disabled | Enable Audit Policies |
| Winlogbeat Service Failure | Incorrect Installation Path | Reinstall Winlogbeat |
| Velociraptor Offline | Firewall Blocking Port 8000 | Allow Outbound Traffic |

---

## 19. Configuration Summary

| Component | Status |
|------------|---------|
| Active Directory Domain Services | Configured |
| DNS Server | Configured |
| Organizational Units | Created |
| Domain Users | Created |
| Audit Policies | Enabled |
| Winlogbeat | Installed |
| Velociraptor Client | Installed |
| Firewall Rules | Configured |
| Elasticsearch Connectivity | Verified |

---

## 20. Conclusion

The Domain Controller was successfully configured as the core infrastructure component of the `nation.local` Active Directory environment. It provides centralized authentication, DNS resolution, audit logging, and policy enforcement while integrating with Elasticsearch, Kibana, Winlogbeat, and Velociraptor for enterprise-scale monitoring and detection.