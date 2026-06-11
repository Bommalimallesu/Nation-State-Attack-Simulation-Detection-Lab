# Kibana Dashboards – APT Attack Chain Simulation

This document describes the Kibana dashboards created to visualise telemetry from Winlogbeat and Sysmon during the attack simulation. Each dashboard provides a different lens into detected activity, from live event feeds to MITRE ATT&CK mapping and attacker behavior tracking.

---

## 1. Dashboard Overview

| Dashboard | Purpose |
|-----------|--------|
| `dashboard-1` | High-level security metrics (endpoints, logons, privileged activity) |
| `dashboard-2` | Security event timeline + SOC live event feed |
| `dashboard-3` | Top users, processes, and network activity |
| `dashboard-4` | IP analysis, process creation, persistence, service installs |
| `dashboard-5` | Endpoint activity, authentication failures, attack chain visibility |

---

## 2. Dashboard Details

### 2.1 Dashboard 1 – High-Level Security Metrics

- Active endpoints (DC, WS1, File Server, etc.)
- Successful logons (Event ID 4624)
- Failed logons (Event ID 4625)
- Privileged logons (Event ID 4672)

**Observation:**
- Spike in 4624 logons due to pass-the-hash lateral movement.
- Increased privileged logons due to `Administrator` account usage.

---

### 2.2 Dashboard 2 – Timeline & SOC Live Feed

- Monthly timeline (June 2026)
- Event spike visible during attack window (10 June)
- SOC feed shows:
  - `host.name`
  - `user.name`
  - `source.ip`
  - `event.code`
  - `winlog.channel`

**Observation:**
- Baseline noise from machine accounts (`DC$`) is present.
- Attack logons require filtering by `source.ip: 192.168.1.5`.

---

### 2.3 Dashboard 3 – Top Users, Processes, Network Activity

- Top users:
  - Administrator
  - SYSTEM
  - WS1 / WS2 / FILE-SERVER
- Top processes:
  - svchost.exe
  - wermgr.exe
  - taskhost.exe
  - dsregcmd.exe
- Network activity:
  - Periodic spikes in traffic

**Observation:**
- Administrator is the most active privileged account.
- Malicious processes (`shell.exe`, `beacon.exe`) are not visible due to low volume filtering.

---

### 2.4 Dashboard 4 – IPs, Process Creation, Persistence

- Top source IPs:
  - `192.168.1.5` (Kali attacker)
  - `192.168.1.10` (DC)
  - `192.168.1.20` (WS1)
- Top destination IPs:
  - `192.168.1.10`
  - multicast traffic (`224.0.0.251`, `ff02::fb`)
- Process creation events: 1400+
- Persistence events: 1 (scheduled task `Updater`)
- Service installations: 1 (likely `PSEXESVC`)

**Observation:**
- Kali IP clearly visible in logs → confirms attacker interaction.
- Persistence and service creation correlate with attack phases.

---

### 2.5 Dashboard 5 – Endpoint & Attack Chain Visibility

- Endpoint process activity: 1400+ events
- Privileged activity: 2000+ events (4672 included)
- Authentication failures: low noise (21 events)
- Attack chain table:
  - Mostly machine account logons (`DC$`)
  - Requires filtering for attacker IP visibility

**Observation:**
- High privileged activity indicates attack execution phase.
- Attack visibility improves significantly with proper filtering.

---

## 3. Attack Visibility Mapping

| Attack Phase | Visible in Dashboard | Location |
|--------------|---------------------|----------|
| Reverse shell (`shell.exe`) | Partial | D4 / D5 |
| Persistence (`Updater`) | Yes | D4 |
| LSASS dumping | Not directly visible | Needs 4663 / Sysmon 10 filter |
| Lateral movement (4624 from Kali) | Partially visible | D4 |
| Admin logon (4672) | Yes | D5 |
| C2 beacon (`beacon.exe`) | Not explicit | Needs network filter |

---

## 4. Recommendations

- Add dedicated panel for attacker IP:
  ```kql
  source.ip: 192.168.1.5
  ```

- Add malicious process panel:
  ```kql
  process.name: (shell.exe OR beacon.exe)
  ```

- Add process lineage tracking:
  ```kql
  process.parent.name: certutil.exe
  ```

- Exclude machine accounts from SOC feed:
  ```kql
  not user.name: *$
  ```

- Reduce noise by limiting time range to attack window (2 hours).

---

## 5. Key KQL Queries

```kql
// Malicious process execution
event.code:4688 AND process.name:(shell.exe OR beacon.exe)

// Lateral movement detection
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5

// LOLBin certutil download
event.code:4688 AND process.name:certutil.exe AND command.line:*-urlcache*

// Process lineage
event.code:4688 AND winlog.event_data.ParentProcess:*certutil.exe*
```

---

## 6. Conclusion

The Kibana dashboards provide strong visibility into authentication activity, process execution, and network behavior during the attack simulation.

However, default dashboards are dominated by normal system noise. To achieve full SOC-level detection capability, additional filtering and dedicated threat-focused panels are required.

When tuned properly, this environment successfully visualises:

- Pass-the-hash attacks
- Privilege escalation
- Persistence mechanisms
- C2 beaconing
- Lateral movement

This confirms that **Winlogbeat + Sysmon + Kibana forms a highly effective APT detection stack when properly configured.**