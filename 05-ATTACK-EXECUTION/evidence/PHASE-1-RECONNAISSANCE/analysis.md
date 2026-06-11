# Reconnaissance Phase Analysis

---

## Tools Used

- `nmap` (version 7.99) executed from Kali Linux (192.168.1.5)

---

## Scan Command

```bash
nmap --privileged -sV -O -oA /tmp/nmap_scan 192.168.1.0/24
```

---

## Live Hosts Identified

| IP Address | Hostname / Role | Detected OS | Key Open Ports / Services |
|------------|----------------|-------------|----------------------------|
| 192.168.1.10 | DC (Domain Controller) | Microsoft Windows Server 2019 | 53 DNS, 88 Kerberos, 135 RPC, 139/445 SMB, 389/636 LDAP, 3268 GC |
| 192.168.1.20 | WS1 | Windows 10 / 11 | 135 RPC |
| 192.168.1.30 | WS-2 | Windows 10 / 11 | 135 RPC |
| 192.168.1.50 | FILESERVER | Windows Server 2019 | 135 RPC, 139/445 SMB, 5985 WinRM |
| 192.168.1.60 | WEBSERVER | Windows Server 2019 | 80 HTTP (IIS 10.0), 5985 WinRM |
| 192.168.1.100 | Wazuh Manager | Linux (Ubuntu 4.15–5.19) | 22 SSH, 8000, 9200 Elasticsearch |
| 192.168.1.5 | Kali Attacker | Linux | All ports filtered |
| 192.168.1.1 | VMware Gateway | — | Filtered |

---

## High-Value Attack Targets

**Domain Controller (192.168.1.10)**  
- Central authentication (Kerberos, LDAP, DNS)  
- Full domain compromise if breached  

**File Server (192.168.1.50)**  
- SMB shares (Documents, Finance, HR)  
- Sensitive organizational data  

**Web Server (192.168.1.60)**  
- IIS web application (Login.aspx)  
- Potential SQL injection vulnerability  

**Workstations (WS1 / WS-2)**  
- User endpoints  
- Social engineering / payload execution targets  

---

## Identified Attack Vectors

| Target | Service / Port | Potential Exploit |
|--------|----------------|-------------------|
| WEBSERVER | HTTP (80) | SQL injection → initial access |
| WS1 / WS-2 | RPC (135) | Malicious file execution / reverse shell |
| DC / FILESERVER | SMB (445) | Pass-the-hash after credential theft |
| DC | Kerberos (88) | Golden ticket attack |
| FILESERVER / WEBSERVER | WinRM (5985) | Remote command execution |

---

## Attack Path Selection

### Primary Path

1. Initial access via reverse shell on WS1  
2. Persistence via scheduled task  
3. Privilege escalation (UAC bypass)  
4. Credential dumping (Mimikatz)  
5. Lateral movement (Pass-the-Hash) to DC  
6. Persistent C2 via HTTP beacon on DC  

---

### Alternative Path

- SQL injection on WEBSERVER  
- Web shell execution  
- Lateral pivot into domain environment  

---

## Observations & Limitations

- WS1 / WS-2 only expose RPC (135); SMB may be restricted  
- No RDP (3389) detected in environment  
- Wazuh Manager (192.168.1.100) is monitoring-only infrastructure  
- Nmap scan successfully mapped full enterprise topology  
- OS fingerprinting aligns with virtual lab environment  

---

## Conclusion

The reconnaissance phase successfully mapped the entire enterprise network, identified high-value targets, and enabled a clear attack path toward full domain compromise.

---