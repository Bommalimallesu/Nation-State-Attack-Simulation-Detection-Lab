# Kibana Visualization Guide – APT Attack Chain Simulation

This guide explains how to create the visualizations used in the **APT Attack Chain Dashboard** using Kibana Lens, TSVB, and Aggregation-based visualizations.

**Index Pattern:** `winlogbeat-*`

---

# 1. Prerequisites

* Kibana accessible at `http://192.168.1.100:5601`
* Winlogbeat data from WS1 and DC indexed in Elasticsearch
* Basic understanding of KQL (Kibana Query Language)

---

# 2. Visualization 1 – Process Creation (Area Chart)

## Purpose

Show timeline of `shell.exe` and `beacon.exe` executions, split by host.

## Steps

### 1. Create a New Lens Visualization

```text
Visualize Library → Create Visualization → Lens
```

### 2. Configure Data Source

* Index Pattern: `winlogbeat-*`
* Time Range: Last 2 hours (or attack window)

### 3. Add KQL Filter

```kql
event.code:4688 AND (process.name:shell.exe OR process.name:beacon.exe)
```

### 4. Configure Metrics and Buckets

**Vertical Axis**

* Count of Records

**Horizontal Axis**

* `@timestamp`
* Date Histogram (Auto Interval)

**Break Down By**

* `host.name`

### 5. Change Chart Type

```text
Chart Type → Area
```

### 6. Customize

* Enable Stacked Area
* Show Legend on Right

### 7. Save

```text
Process Creation – Suspicious Executables
```

### Expected Result

A stacked area chart showing:

* Spike at `06:13:49` for `WS1 (shell.exe)`
* Spike at `06:25:10` for `DC (beacon.exe)`

---

# 3. Visualization 2 – Lateral Movement (Heatmap)

## Purpose

Show frequency of lateral movement events across hosts.

### Relevant Event IDs

* `4624` – Network Logon
* `4672` – Special Privileges Assigned
* `5140` – Network Share Access
* `7045` – Service Installation

## Steps

### KQL Filter

```kql
event.code:4624 OR event.code:4672 OR event.code:5140 OR event.code:7045
```

### Configure Axes

**Horizontal Axis**

* Top Values of `event.code`
* Size: 5

**Vertical Axis**

* Top Values of `host.name`
* Size: 5

**Metric**

* Count

### Chart Type

```text
Heatmap
```

### Color Scheme

* Greens
* Blues

### Save

```text
Lateral Movement Events
```

### Expected Result

Darker cells for DC corresponding to events:

```text
         4624   4672   5140   7045
DC       ████   ████   ███    ███
WS1      ░░░░   ░░░░   ░░░    ░░░
```

---

# 4. Visualization 3 – LSASS Access (Data Table)

## Purpose

List all LSASS handle access events.

## Steps

### Create Visualization

```text
Visualize Library → Create Visualization → Data Table
```

### Index Pattern

```text
winlogbeat-*
```

### KQL Filter

```kql
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe
```

### Buckets

#### Split Rows

* Aggregation: Date Histogram
* Field: `@timestamp`

#### Sub-Bucket 1

* Aggregation: Terms
* Field: `host.name`

#### Sub-Bucket 2

* Aggregation: Terms
* Field: `winlog.event_data.ProcessName`

### Metrics

* Count
* Optional: `winlog.event_data.AccessMask`

### Save

```text
LSASS Access Events
```

### Expected Result

| Timestamp | Host | Process   | Access Mask |
| --------- | ---- | --------- | ----------- |
| 06:14:12  | WS1  | shell.exe | 0x1FFFFF    |

---

# 5. Visualization 4 – Network Logon Timeline (Line Chart)

## Purpose

Display network logon activity over time.

## Steps

### KQL Filter

```kql
event.code:4624 AND winlog.event_data.LogonType:3
```

### Configure

**Vertical Axis**

* Count

**Horizontal Axis**

* `@timestamp`

**Break Down By**

* `host.name`

### Chart Type

```text
Line
```

### Save

```text
Network Logon Timeline
```

### Expected Result

Single spike around:

```text
06:15:23
```

representing a remote logon from the Kali attacker IP.

---

# 6. Saved Search – Attack Chain Events

## Purpose

Display all attack-related events in a single table.

## Discover Query

```kql
host.name:(WS1 OR DC) AND event.code:(4688 OR 4624 OR 4698 OR 4663 OR 4672 OR 5140 OR 7045)
```

### Display Columns

* `@timestamp`
* `host.name`
* `winlog.event_data.TargetUserName`
* `source.ip`
* `winlog.event_data.LogonType`
* `process.name`
* `event.code`

### Sort

```text
@timestamp DESC
```

### Save Search

```text
Attack Chain Events
```

---

# 7. Assembling the Dashboard

## Create Dashboard

```text
Dashboard → Create Dashboard
```

## Add Panels

```text
Add From Library
```

Add:

1. Process Creation – Suspicious Executables
2. Lateral Movement Events
3. LSASS Access Events
4. Network Logon Timeline
5. Attack Chain Events

## Recommended Layout

```text
+--------------------------------------+--------------------------------------+
| Process Creation (Area Chart)        | Lateral Movement (Heatmap)           |
+--------------------------------------+--------------------------------------+
| LSASS Access (Table)                 | Network Logon Timeline (Line Chart)  |
+--------------------------------------+--------------------------------------+
| Attack Chain Events (Saved Search)                                          |
+-----------------------------------------------------------------------------+
```

## Dashboard Controls (Optional)

* Time Picker
* Host Dropdown Filter (`host.name`)

## Save Dashboard

```text
APT Attack Chain Dashboard
```

---

# 8. Visualization Tips

## Lens vs Aggregation-Based

| Visualization | Recommended Tool  |
| ------------- | ----------------- |
| Area Chart    | Lens              |
| Line Chart    | Lens              |
| Heatmap       | Lens              |
| Data Table    | Aggregation-Based |
| Pie Chart     | Aggregation-Based |

## Recommended Colors

| Event Type       | Color  |
| ---------------- | ------ |
| LSASS Access     | Red    |
| Lateral Movement | Orange |
| Process Creation | Blue   |
| Network Logons   | Green  |

## Annotations

Useful timeline markers:

```text
06:13:49 - Reverse Shell Executed
06:14:12 - LSASS Access
06:15:23 - Pass-the-Hash Logon
06:25:10 - Beacon Established
```

## Exporting

```text
Share → Download as PNG
```

---

# 9. Troubleshooting

| Problem            | Cause                     | Solution                   |
| ------------------ | ------------------------- | -------------------------- |
| No data in chart   | Time range too small      | Expand time range          |
| Missing host.name  | Incorrect Winlogbeat data | Verify agent configuration |
| event.code missing | Wrong index pattern       | Refresh field list         |
| Dashboard slow     | Excessive data scanned    | Restrict time window       |

---

# 10. Example Visualization Outputs

## Process Creation Area Chart

```text
Count

4 |
3 |                            █
2 |              █             █
1 |      █       █             █
0 +------------------------------------------------
     06:13   06:15   06:17   06:25   06:27

     WS1 (shell.exe)     DC (beacon.exe)
```

## Lateral Movement Heatmap

```text
          4624   4672   5140   7045

DC        ████   ████   ███    ███
WS1       ░░░░   ░░░░   ░░░    ░░░
```

---

# Dashboard Outcome

The completed dashboard provides visibility into:

* Initial Access
* Persistence
* Privilege Escalation
* Credential Access
* Lateral Movement
* Command & Control

allowing analysts to follow the complete APT attack chain from compromise through post-exploitation.
