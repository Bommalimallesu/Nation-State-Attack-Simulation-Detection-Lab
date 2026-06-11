#!/bin/bash
# lab-setup.sh – Nation‑State Lab
# Complete setup script for the monitoring host (Ubuntu 22.04)
# Deploys Elasticsearch + Kibana using Docker, configures firewall, and prepares the environment.

set -e

# Color output for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] Starting Nation‑State Lab setup on Ubuntu...${NC}"

# 1. Update system and install prerequisites
echo -e "${YELLOW}[1/7] Updating system and installing prerequisites...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git ufw apt-transport-https ca-certificates software-properties-common

# 2. Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}[2/7] Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    newgrp docker
else
    echo -e "${GREEN}[2/7] Docker already installed.${NC}"
fi

# 3. Create Docker network for Elastic stack
echo -e "${YELLOW}[3/7] Creating Docker network 'elastic'...${NC}"
docker network create elastic 2>/dev/null || echo "Network 'elastic' already exists."

# 4. Remove any existing containers (clean start)
echo -e "${YELLOW}[4/7] Removing old Elasticsearch/Kibana containers (if any)...${NC}"
docker stop elasticsearch kibana 2>/dev/null || true
docker rm elasticsearch kibana 2>/dev/null || true

# 5. Deploy Elasticsearch container
echo -e "${YELLOW}[5/7] Starting Elasticsearch container...${NC}"
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

# 6. Wait for Elasticsearch to be ready
echo -e "${YELLOW}[6/7] Waiting 20 seconds for Elasticsearch to initialise...${NC}"
sleep 20

# 7. Deploy Kibana container
echo -e "${YELLOW}[7/7] Starting Kibana container...${NC}"
docker run -d \
  --name kibana \
  --network elastic \
  -p 192.168.1.100:5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  -e "XPACK_SECURITY_ENABLED=false" \
  -v kibana-data:/usr/share/kibana/data \
  docker.elastic.co/kibana/kibana:8.14.0

# 8. Configure firewall (allow necessary ports)
echo -e "${YELLOW}[*] Configuring firewall (UFW)...${NC}"
sudo ufw allow 22/tcp          # SSH (if needed)
sudo ufw allow 9200/tcp        # Elasticsearch
sudo ufw allow 5601/tcp        # Kibana
sudo ufw --force enable

# 9. Set static IP reminder (manual step)
echo -e "${GREEN}[*] Setup completed!${NC}"
echo -e "${GREEN}    Elasticsearch: http://192.168.1.100:9200${NC}"
echo -e "${GREEN}    Kibana: http://192.168.1.100:5601${NC}"
echo -e "${YELLOW}Note: Ensure your Ubuntu VM has static IP 192.168.1.100 configured (e.g., via /etc/netplan).${NC}"
echo -e "${YELLOW}To verify containers: docker ps${NC}"