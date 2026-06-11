# Performance Optimization – Nation-State Lab

This document provides practical tuning recommendations to reduce resource consumption, improve response times, and ensure stable operation of the Nation-State Lab on limited hardware (for example, a host with 16 GB RAM and an Ubuntu monitoring VM with 4 GB RAM).

---

# 1. Elasticsearch & Kibana (Docker)

## 1.1 Heap Size (`ES_JAVA_OPTS`)

| Scenario                | Recommended Heap    | Configuration                                       |
| ----------------------- | ------------------- | --------------------------------------------------- |
| Ubuntu VM with 4 GB RAM | `-Xms512m -Xmx512m` | Add `-e "ES_JAVA_OPTS=-Xms512m -Xmx512m"` to Docker |
| Ubuntu VM with 2 GB RAM | `-Xms256m -Xmx256m` | Lower memory usage, slower indexing                 |
| Host with 8+ GB RAM     | `-Xms1g -Xmx1g`     | Suitable for larger labs                            |

### Verify Current Heap Usage

```bash
curl -s "http://192.168.1.100:9200/_nodes/stats/jvm?pretty" | grep heap_used
```

---

## 1.2 Index Retention (Disk Space Management)

Delete old indices regularly to prevent storage exhaustion.

### View Existing Indices

```bash
curl -s "http://192.168.1.100:9200/_cat/indices/winlogbeat-*?h=index"
```

### Delete Old Index

```bash
curl -X DELETE "http://192.168.1.100:9200/winlogbeat-2026.06.01"
```

### Kibana Method

```text
Stack Management
└── Index Management
    └── Select old winlogbeat-* indices
        └── Delete
```

---

## 1.3 Docker Resource Limits

### Elasticsearch

```bash
docker update --memory=1g --cpus=1 elasticsearch
```

### Kibana

```bash
docker update --memory=512m --cpus=1 kibana
```

---

## 1.4 Disable Unused Elasticsearch Features

```bash
-e "xpack.monitoring.collection.enabled=false"
-e "xpack.watcher.enabled=false"
-e "xpack.ml.enabled=false"
```

---

# 2. Winlogbeat (Windows Systems)

## 2.1 Reduce Event Throughput

```yaml
queue.mem:
  events: 4096
  flush.min_events: 1024
  flush.timeout: 5s

max_procs: 1
```

---

## 2.2 Ignore Noisy Event IDs

Example: Exclude Event ID 4624.

```yaml
winlogbeat.event_logs:
  - name: Security
    query: 'Event/System[EventID != 4624]'
```

---

## 2.3 Reduce Log Retention

```yaml
logging.files:
  keepfiles: 3
```

---

## 2.4 Lower Event Rate for Slow Networks

```yaml
queue.mem:
  events: 2048
  flush.min_events: 512
```

---

# 3. Filebeat (Kali Linux)

## 3.1 Limit CPU and Memory Usage

```yaml
max_procs: 1

queue.mem:
  events: 2048
  flush.min_events: 512
```

---

## 3.2 Reduce Harvested Logs

```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/syslog
      - /var/log/auth.log
```

---

## 3.3 Lower Service Priority

Edit the Filebeat service file:

```ini
[Service]
Nice=10
CPUSchedulingPolicy=idle
```

Reload the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart filebeat
```

---

# 4. Velociraptor Server

## 4.1 Limit Resource Usage

Create a systemd override:

```ini
[Service]
CPUQuota=50%
MemoryMax=1G
```

---

## 4.2 Restart Service

```bash
sudo systemctl daemon-reload
sudo systemctl restart velociraptor-server
```

---

## 4.3 Optimize Datastore Location

```yaml
datastore:
  location: /fast-disk/velociraptor/datastore
