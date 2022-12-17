# Azure Backup

- [Features](#features)
- [Concepts](#concepts)
- [VM backup](#vm-backup)
  - [Backup job](#backup-job)
- [Images](#images)
- [On-prem file backup](#on-prem-file-backup)
- [Backup and Recovery](#backup-and-recovery)
- [Region failover](#region-failover)

## Features

- Storage replication options

  - LRS: replicated three times in a datacenter
  - GRS: replicate to a secondary region

- Unlimited data transfer: Azure Backup doesn't limit or charge inbound or outbound data transfers.

## Concepts

- Backup center

  - A single unified interface to efficiently manage backups spanning multiple workload types, vaults, subscriptions, regions and tenants.
  - Centered on datasource, you could filter views by datasource subscription, resource group or tags.
  - Supported datasources:
    - Azure VM
    - Azure Files
    - Azure Blobs
    - Azure-manged disks
    - SQL in Azure VM
    - SAP HANA in Azure VM
    - Azure Database for PostgreSQL Server

- Recovery Service Vault

  - A storage entity in Azure, could be LRS or GRS(default, data replicated to the paired region)
    - Some backups could be restored to files, and then copied to another region
  - Can be used for both Azure and on-prem workloads

- Backup policy

  Defines when to take snapshots, how long those snapshots are retained

## VM backup

There are several backup options for VMs

![VM backup options](images/azure_backup-vm-options.png)

- Managed disk snapshots

  - Suitable for **dev/test** environments
  - A snapshot is a read-only full copy of a managed disk
  - Snapshots exist independent of the source disk
  - A snapshot can be used to create new managed disks
  - Billed based on actual used size, eg. if you create a snapshot of a managed disk with provisioned capacity of 64 GiB and actual used size of 10 GiB, the snapshot is billed only for the used size of 10 GiB

- Azure Backup

  - Suitable for VMs running **production** workloads
  - Supports **application-consistent backups** for both Windows and Linux VMs
  - Creates recovery points that are stored in geo-redundant recovery vaults
  - When you restore from a recovery point, you can restore the whole VM or just specific files
  - Requires VM Agent been installed on the VM

- Azure Site Recovery

  - Can replicate to any Azure region
  - Protect from major disaster scenarios when a whole region experiences an outage
  - The managed disks are replicated to DR site, VMs are created in DR site when failover occurs
  - Recover your applications with a single click in minutes

  ![Azure Site Recovery](images/azure_backup-site-recovery.png)

### Backup job

![Azure VM backup job](images/azure_backup-vm-snapshot.png)

- When the snapshot is finished, a recovery point of type "snapshot" is created
- When the snapshot is transferred to the vault, the recovery point type changes to "snapshot and vault"
- To reduce backup and restore times, the snapshots are retained locally, the retention value is configurable between 1 to 5 days
- Incremental snapshots are stored as page blobs

## Images

You can create an image from
  - custom VHD in a storage account
  - or a generalized(sysprepped), deallocated VM

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



## Backup and Recovery

TODO: what's the difference between Recovery Services vault and Backup vault ?


## Region failover

Though reduncy at AZ (Availability Zone) level should be enough in most cases, you should still prepare for a region-wide disaster.
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
