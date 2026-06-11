# Security Hardening – Nation-State Lab

This document outlines security hardening measures applied to the Nation-State Lab environment and provides recommendations for production deployments. While the lab intentionally simulates vulnerable configurations for attack simulation, hardening principles are documented to guide real-world implementations.

---

# 1. Windows Domain Controller (DC)

## 1.1 Applied Hardening (Lab Environment)

* Audit policies enabled for:

  * Logon
  * Logoff
  * User Account Management
* Windows Defender exclusions configured for:

  * Winlogbeat
  * Atomic Red Team
* Windows Firewall configured:

  * Outbound access allowed for Elasticsearch (`9200`)
  * Outbound access allowed for Velociraptor (`8000`)
  * Inbound traffic blocked by default

---

## 1.2 Recommended Hardening (Production)

### Identity & Credential Security

* Enable **Windows Defender Credential Guard**
* Implement **Local Administrator Password Solution (LAPS)**
* Disable **NTLMv1**
* Enforce **Kerberos authentication**
* Restrict Kerberos ticket lifetime
* Enforce AES encryption for Kerberos

### Security Baselines

* Apply Microsoft Security Compliance Toolkit baselines
* Apply CIS Benchmarks for Windows Server

### Group Policy Restrictions

Restrict:

* Anonymous SMB access
* Unsigned driver installation
* Unrestricted PowerShell execution

### Availability

* Deploy a secondary Domain Controller
* Eliminate single points of failure

### Patch Management

* Use WSUS or equivalent update management
* Apply regular security updates

---

# 2. Windows Workstations (WS1, WS2)

## 2.1 Lab Configuration

* Standard user account (`normaluser`)
* No local administrator privileges
* Windows auditing enabled
* Winlogbeat installed
* Velociraptor client installed

---

## 2.2 Hardening Recommendations

### User Account Control (UAC)

Enable UAC and require administrator approval for elevation.

### Microsoft Defender Exploit Guard

Enable Attack Surface Reduction (ASR) rules to block:

* Office macro abuse
* Script-based attacks
* Credential theft techniques

### PowerShell Security

Disable PowerShell 2.0:

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root
```

### Application Control

Implement:

* AppLocker
* Windows Defender Application Control (WDAC)

Example blocked executables:

* `shell.exe`
* `beacon.exe`

### SmartScreen

Enable SmartScreen for:

* Microsoft Edge
* Google Chrome

### Disable LLMNR and NetBIOS

```powershell
Set-ItemProperty `
-Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" `
-Name "NetbiosOptions" `
-Value 2
```

### Endpoint Detection and Response

Use:

* Microsoft Defender for Endpoint
* CrowdStrike
* SentinelOne
* Palo Alto Cortex XDR

---

# 3. Active Directory Hardening

## 3.1 Lab State

### Default Domain Policy

* Minimum password length: 7
* Complexity requirements enabled
* No account lockout policy

### Administrative Controls

* No custom delegation
* No additional privileged groups

---

## 3.2 Production Hardening

### Password Policies

| Setting          | Recommendation    |
| ---------------- | ----------------- |
| Minimum Length   | 12–14 Characters  |
| Complexity       | Enabled           |
| Account Lockout  | 5 Failed Attempts |
| Lockout Duration | 15–30 Minutes     |

### Additional Controls

* Fine-grained password policies
* Read-Only Domain Controllers (RODC)
* Active Directory Certificate Services (AD CS)
* Smart card authentication
* Active Directory Recycle Bin

### Monitoring

Monitor event IDs:

| Event ID | Description                |
| -------- | -------------------------- |
| 5136     | Directory Object Modified  |
| 5137     | Directory Object Created   |
| 5138     | Directory Object Undeleted |

### Privileged Group Auditing

Review:

* Domain Admins
* Enterprise Admins
* Schema Admins
* Administrators

---

# 4. Elasticsearch & Kibana

## 4.1 Lab Configuration

```yaml
xpack.security.enabled=false
```

Characteristics:

* No TLS
* No authentication
* No RBAC

Suitable only for isolated lab environments.

---

## 4.2 Production Hardening

### Authentication & Authorization

Enable:

* TLS
* Role-Based Access Control (RBAC)

Create dedicated users:

| Account           | Purpose          |
| ----------------- | ---------------- |
| kibana_system     | Kibana Services  |
| winlogbeat_writer | Log Ingestion    |
| analyst           | Read-Only Access |

### Network Security

Restrict access to:

| Service       | Port |
| ------------- | ---- |
| Elasticsearch | 9200 |
| Kibana        | 5601 |

Allow only trusted management hosts.

### Audit Logging

```yaml
xpack.security.audit.enabled=true
```

### Backups

Implement Elasticsearch snapshots.

### Data Lifecycle

Use Index Lifecycle Management (ILM):

| Data Type     | Retention   |
| ------------- | ----------- |
| Security Logs | 30–90 Days  |
| Audit Logs    | 90–365 Days |

---

# 5. Velociraptor Server

## 5.1 Lab Configuration

* Self-signed certificate
* Default administrator credentials
* Host-only network access

---

## 5.2 Hardening Recommendations

### Certificates

Replace self-signed certificates with certificates from:

* Internal PKI
* Trusted CA

### Authentication

* Change default passwords immediately
* Enable MFA (if supported)

### Access Controls

Restrict GUI access by:

