```bash
#!/bin/bash
#
# install-docker-elastic.sh
# Nation-State Lab
#
# Purpose:
# Deploy Elasticsearch and Kibana on the Ubuntu Monitoring Server
# using Docker containers.
#
# Host:
# Ubuntu Server 22.04 LTS
# IP Address: 192.168.1.100
#
# Components:
# - Docker Engine
# - Elasticsearch 8.14.0
# - Kibana 8.14.0
#

set -euo pipefail

ELASTIC_VERSION="8.14.0"
HOST_IP="192.168.1.100"

echo "================================================="
echo " Nation-State Lab - Elastic Stack Deployment"
echo "================================================="
echo

# -------------------------------------------------
# Root Check
# -------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root:"
    echo "    sudo ./install-docker-elastic.sh"
    exit 1
fi

# -------------------------------------------------
# Docker Installation
# -------------------------------------------------

echo "[*] Checking Docker installation..."

if ! command -v docker >/dev/null 2>&1; then
    echo "[*] Docker not found. Installing Docker..."

    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    systemctl enable docker
    systemctl start docker

    rm -f get-docker.sh

    echo "[+] Docker installed successfully."
else
    echo "[+] Docker already installed."
fi

# -------------------------------------------------
# Create Docker Network
# -------------------------------------------------

echo
echo "[*] Creating Docker network..."

docker network create elastic >/dev/null 2>&1 || true

echo "[+] Network 'elastic' ready."

# -------------------------------------------------
# Create Persistent Volumes
# -------------------------------------------------

echo
echo "[*] Creating Docker volumes..."

docker volume create elasticsearch-data >/dev/null
docker volume create kibana-data >/dev/null

echo "[+] Persistent volumes ready."

# -------------------------------------------------
# Pull Images
# -------------------------------------------------

echo
echo "[*] Pulling Elastic Stack images..."

docker pull docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
docker pull docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}

echo "[+] Images downloaded."

# -------------------------------------------------
# Remove Existing Containers
# -------------------------------------------------

echo
echo "[*] Cleaning previous deployment..."

docker stop elasticsearch kibana >/dev/null 2>&1 || true
docker rm elasticsearch kibana >/dev/null 2>&1 || true

echo "[+] Cleanup completed."

# -------------------------------------------------
# Deploy Elasticsearch
# -------------------------------------------------

echo
echo "[*] Starting Elasticsearch..."

docker run -d \
  --name elasticsearch \
  --network elastic \
  --restart unless-stopped \
  -p ${HOST_IP}:9200:9200 \
  -p ${HOST_IP}:9300:9300 \
  -e discovery.type=single-node \
  -e xpack.security.enabled=false \
  -e ES_JAVA_OPTS="-Xms512m -Xmx512m" \
  -v elasticsearch-data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}

echo "[*] Waiting for Elasticsearch startup..."
sleep 30

# -------------------------------------------------
# Elasticsearch Verification
# -------------------------------------------------

echo
echo "[*] Verifying Elasticsearch..."

if curl -s "http://${HOST_IP}:9200" >/dev/null; then
    echo "[+] Elasticsearch is reachable."
else
    echo "[!] Elasticsearch verification failed."
    docker logs elasticsearch
    exit 1
fi

# -------------------------------------------------
# Deploy Kibana
# -------------------------------------------------

echo
echo "[*] Starting Kibana..."

docker run -d \
  --name kibana \
  --network elastic \
  --restart unless-stopped \
  -p ${HOST_IP}:5601:5601 \
  -e ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
  -e XPACK_SECURITY_ENABLED=false \
  -v kibana-data:/usr/share/kibana/data \
  docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}

echo "[*] Waiting for Kibana startup..."
sleep 30

# -------------------------------------------------
# Kibana Verification
# -------------------------------------------------

echo
echo "[*] Verifying Kibana..."

if curl -s "http://${HOST_IP}:5601" >/dev/null; then
    echo "[+] Kibana is reachable."
else
    echo "[!] Kibana may still be starting."
    echo "    Check with: docker logs kibana"
fi

# -------------------------------------------------
# Deployment Summary
# -------------------------------------------------

echo
echo "================================================="
echo " Elastic Stack Deployment Complete"
echo "================================================="
echo
echo "Elasticsearch:"
echo "  http://${HOST_IP}:9200"
echo
echo "Kibana:"
echo "  http://${HOST_IP}:5601"
echo
echo "Useful Commands:"
echo "  docker ps"
echo "  docker logs elasticsearch"
echo "  docker logs kibana"
echo "  docker restart elasticsearch"
echo "  docker restart kibana"
echo
echo "Status: SUCCESS"
echo
```
