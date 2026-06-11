# Troubleshooting Guide – Nation-State Lab

This document contains the most common issues encountered during the build, deployment, monitoring, and attack simulation phases of the Nation-State Lab. Each section includes the symptom, root cause, and recommended solution.

---

# 1. Elasticsearch & Kibana (Docker)

## 1.1 Kibana Displays "Configure Elastic" Enrollment Screen

### Symptom

Kibana loads at:

```text
http://192.168.1.100:5601
```

but displays an enrollment screen instead of dashboards.

### Root Cause

* No index pattern exists.
* Kibana cannot connect to Elasticsearch.

### Solution

1. Click **Explore on my own** or **Configure manually**.
2. Create index patterns:

   * `winlogbeat-*`
   * `filebeat-*`
3. Set the time field to:

```text
@timestamp
```

4. Verify Kibana connectivity:

```bash
docker logs kibana --tail 30
```

---

## 1.2 Elasticsearch Container Exits with Code 137 (OOM)

### Symptom

```bash
docker ps -a
```

shows:

```text
Exited (137)
```

for the Elasticsearch container.

### Root Cause

The default JVM heap size exceeds available memory.

### Solution

Reduce heap allocation:

```bash
docker run \
-e "ES_JAVA_OPTS=-Xms512m -Xmx512m"
```

For very low-memory systems:

```bash
docker run \
-e "ES_JAVA_OPTS=-Xms256m -Xmx256m"
```

Check memory availability:

```bash
free -h
```

---

## 1.3 Kibana Shows "Kibana Server Is Not Ready Yet"

### Symptom

The message persists indefinitely.

### Root Cause

* Elasticsearch not healthy
* Network connectivity issues
* Incorrect `ELASTICSEARCH_HOSTS`

### Solution

Verify Elasticsearch:

```bash
curl http://192.168.1.100:9200
```

Restart services:

```bash
docker restart elasticsearch
sleep 15
docker restart kibana
```

Check logs:

```bash
docker logs kibana --tail 50
```

Look for:

```text
Unable to connect
No living connections
```

---

## 1.4 Elasticsearch Reachable Only via Localhost

### Symptom

Works locally:

```bash
curl http://localhost:9200
```

Fails remotely:

```bash
curl http://192.168.1.100:9200
```

### Root Cause

Container bound only to localhost.

### Solution

Recreate container:

```bash
docker stop elasticsearch
docker rm elasticsearch

docker run -d \
--name elasticsearch \
-p 9200:9200 \
-p 9300:9300 \
...
```

---

## 1.5 No Data Appears in Discover

### Symptom

```text
No results match your search criteria
```

### Root Cause

* Missing index pattern
* Incorrect time range
* No data ingestion

### Solution

Check indices:

```bash
curl http://192.168.1.100:9200/_cat/indices/winlogbeat-*
```

Recreate index pattern.

Expand time range:

```text
Last 24 Hours
Last 7 Days
```

Generate test events:

```cmd
net user testuser /add
net user testuser /delete
```

---

# 2. Winlogbeat (Windows)

## 2.1 Service Name Invalid

### Symptom

```cmd
net start winlogbeat
```

returns:

```text
The service name is invalid
```

### Root Cause

Winlogbeat service not installed.

### Solution

Install manually:

```powershell
cd C:\Winlogbeat
.\install-service-winlogbeat.ps1

net start winlogbeat
```

Reinstall if necessary:

```cmd
msiexec /x winlogbeat.msi /qn
msiexec /i winlogbeat.msi TARGETDIR="C:\Winlogbeat" /qn
```

---

## 2.2 Security Events Missing

### Symptom

Security events such as:

* 4624
* 4625
* 4688

do not appear.

### Root Cause

Audit policies disabled.

### Solution

Enable auditing:

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable

auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
```

Restart service:

```cmd
net stop winlogbeat
net start winlogbeat
```

---

## 2.3 Installation Fails with Access Denied

### Symptom

Installer returns:

```text
1603
1619
```

### Root Cause

* Insufficient privileges
* Invalid installation path

### Solution

Run installer as Administrator.

Use:

```cmd
TARGETDIR="C:\Winlogbeat"
```

Temporarily disable Defender if required.

---

## 2.4 Service Starts Then Stops

### Symptom

```cmd
sc query winlogbeat
```

shows:

```text
STOPPED
```

### Root Cause

* Invalid configuration
* Elasticsearch unreachable

### Solution

Run manually:

```cmd
cd C:\Winlogbeat

