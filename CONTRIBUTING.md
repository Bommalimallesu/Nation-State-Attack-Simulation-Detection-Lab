# Contributing to Nation-State Lab

First, thank you for your interest in contributing to **Nation-State Lab**.

Nation-State Lab is an enterprise-focused adversary emulation, detection engineering, threat hunting, and incident response platform designed for cybersecurity education, research, and purple-team exercises. Contributions from security practitioners, students, researchers, and defenders are welcomed.

This document outlines the standards, workflows, and expectations for contributing to the project.

---

# Project Philosophy

The primary goals of Nation-State Lab are:

* Reproducibility
* Technical accuracy
* Realistic attack simulation
* Detection-focused learning
* Secure documentation practices
* Community-driven improvement

Every contribution should enhance one or more of these objectives.

---

# Ways to Contribute

Contributions are not limited to source code.

We welcome improvements in the following areas:

## Detection Engineering

* Kibana detection rules
* Sigma rules
* Sysmon configurations
* Elastic dashboards
* Threat detection playbooks
* MITRE ATT&CK mappings

## Threat Hunting

* Velociraptor artifacts
* VQL queries
* Hunt methodologies
* Investigation workflows
* IOC and TTP analysis

## Adversary Emulation

* MITRE ATT&CK technique implementations
* Atomic Red Team integrations
* Caldera abilities and adversary profiles
* Attack-chain enhancements
* Purple-team exercises

## Documentation

* Architecture diagrams
* Deployment guides
* Detection engineering documentation
* Threat hunting reports
* Incident response procedures
* Troubleshooting guides

## Automation

* Deployment scripts
* Infrastructure-as-Code templates
* Log collection automation
* Validation and testing utilities

---

# Before You Start

Before opening an issue or submitting a pull request:

1. Review the existing documentation.
2. Search open and closed issues.
3. Verify the problem has not already been reported.
4. Ensure the contribution aligns with the project's scope.

Contributors are encouraged to discuss significant changes through an issue before beginning implementation.

---

# Reporting Issues

High-quality issue reports help maintain project stability and reproducibility.

## Bug Reports

When reporting a bug, include:

### Environment Information

| Item                  | Example               |
| --------------------- | --------------------- |
| Host Operating System | Windows 11 Pro        |
| Hypervisor            | VMware Workstation 17 |
| Lab Version           | Current release       |
| Elastic Version       | 8.14.0                |
| Velociraptor Version  | 0.76.5                |

### Required Details

* Description of the issue
* Expected behavior
* Actual behavior
* Steps to reproduce
* Screenshots (if applicable)
* Relevant logs
* Error messages

### Useful Log Sources

```text
Docker container logs
Winlogbeat logs
Filebeat logs
Velociraptor logs
Windows Event Logs
Sysmon logs
```

Issues that cannot be reproduced may be closed pending additional information.

---

# Feature Requests

Feature requests should focus on improving:

* Detection coverage
* Adversary realism
* Automation
* Documentation quality
* Operational usability

When proposing a feature, explain:

1. The problem being solved.
2. Why the feature is valuable.
3. Potential implementation approach.
4. Expected impact on the lab.

---

# Pull Request Process

## Workflow

1. Fork the repository.
2. Create a dedicated feature branch.
3. Implement your changes.
4. Validate functionality.
5. Update documentation.
6. Submit a pull request.

### Branch Naming Convention

```text
feature/add-sigma-rules
feature/velociraptor-hunt-pack
fix/winlogbeat-config
docs/architecture-update
enhancement/elastic-dashboard
```

---

# Contribution Standards

## Documentation Standards

Documentation should be:

* Technically accurate
* Easy to reproduce
* Vendor-neutral when possible
* Written in professional English
* Consistent with existing project structure

### Markdown Requirements

* Use descriptive headings.
* Include diagrams where beneficial.
* Specify code block language identifiers.
* Use tables for structured information.
* Keep formatting consistent throughout the repository.

---

## Detection Rule Standards

All detection content should include:

### Required Metadata

```yaml
title:
description:
severity:
mitre_tactic:
mitre_technique:
data_source:
author:
```

### Requirements

* Minimize false positives.
* Include testing procedures.
* Map to MITRE ATT&CK where applicable.
* Provide investigation guidance.
* Include tuning recommendations.

---

## Script Standards

### Bash

```bash
#!/bin/bash
set -euo pipefail
```

### PowerShell

```powershell
#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
```

### General Guidelines

* Avoid hardcoded values.
* Use variables and configuration files.
* Include comments for complex logic.
* Validate user input.
* Handle errors gracefully.

---

# Security Requirements

Security is a core principle of this project.

## Never Commit

* Passwords
* API keys
* Private certificates
* Authentication tokens
* Encryption keys
* Real customer data
* Production indicators

## Allowed Examples

The repository may contain:

```text
Password123!
LabAdmin123!
example.local
192.168.1.10
```

These values exist solely for demonstration and educational purposes.

---

# Testing Requirements

Contributors should validate changes before submission.

## Detection Content

Verify:

* Rules execute successfully
* Alerts trigger correctly
* False positives are documented
* MITRE mappings are accurate

## Infrastructure Changes

Verify:

* Deployment succeeds
* Existing functionality remains operational
* Documentation reflects configuration updates

## Documentation Changes

Verify:

* Markdown renders correctly
* Links function properly
* Commands are accurate
* Screenshots remain relevant

---

# Documentation-First Principle

Major changes must include documentation updates.

Pull requests that modify functionality without updating relevant documentation may be rejected until documentation is provided.

Documentation is considered a deliverable, not an afterthought.

---

# Responsible Use

Nation-State Lab is intended exclusively for:

* Cybersecurity education
* Detection engineering
* Threat hunting
* Purple-team exercises
* Security research

Contributors must not use the project to:

* Conduct unauthorized testing
* Attack third-party systems
* Deploy malware outside controlled environments
* Perform illegal activities

All activities should remain within isolated and authorized lab environments.

---

# Review Process

Pull requests are reviewed for:

| Category      | Evaluation Criteria              |
| ------------- | -------------------------------- |
| Accuracy      | Technical correctness            |
| Security      | Safe implementation              |
| Quality       | Readability and maintainability  |
| Consistency   | Alignment with project standards |
| Documentation | Completeness and clarity         |

Maintainers may request revisions before approval.

---

# Recognition

All accepted contributors will be acknowledged through:

* GitHub contribution history
* Release notes (for significant contributions)
* Project acknowledgements where appropriate

Every contribution, regardless of size, helps improve the learning experience for the cybersecurity community.

---

# License

By submitting a contribution, you agree that your work will be licensed under the same license governing this repository.

Please review the project's `LICENSE` file before contributing.

---

# Questions & Support

For questions, suggestions, or discussions:

* Open a GitHub Issue
* Start a GitHub Discussion (if enabled)
* Contact the project maintainers

Constructive feedback and collaboration are always encouraged.

---

**Thank you for contributing to Nation-State Lab and helping build a practical platform for cybersecurity learning, detection engineering, threat hunting, and incident response.**
