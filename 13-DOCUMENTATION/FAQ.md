# FAQ – Nation‑State Lab

## General Lab Setup

### Q1: What are the minimum hardware requirements to run this lab?
**A:**  
- **Host PC:** 16 GB RAM, 100 GB free disk space, 4+ CPU cores.  
- **VMware Workstation Player** (free) or Pro.  
- **Ubuntu VM:** 4 GB RAM, 60 GB disk.  
- **Windows VMs (DC, WS1, FILESERVER, WEBSERVER):** 2 GB RAM each, 50 GB disk each.  
- **Kali VM:** 4 GB RAM, 40 GB disk.  
- **Total disk usage:** approx. 300 GB (but can be reduced by decommissioning non‑essential VMs).

### Q2: Can I run this lab on a laptop with only 8 GB RAM?
**A:** Possibly with heavy optimisation:  
- Reduce Elasticsearch heap to `-Xms256m -Xmx256m`.  
- Lower Winlogbeat’s `queue_size` and `events_per_second`.  
- Run only DC, WS1, Kali, and Ubuntu (power off other VMs).  
- Use a smaller disk (e.g., 30 GB per VM).  
- Expect slower performance; not recommended for full attack simulation.

### Q3: Why did you choose Elastic Stack instead of Wazuh?
**A:** Initially we used Wazuh Docker, but faced persistent dashboard issues (index pattern corruption, missing events, Filebeat not shipping). After multiple troubleshooting cycles, we switched to Elastic Stack (Elasticsearch + Kibana) because it is more stable, better documented, and allows direct control over indices and dashboards. The Elastic Stack also integrates seamlessly with Winlogbeat and Filebeat without complex configurations.

