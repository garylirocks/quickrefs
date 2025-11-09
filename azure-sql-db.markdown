# Azure SQL DB

- [Overview](#overview)
- [Azure SQL Database (SQL DB)](#azure-sql-database-sql-db)
  - [Concepts](#concepts)
  - [Purchasing models](#purchasing-models)
  - [Deployment models](#deployment-models)
  - [High availability](#high-availability)
  - [Scaling](#scaling)
  - [Networking](#networking)
  - [Free offer](#free-offer)
  - [Automatic tuning](#automatic-tuning)
  - [Elastic query](#elastic-query)
  - [Elastic jobs](#elastic-jobs)
  - [Query performance Insights (QPI)](#query-performance-insights-qpi)
  - [Migration options](#migration-options)
    - [Offline](#offline)
    - [Online](#online)
  - [Hyperscale](#hyperscale)
  - [SQL DB in Fabric](#sql-db-in-fabric)
- [SQL Managed Instance (SQL MI)](#sql-managed-instance-sql-mi)
  - [Connectivity](#connectivity)
  - [Backup and restore](#backup-and-restore)
  - [High availability](#high-availability-1)
  - [Migration options](#migration-options-1)
    - [Offline](#offline-1)
    - [Online](#online-1)
  - [Machine Learning Services](#machine-learning-services)
- [Common PaaS features (SQL DB and SQL MI)](#common-paas-features-sql-db-and-sql-mi)
  - [Backup](#backup)
  - [Disaster recovery](#disaster-recovery)
    - [Notes](#notes)
    - [Failover groups](#failover-groups)
  - [Auditing](#auditing)
- [SQL Server on Azure VM (SQL on VM)](#sql-server-on-azure-vm-sql-on-vm)
  - [Licensing models](#licensing-models)
  - [Storage](#storage)
  - [Performance considerations](#performance-considerations)
  - [Table partition](#table-partition)
  - [Hybrid scenarios](#hybrid-scenarios)
  - [HADR](#hadr)
    - [HA options](#ha-options)
    - [Always On Availability Group](#always-on-availability-group)
    - [Failover Cluster Instance (FCI)](#failover-cluster-instance-fci)
    - [DR options](#dr-options)
  - [Backup](#backup-1)
- [Authentication and authorization](#authentication-and-authorization)
  - [Concepts](#concepts-1)
  - [Authentication](#authentication)
  - [Entra auth (contained user)](#entra-auth-contained-user)
  - [Entra auth (server principals - logins)](#entra-auth-server-principals---logins)
  - [Applications](#applications)
  - [Authorization](#authorization)
- [Data security](#data-security)
  - [Transparent data encryption (TDE)](#transparent-data-encryption-tde)
  - [Dynamic data masking](#dynamic-data-masking)
  - [Always Encrypted](#always-encrypted)
  - [Classification and labeling](#classification-and-labeling)
- [Database Watcher](#database-watcher)
- [Azure SQL Edge](#azure-sql-edge)

## Overview

Deployment options:

![Deployment options](./images/azure_sql-db-deployment-options.png)

|                   | SQL Databases (SQL DB)                  | SQL Managed Instance (SQL MI)               | SQL Server on VM (SQL on VM) |
| ----------------- | ------------------------------ | ---------------------------------- | ---------------- |
| Type              | PaaS                           | PaaS                               | IaaS             |
| Why choose        | Modern cloud solution          | Instance-scoped features           | OS level access  |
| Purchasing models | DTU, vCore                     | vCore                              | -                |
| HA                | geo-replication, auto-failover | automated backup, no auto-failover | no auto-failover |


## Azure SQL Database (SQL DB)

- PaaS, abstracts both the OS and SQL Server instance
- Hyperscale storage: up to 100TB
- Autoscaling for unpredictable workloads (serverless)

### Concepts

- **Elastic pools**: you buy a set of compute and storage resources that are shared among all the databases in the pool
  - Either DTU or vCore
  - Can set resources per database
  - Could be resized online, need to reconnect after resizing
- **Logical SQL DB Server**: a logic container for databases (could be a mix of single databases and elastic pools), it defines
  - Access: connection string (FQDN), location, authentication method (SQL auth, Entra auth, or both)
  - Business continuity management: failover groups
  - Security: networking, TDE, Defender for Cloud, identity, auditing
  - A server could contain databases of different purchasing models

### Purchasing models

This is at database level, NOT server level

![Purchasing models](./images/azure_sql-db-purchasing-models.png)

- DTU: a bundled measure of compute, storage and I/O resources
- vCore: select compute and storage resources independently, allows you to use Azure Hybrid Benefit for SQL Server, compute tier could be
  - Provisioned:
    - Pre-allocated compute resources
    - Billed hourly on vCores configured
  - Serverless:
    - Auto-scale, you set min and max vCores
    - Billed per second
    - Not for "Business Critical" tier
    - Auto-pause could be enabled for "General Purpose" tier, delay from 15 min to 7 days
    ![Auto pause delay](./images/azure_sql-serverless-auto-pause.png)
    - When paused:
      - No vCore charge, only storage charged when paused
      - Application needs retry logic
    - Limitations (no constant background processes):
      - No Geo-replication
      - Long-term backup retention
      - A job database in elastic jobs
      - The sync database in SQL Data Sync

| Service tier            | Basic (DTU) | Standard (DTU) | Premium (DTU) | General Purpose (vCore) | Business Critical (vCore) | Hyperscale (vCore) |
| ----------------------- | ----------- | -------------- | ------------- | ----------------------- | ------------------------- | ------------------ |
| Local redundant support | Yes         | Yes            | Yes           | Yes                     | Yes                       | Yes                |
| Zone redundant support  | No          | No             | Yes           | Yes                     | Yes                       | Yes                |
| Max data size | 2GB | 1TB | 4TB | 4TB                     | 4TB                       | 100TB                |

Tier features:

- Basic (DTU)
  - 5 DTUs
- Standard (DTU)
  - Up to 3000 DTUs
- Premium (DTU)
  - Up to 4000 DTUs
  - Read scale-out
  - Zone redundant option
- General Purpose (vCore)
  - Budget-friendly
  - Remote storage (Premium SSD)
  - Provisioned or serverless compute (supports auto-pause)
- Business Critical (vCore)
  - Local SSD storage
  - **Highest** availability and performance
  - **Lowest** latency
  - Built-in read-only replica
  - In-memory OLTP
  - More memory per core
  - No "serverless" option
- Hyperscale (vCore)
  - Horizontal scaling (adding compute nodes as data sizes grow)
  - Only single SQL database (seems could be used in elastic pool, what does this mean ?)
  - Provisioned or serverless compute (No auto-pause)
  - Up to 4 HA secondary replicas

### Deployment models

- Single DB: dedicated compute and storage
- Elastic pool:
  - Pooled compute and storage
  - Either DTU or vCore-based
  - Suitable for SaaS, multitenant architecture

### High availability

All the options below have **RPO == 0**, **RTO < 60 seconds**

- Basic, Standard and General Purpose

  ![General purpose architecture](./images/azure_sql-general-purpose.png)

  *Local redundant*

  ![General purpose zone-redundant](./images/azure_sql-general-purpose-zone-redundant.png)

  *Zone-redundant (not available for Basic and Standard tiers)*

  - tempdb in locally attached SSD
  - data and log files are in Azure Premium Storage

- Premium and Business Critical

  ![Business critical architecture](./images/azure_sql-business-critical.png)

  *Local redundant*

  ![Business critical zone-redundant](images/azure_sql-business-critical-zone-redundant.png)

  *Zone-redundant*

  - Data and log files are stored on direct-attached SSD
  - It deploys an Always On availability group (AG) behind the scenes
  - There are three secondary replicas, **only one** of them could be used as a read-only endpoint
  - A transaction can complete a commit when at least one the secondary replicas has hardened the change for its transcation log
  - Highest performance and availability of all Azure SQL service tiers

- Hyperscale

  ![Hyperscale architecture](./images/azure_hyperscale-architecture.png)

  - Page servers (sharding) serve database pages out to the compute nodes on demand
  - Auto-scale quickly up to 128TB
  - Data changes from the primary compute replica are propagated through the log service: it gets logs from primary compute replica, persists them, forwards them to other compute replicas and relevant page servers
  - Transcations can commit when the log service hardens to the landing zone
  - Different types of replicas
    - **High-availability replicas**: up to 4, share primary's page servers, same region, same SLO
    - **Named replicas**: up to 30, share primary's page servers, same region, SLO can be different
    - **Geo replicas**: up to 4 in the same or multiple regions, its own copy of the data


### Scaling

- Vertical scaling
- Horizontal scaling
  - Read Scale-out
  - Sharding
    - Hyperscale does this automatically, or you can do it manually with some tools
    - Partitions database into multiple databases/shards
    - Shards can be in different regions, and scale independently
    - The solution uses a special database named shard map manager, which maintains mapping about all shards
- Connection interruption may happen when:
  - Scaling requires an internal failover
  - Adding or removing DB to an elastic pool

Read Scale-out in a Business Critical tier:

![Read Scale-out](images/azure_sql-db-business-critical-service-tier-read-scale-out.png)

- You set **connection string option** to decide whether the connection is routed to the write replica or a read-only replica.
- Data-changes are propagated asynchronously
- Read scale-out with one of the secondary replicas supports **session-level consistency**, if the read-only session reconnects, it might be redirected to another replica

### Networking

Applies to all databases in a server.

There is a networking setting called "**Allow Azure services and resources to access this server**",
  - when turned **ON**, it creates a subresource `Microsoft.Sql/servers/<sql-name>/firewallRules/AllowAllWindowsAzureIps`, this enables connection in both of the following scenarios, you don't need to allow the client subnet:
    - Client Azure VM subnet does not have a `Sql` ServiceEndpoint (via Internet)
    - Client Azure VM subnet has a `Sql` ServiceEndpoint (via ServiceEndpoint)
  - when turned **OFF**, you need to either
    - Allow the client subnet (to connect via ServiceEndpoint)
    - Allow public IP (to connect via Internet)

### Free offer

- 100,000 vCore seconds per month, 32GB data storage
- Free limit exhausted, either:
  - pause the DB for the month, ensure it's free
  - allow over usage, get billed

### Automatic tuning

- Identify expensive queries
- Forcing Last Good Execution Plan
- Adding/removing Indexes

### Elastic query

Run T-SQL queries spanning multiple databases

Supports both vertical and horizontal partitioning (sharding)

### Elastic jobs

SQL Server Agent replacement

- Equivalent to the Multi-Server Admin feature on an on-prem SQL Server
- Useful for DB maintenance tasks
- Execute T-SQL across several target DBs (single, elastic pool, shard map), could cross Azure subs and region
- Runs in parallel
- Not supported by SQL MI

### Query performance Insights (QPI)

Helps find the queries to optimize

### Migration options

#### Offline

Tools:

- Azure Database Migration Service (offline)
- Azure Migrate (offline)
- Import Export Wizard/BACPAC (offline)
- Partial data migration:
  - Bulk Copy - bcp utility (offline)
  - Azure Data Factory (offline)

Migrate:

- Azure SQL Migration extension for Azure Data Studio
  - Uses Azure Database Migration Service (`Microsoft.DataMigration/SqlMigrationServices`)
    - This needs Azure Data Factory's Self-hosted Integration Runtime (SHIR) to handle connectivity and upload backups to Azure
  - Ideal for small to mid-sized DBs
  - You can select which tables to migrate
  ![SQL Migration extension architecture](./images/azure_sql-migration-extension-architecture.png)
  - The DB schema needs to be created in the target first (using BACPAC or SQL Database Projects extension)
  - Could migrate to any Azure SQL offerings, not limited to SQL DB
- Import Export Wizard/BACPAC (offline)
  - `.bacpac` file is a compressed file containing metadata and data
  - You can import in Azure Portal or use `SqlPackage.exe` on localhost
  - Use a higher service tier and scale down after

Performance Considerations:

- Network bandwith can accommodate maximum log ingestion rate
- Use a high tier for transfer, and scale down after
- Disable auto update, autostats, triggers, and indexes during migration
- Partition tables and indexes, drop indexed views, and recreate them after migration

#### Online

Only method: transactional replication

![Transact replication](./images/azure_sql-transact-replication.png)

- Publisher could be SQL on-prem, on VM, SQL MI
- Azure SQL DB could be a push subscriber for both transactional and snapshot replication
- Steps:
  - Take an initial snapshot of publisher DB object and data
  - Subsequent changes to data and schema at the Publisher are delivered in near real-time
- Need to be configured via SSMS, or T-SQL, NOT Azure Portal
- Can only use SQL auth for the target SQL DB

### Hyperscale

- Max data size over 100TB
- Horizontal scaling (adding compute nodes) as data size grows
- Can be converted to, but not back to a standard SQL DB
- Ideal for most workloads
- Storage expands as needed
- Operation times not dependent on data size
  - Backup instantly (using snapshots in Blob storage)
  - Scaling in minutes
  - Restore in minutes
- Scaling
  - Up/Down - CPU and memory
  - In/Out - read replicas
- In your connection string, set `ApplicationIntent` argument to `ReadOnly` to route to read-only replicas
- Row-Level Security (RLS): access to specific rows in a table based on user characteristics, suck as group memberships or execution context


### SQL DB in Fabric

// TODO


## SQL Managed Instance (SQL MI)

- A PaaS service, need a dedicated subnet in a vNet
  - Could have both public and private endpoint
- No need to manage a VM
- Tiers
  - General Purpose (vCore)
  - Business Critical (vCore) - (has readable secondary)
- No DTU model
- Supports up to 100 DBs
- Most of the SQL Server instance-scoped features are still available:
  - Access to tempdb
  - Access to the system databases
  - SQL Server Agent
  - Cross-database queries and transactions (not supported by Azure SQL DB)
  - Common language runtime (CLR)
  - Service Broker
  - Database Mail
  - Linked servers
  - Distributes transcations
  - Machine Learning Services

### Connectivity

Via TDS endpoints

### Backup and restore

Similar to SQL DB. See below.

Notes:
- Can't restore to overwrite an existing DB
- Only be restored to another SQL MI, NOT to SQL DB or SQL on VM
  - Both must be in the same Azure sub and region
  - Only restore individual DBs, not the entire MI instance
  - For a encrypted DB, you need access to the certificate or asymmetric key used for encryption
- Difference to SQL DB:
  - Support copy-only backup to Azure blob storage
  - To take a user-initiated copy-only backup, you must disable TDE for the specific database

### High availability

Has General Purpose and Business Critical service tiers, and high availability options are similar to the options of Azure SQL Databases, see details here https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/high-availability-sla

### Migration options

SQL MI is often the better PaaS option (over SQL DB) for migration from on-prem

#### Offline

- Native backup and restore (easiest)
  ```sql
  BACKUP DATABASE YourDatabase TO URL = 'https://youraccount.blob.core.windows.net/yourcontainer/yourdatabase.bak' WITH COPY_ONLY
  RESTORE DATABASE YourDatabase FROM URL = 'https://youraccount.blob.core.windows.net/yourcontainer/yourdatabase.bak'
  ```
- BACPAC using `SqlPackage`
  - Unlike SQL DB, can't do this in Azure Portal
  - Use `SqlPackage.exe`
- Bulk Copy (bcp)
- ADF
- Azure SQL Migration extension for Azure Data Studio
  - Similar to migrate to SQL DB

#### Online

- Log replay service (LRS)

  ![Log Replay Service](./images/azure_sql-log-replay-service.png)
  - SQL MI only
  - Uses log shipping
  - You must have a storage account, with the SQL backup files
  - More control
  - Start it using PowerShell
  - LRS job is part of SQL MI
    - Will be cancelled after 30 days
    - The MI resource needs access to the storage account
  - Backup and restore performance best practices
    - Split full and diff backups into multiple files
    - Use backup compression
    - Use `CHECKSUM` to speed up restore
- Managed Instance link
  ![Managed Instance link](./images/azure_sql-managed-instance-link-feature.png)
  - Set up using SSMS or T-SQL/PowerShell
  - Using distributed availability group (DAG), replicating data between on-prem and Azure
  - One DB per link
  - A DB can be replicated to multiple SQL MIs
  - A SQL Server instance can have multiple links
  - SQL Server 2022 supports two-way replication (failover to MI, then failback to SQL Server)
  - Can be used to offload read-only workloads
- Transactional replication (online or offline)
  - For large/complex DBs
  - SQL MI can be a publisher, distributor, and subscriber

### Machine Learning Services

- Supports Python and R packages
  - T-SQL store procedure supports Python and R
- Available on SQL MI, SQL on VM, on-prem SQL, NOT SQL DB
- To enable, run
  ```sql
  EXEC sp_configure 'external scripts enabled', 1;
  RECONFIGURE WITH OVERRIDE;
  ```
  Enables execution of external scripts using `sp_execute_external_script`


## Common PaaS features (SQL DB and SQL MI)

### Backup

- Manual backup NOT supported
- Default to GRS storage (could opt for LRS or RA-GRS)
- Continuous automatic backup
  - Transcation log: 5 to 10 minutes
  - Differential: every 12 or 24 hours
  - Full: every week
- Default retention
  - 1 to 35 days (configurable, 7 by default)
  - Max 7 days for Basic (DTU), General Purpose (vCore)
- Long term retention (LTR)
  - Disabled by default
  - Up to 10 years
  - Separate retention for weekly/monthly/yearly backups
- Restore:
  - Can't use T-SQL `RESTORE DATABASE` command
  - Can use PowerShell or Azure CLI
  - Exiting DB must be dropped or renamed, can't overwrite
  - Point-in-time restore (PITR)
    - 1 to 35 days
    - Only to the same server
  - Geo-restore
    - Allows restore to another geo region
    - Require geo-redundant backup storage (default option)

Synapse SQL pool:

- Minimum 7 day default retention
- LTR not supported

### Disaster recovery

Comparison between HA and DR:

|         | HA          | DR           |
| ------- | ----------- | ------------ |
| Region  | Same region | Cross region |
| Latency | < 2ms       | 10 ~ 100 ms  |
| Sync    | Sync        | Async        |

DR options:

- Geo replicas
  - Using log shipping to replicate data
  - Set at DB level
  - Separate endpoint for each replica (need to update endpoint when failover)
  - You need to have a logical SQL server in the replica regions to host the replicas
  - SQL DB only, NOT for SQL MI
  - You can failover to a geo replica manually
  - You can have up to 4 geo replicas for Hyperscale DBs
- Automatic failover group
  - Is an abstraction over geo replicas
  - A failover group can include multiple DBs
  - Same endpoint (redirection happens automatically when failover)
  - A DB can only be in one group
  - A SQL server can have multiple failover groups
  - For SQL MI, all databases will be in one failover group

#### Notes

- DR needs to be sized as production, so it can hold all the data
- With Planned failover, there is no data loss
- With Unplanned failover
  - RPO is 1~2 seconds (*if you want absolute no data loss, consider CosmosDB, it has strong consistency - data stored in multiple regions, but your application needs to accept latency*)
  - RTO is <60 seconds
- You should
  - Have a script to failover everything in sequence, instead of doing stuff manually
  - The script should be tested regularly, so you have the confidence it works

#### Failover groups

You can add databases to a failover group, they'll be replicated automatically to a server in a paired region.

A failover group has two listener endpoints:

- Read/write: `fog-demo.database.windows.net`
- Read-only:  `fog-demo.secondary.database.windows.net`

The DNS resolution chain is like:

```
fog-demo.database.windows.net.     30 IN CNAME sql-demo-eus.database.windows.net.
# if private endpoint is enabled
sql-demo-eus.database.windows.net. 30 IN CNAME sql-demo-eus.privatelink.database.windows.net.
...
```

After failover, the primary region changes:

```
fog-demo.database.windows.net.     30 IN CNAME sql-demo-wus.database.windows.net.
# if private endpoint is enabled
sql-demo-wus.database.windows.net. 30 IN CNAME sql-demo-wus.privatelink.database.windows.net.
...
```

Notes:

- You should use these failover listener endpoints in connection string for your application, so you don't need to manually update the connection string when failover happens, the connection is always routed to whichever instance which is currently primary.
- The listener FQDN's ttl is 30 seconds, when failover happens, it allows the FQDN resolves to the new primary region
- Removing a failover group for a single or pooled database does not stop replication, and it does not delete the replicated database.

### Auditing

- Audit logs saved in an Azure storage account
- Advanced Threat Protection analyzes the logs


## SQL Server on Azure VM (SQL on VM)

A version of SQL Server that runs in an Azure VM

- Access to full capabilities of SQL Server
- Responsible for updating and patching the OS and SQL Server
- You could use either Windows or Linux VMs
- SQL Server IaaS Agent Extention is installed automatically (when you deploy from Marketplace). Features:
  - View SQL Server's configuration and storage utilization
  - Automated backup
  - Automated patching
  - Azure KV integration
  - Defender for Cloud integration
  - View Disk utilization in the Portal
  - Flexible licensing
  - Flexible version or edition
  - SQL best practices assessment
- Reasons to choose this:
  - Full control
  - Compatibility with other apps, vendor supports
  - Use "Analysis Services", "Integration Services", "Reporting Services" on the same machine

### Licensing models

- Pay as you Go: SQL Server preconfigured, license included with the cost of VM
- Microsoft Software Assurance (SA) program
  - BYOL (NOT "Hybrid Benefit", which is only for PaaS options ?), need to manually install SQL Server (through a media, or upload a VM image)
  - Report the usage of licenses to Microsoft by using the License Mobility verification form within 10 days

### Storage

- For SQL data, use managed disks
  - For prod data, use Premium SSD (single ms latency) or Ultra Disk
  - Each VM needs at least two disks:
    - OS disk (C:\ for Windows)
    - Temporary disk (D:\ on Windows)
    - Data disks, better be separate (can be pooled to increase IOPS and storage capacity, using Storage Spaces on Windows, or Logical Volume Management on Linux)
  - **Data files** should be stored on their own **pool** with read-caching
  - **Transaction log** files are better stored on their own **pool** without caching
  - **tempdb** in its own pool, or VM's local temp disk (if supported)
  - When deploying Marketplace image, by default, separate drives will be created for SQL Data, SQL Log and tempdb
- Failover Cluster Instance can be built on shared disk or file storage
- For backup, blob (Standard HDD) is ok

### Performance considerations

- Table partitioning (see below)
- Data compression
  - Page compression, more rows could be saved on each page (8 KB)
  - Small CPU overhead, outweighed by IO benefits
  - Implemented at object level, each index or table can be compressed individually
    - Can compress partitions in a partitioned table or index
  - Use `sp_estimate_data_compression_savings` for estimation
  - Row compression: uses variable-length storage format, stores each value in a row in the minimum space
  - Page compression: on top of row compression, use prefix and dictionary compression
  - Columnstore archival compression

Other considerations:
- Enable backup comrepssion
- Limit autogrowth of the DB
- Move all DBs to data disks, including system DBs
- Move error log and trace file directories to data disks
- Enable Query Store
- Schedule SQL Server Agent jobs to run DBCC CHECKDB, index reorganize, index rebuild, and update statistics jobs
- Monitor and manage the health and size of the transaction log files

### Table partition

- When table becomes too large
- Steps:
  - Filegroup creation
  - Partition function creation
  - Partition scheme creation
  - Partition table creation

```sql
-- Partition function
CREATE PARTITION FUNCTION PartitionByMonth (datetime2)
    AS RANGE RIGHT
    -- The boundary values defined is the first day of each month, where the table will be partitioned into 13 partitions
    FOR VALUES ('20210101', '20210201', '20210301',
      '20210401', '20210501', '20210601', '20210701',
      '20210801', '20210901', '20211001', '20211101',
      '20211201');

-- The partition scheme below will use the partition function created above, and assign each partition to a specific filegroup.
CREATE PARTITION SCHEME PartitionByMonthSch
    AS PARTITION PartitionByMonth
    TO (FILEGROUP1, FILEGROUP2, FILEGROUP3, FILEGROUP4,
        FILEGROUP5, FILEGROUP6, FILEGROUP7, FILEGROUP8,
        FILEGROUP9, FILEGROUP10, FILEGROUP11, FILEGROUP12);

-- Creates a partitioned table called Order that applies PartitionByMonthSch partition scheme to partition the OrderDate column
CREATE TABLE Order ([Id] int PRIMARY KEY, OrderDate datetime2)
    ON PartitionByMonthSch (OrderDate) ;
GO
```

### Hybrid scenarios

- Disaster recovery (failover to other geo regions)
  ![SQL hybrid for DR](./images/azure_sql-hybrid-dr.png)
- Backups
  - To Azure Blob Storage via URL or Azure Files (SMB)
- Store on-prem SQL Server data files for user databases (in Azure Storage)
  - Needs low-latency network
  - Lock down storage account using ACLs and Entra ID
- Arc-enabled SQL Servers
  ![SQL hybrid via Arc](./images/azure_sql-hybrid-arc.png)
  - The on-prem host has both Arc Agent and SQL Arc Extension

Networking:

- ExpressRoute or VPN, ER has lower latency, but costs more
- Unable to apply ER between cloud providers ?

### HADR

Most SQL Server HADR solutions are supported on VMs, as both Azure-only and hybrid solutions.

#### HA options

- Always On Availability Groups (AG)
- Always On Failover Cluster Instances(FCIs)

|                   | Always On AG                                                  | Always On FCIs                                                |
| ----------------- | ------------------------------------------------------------- | ------------------------------------------------------------- |
| Unit of failover | a group of databases | server instance |
| Requirement       | A domain controller VM                                        | Shared storage (Azure shared disks, Premium file shares, etc) |
| Best practices    | VMs in an availability set or different AZs                   |                                                               |
| Disaster recovery | an AG could span multiple Azure regions, or Azure and on-prem |                                                               |

#### Always On Availability Group

![AG overview](./images/azure_sql-availability-group.png)

- Rely on the underlying Windows Server Failover Cluster (WSFC)
- Unit of failover is a group of DBs, not the instance
- VMs should be in an availability set, or different availability zones
  - VMs in one availability set could be placed in a proximity placement group, minimize latency
  - VMs in different AZs offer better availability, but a greater network latency
- An AG could be across different Azure regions (for disaster recovery)
- An AG can contain max. of 9 SQL Server instances, Azure only or hybrid
- One primary replica, secondaries could be either sync or async
- Azure only scenario

  <img src="./images/azure_sql-server-on-azure-vm-availability-group.png" width="400" alt="Always On availability group overview" />
- Hybrid scenario

  <img src="images/azure_sql-server-hybrid-dr-alwayson-ag.png" width="400" alt="Always On AG hybrid" />

  With Software Assurance, Passive and DR instances do not require liscenses

  <img src="images/azure_sql-server-hybrid-failover-liscense.png" width="400" alt="Always On AG free DR license" />


#### Failover Cluster Instance (FCI)

- Relies on WSFC
- Provides high availability for an entire instance, in a single region
- HA only, no DR (limited in a single region)
- AG is recommended in most cases, use FCI only for on-prem migration if needed
- An FCI is a single SQL Server instance that's installed across WSFC nodes (could be across multiple subnets)
- On the network, an FCI appears to be a single instance on a single computer
- SQL Server files needs to be on a shared storage, only the active node can access it at one time, a few options:
  - Azure shared disks
  - Premium file shares
  - Storage Spaces Direct(S2D)
- Cluster quorum supports using:
  - a disk witness
  - a cloud witness
  - a file share witness

#### DR options

DR usually means backup and restore your data in another region

- Always On AG (replicas in another region)
- Backup (see below)
  - To GRS/RA-GRS storage
  - Use Azure Backup
- Log shipping
- Azure Site Recovery
  - Not recommended
  - Need to set a higher recovery point (potential loss of data)
  - Best for stateless environments (eg. web servers), instead of SQL VM

### Backup

- Manual Backup
  - Back up to attached disks or Blob storage (aka. "Back up to URL" ?)
  - Could use SQL Agent jobs
  - Use SSMS or SQL scripts

- Automated Backup
  - Provied by SQL Server IaaS Agent Extension
  - Stored in a storage account you specify (aka. "Back up to URL" ?)
  - Backups retained up to 90 days
  - With SQL Server 2016 and later: manual backup schedule and time window, backup frequency
  - To restore: locate the backup files and restore using SQL Server Management Studio or Transact-SQL commands

- Azure Backup for SQL VMs
  - Azure Backup benefits: zero-infrastructure, long-term retension, central management
  - Azure Backup installs a workload backup extension on the VM
  ![Workload backup extension](./images/azure_sql-on-vm-backup-extension.png)
  - Additional features for SQL Server on VMs:
    - Individual database level backup and restore
    - Support for SQL Always On
    - Workload-aware backups that supports - full, differential, and log
    - SQL transaction log backup RPO up to 15 minutes
    - Point in time recovery up to a second
  - To restore, do it in Azure Backups, not with SSMS or Transact-SQL


## Authentication and authorization

This section applies to Azure SQL DB, Azure SQL MI, or Azure Synapse.

### Concepts

- Security principals:
  - Entities with certain permissions
  - At either server level or database level
  - Can be individuals or collections
  - There are several sets in SQL Server, some have fixed membership, some sets have a membership controlled by the SQL Server administrators
- Securables scopes:
    - Server
    - Database
    - Schema
- Schema
  - A collection of objects, allows objects to be grouped into separate namespaces
  - Every user has a default schema (if no, then it's `dbo`)
  - If you don't specify schema, like `SELECT name FROM customers`, it checks the user default schema, then `dbo`
  - Best practices is to always specify a schema
- Logins
  - At server instance level
  - Credentials stored in the `master` db
  - Should be linked to by user accounts in one or more DBs
  - Logins are for authentication, the mapped users are for authorization in each DB
  ```sql
  USE [master]
  GO

  -- create login in master db
  CREATE LOGIN demo WITH PASSWORD = 'Pa55.w.rd'
  GO

  USE [MyDBName]
  GO

  -- create a linked user in another db
  CREATE USER demo FROM LOGIN demo
  GO
  ```
- Contained users
  - Database level
  - Not linked to a login
  - Could be SQL auth or Windows/Entra auth
  - DB must be configured for partial containment (default in Azure SQL DB, optional in SQL Server)
  ```sql
  -- in a user db context
  CREATE USER [dba@contoso.com] FROM EXTERNAL PROVIDER;
  GO
  ```

### Authentication

To create a user, you need `ALTER ANY USER` permission in the database, it's held by:
- server admin accounts
- with the `CONTROL ON DATABASE` or `ALTER ON DATABASE` permission for that database
- members of the `db_owner` database role

Azure SQL DB server has two types of admins:

![SQL admin accounts](images/azure_sql-entra-auth-admin-accounts.png)

- SQL Server admin, could create
  - users based on SQL Server auth logins
  - contained users based on SQL Server auth (without logins)
- Entra Admin (could be a user or group, group is recommended)
  - (same as above), and
  - contained users based on Entra ID user and groups

When you deploy Azure SQL:

- A SQL **login** created with specified name
- This login has full admin permissions on all databases as a server-level principal
- When you sign into a database with this login, it's matched to the **`dbo` user account**, which
  - exists in every user database
  - has all database permissions
  - is member of the `db_owner` fixed database role

### Entra auth (contained user)
- To use Entra auth, you need to create an Entra ID-based contained database user
  - A contained user doesn't have a login in the `master` database
- You need to login with a Entra admin account to create the first contained user.
- If the Entra admin was removed from the server, existing Entra users created previously inside the server can **no longer** connect to the database with Entra auth.
- Works with users, groups and apps (service principals or managed identity)
  - No implicit users are created for Entra users logged in via membership in a group, operations which require assigning ownership will fail, to resolve this, a contained user must be created for the Entra user
  - Identities in a different tenant don't work, guest users work
- **Azure RBAC roles** (eg. SQL Server Contributor role) **doesn't** grant access to connect to the database in SQL Database, SQL Managed Instance, or Azure Synapse. The access permission must be granted directly in the database using Transact-SQL statements.
- How
  ```sql
  USE MyDatabase;

  -- <identity-name>:
  --  user principal name for a user
  --  display name for a group
  --  resource name for a managed identity
  CREATE USER "<identity-name>" FROM EXTERNAL PROVIDER;

  -- the user gets the "public" role by default
  -- you usually want to assign other roles to the user
  ALTER ROLE db_datareader ADD MEMBER "<identity-name>";
  ```

  The `CREATE USER "<identity-name>" FROM EXTERNAL PROVIDER` command requires **access from SQL to Entra on behalf of the logged-in user**, the user needs MS Graph permissions to read user/group/apps (see the [applications section](#applications) below).
- There are a few authentication options when you use tools like SSMS to connect to Azure SQL, notes:
  - **Microsoft Entra integrated**, only works if
    - You are signed in to a domain-joined machine
    - You have set up
      - ADFS
      - or seamless single sign-on for pass-through authentication
    - Seems not working with password hash synchronization auth
    - See a possible issue [here](https://techcommunity.microsoft.com/t5/azure-database-support-blog/troubleshooting-azure-active-directory-integrated-authentication/ba-p/2670162)
- Other helpful queries:

  ```sql
  -- List users
  USE MyDatabase;
  -- a principal could be either
  --    "SQL_USER", "EXTERNAL_USER", "EXTERNAL_GROUPS" or "DATABASE_ROLE"
  SELECT * FROM sys.database_principals;

  -- Query users and roles
  SELECT dp.name, dp.type_desc, dprole.name
  FROM
      sys.database_role_members drm
  JOIN
      sys.database_principals dp ON drm.member_principal_id = dp.principal_id
  JOIN
      sys.database_principals dprole ON drm.role_principal_id = dprole.principal_id
  ```

### Entra auth (server principals - logins)

You can also create Entra ID-based logins in the `master` database

```sql
-- The login_name specifies the Entra principal, which is a user, group, or application
CREATE LOGIN login_name
  {
    FROM EXTERNAL PROVIDER [WITH OBJECT_ID = 'objectid']
    | WITH <option_list> [,..]
  }

<option_list> ::=
    PASSWORD = { 'password' }
    [ , SID = sid ]

-- create user mapped to the login
CREATE USER [user_name] FROM LOGIN [login_name]

-- a login could be disabled
ALTER LOGIN [login_name] DISABLE
```

### Applications

See: https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal

- An app could access SQL using Entra auth, it could be
  - Just a normal app, for data operations
  - Or an admin app, manage other users/logins in SQL
- Could be service principals or managed identities (recommended)
- An app could be a SQL admin (by itself or as a member of a group), this allows full automation for user/login creation in SQL
- To create Entra-based user/logins in SQL, requires access **from SQL to Entra to read user/group/apps via Microsoft Graph**
  - When a user does this, Azure SQL's firsty-party Microsoft application uses delegated permissions of the user
  - When an app does this, SQL engine uses its **server identity** (see below), which **must have the Microsoft Graph query permissions**.
    - MS doc suggests creating a roles-assignable group, assign "Directory Readers" role to it, then group owner can add server identities to the group
    - Or assign individual permissions to the app
    - Avoid assign the "Directory Readers" role to the app directly, which has unnecessary permissions
- **server identity**
  - Is the **primary managed identity** assigned to the Azure SQL logical server, SQL managed instance, Synapse workspace
  - Could be system-assigned managed identity (SMI) or user-assigned managed identity (UMI)
  - The managed identity of SQL Managed Instance is referred to as the managed **instance identity**, and is automatically assigned when the instance is created
- NOTE there are two app identities involved:
  - One is the app used to create users/logins in SQL (Graph permission is not required)
  - One is the managed identity of SQL logical server/instance, Graph permissions are required to read Entra entities
- SMI / UMI
  - !! In addition to using a UMI/SMI as the server identity, you can use them (only UMI ?) to access the database by using the SQL connection string option `Authentication=Active Directory Managed Identity`, you need to create a contained user in the target database first
  - UMI is recommended, because it's independent, can be used for all SQL servers/instances in a tenant

To test auth with a managed identity of a Windows VM:

```powershell
$SQL_SERVER="sql-13dcb0b659.database.windows.net"
$SQL_DB="sqldb-test-001"
$SQL_TABLE="[SalesLT].[Address]"

# get token
$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdatabase.windows.net%2F' -Method GET -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$AccessToken = $content.access_token

# connect
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source = $SQL_SERVER; Initial Catalog = $SQL_DB; Encrypt=True;"
$SqlConnection.AccessToken = $AccessToken
$SqlConnection.Open()

# query
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "SELECT * from $SQL_TABLE;"
$SqlCmd.Connection = $SqlConnection

$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd

$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

# print the data
$DataSet.Tables[0]
```



### Authorization

Managed using database roles and explicit permissions.


## Data security

| Data State      | Encryption Method         |
| --------------- | ------------------------- |
| Data-at-rest    | TDE, Always Encrypted     |
| Data-in-motion  | SSL/TLS, Always Encrypted |
| Data-in-process | Dynamic data masking      |

### Transparent data encryption (TDE)

- Encrypt/decrypt at the data page level
- Backups are encrypted as well (*backup operation just copies the data pages from the database file to the backup device*)
- Encrypts the storage of an entire database by using a symmetric key called the Database Encryption Key (DEK)
- **Service-mangaged TDE**: DEK is protected by a built-in server certificate
- **Customer-managed TDE**: the TDE Protector that encrypts the DEK is stored in a customer managed Key Vault
- For
  - SQL Database and Azure Synapse, TDE protector is at the server level and inherited by all databases associated with that server.
  - SQL Managed Instance, TDE protector is set at the instance level and inherited by all encrypted databases on that instance.
- Cannot be used to encrypt system databases, such as `master`, which contains objects that are needed to perform the TDE operations on the user databases.

### Dynamic data masking

- A presentation layer feature
- Data in the database is not changed, admins can always view the unmasked data
- You set data masking policy on **columns** (such as Social security number)

### Always Encrypted

- Protect sensitive data stored in specific database **columns**
- Data can only be decrypted by **client applications** with access to the encryption key, a DBA can't see the data if he does not have the key
- Could be used in cases like: you want a third-party to manage the DB for you without exposing all the data
- Can't be used together with dynamic data masking

Steps:

- Two types of keys: column encyrption keys and column master keys
- Column encryption key is used to encrypt data in a column. A column master key is a key-protecting key that encrypts one or more column encryption keys
- The DB engine only stores the encrypted values of column encryption keys and the information about the location of column master keys (eg. Azure Key Vault, Windows Certificate Store)
- To access data stored in an encrypted column in plaintext, an application must use an *Always Encrypted enabled client driver*. Encryption and decryption occurs via the driver.
- The driver gets from the DB engine the encrypted value of the column encryption key and the location of the corresponding column master key
- The driver contacts the key store, to decrypt the encrypted column encryption key value
- The driver uses the plaintext column encryption key to encrypt the parameter
- The driver substitutes the plaintext values of the parameters with their encrypted values, and it sends the query to the server for processing
- The server computes the result set
- The driver decrypts the results and returns plaintext values to the application

### Classification and labeling

- Apply at **column** level
- Policy options:
  - SQL Information Protection policy (legacy)
    - Supports both Sensitivity label and Information type
  - Microsoft Information Protection (MIP) policy
    - Integrate with Purview, Microsoft 365
    - Propagate to downstream applications, such as Power BI
    - Only support Sensitivity label, not Information type
- Sensitivity label:
  - Personal, Public, General, Confidential, Highly Confidential
  - Saved in `sys.sensitivity_classifications` table
- Information type: Credit card, etc


## Database Watcher

A separate resource in Azure to help monitor SQL databases

- Target: collecting data from Azure SQL and managed instances
- Auth: use managed identity
- Data store: a KQL data store
- Networking: supports private endpoints
- Usage: KQL query, dashboards


## Azure SQL Edge

*This services is retiring, switch to SQL Express*

- For IoT and IoT Edge deployments
- Is a containerized Linux application, startup memory footprint is less than 500MB
- Provides capabilities to stream, process and analyze relational and non-relational data (JSON, graph and time-series)
- Optimized for IoT use cases and workloads
- Can work with or without network connectivity

![SQL Edge](images/azure_sql-edge.png)

- **Streaming engine** allows transformation, windowed aggregation, simple anomaly detection and classification of incoming data streams
- A **time-series storage engine** that allows storage of time-indexed data, can be aggregated and stored in cloud for future analysis

Deployment models:
- Connected: Deployed as a module for Azure IoT Edge
- Disconnected: Deployed as a standalone docker container or on a Kubernetes cluster
