# Azure ARC

- [Overview](#overview)
- [Arc machines](#arc-machines)
  - [Roles](#roles)
  - [Onboarding](#onboarding)
- [Multicloud connector](#multicloud-connector)


## Overview

Azure Arc allows you to manage the following resource types hosted outside of Azure:

- **Servers**: Manage Windows and Linux physical servers and virtual machines hosted outside of Azure.
- **Kubernetes clusters**: Attach and configure Kubernetes clusters running anywhere with multiple supported distributions.
- **Azure data services**: Run Azure data services on-premises, at the edge, and in public clouds using Kubernetes and the infrastructure of your choice. Currently supports:
  - SQL Managed Instance
  - and PostgreSQL server (preview) services
- **SQL Server**: Extend Azure services to SQL Server instances hosted outside of Azure.
- **Virtual machines (preview)**: Provision, resize, delete, and manage virtual machines based on *VMware vSphere* or *Azure Stack hyper-converged infrastructure (HCI)* and enable VM self-service through role-based access


## Arc machines

You need to install the "Azure Connected Machine agent" on the target machine(s) to be managed by Azure Arc. It does not replace "Azure Monitor Agent".

### Roles

- "Azure Connected Machine Onboarding":
  - Create Arc machine resources(`Microsoft.HybridCompute/machines`) in Azure
  - Can NOT manage extensions on Arc machines
- "Azure Connected Machine Resource Administrator":
  - Create Arc machine resources(`Microsoft.HybridCompute/machines`) in Azure
  - CAN manage extensions on Arc machines
  - Can manage licenses
  - Can runCommand
- "Azure Connected Machine Resource Manager":
  - Similar to above, can also manage hybrid connectivity endpoints, but seems intended for Azure HCI

### Onboarding

- Permissions: administrator permission required to install the agent on the target machine
  - Linux: by using the root account
  - Windows: as a member of the Local Administrators group
- Interactively:
  - Download a deployment script from Azure portal
  - Windows Admin Center (a web service you deploy on-prem)
  - PowerShell
  - Azure Arc installation wizard
- At scale:
  - You need a **service principal** with at least `Azure Connected Machine Onboarding` role on the resource group (could be an issue, this role can't install VM extensions, but sometimes the `DeployIfNotExists` policy action is triggered this SP, and extension installation fails)
  - Use a tool to run a script:
    - Configuration Manager
    - Group policy
    - Ansible
    - Azure Automation Update Management
- You could specify how the agent connects to Arc service:
  - Public endpoint
  - Private endpoint (`hybridcompute` sub-resource)
  - Proxy server


## Multicloud connector

- Works with AWS now, may be extended to other clouds
- Lightweight, only utilizes AWS API
  - No agents
- AWS account type
  - Single account
  - Organization account
- Solutions (could be multiple ones):
  - Inventory: read resources, put them in a single inventory view
      - Filter by AWS service types and regions
  - Arc onboarding: install Arc agent
    - Connectivity method: public endpoint or proxy server
    - Filter by AWS regions and tags
- Polling interval: 1 ~ 24 hours
- You'll need to use CloudFormation Stack to create two required custom IAM roles in AWS
  - The roles need to be applied to AWS resources
- A discovered AWS resources would have a resource type like `Microsoft.AWSConnector/S3Buckets`
  - For EC2, EKS etc (which could be Arc enabled), the resource type would be like `Microsoft.HybridCompute/*`
  - The resources could be queried use Azure Resource Graph
