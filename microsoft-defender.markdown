# Microsoft Defender

- [Overview](#overview)
- [Defender for Cloud](#defender-for-cloud)
  - [Policies and Initiatives](#policies-and-initiatives)
  - [Roles](#roles)
  - [Multicloud](#multicloud)
  - [Extensions for Compute resources](#extensions-for-compute-resources)
  - [Microsoft cloud security benchmark (MCSB)](#microsoft-cloud-security-benchmark-mcsb)
  - [Recommendattions](#recommendattions)
  - [Just-In-Time (JIT) VM access](#just-in-time-jit-vm-access)
  - [Cloud Security Explorer](#cloud-security-explorer)
- [Defender for Cloud Apps](#defender-for-cloud-apps)
- [Defender for Identity](#defender-for-identity)


## Overview


## Defender for Cloud

- Formerly called "Azure Security Center"
- Two types of plans:
  - **Cloud Security Posture Management (CSPM)** - Remediate security issues and watch your security posture improve

    ![CSPM plans](images/azure_defender-cspm-plans.png)

    - Foundational CSPM - Free, enabled for all your subscriptions when you visit "Defender for Cloud" in the Portal,
    - Defender CSPM - charged per resource (Servers, DBs, Storage accounts)

  - **Cloud Workload Protection (CWP)** - Identify unique workload security requirements, there are defender plans for
    - Servers
    - Containers
    - Storage
    - SQL DB
    - Cosmos DB
    - Open source DBs (resource level only)
    - Key Vault
    - App Service
    - DNS
    - Resource Manager (charged per subscription)
    - DevOps
- Some plans could be enabled at either subscription level or individual resource level
  - Defender for Storage account
  - Defender for SQL
- The Microsoft Defender plans available at the **workspace level** are Microsoft Defender for Servers and Microsoft Defender for SQL servers on machines.

### Policies and Initiatives

Defender for Cloud mainly uses '**Audit**' policies that check specific conditions and configurations and then report on compliance.

- When you enable Defender for Cloud, the initiative named "**Microsoft cloud security benchmark**" is automatically assigned to all Defender for Cloud registered subscriptions
  - You can enable or disable individual policies by editing parameters
- You can add regulatory compliance standards as initiatives, such as CIS, NIST etc
- You can add your own custom initiatives

### Roles

There are two specific roles for Defender for Cloud:

![Security reader and administrator roles](images/azure_defender-for-cloud-roles.jpg)

### Multicloud

Can protect AWS and GCP resources

- Defender for Cloud's CSPM features
  - Assess your AWS resources according to AWS-specific security recommendations
- Microsoft Defender for Kubernetes
  - Extends to EKS clusters
- Microsoft Defender for Servers
  - Can cover EC2 instances

### Extensions for Compute resources

- Collects data from compute resources, such as VMs, VMSS, IaaS containers, and non-Azure computers, data is collected using:
  - Azure Monitor Agent (AMA)
  - Microsoft Defender for Endpoint (MDE)
  - Log Analytics Agent
  - Azure Policy Add-on for Kubernetes
- Some Defender plans require "monitoring components" to collect data from your workloads
  - Defender for Servers
    - Azure Arc agent (For multicloud and on-premises servers)
    - Microsoft Defender for Endpoint
    - Vulnerability assessment
    - Azure Monitor Agent or Log Analytics agent
  - Defender for SQL servers on machines
    - Azure Arc agent (For multicloud and on-premises servers)
    - Azure Monitor Agent or Log Analytics agent
    - Automatic SQL server discovery and registration
  - Defender for Containers
    - Azure Arc agent (For multicloud and on-premises servers)
    - Defender profile, Azure Policy Extension, Kubernetes audit log data
- When you enable an extension, it will be installed on any new or existing resource, by assigning a security policy.
  - eg. After enable "Guest Configuration agent", policies like "ASC provisioning Guest Configuration agent for Linux" will be assigned
  - Policy assignment will be removed once you disable the config

### Microsoft cloud security benchmark (MCSB)

*Formerly known as Azure Security Benchmark (ASB)*

It provides prescriptive best practices and recommendations to help secure your multicloud environment.

Has input from a set of holistic Microsoft and industry security guidance that includes:

  - Cloud Adoption Framework
  - Azure Well-Architected Framework
  - The Chief Information Security Officer (CISO) Workshop
  - Other industry and cloud service providers security best practice standards and framework, eg.:
    - Amazon Web Services (AWS) Well-Architected Framework
    - Center for Internet Security (CIS) Controls
    - National Institute of Standards and Technology (NIST)
    - Payment Card Industry Data Security Standard (PCI-DSS)

### Recommendattions

Based on policy evaluation results.

For a recommendation, you can:

- Take action
- Trigger logic app
- Exempt
- Assign owner and due date

And you can create **Governance rule** to assign owners (by email or resource tag) and time frames to recommendations automatically

### Just-In-Time (JIT) VM access

- A feature of Defender for Servers
- The VM must have an NSG attached
- Defender for Cloud ensures "**deny all inbound traffic**" rules exist for your selected ports in the network security group (NSG) and Azure Firewall rules
  - If other rules for the port exists, they take precedence
- How to get access
  - A user request access
  - Defender for Cloud checks that the user has RBAC permissions for the VM
  - When a request is approved, Defender for Cloud configures NSG and Azure Firewall to allow inbound traffic for a specified time
  - After the time has expired, Defender for Cloud restores the NSGs to their previous states. Connections that are already established are not interrupted.
- Works for AWS EC2 instances

The logic that Defender for Cloud applies when deciding how to categorize VMs

![Just-in-time VM status](images/azure_just-in-time-vm-access.png)

*For AWS EC2 VMs:*

![Just-in-time VM status - AWS EC2](images/azure_just-in-time-vm-access-aws-ec2.png)

### Cloud Security Explorer

Allows you to build queries interactively to hunt for risks, like SQL servers WHICH contain sensitive data AND is exposed to the Internet


## Defender for Cloud Apps

- Microsoft implementation of a CASB service
- Formerly known as Microsoft Cloud App Security (MCAS)

***CASB**: Cloud Access Security Broker, an on-prem or cloud-based security policy enforcement point that is placed between cloud service consumers and cloud service providers to combine and interject enterprise security policies as cloud-based resources are accessed.*

Features:

- Cloud discovery: discover cloud apps your organization is using
- Sanctioning and de-authorizing apps
- Use easy-to-deploy **app connectors** that take advantage of provider APIs, for visibility and governance of apps
- Use **Conditional Access App Control** to control over access and activities within your cloud apps

![Defender for Cloud Apps components](images/microsoft_defender-for-cloud-apps-architecture.png)


## Defender for Identity

- Formerly known as Azure Advanced Threat Protection (ATP)
- Uses on-prem AD signals, can be installed on Domain Controllers and AD FS servers

![Defender for Identity components](./images/microsoft_defender-for-identity.png)
