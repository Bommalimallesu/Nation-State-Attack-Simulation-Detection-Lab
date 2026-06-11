# Tools & Versions – Nation-State Lab

This document provides a complete inventory of all software tools used in the Nation-State Lab, including version numbers, installation locations, and primary purposes. Use this as a quick reference when troubleshooting or replicating the lab.

---

# 1. Monitoring & Logging Tools

| Tool                | Version | Installation Location (OS)             | Purpose                                       |
| ------------------- | ------- | -------------------------------------- | --------------------------------------------- |
| Elasticsearch       | 8.14.0  | Ubuntu 22.04 (Docker Container)        | Central log storage, indexing, and search     |
| Kibana              | 8.14.0  | Ubuntu 22.04 (Docker Container)        | Dashboard, visualization, and alerting        |
| Winlogbeat          | 8.14.0  | Windows (`C:\Winlogbeat`)              | Forwards Windows Event Logs to Elasticsearch  |
| Filebeat            | 8.14.0  | Kali Linux                             | Forwards syslog and auth.log to Elasticsearch |
| Velociraptor Server | 0.76.5  | Ubuntu (`/usr/local/bin/velociraptor`) | Central EDR and threat hunting platform       |
| Velociraptor Client | 0.76.5  | Windows (MSI)                          | Endpoint collection and response agent        |
| Sysmon *(Optional)* | 15.20   | Windows (`C:\Windows\System32`)        | Enhanced process, network, and file telemetry |

---

# 2. Attack & Red-Team Tools (Kali Linux)

| Tool                 | Version         | Installation Method                | Purpose                                   |
| -------------------- | --------------- | ---------------------------------- | ----------------------------------------- |
| Metasploit Framework | 6.4.133-dev     | `apt install metasploit-framework` | Exploitation and post-exploitation        |
| msfvenom             | Bundled         | Included with Metasploit           | Payload generation                        |
| Impacket             | 0.12.0          | `apt install impacket-scripts`     | SMB abuse, pass-the-hash, secrets dumping |
| Caldera              | 4.14.5          | Git source installation            | Adversary emulation platform              |
| BloodHound CE        | Latest          | Docker                             | Active Directory attack-path analysis     |
| Neo4j                | Bundled         | BloodHound container               | Graph database backend                    |
| Atomic Red Team      | Offline Package | Manual copy                        | ATT&CK technique validation               |
| Hydra                | 9.5             | Pre-installed                      | Credential attacks                        |
| Nmap                 | 7.94            | Pre-installed                      | Network reconnaissance                    |
| Responder            | 3.1.1.0         | Pre-installed                      | LLMNR/NBT-NS poisoning                    |
| curl                 | 7.88.1          | Pre-installed                      | HTTP transfers and API testing            |

---

# 3. Windows Agents & Utilities

| Tool                      | Version         | Installation Location           | Purpose                                   |
| ------------------------- | --------------- | ------------------------------- | ----------------------------------------- |
| Winlogbeat                | 8.14.0          | `C:\Winlogbeat`                 | Event log forwarding                      |
| Velociraptor Client       | 0.76.5          | `C:\Program Files\Velociraptor` | Endpoint hunting                          |
| Atomic Red Team           | Offline Package | `C:\AtomicRedTeam`              | Detection validation                      |
| PowerShell                | 5.1             | Built-in                        | Scripting and automation                  |
| schtasks                  | Built-in        | System                          | Scheduled task management                 |
| certutil                  | Built-in        | System                          | File downloads and certificate operations |
| net user / net localgroup | Built-in        | System                          | User and group administration             |

---

# 4. Ubuntu Monitoring Host Utilities

| Tool           | Version   | Installation Method          | Purpose                 |
| -------------- | --------- | ---------------------------- | ----------------------- |
| Docker         | 27.x      | Official installation script | Container runtime       |
| Docker Compose | v2 Plugin | Bundled with Docker          | Container orchestration |
| curl           | 7.81.0    | System package               | API testing             |
| wget           | 1.21.3    | System package               | File downloads          |
| git            | 2.34.1    | System package               | Repository management   |
| ufw            | 0.36.1    | System package               | Firewall management     |
| systemd        | 249.11    | Built-in                     | Service management      |

---

# 5. Development & Scripting Tools (Host PC)

| Tool                      | Version   | Purpose                          |
| ------------------------- | --------- | -------------------------------- |
| VMware Workstation Player | 17.x      | Hypervisor                       |
| AnyToISO / Folder2ISO     | Various   | Offline ISO creation             |
| VS Code / Notepad++       | Latest    | Configuration and script editing |
| PowerShell                | 5.1 / 7.x | Automation and deployment        |
| GitHub Desktop            | Latest    | Repository management            |

---

# 6. Version Verification

## 6.1 Elasticsearch & Kibana

```bash
# Elasticsearch
curl -s http://192.168.1.100:9200 | grep number

# Kibana
docker exec kibana cat /opt/kibana/package.json | grep version
```

## 6.2 Winlogbeat

```powershell
(Get-Item "C:\Winlogbeat\winlogbeat.exe").VersionInfo.ProductVersion
```

## 6.3 Filebeat

```bash
filebeat version
```

## 6.4 Velociraptor

```bash
/usr/local/bin/velociraptor --version
```

## 6.5 Caldera

```bash
cd ~/caldera
git describe --tags
```

## 6.6 Metasploit

```bash
msfconsole -q -x "version; exit"
```

---

# 7. Version Consistency Rules

| Component Pair               | Must Match   | Consequence of Mismatch          |
| ---------------------------- | ------------ | -------------------------------- |
| Elasticsearch ↔ Kibana       | Yes (8.14.x) | Dashboard and API errors         |
| Elasticsearch ↔ Winlogbeat   | Yes (8.14.x) | Template and indexing failures   |
| Elasticsearch ↔ Filebeat     | Yes (8.14.x) | Data ingestion failures          |
| Velociraptor Server ↔ Client | Yes (0.76.5) | Offline clients and failed hunts |
| Caldera Server ↔ Agent       | Yes (4.14.5) | Agent communication failures     |

---

# 8. Notes on Version Selection

### Elastic Stack 8.14.0

Chosen because it provided stable Beats compatibility and all required SIEM functionality.

### Velociraptor 0.76.5

Selected due to stable MSI generation and mature hunting capabilities.

### Caldera 4.14.5

Stable release with extensive documentation and reliable ATT&CK emulation support.

### Kali Linux 2024.4

Includes all required offensive tooling without additional repositories.

---

# 9. Upgrade Paths

## Elastic Stack

```bash
docker pull docker.elastic.co/elasticsearch/elasticsearch:<new-version>
docker pull docker.elastic.co/kibana/kibana:<new-version>
```

Upgrade Elasticsearch, Kibana, Winlogbeat, and Filebeat together.

## Velociraptor

1. Replace server binary.
2. Restart service.
3. Generate a new client MSI.
4. Redeploy clients.

## Caldera

```bash
cd ~/caldera
git pull
```

Rebuild the virtual environment if dependencies change.

---

# Summary

The most critical compatibility requirements in the Nation-State Lab are:

* Elasticsearch ↔ Kibana → Same version
* Elasticsearch ↔ Winlogbeat/Filebeat → Same version
* Velociraptor Server ↔ Client → Same version
* Caldera Server ↔ Agent → Same release

Maintaining version consistency ensures reliable logging, hunting, detection engineering, and adversary emulation throughout the lab.

---

*Part of the Nation-State Lab – Tools & Version Reference.*
