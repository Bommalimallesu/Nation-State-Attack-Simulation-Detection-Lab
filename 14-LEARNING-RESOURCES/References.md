# References – Nation‑State Lab

This document lists all external resources, tools, documentation, and reference materials used in the development and execution of the Nation‑State Lab.

---

## 1. Core Technologies

### 1.1 Virtualisation
- **VMware Workstation Player 17** – https://www.vmware.com/products/workstation-player.html
- **VMware Host‑Only Networking** – https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-5A3C8C0A-6C4E-4B6F-9B7E-0B6F9A6C4E2A.html

### 1.2 Operating Systems
- **Windows Server 2019 Datacenter Evaluation** – https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019
- **Windows 10 Enterprise Evaluation** – https://www.microsoft.com/en-us/evalcenter/download-windows-10-enterprise
- **Kali Linux 2024.4** – https://www.kali.org/get-kali/
- **Ubuntu Server 22.04 LTS** – https://ubuntu.com/download/server

---

## 2. Monitoring Stack (Elastic)

### 2.1 Elasticsearch & Kibana
- **Elastic Stack 8.14.0** – https://www.elastic.co/downloads/
- **Elasticsearch Docker image** – https://www.docker.elastic.co/r/elasticsearch
- **Kibana Docker image** – https://www.docker.elastic.co/r/kibana
- **Elasticsearch documentation** – https://www.elastic.co/guide/en/elasticsearch/reference/8.14/index.html
- **Kibana documentation** – https://www.elastic.co/guide/en/kibana/8.14/index.html
- **Elasticsearch security (xpack)** – https://www.elastic.co/guide/en/elasticsearch/reference/8.14/security-settings.html

### 2.2 Beats
- **Winlogbeat** – https://www.elastic.co/beats/winlogbeat
- **Filebeat** – https://www.elastic.co/beats/filebeat
- **Winlogbeat configuration** – https://www.elastic.co/guide/en/beats/winlogbeat/8.14/winlogbeat-configuration.html
- **Filebeat configuration** – https://www.elastic.co/guide/en/beats/filebeat/8.14/filebeat-configuration.html

### 2.3 Elastic Agent (alternative)
- **Elastic Agent** – https://www.elastic.co/guide/en/fleet/8.14/elastic-agent-installation.html

---

## 3. Windows Audit & Logging

- **auditpol command** – https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/auditpol
- **Windows Security Event IDs** – https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/advanced-security-auditing
- **Sysmon (System Monitor)** – https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- **SwiftOnSecurity sysmon‑config** – https://github.com/SwiftOnSecurity/sysmon-config

---

## 4. Attack Tools & Frameworks

### 4.1 Metasploit Framework
- **Metasploit** – https://www.metasploit.com/
- **msfvenom** – https://www.offensive-security.com/metasploit-unleashed/msfvenom/
- **Meterpreter** – https://www.offensive-security.com/metasploit-unleashed/meterpreter/

### 4.2 Impacket
- **Impacket** – https://github.com/fortra/impacket
- **Impacket documentation** – https://www.secureauth.com/labs/open-source-tools/impacket/

### 4.3 Caldera (MITRE)
- **Caldera** – https://github.com/mitre/caldera
- **Caldera documentation** – https://caldera.readthedocs.io/
- **Sandcat agent** – https://github.com/mitre/caldera/tree/master/plugins/sandcat

### 4.4 BloodHound
- **BloodHound CE** – https://github.com/SpecterOps/BloodHound
- **SharpHound collector** – https://github.com/BloodHoundAD/BloodHound/tree/master/Collectors
- **BloodHound documentation** – https://bloodhound.readthedocs.io/

### 4.5 Atomic Red Team
- **Atomic Red Team** – https://github.com/redcanaryco/atomic-red-team
- **Invoke‑AtomicRedTeam** – https://github.com/redcanaryco/invoke-atomicredteam
- **Atomic Red Team documentation** – https://atomicredteam.io/

