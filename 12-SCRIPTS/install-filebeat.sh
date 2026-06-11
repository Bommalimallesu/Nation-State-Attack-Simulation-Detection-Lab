#!/bin/bash
# install-filebeat.sh – Install and configure Filebeat on Kali Linux
# Forwards /var/log/syslog to Elasticsearch (192.168.1.100:9200)

set -e

ELASTICSEARCH_HOST="192.168.1.100"
ELASTICSEARCH_PORT="9200"
FILEBEAT_VERSION="8.8.0"

echo "[+] Installing Filebeat on Kali..."

# Download and install Filebeat (if not already installed)
if ! command -v filebeat &> /dev/null; then
    echo "[+] Downloading Filebeat ${FILEBEAT_VERSION}..."
    wget -q "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb" -O /tmp/filebeat.deb
    sudo dpkg -i /tmp/filebeat.deb
    rm /tmp/filebeat.deb
else
    echo "[+] Filebeat already installed."
fi

# Backup original config
sudo cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak 2>/dev/null || true

# Configure Filebeat
echo "[+] Configuring Filebeat..."

sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/syslog
  fields:
    host.name: "${HOSTNAME:-kali}"
  fields_under_root: true

output.elasticsearch:
  hosts: ["${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]

setup.kibana:
  host: "http://${ELASTICSEARCH_HOST}:5601"

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
EOF

# Enable and start Filebeat
echo "[+] Enabling and starting Filebeat..."
sudo systemctl enable filebeat
sudo systemctl start filebeat

# Verify status
if systemctl is-active --quiet filebeat; then
    echo "[+] Filebeat is running."
else
    echo "[-] Filebeat failed to start. Check logs: sudo journalctl -u filebeat -f"
    exit 1
fi

# Test output connectivity
echo "[+] Testing connection to Elasticsearch..."
if filebeat test output | grep -q "Connection: OK"; then
    echo "[+] Filebeat can reach Elasticsearch."
else
    echo "[-] Filebeat cannot reach Elasticsearch. Check IP and firewall."
    filebeat test output
fi

echo ""
echo "========================================="
echo "Filebeat installation complete."
echo "Logs are being forwarded to ${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"
echo "View Filebeat logs: sudo journalctl -u filebeat -f"
echo "========================================="

exit 0