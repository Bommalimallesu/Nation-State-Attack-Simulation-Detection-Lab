# Filebeat Configuration – Nation-State Lab (Kali Linux)

## 1. Overview

Filebeat is a lightweight log shipper that forwards system logs from the Kali Linux attacker VM to the central Elasticsearch instance (`192.168.1.100:9200`).

It captures:

- `/var/log/syslog` – General system messages.
- `/var/log/auth.log` – Authentication events, sudo usage, and SSH logs.

This telemetry provides visibility into attacker actions and complements the Windows Security events collected by Winlogbeat.

---

## 2. Installation

Update package repositories:

```bash
sudo apt update
```

Install Filebeat:

```bash
sudo apt install filebeat -y
```

Verify installation:

```bash
filebeat version
```

Expected output:

```text
filebeat version 8.14.0
```

### Default Locations

| Component | Path |
|------------|------------|
| Installation Directory | `/usr/share/filebeat` |
| Configuration File | `/etc/filebeat/filebeat.yml` |
| Log Directory | `/var/log/filebeat` |
| Service Name | `filebeat` |

---

## 3. Configuration

Edit the configuration file:

```bash
sudo nano /etc/filebeat/filebeat.yml
```

Replace the contents with:

```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/syslog
      - /var/log/auth.log

    fields_under_root: true

    fields:
      agent.type: filebeat
      host.os: kali

output.elasticsearch:
  hosts:
    - "http://192.168.1.100:9200"

setup.kibana:
  host: "http://192.168.1.100:5601"

logging.level: info

logging.to_files: true

logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
```

---

## 4. Validate Configuration

Validate YAML syntax:

```bash
sudo filebeat test config
```

Expected output:

```text
Config OK
```

Test Elasticsearch connectivity:

```bash
sudo filebeat test output
```

---

## 5. Service Management

Enable Filebeat:

```bash
sudo systemctl enable filebeat
```

Start Filebeat:

```bash
sudo systemctl start filebeat
```

Check status:

```bash
sudo systemctl status filebeat
```

Expected output:

```text
Active: active (running)
```

---

## 6. Testing

Generate a test log:

```bash
logger "Filebeat test message from Kali"
```

Verify locally:

```bash
grep "Filebeat test message" /var/log/syslog
```

Verify Elasticsearch:

```bash
curl -X GET "http://192.168.1.100:9200/_cat/indices?v"
```

---

## 7. Kibana Verification

Open:

```text
http://192.168.1.100:5601
```

Create Data View:

```text
filebeat-*
```

Time Field:

```text
@timestamp
```

Navigate to Discover and search:

```text
Filebeat test
```

---

## 8. Troubleshooting

### Filebeat Service Fails

Check configuration:

```bash
sudo filebeat test config
```

### Elasticsearch Unreachable

Test connectivity:

```bash
curl http://192.168.1.100:9200
```

### Check Logs

```bash
sudo journalctl -u filebeat -f
```

---

## 9. Summary

| Component | Status |
|------------|------------|
| Installation | Complete |
| Configuration | Complete |
| Service | Running |
| Elasticsearch Connectivity | Verified |
| Kibana Integration | Verified |
| Attack Monitoring | Enabled |

Filebeat successfully forwards Kali Linux logs to Elasticsearch, enabling centralized monitoring of attacker activity alongside Windows Security events collected by Winlogbeat.