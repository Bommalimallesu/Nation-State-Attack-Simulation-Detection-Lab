# Kibana Installation & Configuration – Nation-State Lab

## 1. Overview

Kibana (version 8.14.0) is the visualisation and dashboard interface for the Elastic Stack. It runs as a Docker container on the Ubuntu monitoring host (`192.168.1.100`) and connects to the Elasticsearch container to index and query logs collected from Winlogbeat (Windows VMs) and Filebeat (Kali Linux).

Kibana is used to:

- Create index patterns (`winlogbeat-*`, `filebeat-*`)
- Build a professional security dashboard
- Define detection rules
- Investigate events in real time during attack simulations

All components are isolated in a host-only network. Kibana is accessible from:

`http://192.168.1.100:5601`

---

## 2. Prerequisites

| Requirement | Status | Details |
|------------|---------|---------|
| Docker Engine | ✅ Installed | Version 27.x on Ubuntu 22.04 |
| Docker Network | ✅ Created | `docker network create elastic` |
| Elasticsearch | ✅ Running | Version 8.14.0 |
| Port 5601 | ✅ Opened | Bound to host IP |

No additional dependencies are required because Kibana runs entirely inside Docker.

---

## 3. Kibana Container Deployment

Start Kibana using Docker:

```bash
docker run -d \
  --name kibana \
  --network elastic \
  -p 192.168.1.100:5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  -e "XPACK_SECURITY_ENABLED=false" \
  docker.elastic.co/kibana/kibana:8.14.0
```

### Parameter Explanation

| Parameter | Value | Purpose |
|------------|---------|---------|
| `--name` | kibana | Container name |
| `--network` | elastic | Docker network |
| `-p` | 192.168.1.100:5601:5601 | Expose Kibana |
| `ELASTICSEARCH_HOSTS` | http://elasticsearch:9200 | Elasticsearch endpoint |
| `XPACK_SECURITY_ENABLED` | false | Disable authentication |

---

## 4. Verification

Check container status:

```bash
docker ps | grep kibana
```

Test connectivity:

```bash
curl -I http://192.168.1.100:5601
```

Expected response:

```text
HTTP/1.1 200 OK
```

---

## 5. Initial Setup

1. Open Kibana in browser.
2. Click **Explore on my own**.
3. Skip sample data.
4. Create index patterns.
5. Set default time range.

---

## 6. Create Index Patterns

### Winlogbeat

1. Navigate to:

```text
Management → Stack Management → Index Patterns
```

2. Click **Create Index Pattern**.

3. Enter:

```text
winlogbeat-*
```

4. Select:

```text
@timestamp
```

5. Save.

### Filebeat

Repeat the same process using:

```text
filebeat-*
```

---

## 7. Dashboard Configuration

### Active Agents

- Visualization: Metric
- Aggregation: Unique Count
- Field: `agent.hostname`

### Failed Logons

KQL:

```kql
winlog.event_id: 4625
```

### Suspicious Activity

KQL:

```kql
winlog.event_id: 4688 OR winlog.event_id: 7045
```

### Top Agents

- Visualization: Horizontal Bar Chart
- Metric: Count
- Field: `agent.hostname`

### Security Events Timeline

- Visualization: Bar Chart
- X-Axis: `@timestamp`
- Aggregation: Date Histogram

### Recent Events

Columns:

```text
@timestamp
agent.hostname
winlog.event_id
message
```

Dashboard Name:

```text
My Security Lab – Main Dashboard
```

Auto Refresh:

```text
5 Seconds
```

---

## 8. Detection Rules

### Reverse Shell Detection

Name:

```text
Detect Reverse Shell (shell.exe)
```

Index:

```text
winlogbeat-*
```

KQL:

```kql
winlog.event_id: 4688 AND process.executable: *shell.exe
```

Schedule:

```text
Every 5 Minutes
```

Threshold:

```text
Count > 0
```

---

## 9. Troubleshooting

| Issue | Cause | Resolution |
|---------|---------|---------|
| Connection Refused | Kibana stopped | Start container |
| No Data | Missing index pattern | Create index pattern |
| Dashboard Missing | Volume not mounted | Use persistent volume |
| Slow Performance | Low memory | Increase RAM |

Check logs:

```bash
docker logs kibana
```

Restart Kibana:

```bash
docker restart kibana
```

---

## 10. Persistent Storage

Create volume:

```bash
docker volume create kibana-data
```

Mount volume:

```bash
-v kibana-data:/usr/share/kibana/data
```

Export dashboards:

```text
Management → Stack Management → Saved Objects → Export
```

---

## 11. Attack Chain Visibility

| Attack Phase | Query | Expected Event |
|-------------|--------|---------------|
| Reconnaissance | `message: nmap` | Filebeat Event |
| Reverse Shell | `process.executable: shell.exe` | Event 4688 |
| Scheduled Task | `winlog.event_id: 4698` | Persistence |
| Mimikatz | `process.name: mimikatz.exe` | Credential Theft |
| Pass-the-Hash | `winlog.event_data.LogonType: 3` | Lateral Movement |

---

## 12. Summary

| Component | Status | Details |
|------------|---------|---------|
| Deployment | ✅ | Docker Container |
| Index Patterns | ✅ | winlogbeat-* and filebeat-* |
| Dashboard | ✅ | Security Dashboard |
| Detection Rules | ✅ | Custom Rules |
| Persistent Storage | ✅ | Docker Volume |
| Elasticsearch Connectivity | ✅ | Verified |

Kibana served as the central visualisation platform for the Nation-State Lab, providing dashboards, alerting, event investigation, and attack monitoring capabilities.