```

Prefer SSD storage whenever possible.

---

# 5. Windows VMs (DC, WS1, FILESERVER, WEBSERVER)

## 5.1 Reduce Audit Log Volume

Disable unnecessary file-share auditing:

```cmd
auditpol /set /subcategory:"Detailed File Share" /success:disable /failure:disable
auditpol /set /subcategory:"File Share" /success:disable /failure:disable
```

---

## 5.2 Reduce Event Generation

Use Group Policy to disable unnecessary audit subcategories.

Examples:

* File Share Auditing
* Detailed Tracking
* Other Object Access Events

---

## 5.3 Disable Unnecessary Services

Examples:

* Print Spooler
* Windows Search
* Connected User Experiences and Telemetry

---

# 6. Ubuntu Monitoring VM

## 6.1 CPU Governor

Install CPU frequency tools:

```bash
sudo apt update
sudo apt install cpufrequtils
```

Set governor:

```bash
sudo cpufreq-set -g powersave
```

---

## 6.2 Disable Unused Services

```bash
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
```

---

## 6.3 Configure Swap Space

### Create Swap File

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Persist After Reboot

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Verify:

```bash
swapon --show
```

---

## 6.4 Configure Docker Log Rotation

Edit:

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker:

```bash
sudo systemctl restart docker
```

---

# 7. VMware Optimization

## Recommended Resource Allocation

| Component    | Recommendation    |
| ------------ | ----------------- |
| Total VM RAM | 12–14 GB          |
| Storage      | SSD Preferred     |
| CPU Cores    | 6–8 Logical Cores |

---

## Disable Hyper-V (Windows Host)

```cmd
bcdedit /set hypervisorlaunchtype off
```

Reboot the host afterward.

---

# 8. Monitoring Performance

## Docker Resource Usage

```bash
docker stats elasticsearch kibana
```

---

## Elasticsearch Node Statistics

```bash
curl -s "http://192.168.1.100:9200/_nodes/stats?pretty"
```

---

## System Resource Monitoring

```bash
htop
```

```bash
free -h
```

```bash
df -h
```

---

# 9. Common Optimization Issues

| Issue              | Cause                      | Resolution                        |
| ------------------ | -------------------------- | --------------------------------- |
| OOM Error          | Insufficient memory        | Increase RAM or reduce heap size  |
| High CPU Usage     | Excessive event generation | Reduce event collection           |
| Slow Kibana        | Large indices              | Delete old indices                |
| Disk Full          | Log accumulation           | Enable log rotation and retention |
| Slow Elasticsearch | Heap too small             | Increase heap cautiously          |

---

# 10. Recommended Configuration Summary

## Ubuntu Monitoring VM

| Setting      | Recommended Value |
| ------------ | ----------------- |
| RAM          | 4 GB              |
| Swap         | 2 GB              |
| CPU Governor | powersave         |

### Elasticsearch

| Setting      | Value  |
| ------------ | ------ |
| Heap Size    | 512 MB |
| CPU Limit    | 1 CPU  |
| Memory Limit | 1 GB   |

### Kibana

| Setting      | Value  |
| ------------ | ------ |
| Memory Limit | 512 MB |
| CPU Limit    | 1 CPU  |

### Winlogbeat

| Setting       | Value |
| ------------- | ----- |
| Queue Size    | 2048  |
| Flush Events  | 512   |
| Max Processes | 1     |

### Velociraptor

| Setting      | Value |
| ------------ | ----- |
| Memory Limit | 1 GB  |
| CPU Quota    | 50%   |

### Docker Logging

| Setting      | Value |
| ------------ | ----- |
| Max Log Size | 10 MB |
| Max Files    | 3     |

---

# 11. Conclusion

Apply performance optimizations gradually and monitor resource utilization after each change.

### Primary Objectives

* Maintain Elasticsearch stability
* Prevent out-of-memory conditions
* Reduce unnecessary log volume
* Preserve disk space
* Ensure Kibana remains responsive
* Keep the cybersecurity lab usable on limited hardware

Continuous monitoring and incremental tuning provide the best balance between visibility and performance.
