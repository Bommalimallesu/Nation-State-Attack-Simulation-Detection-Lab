# Troubleshooting Guide – Nation-State Lab

## 1. Overview

This document contains the most common issues encountered during the deployment and operation of the Nation-State Lab environment, along with their root causes and solutions.

The troubleshooting section covers:

- Active Directory
- DNS
- Domain Join
- Winlogbeat
- Filebeat
- Elasticsearch
- Kibana
- Velociraptor
- Docker
- Attack Simulation Issues

---

# 2. Active Directory Issues

## Issue: Domain Controller Not Reachable

### Symptoms

- Cannot ping Domain Controller
- Domain join fails
- Authentication errors

### Root Cause

- Incorrect IP configuration
- VM network disconnected
- Wrong subnet configuration

### Solution

```powershell
ipconfig /all
```

Verify:

- IP Address: `192.168.1.10`
- Subnet Mask: `255.255.255.0`
- DNS Server: `127.0.0.1`

Restart network adapter if required.

---

## Issue: Active Directory Services Not Running

### Symptoms

- Login failures
- ADUC cannot connect
- Domain unavailable

### Solution

```powershell
Get-Service NTDS
```

Expected:

```text
Status : Running
```

Start service if stopped:

```powershell
Start-Service NTDS
```

---

# 3. DNS Issues

## Issue: DNS Resolution Fails

### Symptoms

```text
The specified domain either does not exist or could not be contacted.
```

### Verification

```powershell
nslookup nation.local
```

Expected:

```text
Server:  dc.nation.local
Address: 192.168.1.10
```

### Solution

Configure all domain-joined systems to use:

```text
DNS Server: 192.168.1.10
```

---

## Issue: Domain Name Not Resolving

### Verification

```powershell
ping nation.local
```

### Solution

Restart DNS Service:

```powershell
Restart-Service DNS
```

---

# 4. Domain Join Problems

## Issue: Computer Cannot Join Domain

### Symptoms

```text
An Active Directory Domain Controller could not be contacted
```

### Root Cause

- Wrong DNS
- Time synchronization issue
- Domain controller unavailable

### Verification

```powershell
Test-NetConnection 192.168.1.10
```

### Solution

Verify:

```text
IP Address
DNS Server
Network Connectivity
System Time
```

---

## Issue: Time Synchronization Error

### Symptoms

```text
The clock skew is too great
```

### Solution

```powershell
w32tm /resync
```

Or reboot the VM.

---

# 5. Winlogbeat Issues

## Issue: Winlogbeat Service Not Starting

### Verification

```powershell
Get-Service winlogbeat
```

### Check Logs

```powershell
Get-Content "C:\Winlogbeat\logs\winlogbeat"
```

### Common Causes

- Invalid YAML syntax
- Elasticsearch unreachable
- Wrong configuration path

### Validate Configuration

```powershell
winlogbeat test config
```

Expected:

```text
Config OK
```

---

## Issue: Logs Not Appearing in Elasticsearch

### Verification

```powershell
Test-NetConnection 192.168.1.100 -Port 9200
```

Expected:

```text
TcpTestSucceeded : True
```

### Solution

Check:

```yaml
output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

Restart service:

```powershell
Restart-Service winlogbeat
```

---

# 6. Filebeat Issues

## Issue: Filebeat Service Fails

### Validation

```bash
sudo filebeat test config
```

Expected:

```text
Config OK
```

### Solution

Correct YAML formatting.

Restart service:

```bash
sudo systemctl restart filebeat
```

---

## Issue: No Filebeat Data in Kibana

### Verification

```bash
curl http://192.168.1.100:9200
```

### Solution

Verify:

```yaml
output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

Check logs:

```bash
sudo journalctl -u filebeat -f
```

---

# 7. Elasticsearch Issues

## Issue: Elasticsearch Container Exits

### Verification

```bash
docker logs elasticsearch
```

### Common Cause

Low memory.

### Solution

Reduce heap size:

```yaml
ES_JAVA_OPTS=-Xms256m -Xmx256m
```

Restart container.

---

## Issue: Elasticsearch Not Accessible

### Verification

```bash
curl http://192.168.1.100:9200
```

Expected:

```json
{
  "cluster_name":"docker-cluster"
}
```

### Solution

Verify container:

```bash
docker ps
```

Restart:

```bash
docker restart elasticsearch
```

---

