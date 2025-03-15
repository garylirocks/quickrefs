# Azure Update Manager

- [Overview](#overview)
- [How](#how)
  - [Extension](#extension)
  - [Update source](#update-source)
  - [Update process](#update-process)
  - [Azure Resource Graph](#azure-resource-graph)
  - [Networking requirements](#networking-requirements)
  - [Troubleshooting](#troubleshooting)
- [Windows](#windows)
- [Maintenance configuration](#maintenance-configuration)
- [Policies](#policies)


## Overview

- Unlike the legacy version, the new Update Manager does NOT use Log Analytics or Automation Account
- Utilizes Azure Resource Graph to store information about the assessment and update results
- Extension based
  - Works for Arc-enabled Server OS
  - For both Windows and Linux
- VM level RBAC
- No support for Windows 10, 11 (you should use Intune instead)
- Free for Azure VMs, $5 per server per month for Arc-enabled servers


## How

- Azure VM
  - Need customer managed schedules (maintenance configuration) ?
  - Assessment
    - Every 24 hours
    - Windows: Windows Update Agent
    - Linux: Oval
  - To associate a schedule (maintenance configuration) to an Azure VM, there are prerequisites:
    - `patchMode` set to `AutomaticByPlatform`
    - `bypassPlatformChecksOnUserSchedule` set to `true`


### Extension

Update Manager VM extensions
- Automatically installed when you initiate any AUM operations: on-demand/periodic assessment, on-demand/scheduled update
- Single extention for Azure VMs, two for Arc-enabled servers
- The extension interacts with the VM/Arc agent to fetch and install updates
- No dependency on MMA or AMA

### Update source

AUM honors the settings on the machine.

- Windows, the source could be:
  - Windows Update repository
  - Microsoft Update repository
  - Windows Server Update Services (WSUS)
- Linux, package manager

### Update process

See [docs](https://learn.microsoft.com/en-gb/azure/update-manager/workflow-update-manager?tabs=azure-vms%2Cupdate-win#how-patches-are-installed-in-azure-update-manager)

- Begins and ends with an assessment
- Stops the update if it's going to exceed the maintenance window, based on calculations

### Azure Resource Graph

Some information is stored in ARG tables:

- Pending updates (table: `patchassessmentresources`): 7 days
- Update results (table: `patchinstallationresources`): 30 days

### Networking requirements

See [docs](https://learn.microsoft.com/en-gb/azure/update-manager/prerequisites#network-planning)

### Troubleshooting

- The update happens within the maintenance window, so may be a few minutes later than the scheduled time.
- In the VM resource's activity log, the update operation will be logged as "Install OS update patches on virtual machine", no matter if it's manually triggered or scheduled.
- Within the VM
  - In "Programs and Features" -> "Installed Updates", some updates (KBs) don't show up, no matter whether they were installed by Windows Update or Azure Update Manager
  - In "Update history", only the ones installed by Windows Update show up, NOT the ones by Azure Update Manager
  - If you install an update via Windows Update, in Azure Update Manager: after an assessment it still shows up as pending to be installed, seems like it doesn't know that it's already installed


## Windows

AUM relies on the Windows Update client, its settings could be managed by:

- Local Group Policy Editor
- Group Policy
- PowerShell
- Direct editing the Registry

Notes:

- ?? Don't use pre-download functionality through AUOptions while using Azure Update Manager default/advanced patching mechanisms which sets `NoAutoUpdate=1`.
- Some registry keys could cause your machines to reboot, even if you specify "Never Reboot" in your maintenance configuration




## Maintenance configuration

- Reboot settings:
  - Reboot if required
  - Always
  - Never
- Scope:
  - Host (dedicated)
  - VMSS
  - Azure and Arc VM
- Schedule:
  - Maintenance window
  - Offset: in days, only needed if you select something like second Tuesday of a month
- Dynamic scope, evaluated at runtime, could be based on:
  - Resource groups
  - Resource types
  - Locations
  - OS types
  - Tags
- Resources (static)
- Update types: Security, Critical, KBs/packages to include/exclude, etc
- Pre/post event to Event Grid
  - You could use it to start a VM before a scheduled patching, and stop it after
  - You could use an Automation Account runbook or a function app, see [here](https://learn.microsoft.com/en-us/azure/update-manager/tutorial-using-functions)


## Policies

There are built-in policies to audit or apply the maintenance configuration settings. These policies are:

- **Machines should be configured to periodically check for missing system updates**

  `Audit`

  Whether the `Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.patchSettings.assessmentMode`, `Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration.patchSettings.assessmentMode` field is set to `AutomaticByPlatform`

- **Configure periodic checking for missing system updates on azure virtual machines**

  `Modify`

  Set the `assessmentMode` field to `AutomaticByPlatform`

- **Schedule recurring updates using Azure Update Manager**

  `DeployIfNotExists`

  Associate maintenance configuration to target Azure/Arc VM, resource type: `Microsoft.Compute/virtualMachines/providers/configurationAssignments`

  Could target VMs by location, RG, OS type, tags

- **[Preview]: Set prerequisite for Scheduling recurring updates on Azure virtual machines.**

  `DeployIfNotExists`

  This policy will set the prerequisite needed to schedule recurring updates on Azure Update Manager by configuring patch orchestration to 'Customer Managed Schedules'. This change will automatically set the patch mode to `AutomaticByPlatform` and enables `BypassPlatformSafetyChecksOnUserSchedule` to `True` on Azure VMs. The prerequisite is not applicable for Arc-enabled servers.
