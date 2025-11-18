# Azure Backup

- [Vaults](#vaults)
  - [Recovery Service Vault](#recovery-service-vault)
  - [Backup Vault](#backup-vault)
  - [Alerting](#alerting)
- [Concepts](#concepts)
  - [Backup](#backup)
  - [Restore](#restore)
  - [Consistency](#consistency)
- [VM backup](#vm-backup)
  - [Disk Snapshot](#disk-snapshot)
    - [Create a disk from a snapshot](#create-a-disk-from-a-snapshot)
  - [Azure Disk Backup](#azure-disk-backup)
  - [VM restore points](#vm-restore-points)
  - [Azure VM Backup](#azure-vm-backup)
  - [Azure Site Recovery](#azure-site-recovery)
- [Images](#images)
  - [Images vs. Snapshots](#images-vs-snapshots)
- [On-prem file backup](#on-prem-file-backup)
- [Region failover](#region-failover)


## Vaults

**Backup Center**: A single unified interface to efficiently manage backups spanning multiple workload types, vaults, subscriptions, regions and tenants.

### Recovery Service Vault

- Resource type `Microsoft.RecoveryServices/vaults`
- Used to back up these workloads: Azure VMs, SQL in Azure VMs, Azure Files, SAP HANA in Azure VMs, on-prem workloads via MARS, MABS, System Center DPM
  - For Azure Files, backup is kept in the source storage account, won't be copied to the vault storage, and a lock will be put on the storage account, so it won't be deleted accidentally
- Storage redundancy setting (does not apply to the operational tier): LRS, GRS
  - Upgrades to RA-GRS if cross-region restore feature enabled
- Unlimited data transfer: Azure Backup doesn't limit or charge inbound or outbound data transfers.
- Storage tiers:
  - **Operational tier**
    - First phase of VM backup, copied to vault tier later
    - Instant restore
    - For VM: Restore Point Collection is saved in a dedicated RG (`AzureBackupRG_*`) in your subscription
  - **Vault-standard tier**
    - For all workload
    - An auto-scaling set of storage accounts in a **Microsoft managed tenant**
  - **Vault-archive tier**
- Could have "soft delete" enabled, first 14 days are free
- To delete an RSV, you need to:
  - Stop and delete all backup items
  - Disable replication for site recovery
  - Remove private endpoints

### Backup Vault

- Resource type `Microsoft.DataProtection/BackupVaults`
- Supports certain **newer** workloads: Azure Disks, Azure Blobs, Azure Databases for PostgreSQL servers
  - For Azure Blobs, backup is kept in the source storage account, won't be copied to the vault storage ? could be in a vault storage now ?
  - For Azure Disks, backup is kept as snapshots in your subscription, won't be copied to the vault storage ? could be in a vault storage now ?
- A config is called "backup instance"
- Three types of redundancy: LRS, ZRS, GRS
- Storage tiers:
  - Operational data store
  - Vault storage
- Has Soft delete settings, free up to 14 days
- Similar to Recovery Service Vault, but does not support:
  - Integrated monitoring
  - Recovering of individual folders and files

### Alerting

Previously Azure Backup and Azure Site Recovery did not suport Azure Monitor alert rules, only native built-in alerts.

Now it's supported.


## Concepts

### Backup

- **Backup extension**: extension to Azure VM agent, specific to workload types (SQL, SAP HANA, etc), managed by Azure Backup

- **MABS / Azure Backup Server**: protect application workloads such as Hyper-V VMs, SQL Server, SharePoint Server, etc from  a single console

- **MARS Agent**: to backup data from on-prem machines and Azure VMs to a Recovery Services vault in Azure

- **Backup policy**:
  - backup schedule: when, how often, snapshot method (full, incremental, differential)
  - retention rules: how long those snapshots are retained
    - A backup policy can have **multiple retention rules**
      - a default one target all backups
      - custom ones can target first successful backup of every day/week

- **GFS Backup Policy**
  - Grandfather-father-son
  - Define weekly, monthly, and yearly backup schedules in addition to the daily schedule
  - Each of these sets of backup copies can be configure to be retained for different durations

- **Disk Snapshot**
  - Resource type `Microsoft.Snapshot`
  - a *full, ready-only* copy fo a virtual hard drive or an Azure File share, you could create an incremental one based on a previous snapshot
  - Can be created for attached or unattached disks
  - Snapshots exist independent of the source disk
  - Like a disk, it can be
    - Downloaded
    - Set CMK (disk encryption set)
    - Accessed through private endpoint with "Disk Access" resource
  - A snapshot can be used to create new managed disks
  - Billed based on actual used size, eg. if you create a snapshot of a managed disk with provisioned capacity of 64 GiB and actual used size of 10 GiB, the snapshot is billed only for the used size of 10 GiB

- **System state backup**: back up operating system files


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

|               | Disk snapshots              | VM restore points                                                                           | Azure Disk Backup                                       | Azure VM Backup                                                 | Azure Site Recovery |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------- | ------------------- |
| Backup Center | No                          | No                                                                                          | Yes                                                     | Yes                                                             | No                  |
| Suited for    | dev/test, quick and simple  | small number of VMs, REST API                                                               | production                                              | production                                                      | regional outage     |
| What          | per managed disk            | entire VM (could exclude specified data disks)                                              | per managed disk                                        | entire VM (could exclude specified data disks)                  | managed disks       |
| Consistency   | file system consistent      | application-consistent                                                                      | crash-consistent                                        | application-consistent                                          | -                   |
| Agent         | No                          | VSS writer (for Windows), pre/post scripts (for Linux) required for application consistency | No                                                      | Yes                                                             | -                   |
| Storage       | -                           | -                                                                                           | operational tier only (LRS or ZRS), not copied to vault | operational and vault tier, geo-replicated to paired region     | any region          |
| Restore       | a new disk                  | single disk or a new VM                                                                     | a new disk                                              | entire VM or specific files/folder, could to a secondary region | in another region   |
| RTO           | -                           | -                                                                                           | instant restore                                         | -                                                               | in minutes          |
| Cons          | manual, management overhead | no shared disks                                                                             | -                                                       | impact on VM performance                                        | -                   |

### Disk Snapshot

- A snapshot could be of type:
  - **Full**
  - **Incremental**: a partial copy of the disk based on the difference between the last snapshot
    - they all show as the same size as the original disk
    - if you have a series of incremental snapshots like `snap-001`, `snap-002`, ..., `snap-010`, you could still delete any snapshot
- Original disk **can be deleted** without deleting its snapshots

#### Create a disk from a snapshot

- The new disk size **could be bigger** than the original one, not smaller, the extra space would be "unallocated"
- An OS disk snapshot could be used to create a new VM or VM image version


### Azure Disk Backup

This is a managed version of the "disk snapshot" backup method

Backup

- No agent, no impact on application performance
- Cost-effective, incremental
- Supports multiple backups per day
- Supports both OS and data disks (including shared disks)
- Operational tier backup only, it creates resources in a snapshot RG in your subscription, won't copy to Backup vault storage
- Always stored on most cost-effective storage: **standard HDD** (LRS or ZRS depending on region)
- Older snapshots are deleted according to the retention policy
- Can be used alongside Azure VM backup (eg. back up VM once a day, back up critical disks multiple times a day)
- Limit to 200 snapshots per disk

Backup vault

- Uses Backup vault, not Recovery Services vault
- A "backup instance" is created within the backup vault, allows you to view operation health, trigger on-demand backup, restore
- Backup vault can be in a different subscription, but must be in the same region as the source disk
- Backup vault uses a managed identity, requires permissions on the source disk, snapshot RG and the restore target RG, see https://learn.microsoft.com/en-us/azure/backup/disk-backup-faq?source=recommendations#what-are-the-permissions-used-by-azure-backup-during-backup-and-restore-operation-

Restore

- Can restore to a different subscription

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

### Azure VM Backup

![Azure VM backup job](images/azure_backup-vm-snapshot.png)

- This is a managed version of the "VM restore points" backup method
- Policy types:
  - Standard: once-a-day, 1-5 days operational tier (LRS)
  - Enhanced: multiple times a day, 1-30 days operational tier (ZRS)
- The snapshot of VM is saved as a **"Restore Point Collection" resource** in a **dedicated resource group** (`AzureBackupRG_*`) in your subscription
- The restore point type is "**snapshot**" when first created, after the snapshot is transferred to the vault, the type changes to "**snapshot and vault**"
- Restore options:
  - Files: a script is provided for you to attach disks to a VM, to retrieve files
  - Disks: replacing existing disks in the source VM
  - Disks: new unattached disks
  - VM: a new VM, including VM, disks, NIC, public IP

### Azure Site Recovery

- Not a independent resource type, part of Recovery Service Vault
- Relies on a SiteRecovery agent running in VM or physical machines
- You could define a **mapping of properties** between source VM to destination VM: like VM name, NIC name, VNET, IP, etc
- Replicates continuously for Azure and VMware VMs
- Replication frequency for Hyper-V is as low as 30 seconds
- Can replicate to any Azure region
- Protect from major disaster scenarios when a whole region experiences an outage
- The managed disks are replicated to DR site, VMs are only created when failover occurs, you could reserve compute capacity at the destination beforehand
- Recover your applications with a single click in minutes
- On-demand test failover, without affecting your prod workloads or ongoing replication
- **Recovery plans** can be created to orchestrate failover and failback of entire application running on **multiple VMs**, this feature is integrated with Automation runbooks

![Azure Site Recovery](images/azure_backup-site-recovery.png)


## Images

You can create an image from either a VHD file or a generalized(sysprepped) and *deallocated* VM

Two types of VM images:

  - **Generalized**: VMs created from this image require hostname, admin user, and other VM related setup to be completed on first boot
    - CLI:
      ```sh
      az vm deallocate -g MyResourceGroup -n MyVm
      az vm generalize -g MyResourceGroup -n MyVm
      az vm capture -g MyResourceGroup -n MyVm --vhd-name-prefix MyPrefix
      ```
    - After been generalized, the VM CAN'T be used anymore, you need to use the image to create new VMs

  - **Specialized**: VMs created from this image are completely configured and do not require parameters such as hostname and admin user/password

### Images vs. Snapshots

|               | Snapshot                 | Image                     |
| ------------- | ------------------------ | ------------------------- |
| Includes      | one disk (OS or data)    | all OS and data disks     |
| Create new VM | only if OS disk snapshot | yes                       |
| Type          | full / incremental       | generalized / specialized |


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
  - Usually have a active-passive setup, you only write to the primary region and read from any region
  - CMK is at the DB server level, it should be different in each region
- CosmosDB
