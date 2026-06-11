# Phase 1: Reconnaissance – Nation-State Lab

## 1. Objective

The reconnaissance phase aims to discover live hosts, open ports, and running services within the target network (`192.168.1.0/24`). This helps identify potential entry points such as the Domain Controller, file servers, and workstations.

### MITRE ATT&CK Mapping

- **Tactic:** TA0043 – Reconnaissance  
- **Technique:** T1595 – Active Scanning  

---

## 2. Attack Execution

All reconnaissance activity was performed from the Kali Linux attacker VM (`192.168.1.5`).

---

### 2.1 Nmap Scan

```bash
nmap -sV -O 192.168.1.0/24
```

### Flag Explanation
- `-sV` → Service version detection  
- `-O` → Operating system detection  

---

### 2.2 Expected Output (Abbreviated)

```text
Nmap scan report for 192.168.1.10
Host is up (0.0012s latency)

PORT      STATE SERVICE       VERSION
53/tcp    open  domain        Microsoft DNS
88/tcp    open  kerberos-sec  Kerberos
135/tcp   open  msrpc         Microsoft Windows RPC
139/tcp   open  netbios-ssn   NetBIOS
389/tcp   open  ldap          Active Directory LDAP (nation.local)
445/tcp   open  microsoft-ds  SMB
3389/tcp  open  ms-wbt-server RDP
```

---

## 3. Detection in Kibana

The scan activity was logged via Filebeat from `/var/log/syslog` and indexed in Elasticsearch.

---

### 3.1 Kibana Query

```text
index: filebeat-* AND message: "nmap"
```

---

### 3.2 Example Log Entry

```json
{
  "_index": "filebeat-8.14.0-2026.06.09",
  "_source": {
    "host": {
      "name": "kali"
    },
    "message": "nmap -sV -O 192.168.1.0/24",
    "process": {
      "name": "nmap"
    },
    "timestamp": "2026-06-09T10:15:22.000Z"
  }
}
```

---

## 4. Detection Rule (Kibana Alerting)

### Rule Name
Reconnaissance – Port Scan Detection

### Configuration

- **Index Pattern:** filebeat-*
- **KQL Query:**

```text
message: "nmap" OR message: "masscan" OR process.name: "nmap"
```

- **Schedule:** Every 5 minutes  
- **Threshold:** Count > 0  

### Action
- Log alert in Kibana (or email/webhook in production)

---

## 5. Screenshot Requirements

Capture the following:

- Kali terminal showing `nmap` execution and partial output  
- Kibana Discover page with query:
  ```
  message: "nmap"
  ```
- Filebeat logs showing attacker activity

---

## 6. Limitations

### False Positives
- Admin network scanning tools may trigger alerts

### Evasion
- Slow scans or decoys may bypass simple detection rules

### Lab Context
- Host-only network ensures controlled and repeatable behavior

---

## 7. Conclusion

The reconnaissance phase successfully identified all live hosts and open ports in the target environment. All attacker activity was logged via Filebeat and visualized in Kibana, providing full visibility into early-stage adversary behavior.

This marks the first stage of the Nation-State Lab Attack Chain simulation.