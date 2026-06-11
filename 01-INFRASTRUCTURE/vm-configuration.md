# Virtual Machine Configuration – Nation-State Lab

This document details the exact hardware and software configuration of each virtual machine used in the lab. All VMs are connected via VMware Host-Only Network (`VMnet1`, subnet `192.168.1.0/24`) and have static IP addresses.

---

## 1. Domain Controller (DC)

| Attribute | Value |
|-----------|-------|
| **Hostname** | `DC` |
| **Operating System** | Windows Server 2019 Datacenter Evaluation |
| **IP Address** | `192.168.1.10` (static) |
| **Subnet Mask** | `255.255.255.0` |
| **Default Gateway** | None (isolated network) |
| **DNS Server** | `127.0.0.1` (self) |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 50 GB |
| **VMware Tools** | Installed |

### Installed Roles & Features

- Active Directory Domain Services (AD DS)
- DNS Server
- Group Policy Management

### Configuration

- Domain: `nation.local`
- Forest/Domain functional level: Windows Server 2016
- OUs created:
  - Computers
  - Users
  - Servers
  - Groups

### Domain Users

- Administrator
- normaluser
- developer
- service_account

### Audit Policy Enabled

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

### Monitoring Agents

- Winlogbeat 8.14.0 (`C:\Winlogbeat`)
- Velociraptor Client 0.76.5

### File Transfers

Shared Folder:

```text
\\vmware-host\Shared Folders\share
```

---

## 2. Workstation 1 (WS1) – Standard User

| Attribute | Value |
|-----------|-------|
| **Hostname** | `WS1` |
| **Operating System** | Windows 10 Pro (21H2/22H2) |
| **IP Address** | `192.168.1.20` |
| **Subnet Mask** | `255.255.255.0` |
| **Default Gateway** | None |
| **DNS Server** | `192.168.1.10` |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 50 GB |
| **VMware Tools** | Installed |

### Domain Membership

- Joined to `nation.local`
- Domain User: `normaluser`

### Audit Policy

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

### Monitoring Agents

- Winlogbeat 8.14.0
- Velociraptor Client 0.76.5

---

## 3. Workstation 2 (WS2) – Developer 

| Attribute | Value |
|-----------|-------|
| **Hostname** | `WS2` |
| **Operating System** | Windows 10 Pro (21H2/22H2) |
| **IP Address** | `192.168.1.30` |
| **Subnet Mask** | `255.255.255.0` |
| **Default Gateway** | None |
| **DNS Server** | `192.168.1.10` |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 50 GB |
| **VMware Tools** | Installed |

---

## 4. Workstation 3 (WS3) – Admin (Removed)

| Attribute | Value |
|-----------|-------|
| Hostname | WS3 |
| Operating System | Windows 10 Pro |
| IP Address | 192.168.1.40 |
| Domain User | service_account |
| Status | Removed due to disk space constraints |

---

## 5. File Server (FILESERVER)

| Attribute | Value |
|-----------|-------|
| **Hostname** | `FILESERVER` |
| **Operating System** | Windows Server 2019 Datacenter Evaluation |
| **IP Address** | `192.168.1.50` |
| **Subnet Mask** | `255.255.255.0` |
| **DNS Server** | `192.168.1.10` |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 50 GB |
| **VMware Tools** | Installed |

### Domain Membership

- Joined to `nation.local`

### Shared Folders

#### Documents

```text
C:\Shares\Documents
```

Permission:

- Domain Users → Read

#### Finance

```text
C:\Shares\Finance
```

Permission:

- Domain Users → Modify

#### HR

```text
C:\Shares\HR
```

Permissions:

- Domain Admins → Full Control
- Domain Users → Read

### Monitoring Agents

- Winlogbeat 8.14.0
- Velociraptor Client 0.76.5

---

## 6. Web Server (WEBSERVER)

| Attribute | Value |
|-----------|-------|
| **Hostname** | `WEBSERVER` |
| **Operating System** | Windows Server 2019 Datacenter Evaluation |
| **IP Address** | `192.168.1.60` |
| **DNS Server** | `192.168.1.10` |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 50 GB |

### Installed Roles

- IIS Web Server
- ASP.NET 4.7

### Vulnerable Application

```text
C:\inetpub\wwwroot\VulnerableApp\Login.aspx
```

### Example SQL Injection Payload

```sql
' OR '1'='1
```

### Monitoring Agents

- Winlogbeat 8.14.0
- Velociraptor Client 0.76.5

---

## 7. Kali Linux (Attacker)

| Attribute | Value |
|-----------|-------|
| **Hostname** | `kali` |
| **Operating System** | Kali Linux 2024.4 |
| **IP Address** | `192.168.1.5` |
| **vCPU** | 2 |
| **RAM** | 4 GB |
| **Disk** | 40 GB |

### Network Configuration

```text
auto eth0
iface eth0 inet static
    address 192.168.1.5
    netmask 255.255.255.0
    gateway 192.168.1.1
```

### Installed Tools

- Metasploit Framework
- Caldera
- BloodHound CE
- Neo4j
- Impacket
- Hydra
- Nmap
- Responder
- Netcat

### Monitoring Agent

Filebeat 8.14.0

Collected Logs:

```text
/var/log/syslog
/var/log/auth.log
```

---

## 8. Ubuntu Server (Monitoring & SIEM)

| Attribute | Value |
|-----------|-------|
| **Hostname** |` wazuh-manager `|
| **Operating System** | Ubuntu Server 22.04 LTS |
| **IP Address** | `192.168.1.100` |
| **vCPU** | 2 |
| **RAM** | 4 GB |
| **Disk** | 60 GB |

### Netplan Configuration

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
```

### Docker Containers

- Elasticsearch 8.14.0
- Kibana 8.14.0

### Native Services

- Velociraptor Server 0.76.5

### Firewall (UFW)

```bash
sudo ufw allow 9200/tcp
sudo ufw allow 5601/tcp
sudo ufw allow 8889/tcp
sudo ufw allow 8000/tcp
sudo ufw enable
```

---

## 9. Summary Table

| VM | IP | OS | vCPU | RAM | Disk | Role |
|----|----|----|----|----|----|----|
| DC | 192.168.1.10 | Windows Server 2019 | 2 | 2 GB | 50 GB | AD DS, DNS |
| WS1 | 192.168.1.20 | Windows 10 Pro | 2 | 2 GB | 50 GB | Standard User |
| WS2 | 192.168.1.30 | Windows 10 Pro | 2 | 2 GB | 50 GB | Developer |
| FILESERVER | 192.168.1.50 | Windows Server 2019 | 2 | 2 GB | 50 GB | File Shares |
| WEBSERVER | 192.168.1.60 | Windows Server 2019 | 2 | 2 GB | 50 GB | IIS |
| Kali | 192.168.1.5 | Kali Linux 2024.4 | 2 | 4 GB | 40 GB | Attacker |
| Ubuntu | 192.168.1.100 | Ubuntu 22.04 | 2 | 4 GB | 60 GB | Monitoring |

---

## Conclusion

All configuration changes, including static IP assignment, domain joins, audit policy configuration, Winlogbeat deployment, Velociraptor deployment, and monitoring stack installation, were applied manually or through automation scripts documented during the project lifecycle.

The final environment successfully simulated a realistic enterprise Active Directory network with centralized monitoring, attack emulation capabilities, and threat-hunting visibility.