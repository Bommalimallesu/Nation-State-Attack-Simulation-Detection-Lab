# Elasticsearch Setup – Nation-State Lab

## 1. Overview

Elasticsearch (version 8.14.0) was deployed as the central log storage backend for the lab. It receives Windows security events from Winlogbeat (installed on DC, WS1, FILESERVER, and WEBSERVER) and system logs from Filebeat on Kali Linux. The data is then visualized in Kibana, which connects to the same Elasticsearch instance.

All components run in Docker containers on the Ubuntu monitoring host (`192.168.1.100`). This approach isolates Elasticsearch from the host system, simplifies upgrades, and allows easy recreation without affecting other services.

---

## 2. Environment & Prerequisites

- **Host:** Ubuntu Server 22.04 LTS
- **Host IP:** `192.168.1.100`
- **Docker Engine:** Installed
- **Docker Network:** `elastic`
- **Elasticsearch Version:** `8.14.0`
- **Security:** Disabled (`xpack.security.enabled=false`)
- **Deployment Method:** Docker Container / Docker Compose

### Create Docker Network

```bash
docker network create elastic
```

---

## 3. Elasticsearch Container Configuration

### Docker Run Command

```bash
docker run -d \
  --name elasticsearch \
  --network elastic \
  -p 192.168.1.100:9200:9200 \
  -p 192.168.1.100:9300:9300 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
  -v elasticsearch-data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:8.14.0
```

### Configuration Details

| Parameter | Value | Purpose |
|------------|---------|----------|
| `discovery.type` | `single-node` | Runs Elasticsearch as a standalone node |
| `xpack.security.enabled` | `false` | Disables authentication and TLS |
| `ES_JAVA_OPTS` | `-Xms512m -Xmx512m` | Limits heap memory usage |
| `9200` | REST API Port | Log ingestion and queries |
| `9300` | Transport Port | Cluster communication |
| `elasticsearch-data` | Docker Volume | Persistent storage |

---

## 4. Verification Steps

### Verify Container Status

```bash
docker ps | grep elasticsearch
```

Expected Output:

```text
elasticsearch   Up xx minutes
```

### Verify Elasticsearch API

```bash
curl http://192.168.1.100:9200
```

Expected Output:

```json
{
  "name":"elasticsearch",
  "cluster_name":"docker-cluster",
  "version":{
    "number":"8.14.0"
  },
  "tagline":"You Know, for Search"
}
```

---

## 5. Verify Indices

### List All Indices

```bash
curl -X GET "http://192.168.1.100:9200/_cat/indices?v"
```

### Verify Winlogbeat Indices

```bash
curl -X GET "http://192.168.1.100:9200/_cat/indices/winlogbeat-*?v"
```

Expected Example:

```text
green open winlogbeat-8.14.0-2026.06.07
```

### Verify Filebeat Indices

```bash
curl -X GET "http://192.168.1.100:9200/_cat/indices/filebeat-*?v"
```

---

## 6. Winlogbeat Integration

### Windows Configuration

File:

```text
C:\Winlogbeat\winlogbeat.yml
```

Configuration:

```yaml
output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

### Restart Winlogbeat

```powershell
Restart-Service winlogbeat
```

### Verify Service

```powershell
Get-Service winlogbeat
```

Expected:

```text
Status : Running
```

---

## 7. Filebeat Integration (Kali Linux)

### File

```bash
/etc/filebeat/filebeat.yml
```

### Configuration

```yaml
output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

### Restart Filebeat

```bash
sudo systemctl restart filebeat
```

### Verify Status

```bash
sudo systemctl status filebeat
```

---

## 8. Performance Tuning

### Heap Memory

Current Configuration:

```text
-Xms512m -Xmx512m
```

Reason:

- Ubuntu VM contains only 4 GB RAM.
- Prevents Out-of-Memory (OOM) errors.
- Sufficient for lab-scale logging.

### Monitoring Resource Usage

```bash
docker stats
```

---

## 9. Troubleshooting

### Elasticsearch Container Stops

#### Symptoms

```bash
docker ps -a
```

Container shows:

```text
Exited (137)
```

#### Cause

Insufficient memory.

#### Fix

Reduce heap size:

```bash
-e "ES_JAVA_OPTS=-Xms256m -Xmx256m"
```

---

### Connection Refused

#### Test

```bash
curl http://192.168.1.100:9200
```

#### Fix

Check container logs:

```bash
docker logs elasticsearch
```

Verify container status:

```bash
docker ps
```

---

### Missing Winlogbeat Data

Verify Winlogbeat service:

```powershell
Get-Service winlogbeat
```

Verify network connectivity:

```powershell
Test-NetConnection 192.168.1.100 -Port 9200
```

Expected:

```text
TcpTestSucceeded : True
```

---

### Missing Filebeat Data

Check service:

```bash
sudo systemctl status filebeat
```

Check logs:

```bash
sudo journalctl -u filebeat -f
```

---

## 10. Backup and Recovery

### Backup Docker Volume

```bash
docker volume inspect elasticsearch-data
```

Copy volume contents from:

```text
/var/lib/docker/volumes/elasticsearch-data/_data
```

### Restore

Reattach the same Docker volume when recreating the container.

---

## 11. Operational Commands

### Start Container

```bash
docker start elasticsearch
```

### Stop Container

```bash
docker stop elasticsearch
```

### Restart Container

```bash
docker restart elasticsearch
```

### View Logs

```bash
docker logs -f elasticsearch
```

### Remove Container

```bash
docker rm -f elasticsearch
```

---

## 12. Elasticsearch Role in the Lab

| Function | Status | Description |
|-----------|---------|-------------|
| Log Storage | Active | Stores Windows and Linux logs |
| Winlogbeat Integration | Active | Receives Security, System, Application events |
| Filebeat Integration | Active | Receives Kali Linux logs |
| Kibana Integration | Active | Provides dashboards and visualization |
| Persistence | Enabled | Docker volumes preserve data |
| Detection Support | Active | Enables KQL searches and dashboards |

---

## 13. Summary

Elasticsearch 8.14.0 serves as the central log repository for the Nation-State Lab. It collects telemetry from Windows and Linux systems, stores events in searchable indices, and powers Kibana dashboards used for threat hunting, incident response, attack detection, and security monitoring.

The deployment uses Docker containers with persistent storage, reduced memory allocation, and host-only network exposure, making it suitable for a low-resource cybersecurity laboratory while maintaining enterprise-style log management capabilities.