winlogbeat.exe -c winlogbeat.yml -e
```

Test connectivity:

```powershell
Test-NetConnection 192.168.1.100 -Port 9200
```

---

# 3. Filebeat (Kali Linux)

## 3.1 Service Running but No Data

### Symptom

Filebeat service is active but no events appear.

### Root Cause

* Invalid paths
* Permission issues
* Elasticsearch unreachable

### Solution

Check logs:

```bash
sudo journalctl -u filebeat -f
```

Verify files:

```bash
ls -la /var/log/syslog
ls -la /var/log/auth.log
```

Test Elasticsearch:

```bash
curl http://192.168.1.100:9200
```

Restart Filebeat:

```bash
sudo systemctl restart filebeat
```

---

## 3.2 Permission Denied Reading Logs

### Symptom

```text
permission denied
```

### Root Cause

Filebeat lacks read permissions.

### Solution

Temporary workaround:

```bash
sudo chmod 644 /var/log/auth.log
```

Prefer proper group membership in production.

---

# 4. Velociraptor

## 4.1 GUI Connection Refused

### Symptom

Cannot access:

```text
https://192.168.1.100:8889
```

### Root Cause

Server stopped or firewall blocked.

### Solution

Check service:

```bash
sudo systemctl status velociraptor-server
```

Start service:

```bash
sudo systemctl start velociraptor-server
```

Allow firewall access:

```bash
sudo ufw allow 8889/tcp
```

---

## 4.2 Clients Show Offline

### Symptom

Clients appear offline in Deployments.

### Root Cause

* Wrong frontend address
* Firewall issues

### Solution

Test connectivity:

```powershell
Test-NetConnection 192.168.1.100 -Port 8000
```

Regenerate MSI with correct server IP.

Reinstall client.

---

## 4.3 Hunt Returns No Results

### Symptom

Notebook contains zero results.

### Root Cause

* Narrow time filter
* Restrictive hunt parameters

### Solution

* Expand hunt time range.
* Remove unnecessary filters.
* Re-run hunt.

---

# 5. Attack Tools

## 5.1 Metasploit Payload Does Not Connect

### Root Cause

* Incorrect LHOST
* Firewall blocking
* Defender interference

### Solution

Verify payload configuration:

```bash
LHOST=192.168.1.5
```

Check active jobs:

```bash
jobs
```

Disable Defender temporarily during testing.

---

## 5.2 Caldera Agent Cannot Connect

### Root Cause

Incorrect callback URL.

### Solution

Use:

```text
http://192.168.1.5:8888
```

Allow firewall access:

```bash
sudo ufw allow 8888
```

Test:

```bash
curl http://192.168.1.5:8888
```

---

## 5.3 BloodHound Container Fails

### Root Cause

* Port conflict
* Insufficient memory

### Solution

Check port usage:

```bash
sudo lsof -i :8080
```

Use alternate port:

```bash
docker run -d \
--name bloodhound \
-p 8081:8080 \
specterops/bloodhound
```

---

# 6. VMware Shared Folders & File Transfer

## 6.1 Shared Folder Not Accessible

### Symptom

```text
\\vmware-host\Shared Folders\share
```

cannot be opened.

### Solution

Enable:

```text
VM Settings
└── Options
    └── Shared Folders
        └── Always Enabled
```

Install:

* VMware Tools
* open-vm-tools

Restart VM.

---

## 6.2 Copy/Paste Not Working

### Root Cause

Guest isolation disabled.

### Solution

Enable:

```text
Options
└── Guest Isolation
    ├── Enable Copy and Paste
    └── Enable Drag and Drop
```

Reboot VM.

---

# 7. Ubuntu & Kali Linux

## 7.1 netstat Command Missing

### Symptom

```bash
netstat: command not found
```

### Solution

Install:

```bash
sudo apt install net-tools -y
```

Alternative:

```bash
ss -tulpn
```

---

## 7.2 Docker Containers Missing After Reboot

### Root Cause

No restart policy configured.

### Solution

Update existing containers:

```bash
docker update --restart unless-stopped <container>
```

Or create containers with:

```bash
--restart unless-stopped
```

---

## 7.3 Elasticsearch Connection Refused

### Solution

Verify container:

```bash
docker ps
```

Restart:

```bash
docker restart elasticsearch
```

Allow firewall:

```bash
sudo ufw allow 9200/tcp
```

---

# 8. Windows Agent Connectivity

## 8.1 Firewall Blocks Elasticsearch

### Test

```powershell
Test-NetConnection 192.168.1.100 -Port 9200
```

### Temporary Workaround

```cmd
netsh advfirewall set allprofiles state off
```

### Permanent Rule

```cmd
netsh advfirewall firewall add rule name="Allow Elasticsearch" dir=out protocol=tcp remoteport=9200 action=allow
```

---

## 8.2 Defender Removes Payloads

### Symptom

Payload deleted immediately.

### Solution

Add exclusion:

```powershell
Add-MpPreference -ExclusionPath "C:\Users\Public"
```

Temporarily disable real-time protection during simulations.

---

# 9. Incident Response & Reporting

## 9.1 Kibana Dashboards Disappear

### Root Cause

No persistent volume configured.

### Solution

Use:

```bash
-v kibana-data:/usr/share/kibana/data
```

Backup objects:

```text
Stack Management
└── Saved Objects
    └── Export
```

---

## 9.2 Velociraptor Hunt Data Missing

### Root Cause

Datastore not persisted.

### Solution

Verify:

```yaml
datastore:
  location: /var/lib/velociraptor/datastore
```

Store on persistent storage.

---

# 10. Helpful Resources

| Component     | Resource                                       |
| ------------- | ---------------------------------------------- |
| Elasticsearch | https://discuss.elastic.co                     |
| Kibana        | https://www.elastic.co/guide                   |
| Velociraptor  | https://docs.velociraptor.app                  |
| Metasploit    | https://github.com/rapid7/metasploit-framework |
| MITRE Caldera | https://github.com/mitre/caldera               |

---

# Conclusion

This troubleshooting guide covers the most common issues encountered when deploying and operating the Nation-State Lab. When diagnosing problems:

1. Verify network connectivity.
2. Review service logs.
3. Confirm configuration files.
4. Check firewall rules.
5. Validate resource availability (CPU, RAM, Disk).

Maintaining snapshots, backups, and configuration documentation significantly reduces recovery time and improves lab stability.
