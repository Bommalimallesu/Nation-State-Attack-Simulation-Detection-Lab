# Best Practices – Nation-State Lab

This document consolidates lessons learned and industry best practices derived from building and operating the Nation-State Lab. Use these guidelines to enhance security monitoring, incident detection, and response in your own environments.

---

## 1. Network Isolation & Segmentation

- **Use host-only networks** for isolated lab environments. This prevents accidental exposure of internal traffic to the internet or corporate networks.
- **Assign static IPs** to all critical assets (DC, workstations, servers, monitoring host). Document IP allocations in a central table.
- **Avoid NAT for production monitoring** – keep management interfaces on a dedicated, isolated VLAN.
- **Limit outbound firewall rules** – only allow essential ports (e.g., 9200 for Elasticsearch, 8000 for Velociraptor clients). Block all inbound by default.

---

## 2. Monitoring Stack (Elasticsearch + Kibana)

- **Use Docker for Elastic Stack** – simplifies deployment, updates, and resource management. Bind containers to specific host IPs (`192.168.1.100:9200`) rather than `0.0.0.0`.
- **Disable security (`xpack.security.enabled=false`) only in isolated labs**. In production, enable TLS and authentication.
- **Set heap size (`ES_JAVA_OPTS=-Xms512m -Xmx512m`)** to prevent Elasticsearch RAM exhaustion.
- **Persist data using Docker volumes** (`elasticsearch-data`, `kibana-data`) to avoid data loss after restarts.
- **Create index patterns immediately** (`winlogbeat-*`, `filebeat-*`) and verify `@timestamp` field.
- **Backup Kibana saved objects** via Stack Management → Saved Objects → Export.

---

## 3. Log Collection (Winlogbeat & Filebeat)

### Winlogbeat (Windows)

- Install to `C:\Winlogbeat`
- Remove `<query>` filter to capture all events (4624, 4625, 4688, 4698, 4663)
- Enable audit policies:

auditpol /set /subcategory:"Logon" /success:enable /failure:enable  
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable  
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable  

Test connectivity:

Test-NetConnection 192.168.1.100 -Port 9200  

- Add Windows Defender exclusions for Winlogbeat.

---

### Filebeat (Linux / Kali)

- Use Filebeat instead of Elastic Agent
- Monitor:
  /var/log/syslog  
  /var/log/auth.log  
- Enable service:

systemctl enable --now filebeat  

---

## 4. Attack Tools & Simulation

- Use `msfvenom` with consistent LHOST/LPORT
- Run Metasploit jobs in background (`exploit -j`)
- Verify privileges using `getuid`
- Never store credentials in Git
- Use LM:NT format for pass-the-hash
- Deploy Caldera agents using correct IP
- Use BloodHound CE in Docker

---

## 5. Velociraptor for Threat Hunting

- Install server natively (not Docker)
- Use static IP for frontend
- Generate MSI via `Server.Utils.CreateMSI`
- Run hunts after attacks
- Export results for reporting

VQL Query:

SELECT * FROM hunt_results()
WHERE Name =~ '(?i)shell.exe|beacon.exe'

---

## 6. Detection Engineering (Kibana Rules)

- Create rules in Stack Management → Rules
- Use precise KQL queries
- Run every 5 minutes
- Map to MITRE ATT&CK

Example:

winlog.event_id: 4688 AND process.executable: *shell.exe  

Pass-the-hash:

winlog.event_id: 4624 AND winlog.event_data.LogonType: 3 AND winlog.event_data.IpAddress: 192.168.1.5  

---

## 7. Incident Response & Reporting

- Maintain attack timeline
- Capture Kibana + Velociraptor screenshots
- Write structured incident reports
- Store artifacts in GitHub
- Map to MITRE ATT&CK

---

## 8. Resource Management

- Minimum 4 GB RAM for monitoring host
- Elasticsearch heap: 512MB–1GB
- Clean Docker:

docker system prune -a --volumes -f  

df -h  

- Remove unused VMs

---

## 9. Automation & Scripting

- Use Bash / PowerShell scripts
- Prefer docker-compose
- Store scripts in GitHub

---

## 10. Future Improvements

- Enable Elastic Security (`xpack.security.enabled=true`)
- Multi-node Elasticsearch cluster
- Integrate TheHive via webhooks
- Automate Atomic Red Team testing
- Add YARA + memory analysis

---

## 11. Conclusion

These best practices help build a professional cybersecurity lab with strong detection, monitoring, and incident response capabilities.