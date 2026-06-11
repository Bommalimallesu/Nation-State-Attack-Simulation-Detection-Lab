# Memory Forensics – APT Attack Chain Simulation

This document describes the memory forensics analysis performed on the compromised hosts (**WS1** and **DC**) during the APT attack chain simulation. The objective is to identify volatile evidence such as active processes, network connections, process command lines, and credential-related artifacts that may not be visible through traditional disk or event log analysis.

---

# 1. Memory Acquisition

| Host | Acquisition Tool | Memory Image | Approximate Size | Acquisition Time |
|------|------------------|--------------|------------------|------------------|
| WS1 | WinPmem / DumpIt | `ws1_memory.dmp` | ~8 GB | 2026-06-10 06:30 UTC |
| DC | WinPmem / DumpIt | `dc_memory.dmp` | ~12 GB | 2026-06-10 06:32 UTC |

Example acquisition command:

```cmd
winpmem_mini_x64_rc2.exe -o ws1_memory.dmp
```

Alternatively, memory can be acquired remotely using enterprise forensic collection tools that support live memory capture.

---

# 2. Analysis Tools

| Tool | Purpose |
|------|---------|
| Volatility 3 | Primary memory forensic framework |
| Rekall | Alternative memory analysis framework |
| strings | Extract printable strings |
| grep | Search extracted output |
| YARA | Scan memory for known malware signatures |

Basic system information:

```bash
vol -f ws1_memory.dmp windows.info
```

---

# 3. WS1 Memory Analysis

## 3.1 Running Processes

```bash
vol -f ws1_memory.dmp windows.pslist
```

### Relevant Processes

| Process | PID | Description |
|----------|-----|-------------|
| shell.exe | 8188 | Reverse shell payload |
| cmd.exe | 4764 | Parent process |
| lsass.exe | 672 | Windows authentication process |
| notepad.exe | 1232 | User application |

---

## 3.2 Process Command Lines

```bash
vol -f ws1_memory.dmp windows.cmdline.CmdLine
```

Example output:

```text
PID 8188  C:\Users\Public\shell.exe
PID 4764  cmd.exe /c C:\Users\Public\shell.exe
```

This confirms execution of the payload from the `C:\Users\Public` directory.

---

## 3.3 Active Network Connections

```bash
vol -f ws1_memory.dmp windows.netscan
```

| Process | PID | Local Address | Remote Address | State |
|----------|-----|---------------|----------------|-------|
| shell.exe | 8188 | 192.168.1.20:49234 | 192.168.1.5:4444 | ESTABLISHED |

The active connection indicates a reverse shell communicating with the attacker-controlled system.

---

## 3.4 LSASS Memory Extraction

```bash
vol -f ws1_memory.dmp windows.memdump --pid 672 -o lsass.dmp
```

Example credential analysis:

```bash
mimikatz.exe "sekurlsa::minidump lsass.dmp" "sekurlsa::logonpasswords" exit
```

Example recovered artifact:

```text
Username : Administrator
Domain   : NATION
NTLM Hash: 2906d851e56454c1a699b58709c46497
```

Replace this value with the actual evidence recovered from the investigation if applicable.

---

## 3.5 Handle Inspection

```bash
vol -f ws1_memory.dmp windows.handles.Handles --pid 8188
```

Review process handles for references to `lsass.exe`, which may indicate credential access activity.

---

# 4. Domain Controller Memory Analysis

## 4.1 Running Processes

| Process | PID | Description |
|----------|-----|-------------|
| beacon.exe | 6720 | Simulated command-and-control payload |
| PSEXESVC.exe | 3940 | Remote execution service |
| cmd.exe | Various | Command interpreter |

---

## 4.2 Network Connections

```bash
vol -f dc_memory.dmp windows.netscan
```

| Process | PID | Local Address | Remote Address | State |
|----------|-----|---------------|----------------|-------|
| beacon.exe | 6720 | 192.168.1.10:49235 | 192.168.1.5:8081 | ESTABLISHED |