* Source IP
* Firewall rules

Enable Velociraptor RBAC.

### File Permissions

Protect configuration files:

```bash
chmod 600 server.config.yaml
```

### Maintenance

Keep Velociraptor updated to the latest stable release.

---

# 6. Kali Linux

## 6.1 Lab State

Deliberately insecure for adversary simulation.

Characteristics:

* Default installation
* Full offensive toolkit
* Minimal hardening

---

## 6.2 Hardening Recommendations

### User Management

Create a standard user:

```bash
sudo adduser analyst
sudo usermod -aG sudo analyst
```

### Firewall

```bash
sudo ufw enable
```

### Disable Unnecessary Services

```bash
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
```

### SSH Security

* Key-based authentication
* Disable password login
* Disable root login

### Brute Force Protection

Install Fail2Ban:

```bash
sudo apt install fail2ban
```

### Updates

```bash
sudo apt update && sudo apt upgrade -y
```

### Containerization

Run tools in isolated containers:

* BloodHound
* Caldera
* Mythic
* OpenVAS

---

# 7. Ubuntu Monitoring Host

## 7.1 Lab Configuration

* Docker containers running as root
* UFW enabled
* Static IP address
* No external connectivity

---

## 7.2 Hardening Recommendations

### Container Security

Run containers as non-root users whenever possible.

### Mandatory Access Control

Enable:

* AppArmor
* SELinux

### Automatic Updates

```bash
sudo apt install unattended-upgrades
```

### SSH Hardening

Edit:

```bash
/etc/ssh/sshd_config
```

Recommended settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

### Auditd

Install:

```bash
sudo apt install auditd
```

Monitor:

* `/etc/passwd`
* `/etc/shadow`
* `/etc/ssh/sshd_config`

### Vulnerability Scanning

Recommended tools:

* Lynis
* ClamAV
* OpenSCAP

---

# 8. Network & Firewall Security

## 8.1 Lab Configuration

* VMware Host-Only Network
* No routing to production network
* Temporary firewall relaxations during testing

---

## 8.2 Production Hardening

### Network Segmentation

Recommended VLANs:

| VLAN | Purpose      |
| ---- | ------------ |
| 10   | Management   |
| 20   | Servers      |
| 30   | Workstations |
| 40   | DMZ          |

### Firewall Strategy

Implement:

* Default Deny Inbound
* Least Privilege Access

### Network Monitoring

Deploy:

* Suricata
* Snort
* Zeek

### Logging

Enable:

* NetFlow
* sFlow

### Restrict Administrative Protocols

Limit:

* RDP
* SMB
* WinRM
* SSH

to authorized management systems only.

### Additional Controls

* Deploy 802.1X
* Disable IPv6 if not required

---

# 9. Logging & Monitoring Hardening

## 9.1 Lab Measures

* Windows auditing enabled
* Winlogbeat forwarding logs
* Velociraptor artifact collection

---

## 9.2 Production Enhancements

### PowerShell Logging

Enable:

* Module Logging
* Script Block Logging
* PowerShell Transcription

### Sysmon

Deploy Sysmon using:

* SwiftOnSecurity configuration
* Olaf Hartong Sysmon Modular

### Defender Telemetry

Forward:

* Microsoft Defender Events
* Security Center Events

### Linux Monitoring

Use:

```bash
auditd
```

to monitor critical system activity.

### Log Integrity

Implement:

* Wazuh
* OSSEC

### Secure Transport

Encrypt logs using TLS.

### Log Protection

Store logs in a write-once or restricted repository.

---

# 10. Incident Response & Recovery

## Backup Strategy

Regularly back up:

* Elasticsearch indices
* Velociraptor datastore
* Configuration files

---

## Response Procedures

Document:

1. Detection
2. Containment
3. Collection
4. Analysis
5. Eradication
6. Recovery
7. Lessons Learned

---

## Lab Recovery

Maintain:

* VM snapshots
* Golden images
* Automated rebuild scripts

### Infrastructure as Code

Recommended tools:

* Terraform
* Packer
* Ansible

---

# 11. Recommended Hardening Tools

| Area                      | Tool / Technique                      | Purpose             |
| ------------------------- | ------------------------------------- | ------------------- |
| Windows Security Baseline | Microsoft Security Compliance Toolkit | Harden Windows      |
| Endpoint Protection       | Defender + ASR                        | Malware Prevention  |
| Credential Protection     | Credential Guard + LAPS               | Credential Security |
| Network Security          | VLANs + Firewalls                     | Segmentation        |
| Logging                   | Sysmon + PowerShell Logging           | Enhanced Telemetry  |
| Elasticsearch             | TLS + RBAC                            | Secure Log Storage  |
| Velociraptor              | Certificates + MFA                    | Secure Access       |
| Linux                     | AppArmor, SELinux, Fail2Ban           | Host Hardening      |

---

# 12. Conclusion

The Nation-State Lab was designed primarily for attack simulation, detection engineering, and threat hunting. To support realistic adversary activity, several production security controls were intentionally omitted, including:

* LAPS
* Credential Guard
* TLS-secured logging
* Multi-factor authentication
* Application whitelisting

The recommendations in this guide provide a practical roadmap for transforming the environment into a production-like deployment. Implement changes incrementally, validate functionality after each modification, and maintain documentation of all security controls to ensure long-term stability and security.