### 4.6 Other Tools
- **Hydra** – https://github.com/vanhauser-thc/thc-hydra
- **Nmap** – https://nmap.org/
- **Responder** – https://github.com/lgandx/Responder
- **Netcat** – https://netcat.sourceforge.net/
- **curl** – https://curl.se/

---

## 5. Velociraptor

- **Velociraptor** – https://github.com/Velocidex/velociraptor
- **Velociraptor documentation** – https://docs.velociraptor.app/
- **Velociraptor hunts** – https://docs.velociraptor.app/docs/artifact_references/
- **VQL (Velociraptor Query Language)** – https://docs.velociraptor.app/docs/vql/

---

## 6. MITRE ATT&CK Framework

- **MITRE ATT&CK®** – https://attack.mitre.org/
- **ATT&CK Navigator** – https://mitre-attack.github.io/attack-navigator/
- **Enterprise Matrix** – https://attack.mitre.org/matrices/enterprise/
- **Tactics and Techniques** – https://attack.mitre.org/tactics/enterprise/

---

## 7. Docker & Containerisation

- **Docker** – https://www.docker.com/
- **Docker Compose** – https://docs.docker.com/compose/
- **Docker network** – https://docs.docker.com/network/

---

## 8. Incident Response & Detection Engineering

- **NIST SP 800‑61 Rev. 2** – https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final
- **Elastic Security Detection Rules** – https://www.elastic.co/guide/en/security/current/detection-engine-overview.html
- **Sigma Rules** – https://github.com/SigmaHQ/sigma
- **Kibana Alerting** – https://www.elastic.co/guide/en/kibana/8.14/alerting-getting-started.html

---

## 9. PowerShell & Command Line References

- **PowerShell documentation** – https://learn.microsoft.com/en-us/powershell/
- **schtasks command** – https://learn.microsoft.com/en-us/windows/win32/taskschd/schtasks
- **net user / net localgroup** – https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/net-user

---

## 10. Network & Firewall

- **Windows Firewall commands (netsh advfirewall)** – https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/netsh-advfirewall
- **Ubuntu UFW** – https://help.ubuntu.com/community/UFW

---

## 11. Troubleshooting & Community Forums

- **Elastic Discuss** – https://discuss.elastic.co/
- **Velociraptor Discussions** – https://github.com/Velocidex/velociraptor/discussions
- **Metasploit GitHub Issues** – https://github.com/rapid7/metasploit-framework/issues
- **Stack Overflow (cybersecurity)** – https://stackoverflow.com/questions/tagged/cybersecurity

---

## 12. Version Summary Table

| Tool / Component | Version Used |
|----------------|---------------|
| VMware Workstation Player | 17 |
| Windows Server 2019 | 10.0.17763 |
| Windows 10 Pro | 22H2 (19045) |
| Kali Linux | 2024.4 |
| Ubuntu Server | 22.04 LTS |
| Elasticsearch | 8.14.0 |
| Kibana | 8.14.0 |
| Winlogbeat | 8.14.0 |
| Filebeat | 8.14.0 |
| Velociraptor Server | 0.76.5 |
| Velociraptor Client | 0.76.5 (MSI) |
| Metasploit Framework | 6.4.133‑dev (Kali) |
| Caldera | 4.14.5 (source) |
| BloodHound CE | Latest Docker image |
| Atomic Red Team | (offline package) |
| Impacket | 0.12.0 (Kali) |

---

## 13. Licence Notices

- **MITRE ATT&CK®** is a registered trademark of The MITRE Corporation.
- **Elasticsearch, Kibana, Beats** are trademarks of Elasticsearch BV.
- **Velociraptor** is licensed under the Apache License 2.0.
- **Metasploit Framework** is licensed under the BSD 3‑Clause License.
- **Caldera** is licensed under the Apache License 2.0.
- **BloodHound** is licensed under the GPLv3.
- **VMware** is a registered trademark of VMware, Inc.

*This document is part of the Nation‑State Lab – Final Documentation.*