# Kibana Dashboard Import Guide – APT Attack Chain Simulation

This document explains how to import the **APT Attack Chain Dashboard** into Kibana using the provided `dashboard-export.ndjson` file. The dashboard contains visualisations and saved searches that display key detection events from the attack simulation.

---

## 1. Prerequisites

Before importing the dashboard, ensure the following:

- **Kibana** is accessible at `http://192.168.1.100:5601` (or your lab address).
- **Winlogbeat** is installed and running on WS1 and DC, forwarding logs to Elasticsearch.
- The index pattern `winlogbeat-*` exists (the import will create it if missing).
- You have **administrator** or **editor** privileges in Kibana to import saved objects.

---

## 2. Import the Dashboard

### Step 1 – Locate the Export File

Save the provided `dashboard-export.ndjson` content to a file on your host PC (e.g., `C:\temp\dashboard-export.ndjson` or `~/Downloads/dashboard-export.ndjson`).

### Step 2 – Open Kibana Saved Objects

1. Log into Kibana.
2. Click the **hamburger menu** (≡) in the top‑left corner.
3. Go to **Stack Management** → **Saved Objects**.

### Step 3 – Import

1. Click the **Import** button (top‑right).
2. Select the `dashboard-export.ndjson` file.
3. If prompted about **conflicts** (e.g., an existing index pattern with the same ID), choose **“Overwrite”** or **“Skip”** depending on your preference. It is safe to overwrite.
4. Click **Import**.

**Expected result:** A success message listing:
- 1 index pattern (`winlogbeat-*`)
- 4 visualisations
- 1 saved search
- 1 dashboard

---

## 3. Verify Data Source

- Go to **Discover**.
- Select the index pattern `winlogbeat-*`.
- Ensure the time filter is set to a range that includes your attack simulation (e.g., `2026-06-10 06:00 to 07:00`).
- Confirm that events (e.g., `event.code:4688`) appear.

If no data is shown, check:
- Winlogbeat is running (`sc query winlogbeat` on WS1/DC).
- Elasticsearch is reachable from the Windows hosts.
- The correct index pattern is selected.

---

## 4. Open the Dashboard

1. Go to **Dashboard** via the main menu (≡ → Dashboard).
2. Search for **“APT Attack Chain Dashboard”** and click on it.
3. Set the time range to the attack window (e.g., **Last 2 hours** or absolute range covering 2026-06-10 06:00–07:00 UTC).

---

## 5. Dashboard Panels Explained

The dashboard contains five panels:

| Panel | Type | Description | KQL Query Behind It |
|-------|------|-------------|----------------------|
| Process Creation – Suspicious Executables | Area chart | Shows counts of `shell.exe` and `beacon.exe` over time, split by host. | `event.code:4688 AND (process.name:shell.exe OR process.name:beacon.exe)` |
| Lateral Movement Events | Heatmap | Displays event codes (4624,4672,5140,7045) by host. | `event.code:4624 OR event.code:4672 OR event.code:5140 OR event.code:7045` |
| LSASS Access Events | Table | Lists each LSASS handle event (4663) with host and source process. | `event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe` |
| Network Logon Timeline | Line chart | Shows network logons (4624, Logon Type 3) over time, split by host. | `event.code:4624 AND winlog.event_data.LogonType:3` |
| Attack Chain Events | Data table | Displays all relevant events (4688,4624,4698,4663,4672,5140,7045) for WS1 and DC. | `host.name:(WS1 OR DC) AND event.code:(4688 OR 4624 OR 4698 OR 4663 OR 4672 OR 5140 OR 7045)` |

---

## 6. Manual Adjustments (If Needed)

- **Time filter:** If the dashboard loads with no data, expand the time picker and select **Absolute** to input your exact attack start/end times.
- **Index pattern name:** If your index pattern is not `winlogbeat-*` (e.g., `logs-windows.*`), edit each visualisation and saved search to use the correct pattern.
- **Host names:** The queries assume host names `WS1` and `DC`. If your hosts have different names, modify the queries accordingly.

---

## 7. Troubleshooting

| Problem | Likely Cause | Solution |
|---------|--------------|----------|
| Dashboard shows “No results” | No matching data in Elasticsearch | Verify Winlogbeat is running and sending logs. Check time range. |
| Visualisations show “No data” | Wrong index pattern or field names | Edit visualisation → check index pattern and field mappings. |
| Import fails with version error | Kibana version mismatch | The export was created for version 8.8.0. If your Kibana is newer, try importing anyway (Kibana auto‑upgrades). |
| Missing “winlogbeat-*” index pattern | Winlogbeat never ran | Start Winlogbeat on at least one Windows host to create the index. |

---

## 8. Customisation Tips

- **Add filters:** From the dashboard, click **Add filter** to, for example, exclude machine account logons: `winlog.event_data.TargetUserName NOT *$`.
- **Change chart type:** Edit any visualisation (click the gear icon) and change the aggregation or chart type.
- **Export as PNG:** From the dashboard, click **Share** → **Download as PNG** to capture a snapshot.

---

## 9. Example Dashboard View

Once imported and with data, you should see:

- A **spike** in the process creation chart at 06:13:49 (`shell.exe` on WS1) and at 06:25:10 (`beacon.exe` on DC).
- A **heatmap** showing lateral movement events on DC (4624, 4672, 5140, 7045).
- A **table** listing LSASS handle events with `shell.exe` as the source process.
- A **line chart** of network logons, with a peak at 06:15:23 (4624 from Kali).
- A **data table** containing all relevant events in chronological order.

---

## 10. Related Files

- `dashboard-export.ndjson` – the actual export file.
- `kibana-dashboards.md` – analysis of the dashboards from the simulation.
- `detection-overview.md` – KQL queries and event IDs.

---
