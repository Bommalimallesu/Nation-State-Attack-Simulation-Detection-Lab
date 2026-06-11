```bash
#!/bin/bash
#
# install-kali-tools.sh
# Nation-State Lab
#
# Purpose:
# Install the primary lab tools used for security testing,
# network analysis, Active Directory assessment, and research.
#
# Tested on:
# Kali Linux 2025.x
#

set -euo pipefail

echo "========================================"
echo " Nation-State Lab - Kali Tool Installer "
echo "========================================"
echo

# Verify root privileges
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root:"
    echo "    sudo ./install-kali-tools.sh"
    exit 1
fi

echo "[*] Updating repositories..."
apt update

echo "[*] Upgrading installed packages..."
apt upgrade -y

echo "[*] Installing core packages..."
apt install -y \
    metasploit-framework \
    impacket-scripts \
    bloodhound \
    neo4j \
    hydra \
    nmap \
    responder \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    unzip \
    net-tools

echo
echo "[*] Installing MITRE Caldera..."

mkdir -p /opt
cd /opt

if [ ! -d "/opt/caldera" ]; then
    git clone -b v4.14.5 https://github.com/mitre/caldera.git --recursive
fi

cd /opt/caldera

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

echo
echo "[*] Creating Caldera systemd service..."

cat > /etc/systemd/system/caldera.service << 'EOF'
[Unit]
Description=MITRE Caldera
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/caldera
ExecStart=/opt/caldera/venv/bin/python3 /opt/caldera/server.py --insecure
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable caldera

echo
echo "[*] Checking Docker installation..."

if ! command -v docker >/dev/null 2>&1; then
    echo "[*] Docker not found. Installing Docker..."
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
fi

echo
echo "[*] Pulling BloodHound Community Edition container..."

docker pull specterops/bloodhound:latest

if ! docker ps -a --format '{{.Names}}' | grep -q "^bloodhound$"; then
    docker run -d \
        --name bloodhound \
        -p 8080:8080 \
        -p 7474:7474 \
        specterops/bloodhound:latest
fi

echo
echo "========================================"
echo " Installation Complete"
echo "========================================"
echo
echo "Installed Components:"
echo "  - Metasploit Framework"
echo "  - Impacket"
echo "  - BloodHound"
echo "  - Neo4j"
echo "  - Hydra"
echo "  - Nmap"
echo "  - Responder"
echo "  - MITRE Caldera"
echo "  - Python3 / Pip / Venv"
echo
echo "Caldera Service:"
echo "  sudo systemctl start caldera"
echo "  sudo systemctl status caldera"
echo
echo "BloodHound:"
echo "  http://localhost:8080"
echo
echo "Done."
```