### Q4: How do I set a static IP for Ubuntu?
**A:** Edit `/etc/netplan/00-installer-config.yaml`:
```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
Then apply: sudo netplan apply.

Monitoring Stack (Elasticsearch + Kibana)
Q5: Why does Kibana show “Configure Elastic” enrollment screen?
A: This appears when no index pattern exists. Click “Configure manually” or “Explore on my own”, then create index patterns winlogbeat-* and filebeat-* with time field @timestamp.

Q6: How do I restart Elasticsearch/Kibana containers?
A:

bash
docker restart elasticsearch
docker restart kibana
Wait 30 seconds for services to become healthy.

Q7: Why does Elasticsearch container exit with code 78 or 137?
A: Code 78 indicates a configuration error (e.g., invalid elasticsearch.yml). Code 137 means out of memory (OOM). Fix:

Reduce heap size: -e "ES_JAVA_OPTS=-Xms256m -Xmx256m".

Ensure the Ubuntu VM has at least 4 GB RAM.

Check logs: docker logs elasticsearch --tail 50.

Q8: Kibana returns “Kibana server is not ready yet”
A: Common causes:

Elasticsearch not healthy: check docker logs elasticsearch.

Network issue: ensure both containers are on the same elastic network.

Port binding: run docker port kibana – should show 5601/tcp -> 0.0.0.0:5601.

Restart both containers in order: docker restart elasticsearch; sleep 10; docker restart kibana.

Q9: How do I backup and restore Kibana dashboards?
A:

Backup: Kibana UI → Management → Stack Management → Saved Objects → select all → Export.

Restore: Same page → Import and upload the exported NDJSON file.

Winlogbeat & Windows Agents
Q10: Winlogbeat service fails to start with “service name invalid”
A: The service is not installed. Run as Administrator:

powershell
cd C:\Winlogbeat
.\install-service-winlogbeat.ps1
net start winlogbeat
Q11: No Security events (4624, 4625) appear in Kibana
A: Enable audit policies:

cmd
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
Also ensure the <query> filter in winlogbeat.yml is removed (or commented out).

Q12: How to test if Winlogbeat is sending logs?
A: Generate a test event:

cmd
net user testuser P@ssw0rd /add && net user testuser /delete
Then in Kibana, search winlog.event_id: 4720.

Q13: Winlogbeat installation fails with “Access denied”
A: Install to a simple path without spaces, e.g., C:\Winlogbeat:

cmd
msiexec /i "winlogbeat.msi" TARGETDIR="C:\Winlogbeat" /qn
Run Command Prompt or PowerShell as Administrator.

Attack Tools & Execution
Q14: Metasploit payload shell.exe does not connect back
A: Check:

LHOST in msfvenom must be Kali’s IP (192.168.1.5).

Listener (multi/handler) must use same LHOST and LPORT.

Windows Firewall may block outbound connection – temporarily disable:

cmd
netsh advfirewall set allprofiles state off
Test connectivity: Test-NetConnection 192.168.1.5 -Port 4444.

Q15: UAC bypass fails (“DLL injection failed”)
A: Windows Defender Real‑time protection may interfere. Add an exclusion for the payload directory and temporarily disable Defender:

powershell
Set-MpPreference -DisableRealtimeMonitoring $true
After escalation, re‑enable: Set-MpPreference -DisableRealtimeMonitoring $false.

Q16: How to extract NTLM hash with Mimikatz in Meterpreter?
A: From a SYSTEM session:

text
load kiwi
creds_all
If kiwi fails, migrate to a 64‑bit process:

text
ps | grep explorer
migrate <PID>
load kiwi
Q17: Impacket pass‑the‑hash returns “STATUS_LOGON_FAILURE”
A: Ensure the hash format is LM:NT (even if LM is placeholder). Example:

bash
impacket-psexec -hashes aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 nation/administrator@192.168.1.10
Also verify the target is reachable and SMB port 445 is open.

Q18: Caldera agent deployment PowerShell command fails with “Unable to connect”
A: Change app.contact.http to Kali’s actual IP (e.g., http://192.168.1.5:8888) not localhost or 0.0.0.0. Regenerate the command from Caldera UI.

Velociraptor
Q19: Velociraptor GUI shows “ERR_CONNECTION_REFUSED”
A: The server service may not be running:

bash
sudo systemctl status velociraptor-server
If stopped, start it: sudo systemctl start velociraptor-server.
Check firewall: sudo ufw allow 8889/tcp.

Q20: Velociraptor clients show “Offline” in Deployments
A: Ensure clients can reach the server on port 8000:

From Windows VM, run Test-NetConnection 192.168.1.100 -Port 8000.

If failed, temporarily disable Windows Firewall.

Verify the client MSI was built with the correct server IP (use Server.Utils.CreateMSI artefact).

Q21: How to run a Velociraptor hunt against all Windows VMs?
A: In the GUI → Hunts → New Hunt → Artifact Collection → choose an artifact (e.g., Windows.System.Pslist). Leave client rules blank to target all online clients. After hunt completes, use the Notebook tab to filter results with VQL.

Storage & Performance
Q22: Ubuntu VM disk is full (No space left on device)
A: Clean up:

Remove old Docker images: docker system prune -a --volumes -f.

Delete old Elasticsearch indices via Kibana Index Management (e.g., keep only last 7 days).

Vacuum system logs: sudo journalctl --vacuum-size=100M.

Expand VM disk in VMware settings and resize LVM: sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv; sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv.

Q23: Winlogbeat consumes high memory ( > 200 MB)
A: Reduce event queue size in winlogbeat.yml:

yaml
queue.mem:
  events: 4096
  flush.min_events: 1024
Restart the service.

Q24: How to reduce Elasticsearch memory usage further?
A: Set ES_JAVA_OPTS=-Xms256m -Xmx256m in the Docker run command. Monitor performance – may cause slower indexing.

General Troubleshooting
Q25: Shared folder \\vmware-host\Shared Folders\share not visible in Windows VM
A: Ensure the shared folder is enabled in VMware (VM Settings → Options → Shared Folders → Always enabled). Also install VMware Tools (or open-vm-tools on Linux). Restart the VM if necessary.

Q26: Copy‑paste not working between host and VM
A: Install VMware Tools (Windows) or open-vm-tools (Linux). In VM settings → Options → Guest Isolation → check “Enable copy and paste”. Restart the VM.

Q27: Test-NetConnection command not found in Command Prompt
A: Test-NetConnection is a PowerShell cmdlet. Use PowerShell (Admin) or use telnet (enable via Windows Features) or curl.

Q28: How to reset Kibana completely (delete all saved objects)?
A: Stop Kibana container, remove the Kibana volume, restart:

bash
docker stop kibana
docker rm kibana
docker volume rm kibana-data
docker run -d --name kibana ... (as before)
This deletes all dashboards, index patterns, and visualisations – but not the Elasticsearch data.

Security & Best Practices
Q29: Should I enable security (xpack.security) in production?
A: Yes. In an isolated lab, disabling security simplifies setup. For any production or internet‑connected environment, enable TLS and authentication. Use the official Elastic documentation to generate certificates and set passwords.

Q30: How to prevent Windows Defender from deleting Mimikatz?
A: Add an exclusion for the folder containing Mimikatz (e.g., C:\Users\Public):

powershell
Add-MpPreference -ExclusionPath "C:\Users\Public"
Temporarily disable Real‑time protection during testing; re‑enable afterwards.

Q31: How to remove all monitoring agents from Windows VMs?
A:

Winlogbeat: msiexec /x "winlogbeat.msi" /qn; delete C:\Winlogbeat.

Velociraptor: msiexec /x velociraptor_client.msi /qn; delete C:\Program Files\Velociraptor.

Wazuh (if present): msiexec /x wazuh-agent-4.14.5-1.msi /qn; delete C:\Program Files (x86)\ossec-agent.

Contributions & Further Help

Project repository: GitHub – Nation‑State Lab (internal).

Elastic documentation: https://www.elastic.co/guide

Velociraptor docs: https://docs.velociraptor.app/

MITRE ATT&CK: https://attack.mitre.org/

For issues not covered here, refer to the troubleshooting.md document or open an issue in the project repository.