The outbound connection is consistent with periodic command-and-control communication.

---

## 4.3 Memory Injection Detection

```bash
vol -f dc_memory.dmp windows.malfind.Malfind --pid 6720
```

The `malfind` plugin searches for suspicious executable memory regions that may indicate injected code or in-memory malware.

---

## 4.4 Command Line Recovery

```bash
vol -f dc_memory.dmp windows.cmdline.CmdLine
```

Example:

```text
PID 1024  cmd.exe /c C:\Users\Public\beacon.exe
```

---

# 5. Additional Memory Analysis Techniques

## YARA Scan

```bash
vol -f ws1_memory.dmp windows.yarascan.YaraScan --yara-rules mimikatz.yar
```

## Dump Executables from Memory

```bash
vol -f ws1_memory.dmp windows.dumpfiles.DumpFiles --pid 8188
```

## Enumerate Registry Hives

```bash
vol -f ws1_memory.dmp windows.registry.hivelist
```

## Build a Process Timeline

```bash
vol -f ws1_memory.dmp windows.psscan.PsScan > processes.txt
vol -f ws1_memory.dmp windows.netscan.NetScan > network.txt
```

---

# 6. Key Memory Artifacts

| Artifact | Host | Description |
|-----------|------|-------------|
| `shell.exe` | WS1 | Reverse shell process |
| `beacon.exe` | DC | Simulated beacon process |
| Active TCP sessions | WS1, DC | Network communications |
| Process command lines | WS1, DC | Execution details |
| LSASS memory | WS1 | Credential-related evidence |
| Parent-child relationships | WS1, DC | Process hierarchy |

---

# 7. Detection Opportunities

| Technique | Memory Indicator | Investigation Benefit |
|-----------|-----------------|-----------------------|
| Suspicious executable | `shell.exe` in `C:\Users\Public` | Detect unauthorized execution |
| Credential access | LSASS interaction | Investigate possible credential theft |
| Beacon activity | Persistent outbound TCP | Identify command-and-control traffic |
| Code injection | Suspicious executable memory | Detect injected malware |
| Unusual process tree | `cmd.exe` spawning payloads | Identify abnormal execution chains |

---

# 8. Memory vs. Disk Evidence

| Artifact | Disk Analysis | Memory Analysis |
|-----------|--------------|----------------|
| Process execution | Windows Event Logs | Complete process structures |
| Command line | Depends on logging configuration | Often recoverable directly |
| Network connections | Sysmon (if enabled) | Active socket information |
| Credentials | Generally unavailable | Potentially recoverable from LSASS memory |
| Injected code | Often not visible | Detectable with memory analysis |

---

# 9. Example Volatility Automation Script

```bash
#!/bin/bash

DUMP=$1
OUTDIR=$2

mkdir -p "$OUTDIR"

vol -f "$DUMP" windows.info > "$OUTDIR/info.txt"
vol -f "$DUMP" windows.pslist > "$OUTDIR/pslist.txt"
vol -f "$DUMP" windows.cmdline > "$OUTDIR/cmdline.txt"
vol -f "$DUMP" windows.netscan > "$OUTDIR/netscan.txt"
vol -f "$DUMP" windows.handles > "$OUTDIR/handles.txt"
vol -f "$DUMP" windows.malfind > "$OUTDIR/malfind.txt"
```

---

# 10. Conclusion

Memory forensics complements Windows event logs and disk-based investigations by preserving volatile evidence that may disappear after reboot or malware cleanup. In this simulated investigation, memory analysis confirmed suspicious processes, recovered process command lines, identified active network communications, and demonstrated techniques for examining memory artifacts during an incident response investigation.

Combining memory acquisition with endpoint logs, network telemetry, and forensic analysis provides a more complete understanding of attacker activity and strengthens incident response capabilities.