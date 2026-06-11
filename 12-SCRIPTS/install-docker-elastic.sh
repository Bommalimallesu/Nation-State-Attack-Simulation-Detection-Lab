#!/bin/bash
# install-docker-elastic.sh
# Installs Docker, Docker Compose, and runs Elasticsearch + Kibana for the APT lab.

set -e

# Configuration
ELASTIC_VERSION="8.8.0"
ES_PORT="9200"
KIBANA_PORT="5601"
KIBANA_HOST="192.168.1.100"   # Change to your host IP
MEM_LIMIT="4g"
COMPOSE_DIR="/opt/elastic-lab"

echo "[+] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "[+] Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "[+] Docker installed. You may need to log out and back in for group changes."
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "[+] Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
fi

# Create directory for docker-compose
sudo mkdir -p $COMPOSE_DIR
sudo chown $USER:$USER $COMPOSE_DIR
cd $COMPOSE_DIR

# Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - "${ES_PORT}:9200"
    networks:
      - elastic
    restart: unless-stopped

  kibana:
    image: docker.elastic.co/kibana/kibana:${ELASTIC_VERSION}
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - SERVER_HOST=0.0.0.0
    ports:
      - "${KIBANA_PORT}:5601"
    networks:
      - elastic
    depends_on:
      - elasticsearch
    restart: unless-stopped

volumes:
  es_data:

networks:
  elastic:
    driver: bridge
EOF

echo "[+] Starting Elasticsearch and Kibana via Docker Compose..."
docker compose up -d

# Wait for Elasticsearch to be ready
echo "[+] Waiting for Elasticsearch to start (up to 60s)..."
for i in {1..60}; do
    if curl -s "http://localhost:${ES_PORT}/_cluster/health" | grep -q '"status":"green\|yellow"'; then
        echo "[+] Elasticsearch is ready."
        break
    fi
    sleep 1
done

# Wait for Kibana
echo "[+] Waiting for Kibana to start (up to 90s)..."
for i in {1..90}; do
    if curl -s "http://localhost:${KIBANA_PORT}/api/status" | grep -q '"level":"available"'; then
        echo "[+] Kibana is ready."
        break
    fi
    sleep 1
done

echo ""
echo "========================================="
echo "Elastic Stack is running!"
echo "Elasticsearch: http://localhost:${ES_PORT}"
echo "Kibana: http://${KIBANA_HOST}:${KIBANA_PORT}"
echo ""
echo "To check logs: docker compose logs -f"
echo "To stop: docker compose down"
echo "========================================="

# Optional: install Winlogbeat on this host? Not included.
exit 0