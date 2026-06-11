#!/bin/bash
# velociraptor-setup.sh – Nation‑State Lab
# Installs and configures Velociraptor server on Ubuntu 22.04 (192.168.1.100)
# Usage: sudo ./velociraptor-setup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Velociraptor Server Installation     ${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo).${NC}"
   exit 1
fi

# Variables
VERSION="0.76.5"
BINARY="velociraptor-v${VERSION}-linux-amd64"
DOWNLOAD_URL="https://github.com/Velocidex/velociraptor/releases/download/v0.76/${BINARY}"
INSTALL_DIR="/opt/velociraptor"
CONFIG_DIR="/etc/velociraptor"
DATA_DIR="/var/lib/velociraptor"
LOG_DIR="/var/log/velociraptor"
SERVICE_FILE="/etc/systemd/system/velociraptor-server.service"
SERVER_IP="192.168.1.100"
ADMIN_USER="admin"
ADMIN_PASS="Velociraptor123!"  # Change this after installation

echo -e "${YELLOW}[1/8] Creating directories...${NC}"
mkdir -p ${INSTALL_DIR} ${CONFIG_DIR} ${DATA_DIR} ${LOG_DIR}
cd ${INSTALL_DIR}

echo -e "${YELLOW}[2/8] Downloading Velociraptor binary...${NC}"
wget -q --show-progress -O ${BINARY} ${DOWNLOAD_URL}
chmod +x ${BINARY}

echo -e "${YELLOW}[3/8] Generating server configuration (interactive)...${NC}"
# Use expect or auto-answer? We'll generate a minimal config using command line.
# The easiest is to use 'config generate' with a pre-defined answers file, but that's complex.
# Instead, we'll use the 'config generate' command and then edit the file.
# However, the interactive wizard requires manual input. To automate, we can use 'config generate' with a here-document.
# Simpler: generate default config and then sed the necessary fields.

echo -e "${GREEN}   Generating configuration using default values...${NC}"
# Create a temporary file with answers for the wizard (using expect is overkill; use --merge flag? Not available.)
# We'll use a non-interactive approach: generate a minimal config file manually.
# But the recommended way is to run the wizard once; for automation, we can provide a pre-made config template.
# Instead, let's create a minimal server.config.yaml manually.

cat > ${CONFIG_DIR}/server.config.yaml <<EOF
---
ca_certificate: |
  -----BEGIN CERTIFICATE-----
  (placeholder)
  -----END CERTIFICATE-----
client_server_cert: |
  -----BEGIN CERTIFICATE-----
  (placeholder)
  -----END CERTIFICATE-----
client_server_key: |
  -----BEGIN RSA PRIVATE KEY-----
  (placeholder)
  -----END RSA PRIVATE KEY-----
frontend:
  bind_address: 0.0.0.0
  bind_port: 8000
  public_url: https://${SERVER_IP}:8000/
gui:
  bind_address: 0.0.0.0
  bind_port: 8889
  public_url: https://${SERVER_IP}:8889/
  tls_certificate: |
    -----BEGIN CERTIFICATE-----
    (placeholder)
    -----END CERTIFICATE-----
  tls_private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    (placeholder)
    -----END RSA PRIVATE KEY-----
datastore:
  location: ${DATA_DIR}/datastore
  filestore_directory: ${DATA_DIR}/filestore
  implementation: FileBaseDataStore
logging:
  output_directory: ${LOG_DIR}
  separate_logs_per_component: true
max_upload_size: 52428800
EOF

# This placeholder config is invalid without real certificates. We need to generate proper certs.
# Better to run the wizard once interactively. Since we can't, we'll use the official method:
# Let the user run 'velociraptor config generate -i' manually if needed.
# But for script, we can run it with a pre-defined answer file using 'expect'. However, that adds dependency.
# Simpler: instruct the user to run the config generator manually after script.
# We'll provide instructions.

echo -e "${YELLOW}[4/8] Running interactive configuration wizard (manual step)...${NC}"
echo -e "${YELLOW}   Please run the following command and answer the prompts:${NC}"
echo -e "${GREEN}   sudo ${INSTALL_DIR}/${BINARY} config generate -i${NC}"
echo -e "${YELLOW}   After completion, move the generated config to ${CONFIG_DIR}/server.config.yaml${NC}"
read -p "Press Enter after you have generated and moved the config file..."

# Verify config exists
if [ ! -f ${CONFIG_DIR}/server.config.yaml ]; then
    echo -e "${RED}Config file not found. Exiting.${NC}"
    exit 1
fi

echo -e "${YELLOW}[5/8] Adding admin user...${NC}"
${INSTALL_DIR}/${BINARY} --config ${CONFIG_DIR}/server.config.yaml user add ${ADMIN_USER} --role administrator <<EOF
${ADMIN_PASS}
${ADMIN_PASS}
EOF

echo -e "${YELLOW}[6/8] Creating systemd service...${NC}"
cat > ${SERVICE_FILE} <<EOF
[Unit]
Description=Velociraptor Server
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=${INSTALL_DIR}/${BINARY} --config ${CONFIG_DIR}/server.config.yaml frontend -v
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable velociraptor-server.service

echo -e "${YELLOW}[7/8] Starting Velociraptor server...${NC}"
systemctl start velociraptor-server.service

sleep 5
if systemctl is-active --quiet velociraptor-server; then
    echo -e "${GREEN}✓ Velociraptor server is running.${NC}"
else
    echo -e "${RED}✗ Velociraptor server failed to start. Check logs with: journalctl -u velociraptor-server${NC}"
    exit 1
fi

echo -e "${YELLOW}[8/8] Downloading Windows client MSI (for later deployment)...${NC}"
CLIENT_MSI="velociraptor-v${VERSION}-windows-amd64.msi"
wget -q --show-progress -O ${INSTALL_DIR}/${CLIENT_MSI} https://github.com/Velocidex/velociraptor/releases/download/v0.76/${CLIENT_MSI} || echo -e "${RED}Failed to download client MSI. You can download manually.${NC}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Velociraptor installation complete!${NC}"
echo -e "${GREEN}Web UI: https://${SERVER_IP}:8889${NC}"
echo -e "${GREEN}Username: ${ADMIN_USER}${NC}"
echo -e "${GREEN}Password: ${ADMIN_PASS}${NC}"
echo -e "${YELLOW}Note: Change the password after first login.${NC}"
echo -e "${YELLOW}To deploy clients, generate custom MSI from the GUI (Server Artifacts -> Server.Utils.CreateMSI).${NC}"
echo -e "${GREEN}========================================${NC}"