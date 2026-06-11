# BloodHound Setup – Nation-State Lab

## 1. Overview

BloodHound is a powerful Active Directory (AD) attack path mapping tool that uses graph theory to visualize relationships between users, groups, computers, sessions, and permissions.

BloodHound consists of two primary components:

- **SharpHound** – Data collection tool
- **BloodHound CE** – Web-based visualization platform

In this lab, BloodHound CE was deployed on the Kali Linux attacker VM (`192.168.1.5`) using Docker. SharpHound was executed on domain-joined Windows systems to collect Active Directory data and identify privilege escalation and lateral movement paths.

---

## 2. Architecture

| Component | Location | Purpose |
|------------|-----------|----------|
| BloodHound CE | Kali Linux | Web Interface |
| Neo4j Database | Kali Linux | Graph Database |
| SharpHound | DC, WS1 | Data Collection |

---

## 3. Installation on Kali Linux

### 3.1 Verify Docker

```bash
docker --version
```

Install Docker if required:

```bash
sudo apt update
sudo apt install docker.io -y

sudo systemctl enable docker
sudo systemctl start docker
```

### 3.2 Deploy BloodHound CE

```bash
docker run -d \
  --name bloodhound \
  -p 8080:8080 \
  -p 7474:7474 \
  specterops/bloodhound:latest
```

Verify container status:

```bash
docker ps
```

---

### 3.3 Access BloodHound

Open:

```text
http://localhost:8080/ui/login
```

Default Credentials:

```text
Username: admin
Password: bloodhoundcommunityedition
```

Change the password after first login.

---

## 4. SharpHound Collection

### 4.1 Transfer SharpHound

Extract SharpHound:

```bash
docker cp bloodhound:/app/BloodHound/Collectors/SharpHound.exe .
```

Transfer the executable to:

- Domain Controller
- WS1

---

### 4.2 Run SharpHound on Domain Controller

Open Command Prompt as Administrator:

```cmd
SharpHound.exe -c All --outputdirectory C:\Temp --zipfilename BloodHound_DC.zip
```

Expected output:

```text
SharpHound completed successfully
```

---

### 4.3 Run SharpHound on WS1

```cmd
SharpHound.exe -c All --outputdirectory C:\Temp --zipfilename BloodHound_WS1.zip
```

---

## 5. Upload Data

Open BloodHound CE and click:

```text
Upload Data
```

Upload:

```text
BloodHound_DC.zip
BloodHound_WS1.zip
```

Wait until:

```text
Data uploaded successfully
```

appears.

---

## 6. Useful Queries

### Shortest Path to Domain Admins

Navigate to:

```text
Analysis → Shortest Paths to Domain Admins
```

---

### Users Able to Reset Domain Admin Passwords

```cypher
MATCH (u:User)-[:ForceChangePassword]->(da:User)
WHERE da.admincount = true
RETURN u
```

---

### Computers with Admin Sessions

```cypher
MATCH (c:Computer)-[:HasSession]->(u:User)
WHERE u.admincount = true
RETURN u.name,c.name
```

---

### High Value Targets

```cypher
MATCH (n)
WHERE n.highvalue = TRUE
RETURN n
```

---

## 7. Troubleshooting

### Container Not Starting

Check:

```bash
docker ps -a
```

Restart:

```bash
docker restart bloodhound
```

---

### SharpHound Access Denied

Run Command Prompt as Administrator.

---

### Empty Graph

Verify ZIP upload completed successfully and refresh the browser.

---

### Neo4j Authentication Issues

```bash
docker exec -it bloodhound bash
```

Then:

```bash
cypher-shell
```

Reset password if necessary.

---

## 8. Cleanup

Stop BloodHound:

```bash
docker stop bloodhound
```

Remove Container:

```bash
docker rm bloodhound
```

Remove Image:

```bash
docker rmi specterops/bloodhound:latest
```

---

## 9. Summary

| Component | Status |
|------------|---------|
| BloodHound CE | ✅ Running |
| Neo4j Database | ✅ Operational |
| SharpHound Collection | ✅ Complete |
| Data Upload | ✅ Successful |
| Attack Path Analysis | ✅ Performed |

BloodHound successfully provided Active Directory attack-path analysis and reconnaissance capabilities for the Nation-State Lab.