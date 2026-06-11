===============================
KIBANA DETECTION ANALYSIS – COMPLETE ATTACK CHAIN
===============================

Environment:
- Elasticsearch/Kibana: 192.168.1.100:5601
- Index pattern: winlogbeat-*
- Time range: Full attack window (2 hours)

Objective:
Detect and correlate all phases of the APT simulation using Windows Event Logs ingested via Winlogbeat.

================================================
1. DETECTION COVERAGE SUMMARY
================================================

Phase | Attack Action | Relevant Event IDs | Kibana Query
-----------------------------------------------------------
1 | Reconnaissance (Nmap) | Sysmon 3 (network) | event.code:3 AND source.ip:192.168.1.5
2 | Reverse shell execution | 4688 | event.code:4688 AND process.name:shell.exe
3 | Persistence (scheduled task) | 4698 | event.code:4698 AND winlog.event_data.TaskName:Updater
4 | UAC bypass | 4688 | event.code:4688 AND process.name:(eventvwr.exe OR sdclt.exe)
5 | Credential dumping | 4663, 10 | event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe
6 | Lateral movement | 4624, 4672 | event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5
7 | C2 HTTP beacon | 4688, 3 | event.code:3 AND destination.port:8081
8 | Process lineage | 4688 | winlog.event_id:4688 AND winlog.event_data.ParentProcess:*certutil.exe*

================================================
2. KEY EVENT QUERIES & DETECTION EXAMPLES
================================================

2.1 PROCESS EXECUTION – shell.exe (EVENT 4688)
------------------------------------------------
Query:
event.code:4688 AND winlog.event_data.ProcessName:*shell.exe

Observed:
- Process Path: C:\Users\Public\shell.exe
- Parent Process: cmd.exe
- User: WS-1 / Administrator

HASH (IOC):
- File Name: shell.exe
- Location: C:\Users\Public\
- Type: Reverse Shell Payload (Meterpreter)

================================================

2.2 SCHEDULED TASK PERSISTENCE (EVENT 4698)
------------------------------------------------
Query:
event.code:4698 AND winlog.event_data.TaskName:Updater

Observed:
- Task Name: Updater
- Action: C:\Users\Public\shell.exe
- Trigger: Daily 09:00

================================================

2.3 LSASS CREDENTIAL DUMPING (EVENT 4663 / SYSMON 10)
------------------------------------------------
Query:
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe
event.code:10 AND winlog.event_data.TargetImage:*lsass.exe

Observed:
- Source: mimikatz.exe / shell.exe
- Access: 0x1FFFFF (Full Dump)

HASHES EXTRACTED (CRITICAL IOC):
------------------------------------------------
Administrator (NATION)
LM Hash : aad3b435b51404eeaad3b435b51404ee
NTLM Hash: 31d6cfe0d16ae931b73c59d7e0c089c0
SHA1    : aeb22f1a3af63039b3e5f6d3a6aee96c282b4471

WS1 User
NTLM Hash: aeb22f1a3af63039b3e5f6d3a6aee96c

================================================

2.4 LATERAL MOVEMENT (EVENT 4624 / 4672)
------------------------------------------------
Query:
event.code:4624 AND winlog.event_data.LogonType:3 AND source.ip:192.168.1.5

Observed:
- User: Administrator
- Domain: NATION
- Auth: NTLM
- Source IP: Kali (192.168.1.5)

================================================

2.5 C2 HTTP BEACON (SYSMON EVENT 3)
------------------------------------------------
Query:
event.code:3 AND destination.port:8081

Observed:
- Process: beacon.exe
- Destination: 192.168.1.5:8081
- Protocol: HTTP C2

================================================

2.6 PROCESS LINEAGE (LOLBIN ATTACK)
------------------------------------------------
Query:
winlog.event_id:4688 AND winlog.event_data.ParentProcess:*certutil.exe*

Process Tree:
cmd.exe → certutil.exe → beacon.exe

================================================
3. KIBANA VISUALIZATIONS
================================================

3.1 Timeline View:
- Attack spikes observed at:
  * shell execution
  * LSASS access
  * scheduled task creation
  * beacon callback

3.2 MITRE ATT&CK MAPPING:
------------------------------------------------
4688   → Execution (T1059)
4698   → Persistence (T1053.005)
4663/10 → Credential Access (T1003.001)
4624/4672 → Lateral Movement (T1550.002)
3      → Command & Control (T1071.001)

3.3 ATTACK SOURCE:
- 192.168.1.5 (Kali Attacker)

================================================
4. KIBANA ALERT RULES
================================================

Rule 1:
event.code:4688 AND winlog.event_data.ProcessName:C:\\Users\\Public\\*.exe

Rule 2:
event.code:4663 AND winlog.event_data.ObjectName:*lsass.exe

Rule 3:
event.code:4624 AND winlog.event_data.LogonType:3

Rule 4:
event.code:4698 AND winlog.event_data.TaskName:Updater

================================================
5. IOC SUMMARY (IMPORTANT)
================================================

FILE IOCs:
- shell.exe → C:\Users\Public\
- beacon.exe → C:\Users\Public\

NETWORK IOCs:
- 192.168.1.5 (Attacker/Kali)
- Port 8081 (HTTP C2)

AUTH IOCs:
- NTLM Pass-the-Hash used
- Administrator hash compromised

HASH IOCs:
- aad3b435b51404eeaad3b435b51404ee
- 31d6cfe0d16ae931b73c59d7e0c089c0

================================================
6. VELOCIRAPTOR CORRELATION
================================================

4688 → Windows.Sys.Processes
4698 → Windows.Sys.ScheduledTasks
4663 → Windows.EventLogs.Security
4624 → Windows.EventLogs.Security
beacon.exe → Windows.Search.FileFinder

================================================
7. SAMPLE ATTACK TIMELINE
================================================

06:13:49  WS1  4688  shell.exe
06:15:00  WS1  4698  Updater Task
06:15:10  WS1  4663  LSASS Access
06:15:23  DC   4624  NTLM Logon (Kali)
06:15:24  DC   4672  Admin Privileges
06:25:10  DC   3     beacon.exe C2

================================================
8. GAPS & RECOMMENDATIONS
================================================

- Enable Sysmon on Kali for full reconnaissance visibility
- Enable file hash logging (Elastic Defend)
- Ensure process.command_line logging in Winlogbeat
- Add correlation rules between 4688 + 3 (execution + network)