# Velociraptor Setup – Nation-State Lab

## 1. Overview

Velociraptor is an open-source Digital Forensics and Incident Response (DFIR) platform that operates using a client-server architecture.

### Key Capabilities

- Real-time endpoint monitoring
- Threat hunting using VQL
- Forensic artifact collection
- Incident response investigations
- Centralized endpoint visibility

### Lab Usage

Velociraptor was deployed to:

- Hunt for malicious processes
- Identify persistence mechanisms
- Investigate Windows Security Events
- Locate payload files on compromised hosts
- Validate attack-chain execution

The platform complements Elasticsearch and Kibana by providing deep endpoint visibility and forensic investigation capabilities.

---

## 2. Architecture

| Component | IP Address | Ports | Purpose |
|------------|------------|---------|----------|
| Velociraptor Server | 192.168.1.100 | 8000, 8889 | Central Management |
| Windows Clients | Multiple | Outbound 8000 | Endpoint Monitoring |

### Port Usage

| Port | Purpose |
|--------|----------|
| 8000 | Client Communication |
| 8889 | Web GUI |

---

## 3. Server Installation

### Create Working Directory

```bash
mkdir ~/velociraptor
cd ~/velociraptor
```

### Download Binary

```bash
wget https://github.com/Velocidex/velociraptor/releases/download/v0.76/velociraptor-v0.76.5-linux-amd64
```

### Make Executable

```bash
chmod +x velociraptor-v0.76.5-linux-amd64
```

---

## 4. Generate Server Configuration

Run:

```bash
./velociraptor-v0.76.5-linux-amd64 config generate -i
```

### Configuration Values

| Prompt | Value |
|----------|---------|
| Deployment Type | Self Signed SSL |
| Operating System | Linux |
| Datastore Path | Default |
| Logs Path | Default |
| Certificate Validity | 2 Years |
| Registry Writeback | No |
| Public Frontend Address | 192.168.1.100 |
| DNS Type | None |
| Websocket Communication | No |
| Frontend Port | 8000 |
| GUI Port | 8889 |

### Admin Account

| Setting | Value |
|-----------|---------|
| Username | admin |
| Password | Velociraptor123! |

---

## 5. Copy Configuration

```bash
sudo mkdir -p /etc/velociraptor
sudo cp server.config.yaml /etc/velociraptor/server.config.yaml
```

---

## 6. Create Systemd Service

Create:

```bash
sudo nano /etc/systemd/system/velociraptor-server.service
```

Insert:

```ini
[Unit]
Description=Velociraptor Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/velociraptor --config /etc/velociraptor/server.config.yaml frontend -v
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

---

## 7. Install Binary

```bash
sudo cp velociraptor-v0.76.5-linux-amd64 /usr/local/bin/velociraptor
```

---

## 8. Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable velociraptor-server
sudo systemctl start velociraptor-server
```

---

## 9. Verify Server Status

```bash
sudo systemctl status velociraptor-server
```

Check listening ports:

```bash
sudo netstat -tulpn | grep -E "8000|8889"
```

Expected:

```text
0.0.0.0:8000
0.0.0.0:8889
```

---

## 10. Firewall Configuration

```bash
sudo ufw allow 8000/tcp
sudo ufw allow 8889/tcp
sudo ufw reload
```

---

## 11. Generate Windows Client MSI

### Access GUI

```text
https://192.168.1.100:8889
```

### Steps

1. Login as admin
2. Open Server Artifacts
3. Click Add Collection
4. Search for:

```text
Server.Utils.CreateMSI
```

5. Launch Artifact
6. Wait for completion
7. Download generated MSI

---

## 12. Windows Client Installation

Copy MSI to Windows host.

Install silently:

```cmd
msiexec /i "C:\Temp\velociraptor-v0.76.5-windows-amd64.msi" /qn
```

Verify:

```cmd
sc query Velociraptor
```

Start service if necessary:

```cmd
net start Velociraptor
```

---

## 13. Verify Client Connectivity

Open:

```text
https://192.168.1.100:8889
```

Navigate to:

```text
Deployments
```

Expected:

- DC Online
- WS1 Online
- FILESERVER Online
- WEBSERVER Online

---

## 14. Threat Hunting Examples

### Hunt Running Processes

Artifact:

```text
Windows.System.Pslist
```

Filter:

```text
(?i)shell.exe|beacon.exe
```

Query:

```sql
SELECT Name,Pid,CommandLine
FROM hunt_results()
WHERE Name =~ '(?i)shell.exe|beacon.exe'
```

---

### Hunt Scheduled Tasks

Artifact:

```text
Windows.Sys.ScheduledTasks
```

Query:

```sql
SELECT *
FROM hunt_results()
WHERE Name =~ '(?i)Updater'
```

---

### Hunt Security Events

Artifact:

```text
Windows.EventLogs.Security
```

Query:

```sql
SELECT System.EventID,
       System.TimeCreated.SystemTime,
       EventData.Data
FROM hunt_results()
WHERE System.EventID IN (4624,4688,4698)
```

---

### Hunt Payload Files

Artifact:

```text
Windows.Search.FileFinder
```

Search:

```text
C:\Users\Public\shell.exe
```

Search:

```text
C:\Users\Public\beacon.exe
```

---

## 15. Integration With Elastic Stack

| Service | Port |
|-----------|--------|
| Elasticsearch | 9200 |
| Kibana | 5601 |
| Velociraptor Client | 8000 |
| Velociraptor GUI | 8889 |

No port conflicts exist.

---

## 16. Troubleshooting

| Problem | Cause | Resolution |
|-----------|---------|-------------|
| GUI unavailable | Service stopped | Restart service |
| Client offline | Firewall block | Allow TCP 8000 |
| MSI install fails | Corrupt install | Remove and reinstall |
| Hunt returns no data | Wrong time range | Expand time window |
| Login failure | Invalid credentials | Reset admin password |

### Restart Server

```bash
sudo systemctl restart velociraptor-server
```

### View Logs

```bash
sudo journalctl -u velociraptor-server -f
```

---

## 17. Useful VQL Queries

### Running Processes

```sql
SELECT * FROM pslist()
```

### Specific Process

```sql
SELECT * FROM pslist(pid=1234)
```

### Read File

```sql
SELECT * FROM read_file(
 filename='C:\\Windows\\System32\\drivers\\etc\\hosts'
)
```

### Registry Query

```sql
SELECT *
FROM registry_read(
 key='HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run'
)
```

### Failed Logons

```sql
SELECT *
FROM watch_events()
WHERE System.EventID = 4625
```

---

## 18. Summary

| Component | Status |
|------------|---------|
| Velociraptor Server | Operational |
| Windows Clients | Connected |
| Threat Hunting | Functional |
| Event Collection | Functional |
| Process Hunting | Functional |
| Scheduled Task Detection | Functional |
| Security Event Analysis | Functional |

Velociraptor successfully provided endpoint visibility and forensic hunting capabilities for the Nation-State Lab environment and complemented the SIEM functionality provided by Elasticsearch and Kibana.