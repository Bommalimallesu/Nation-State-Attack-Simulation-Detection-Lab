#!/bin/bash
# install-kali-tools.sh – Install required tools for APT simulation on Kali Linux

set -e

echo "[+] Updating package lists..."
sudo apt update -qq

echo "[+] Installing core tools..."
sudo apt install -y \
    metasploit-framework \
    impacket-scripts \
    nmap \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    netcat-traditional \
    net-tools \
    dos2unix \
    jq \
    file

# Install additional Python libraries
echo "[+] Installing Python libraries..."
pip3 install --user impacket pexpect requests

# Ensure msfvenom is available (part of metasploit-framework)
if command -v msfvenom &> /dev/null; then
    echo "[+] msfvenom found: $(msfvenom --version | head -1)"
else
    echo "[-] msfvenom not found. Reinstalling metasploit-framework..."
    sudo apt install --reinstall -y metasploit-framework
fi

# Ensure impacket scripts are in PATH
if command -v impacket-psexec &> /dev/null; then
    echo "[+] impacket-psexec found."
else
    echo "[!] impacket-psexec not found; you may need to add /usr/bin/ to PATH or reinstall impacket-scripts."
fi

# Start PostgreSQL (required for Metasploit)
echo "[+] Starting PostgreSQL for Metasploit..."
sudo systemctl enable postgresql --now 2>/dev/null || echo "[!] PostgreSQL not installed; Metasploit may still work."

# Optional: install Sysmon for Linux (if needed for logging)
read -p "Install Sysmon for Linux (optional, for advanced logging)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[+] Installing Sysmon for Linux..."
    # Download latest release
    SYSMON_URL=$(curl -s https://api.github.com/repos/Sysinternals/SysmonForLinux/releases/latest | grep -oP '"browser_download_url": "\K(.*sysmonforlinux-x64\.deb)' | head -1)
    if [ -n "$SYSMON_URL" ]; then
        wget -q "$SYSMON_URL" -O /tmp/sysmon.deb
        sudo dpkg -i /tmp/sysmon.deb
        rm /tmp/sysmon.deb
        echo "[+] Sysmon installed. Configure with: sudo sysmon -accepteula -i"
    else
        echo "[!] Could not download Sysmon. Install manually."
    fi
fi

echo ""
echo "========================================="
echo "Kali tools installation complete."
echo "Tools installed: msfconsole, msfvenom, impacket-* (psexec, wmiexec), nmap, python3, netcat, jq, etc."
echo ""
echo "Test commands:"
echo "  msfconsole --version"
echo "  impacket-psexec -h"
echo "  nmap -V"
echo "========================================="

exit 0