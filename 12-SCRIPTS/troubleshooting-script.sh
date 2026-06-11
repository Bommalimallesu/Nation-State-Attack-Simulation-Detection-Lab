#!/bin/bash
# troubleshooting-script.sh – Nation‑State Lab
# Run on Ubuntu monitoring host (192.168.1.100) to diagnose common issues.
# Use: chmod +x troubleshooting-script.sh && sudo ./troubleshooting-script.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Nation‑State Lab Troubleshooting Tool  ${NC}"
echo -e "${GREEN}========================================${NC}"

# 1. Check Docker containers
echo -e "\n${YELLOW}[1] Docker Containers Status${NC}"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "elasticsearch|kibana|NAME"

# 2. Elasticsearch health
echo -e "\n${YELLOW}[2] Elasticsearch Health${NC}"
ES_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.1.100:9200)
if [ "$ES_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Elasticsearch is reachable (HTTP 200)${NC}"
    curl -s http://192.168.1.100:9200/_cluster/health?pretty | grep -E "status|number_of_nodes"
else
    echo -e "${RED}✗ Elasticsearch not responding (HTTP $ES_HEALTH)${NC}"
fi

# 3. Kibana health
echo -e "\n${YELLOW}[3] Kibana Health${NC}"
KIBANA_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.1.100:5601)
if [ "$KIBANA_HEALTH" = "302" ] || [ "$KIBANA_HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Kibana is reachable (HTTP $KIBANA_HEALTH)${NC}"
else
    echo -e "${RED}✗ Kibana not responding (HTTP $KIBANA_HEALTH)${NC}"
fi

# 4. Docker logs (last 5 lines of each)
echo -e "\n${YELLOW}[4] Docker Logs (last 5 lines)${NC}"
for CONTAINER in elasticsearch kibana; do
    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER$"; then
        echo -e "${GREEN}--- $CONTAINER ---${NC}"
        docker logs $CONTAINER --tail 5
    else
        echo -e "${RED}Container $CONTAINER not found${NC}"
    fi
done

# 5. Firewall status
echo -e "\n${YELLOW}[5] Firewall (UFW) Status${NC}"
sudo ufw status | grep -E "Status|9200|5601|22"

# 6. Disk space
echo -e "\n${YELLOW}[6] Disk Space (root)${NC}"
df -h / | tail -1

# 7. Memory usage
echo -e "\n${YELLOW}[7] Memory Usage${NC}"
free -h

# 8. Network connectivity to critical hosts
echo -e "\n${YELLOW}[8] Network Connectivity${NC}"
for HOST in 192.168.1.10 192.168.1.20 192.168.1.50 192.168.1.60; do
    if ping -c 1 -W 1 $HOST &>/dev/null; then
        echo -e "${GREEN}✓ $HOST reachable${NC}"
    else
        echo -e "${RED}✗ $HOST unreachable${NC}"
    fi
done

# 9. Winlogbeat indices in Elasticsearch
echo -e "\n${YELLOW}[9] Winlogbeat Indices${NC}"
WINLOGBEAT_INDICES=$(curl -s "http://192.168.1.100:9200/_cat/indices/winlogbeat-*?h=index" | wc -l)
if [ "$WINLOGBEAT_INDICES" -gt 0 ]; then
    echo -e "${GREEN}✓ Found $WINLOGBEAT_INDICES winlogbeat index(es)${NC}"
else
    echo -e "${RED}✗ No winlogbeat indices found${NC}"
fi

# 10. Velociraptor server status (if installed)
if systemctl list-units --full -all | grep -q "velociraptor-server.service"; then
    echo -e "\n${YELLOW}[10] Velociraptor Server Status${NC}"
    sudo systemctl is-active velociraptor-server && echo -e "${GREEN}✓ Velociraptor running${NC}" || echo -e "${RED}✗ Velociraptor stopped${NC}"
else
    echo -e "\n${YELLOW}[10] Velociraptor not installed (skipped)${NC}"
fi

# 11. Docker network inspection
echo -e "\n${YELLOW}[11] Docker Network 'elastic'${NC}"
if docker network inspect elastic &>/dev/null; then
    echo -e "${GREEN}✓ Network 'elastic' exists${NC}"
    CONNECTED_CONTAINERS=$(docker network inspect elastic -f '{{range .Containers}}{{.Name}} {{end}}')
    echo -e "   Connected containers: $CONNECTED_CONTAINERS"
else
    echo -e "${RED}✗ Network 'elastic' not found${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Troubleshooting completed. Review output above.${NC}"
echo -e "${GREEN}========================================${NC}"