# Microsoft Defender

- [Overview](#overview)
- [Defender for Cloud](#defender-for-cloud)
  - [Roles](#roles)
  - [Multicloud](#multicloud)
  - [Policies and Initiatives](#policies-and-initiatives)
  - [Microsoft cloud security benchmark (MCSB)](#microsoft-cloud-security-benchmark-mcsb)
  - [Recommendattions](#recommendattions)
  - [Agentless scanning](#agentless-scanning)
  - [Cloud Security Explorer](#cloud-security-explorer)
  - [Extensions for Compute resources](#extensions-for-compute-resources)
  - [Just-In-Time (JIT) VM access](#just-in-time-jit-vm-access)
- [Defender for Containers](#defender-for-containers)
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

    | Plan              | Level               |
    | ----------------- | ------------------- |
    | Servers           | sub or workspace    |
    | SQL server on VMs | sub or workspace    |
    | Containers        | sub                 |
    | Storage           | sub or resource     |
    | SQL DB            | sub or resource     |
    | Cosmos DB         | sub                 |
    | Open source DBs   | resource level only |
    | Key Vault         | sub                 |
    | App Service       | sub                 |
    | DNS               | sub                 |
    | Resource Manager  | charged per sub     |
    | DevOps            | sub                 |

    - When you enable Microsoft Defender for Servers on an Azure subscription (or a connected AWS account), all of the connected machines are protected by Defender for Servers. You can enable Microsoft Defender for Servers at the Log Analytics workspace level, but only servers reporting to that workspace will be protected and billed and those servers won't receive some benefits, such as Microsoft Defender for Endpoint, vulnerability assessment, and just-in-time VM access.

- You can enabled Defender for Cloud on a subscription automatically by using an Azure policy: `Enable Microsoft Defender for Cloud on your subscription`, which checks whether the VM plan is either set to "Free" or "Standard", see [Defender for Cloud on all subscriptions](https://learn.microsoft.com/en-us/azure/defender-for-cloud/onboard-management-group)

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

### Policies and Initiatives

Defender for Cloud mainly uses '**Audit**' policies that check specific conditions and configurations and then report on compliance.

- When you enable Defender for Cloud, the initiative named "**Microsoft cloud security benchmark**" is automatically assigned to all Defender for Cloud registered subscriptions
  - You can enable or disable individual policies by editing parameters
- You can add regulatory compliance standards as initiatives, such as CIS, NIST etc
- You can add your own custom initiatives

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

### Agentless scanning

This scans VM disks, so it needs the built-in role “VM scanner operator”, which has permissions like `Microsoft.Compute/disks/read`, `Microsoft.Compute/virtualMachines/read`

### Cloud Security Explorer

Allows you to build queries interactively to hunt for risks, like SQL servers WHICH contain sensitive data AND is exposed to the Internet


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


## Defender for Containers

- Only supports AKS clusters that use VMSS
- A Defender agent is deployed on each node as a DaemonSet
  - The agent is registered with a Log Analytics Workspace (LAW), a default LAW is created when you install the agent
  - The default LAW will be called `DefaultWorkspace-<sub-id>-<RegionShortCode>` in a RG named `DefaultResourceGroup-<RegionShortCode>`
  - You can also specify a custom LAW
- Pulls images from the registry and runs it in an isolated sandbox with Qualys scanner or with Microsoft Defender Vulnerability Management (MDVM) scanner
- Only scan images in ACR, AWS ECR, NOT Docker Hub, Microsoft Artifact Registry/Microsoft Container Registry and ARO built-in registry yet


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
