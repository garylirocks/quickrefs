# Azure Backup

- [Features](#features)
- [Concepts](#concepts)
  - [Backup](#backup)
  - [Vaults](#vaults)
  - [Restore](#restore)
  - [Consistency](#consistency)
- [VM backup](#vm-backup)
  - [Managed disk snapshots](#managed-disk-snapshots)
  - [Azure Disk Backup](#azure-disk-backup)
  - [Azure VM Backup](#azure-vm-backup)
  - [VM restore points](#vm-restore-points)
  - [Azure Site Recovery](#azure-site-recovery)
- [Images](#images)
- [On-prem file backup](#on-prem-file-backup)
- [Region failover](#region-failover)

## Features

- Storage replication options

  - LRS: replicated three times in a datacenter
  - GRS: replicate to a secondary region
    - Upgrades to RA-GRS if cross-region restore feature enabled

- Unlimited data transfer: Azure Backup doesn't limit or charge inbound or outbound data transfers.

- Storage tiers:
  - **Snapshot tier**
    - First phase of VM backup, copied to vault tier later
    - Snapshot is stored along with the disk
    - Instant restore
  - **Vault-standard tier**
    - For all workload
    - An auto-scaling set of storage accounts in a Microsoft managed tenant

## Concepts

### Backup

- **Backup extension**: extension to Azure VM agent, specific to workload types (SQL, SAP HANA, etc), managed by Azure Backup

- **MABS / Azure Backup Server**: protect application workloads such as Hyper-V VMs, SQL Server, SharePoint Server, etc from  a single console

- **MARS Agent**: to backup data from on-prem machines and Azure VMs to a Recovery Services vault in Azure

- **Backup policy**:
  - backup rules: when, how often, snapshot method (full, incremental, differential)
  - retention rules: how long those snapshots are retained

- **GFS Backup Policy**
  - Grandfather-father-son
  - Define weekly, monthly, and yearly backup schedules in addition to the daily schedule
  - Each of these sets of backup copies can be configure to be retained for different durations

- **Snapshot**: a *full, ready-only* copy fo a virtual hard drive or an Azure File share
- **System state backup**: back up operating system files

### Vaults

- **Recovery Service Vault**

  - Resource type `Microsoft.RecoveryServices/vaults`
  - Used to back up these workloads: Azure VMs, SQL on Azure VMs, SAP HANA in Azure VMs, Azure File shares, on-prem workloads via MARS, MABS, System Center DPM
  - A storage entity in Azure, could be LRS or GRS(default, data replicated to the paired region)
    - Some backups could be restored to files, and then copied to another region
  - An auto-scaling set of storage accounts in a Microsoft managed tenant

- **Backup Vault**
  - Resource type `Microsoft.DataProtection/BackupVaults`
  - Used for Azure Databases for PostgreSQL Server
  - Similar to Recovery Service Vault, but does not support:
    - Integrated monitoring
    - Recovering of individual folders and files

- **Backup center**
  - A single unified interface to efficiently manage backups spanning multiple workload types, vaults, subscriptions, regions and tenants.
  - Supported datasources:
    - Azure Blobs
    - Azure Files
    - Azure VM
    - Azure-managed disks
    - SQL in Azure VM
    - SAP HANA in Azure VM
    - Azure Database for PostgreSQL Server
  - *For Blobs and Files, Azure Backup does NOT copy anything to a recovery service vault, it ONLY works as an orchestrator, defining when to take snapshots, retain them for how long, etc*

### Restore

- **Alternate location recovery**: restore a recovery point to a location other than the original location, eg. restoring the VM to another server

- **Cross-Region Restore** (CRR)

- **Original location recovery** (OLR)

- **Instant restore**: restore from a backup snapshot rather than from a vault
- **Item-level restore**: restore individual files or folders from a recovery point

- **RPO**: Recovery Point Objective, determined by backup frequency
- **RTO**: Recovery Time Objective

### Consistency

- **File system consistent backup**: taking a snapshot of all files at the same time

- **Crash consistent backup**: typically occur if an Azure VM shut down at the time of backup

- **Application consistent backup**: captures memory content and pending I/O operations to ensure consistency of the app data before a backup occurs


## VM backup

There are several backup options for VMs

|             | Managed disk snapshots                        | Azure Disk Backup | Azure VM Backup                                               | VM restore points                                                                           | Azure Site Recovery |
| ----------- | --------------------------------------------- | ----------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------- |
| Why         | quick and simple                              |                   | managed                                                       | -                                                                                           | regional outage     |
| Suited for  | dev/test                                      |                   | production                                                    | -                                                                                           |                     |
| What        | single managed disk                           |                   | entire VM                                                     | entire VM                                                                                   | managed disks       |
| Consistency | file system consistent                        | crash-consistent  | application-consistent                                        | application-consistent                                                                      | -                   |
| Agent       | No                                            | No                | Yes                                                           | VSS writer (for Windows), pre/post scripts (for Linux) required for application consistency | -                   |
| Storage     | -                                             |                   | snapshot tier and vault tier, geo-replicated to paired region | -                                                                                           | any region          |
| Restore     | create new managed disks when a VM is rebuilt |                   | entire VM or specific files                                   | single disk or a new VM                                                                     | in another region   |
| RTO         |                                               |                   |                                                               | -                                                                                           | in minutes          |

### Managed disk snapshots

- Resource type `Microsoft.Snapshot`
- A snapshot is a read-only full copy of a managed disk, you could create a incremental one based on a previous snapshot
- Snapshots exist independent of the source disk
- A snapshot can be used to create new managed disks
- Billed based on actual used size, eg. if you create a snapshot of a managed disk with provisioned capacity of 64 GiB and actual used size of 10 GiB, the snapshot is billed only for the used size of 10 GiB

### Azure Disk Backup

- Doesn't interrupt VM
- Doesn't affect application performance
- Cost-effective
- Supports multiple backups per day
- Supports both OS and data disks (including shared disks)
- Can be used alongside Azure VM backup

### Azure VM Backup

![Azure VM backup job](images/azure_backup-vm-snapshot.png)

- When the snapshot is finished, a recovery point of type "**snapshot**" is created, which offers "instant restore"
- When the snapshot is transferred to the vault, the recovery point type changes to "snapshot and vault"
- To reduce backup and restore times, the snapshots are retained locally, the retention value is configurable between 1 to 5 days
- Incremental snapshots are stored as page blobs

### VM restore points

![Restore point hierarchy](images/azure_vm-restore-point-hierarchy.png)

- Grouped in collections (resource type `Microsoft.RestorePointCollection`), one collection for one VM
- Application consistent for Windows, file system consistent for Linux
- Each restore point stores
  - a VM's configuration
  - a snapshot for each attached managed disk
- Optionally exclude any disk to reduce cost
- Incremental, first restore point stores a full copy
- Restore:
  - individual disks
  - or a VM: restore all relevant disks and attach them to a new VM

Limitations:
- Only for managed disks
- No support for Ultra-disks, Ephemeral OS disks, and Shared disks
- No support for VMSS in Uniform orchestration mode
- Can't move VM to another RG or Subscription when the VM has restore points

### Azure Site Recovery

- Run on virtual or physical machines
- Replicates continuously for Azure and VMware VMs
- Replication frequency for Hyper-V is as low as 30 seconds
- Can replicate to any Azure region
- Protect from major disaster scenarios when a whole region experiences an outage
- The managed disks are replicated to DR site, VMs are created in DR site when failover occurs
- Recover your applications with a single click in minutes
- On-demand test failover, without affecting your prod workloads or ongoing replication
- Recovery plans to orchestrate failover and failback of entire application running on multiple VMs, this feature is integrated with Automation runbooks

![Azure Site Recovery](images/azure_backup-site-recovery.png)


## Images

You can create an image from
  - custom VHD in a storage account
  - or a generalized(sysprepped), *deallocated* VM

When you create an image from a VM
  - this image contains all managed disks associated with the VM, including *both OS and data disks*
  - you could create hundreds of VMs from this managed custom image without the need to copy or manage any storage account

**Images vs. Snapshots**

  - An image includes **all of the disks** attached to a VM
  - A snapshot applies only to **one disk**
  - If a VM has only one disk (the OS disk), then you could take either a snapshot or an image of it and create a VM from either

## On-prem file backup

![On-prem file and folder backup](images/azure_on-prem-file-folder-backup.png)

The Backup Agent can be deployed to any Windows Server VM or physical machine.


## Region failover

Though redundancy at AZ (Availability Zone) level should be enough in most cases, you should still prepare for a region-wide disaster.
There are a few things to consider based on resource types:

- Compute:
  - These resources are often regional, they don't have service level failover mechanism, you need to prepare it yourself
  - Azure Site Recovery could replicate managed disks to another region
  - VM, VMSS, AKS
    - Active-passive: start them up in DR region during failover
    - Active-active: keep a duplicate running in DR region
  - Azure Compute Gallery
    - Replicate artifacts to another region
  - Azure Container Registry
    - Replicate artifacts to another region
- Key vault:
  - You need a separate key vault in DR region
  - CMK (Customer managed keys) should be different in DR region
  - If keys/secrets need to be shared, you may need to use your own scripts or the backup/restore function to replicate the keys/secrets
- Relational DBs: SQL, MySQL, PostgreSQL
  - Usually have a failover group setup, data in primary region is asynchronously replicated to other regions
  - Usaully have a active-passive setup, you only write to the pirmary region and read from any region
  - CMK is at the DB server level, it should be different in each region
- CosmosDB
