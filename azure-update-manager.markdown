# Azure Update Manager

- [Overview](#overview)
- [How](#how)
- [Maintenance configuration](#maintenance-configuration)
- [Policies](#policies)


## Overview

- Unlike the legacy version, the new Update Manager does NOT use Log Analytics or Automation Account
- Utilizes Azure Resource Graph to store information about the patches, reboot requirements, etc
- Extension based
  - Works for Arc-enabled Server OS
  - For both Windows and Linux
- VM level RBAC


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

The update happens within the maintenance window, so may be a few minutes later than the scheduled time.

The update activity will be logged in activity log as "Install OS update patches on virtual machine"

For all the updates shown installed by the Update Manager, if you check the Windows VM:
  - They don't show up in update history
  - Only some show up in "Programs and Features" -> "Installed Updates"

If you install an update within the VM via Windows Update:
  - In the VM: it shows up in update history
  - In Azure Update Manager: after an assessment it still shows up as pending to be installed, seems like it doesn't know that it's already installed


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