## Issue: No Indices Created

### Verification

```bash
curl http://192.168.1.100:9200/_cat/indices?v
```

### Solution

Verify:

- Winlogbeat running
- Filebeat running
- Elasticsearch reachable

---

# 8. Kibana Issues

## Issue: ERR_CONNECTION_REFUSED

### Symptoms

Browser shows:

```text
This site can't be reached
ERR_CONNECTION_REFUSED
```

### Verification

```bash
docker ps | grep kibana
```

### Solution

Start container:

```bash
docker start kibana
```

---

## Issue: Kibana Loads but No Data

### Root Cause

Index pattern missing.

### Solution

Create:

```text
winlogbeat-*
filebeat-*
```

Time field:

```text
@timestamp
```

---

## Issue: Saved Dashboard Missing

### Root Cause

Persistent volume not mounted.

### Solution

Use:

```yaml
volumes:
  - kibana-data:/usr/share/kibana/data
```

---

# 9. Docker Issues

## Issue: Container Not Starting

### Verification

```bash
docker logs <container_name>
```

### Solution

Inspect:

```bash
docker inspect <container_name>
```

Check:

- Port conflicts
- Memory allocation
- Missing volumes

---

## Issue: Docker Network Missing

### Symptoms

Containers cannot communicate.

### Solution

Create network:

```bash
docker network create elastic
```

Verify:

```bash
docker network ls
```

---

# 10. Velociraptor Issues

## Issue: Client Not Appearing Online

### Verification

Open:

```text
https://192.168.1.100:8889
```

### Root Cause

- Firewall
- Client not installed
- Service stopped

### Solution

Verify service:

```powershell
Get-Service velociraptor
```

Restart:

```powershell
Restart-Service velociraptor
```

---

# 11. Attack Simulation Issues

## Issue: Event ID 4625 Not Generated

### Root Cause

Audit policy not configured.

### Verification

```powershell
auditpol /get /subcategory:"Logon"
```

Expected:

```text
Success and Failure
```

### Solution

```powershell
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
```

Run:

```powershell
gpupdate /force
```

---

## Issue: Reverse Shell Not Connecting

### Verification

Check listener:

```bash
netstat -ano
```

### Root Cause

- Firewall
- Wrong IP
- Wrong port

### Solution

Verify:

```text
Kali IP
Payload IP
Listener Port
Firewall Rules
```

---

## Issue: Pass-the-Hash Fails

### Root Cause

- Incorrect NTLM hash
- SMB blocked
- Account permissions

### Verification

```bash
crackmapexec smb 192.168.1.10
```

### Solution

Verify:

- Correct hash
- Administrator privileges
- SMB connectivity

---

# 12. Dashboard Troubleshooting

## Issue: Metrics Show Zero

### Verification

```kql
*
```

Search in Discover.

### Solution

Verify:

- Correct time range
- Correct index pattern
- Data ingestion working

---

## Issue: Visualizations Not Updating

### Solution

Set:

```text
Auto Refresh = 5 Seconds
```

Refresh browser.

---

# 13. Lab Recovery Procedures

## Restart Entire Monitoring Stack

```bash
docker restart elasticsearch
docker restart kibana
```

---

## Restart Filebeat

```bash
sudo systemctl restart filebeat
```

---

## Restart Winlogbeat

```powershell
Restart-Service winlogbeat
```

---

## Force Group Policy Update

```powershell
gpupdate /force
```

---

## Reboot Domain Controller

```powershell
shutdown /r /t 0
```

---

# 14. Final Validation Checklist

| Component | Verification | Status |
|------------|-------------|---------|
| Domain Controller | AD DS Running | ✅ |
| DNS | nslookup nation.local | ✅ |
| Domain Join | Successful | ✅ |
| Winlogbeat | Service Running | ✅ |
| Filebeat | Service Running | ✅ |
| Elasticsearch | API Responding | ✅ |
| Kibana | Dashboard Accessible | ✅ |
| Velociraptor | Clients Online | ✅ |
| Audit Policy | Event 4625 Generated | ✅ |
| Dashboard | Live Events Visible | ✅ |

---

## Conclusion

Following the procedures in this troubleshooting guide resolves the majority of issues encountered in the Nation-State Lab. The guide provides a structured approach for diagnosing authentication, logging, monitoring, Docker, and attack-simulation problems while maintaining a stable environment for detection engineering and adversary emulation exercises.