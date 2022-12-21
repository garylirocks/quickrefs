# Azure SQL DB

- [Overview](#overview)
- [SQL Database](#sql-database)
  - [Purchasing models](#purchasing-models)
  - [Service tiers](#service-tiers)
  - [Scaling](#scaling)
  - [Business continuity (BCDR)](#business-continuity-bcdr)
- [SQL Managed Instance](#sql-managed-instance)
- [Backup for SQL, SQL MI](#backup-for-sql-sql-mi)
- [SQL Server on Azure VM](#sql-server-on-azure-vm)
  - [HADR](#hadr)
    - [Always On availability group](#always-on-availability-group)
    - [Failover cluster instance (FCI)](#failover-cluster-instance-fci)
  - [Backup](#backup)
- [Data security](#data-security)
  - [Transparent data encryption (TDE)](#transparent-data-encryption-tde)
  - [Dynamic data masking](#dynamic-data-masking)
  - [Always Encrypted](#always-encrypted)
- [Azure SQL Edge](#azure-sql-edge)

## Overview

Deployment options:

![Deployment options](./images/azure_sql-db-deployment-options.png)

Elastic pool: multiple databases in a single logical SQL server, and all the DBs share the server's resources

|                   | SQL Databases                  | SQL Managed Instance               | SQL Server on VM |
| ----------------- | ------------------------------ | ---------------------------------- | ---------------- |
| Type              | PaaS                           | PaaS                               | IaaS             |
| Why choose        | Modern cloud solution          | Instance-scoped features           | OS level access  |
| Purchasing models | DTU, vCore                     | vCore                              | -                |
| HA                | geo-replication, auto-failover | automated backup, no auto-failover | no auto-failover |

## SQL Database

- PaaS, abstracts both the OS and SQL Server instance
- Hyperscale storage: up to 100TB
- Autoscaling for unpredictable workloads (serverless)

**Elastic pools**: you buy a set of compute and storage resources that are shared among all the databases in the pool

### Purchasing models

![Purchasing models](./images/azure_sql-db-purchasing-models.png)

- DTU: a bundled measure of compute, storage and I/O resources
- vCore: select compute and storage resources independently, allows you to use Azure Hybrid Benefit for SQL Server

| Purchasing Model | DTU                      | vCore                                         |
| ---------------- | ------------------------ | --------------------------------------------- |
| Service tiers    | Basic, Standard, Premium | General Purpose, Bisness Critical, Hyperscale |

### Service tiers

- General Purpose

  ![General purpose architecture](./images/azure_sql-general-purpose.png)

  - tempdb in locally attached SSD
  - data and log files are in Azure Premium Storage

- Business Critical

  ![Business critical architecture](./images/azure_sql-business-critical.png)

  - Data and log files are stored on direct-attached SSD
  - It deploys an Always On availability group (AG) behind the scenes
  - There are three secondary replicas, **only one** of them could be used as a read-only endpoint
  - A transaction can complete a commit when at least one the secondary replicas has hardened the change for its transcation log
  - Highest performance and availability of all Azure SQL service tiers

- Hyperscale

  ![Hyperscale architecture](./images/azure_hyperscale-architecture.png)

  - Page servers (sharding) serve database pages out to the compute nodes on demand
  - Data changes from the primary compute replica are propagated through the log service: it gets logs from primary compute replica, persists them, forwards them to other compute replicas and relevant page servers
  - Transcations can commit when the log service hardens to the landing zone
  - Can have 0 to 4 secondary replicas, can all be used for read-scale

### Scaling

- Vertical scaling
- Horizontal scaling
  - Read Scale-out
  - Sharding
    - Hyperscale does this automatically, or you can do it manually with some tools
    - Partitions database into multiple databases/shards
    - Shards can be in different regions, and scale independently
    - The solution uses a special database named shard map manager, which maintains mapping about all shards


Read Scale-out in a business critical service tier:

![Read Scale-out](images/azure_sql-db-business-critical-service-tier-read-scale-out.png)

- You set **connection string option** to decide whether the connection is routed to the write replica or a read-only replica.
- Data-changes are propagated asynchronously
- Read scale-out with one of the secondary replicas supports **session-level consistency**, if the read-only session reconnects, it might be redirected to another replica

### Business continuity (BCDR)

You can add databases to a failover group, they'll be replicated automatically to a server in a paired region.

A failover group has its own listener endpoints like:

- Read/write: `fog-demo.database.windows.net`
- Read-only:  `fog-demo.secondary.database.windows.net`


The DNS resolution chain is like:

```
fog-demo.database.windows.net.     30 IN CNAME sql-demo-eus.database.windows.net.
# if private endpoint is enabled
sql-demo-eus.database.windows.net. 30 IN CNAME sql-demo-eus.privatelink.database.windows.net.
...
```

After failover, it would be like:

```
fog-demo.database.windows.net.     30 IN CNAME sql-demo-wus.database.windows.net.
# if private endpoint is enabled
sql-demo-wus.database.windows.net. 30 IN CNAME sql-demo-wus.privatelink.database.windows.net.
...
```

Notes:

- You should use these failover listener endpoints in connection string for your application, so you don't need to manually update the connection string when failover happens, the connection is always routed to whichever instance which is currently primary.
- Removing a failover group for a single or pooled database does not stop replication, and it does not delete the replicated database.


## SQL Managed Instance

- A PaaS service, but deployed into your own vNet
- No need to manage a VM
- Most of the SQL Server instance-scoped features are still available:
  - SQL Server Agent
  - Service Broker
  - Common language runtime (CLR)
  - Cross-database transactions
  - Database Mail
  - Linked servers
  - Distributes transcations
  - Machine Learning Services


## Backup for SQL, SQL MI

SQL, SQL MI:

- A minimum 7 day default backup retention period
- Standard and premium can be configured for retention up to 35 days without having to configure long-term retention(LTR), only up to 7 days for basic tier.
- For all SQL DB tiers, LTR can be configured for up to 10 year retention.

Synapse SQL pool:

- Minimum 7 day default retention
- LTR not supported


## SQL Server on Azure VM

A version of SQL Server that runs in an Azure VM

- Access to full capabilities of SQL Server
- Responsible for updating and patching the OS and SQL Server
- You could use either Windows or Linux VMs

There's SQL IaaS Agent Extention that helps with licensing, patching, backing up, etc

### HADR

Most SQL Server HADR solutions are supported on VMs, as both Azure-only and hybrid solutions.

- Always On availability groups
- Always On failover cluster instances(FCIs)
- Log shipping
- Backup and restore with Azure Blob storage
- Replicate and fail over SQL Server with Azure Site Recovery

|                   | Always On AG                                                  | Always On FCIs                                                |
| ----------------- | ------------------------------------------------------------- | ------------------------------------------------------------- |
|                   | database level                                                | instance level                                                |
| Requirement       | A domain controller VM                                        | Shared storage (Azure shared disks, Premium file shares, etc) |
| Best practices    | VMs in an availability set or different AZs                   |                                                               |
| Disaster recovery | an AG could span multiple Azure regions, or Azure and on-prem |                                                               |

#### Always On availability group

- Azure Only

  <img src="./images/azure_sql-server-on-azure-vm-availability-group.png" width="400" alt="Always On availability group overview" />

- Hybrid

  <img src="images/azure_sql-server-hybrid-dr-alwayson-ag.png" width="400" alt="Always On AG hybrid" />

  With Software Assurance, Passive and DR instances do not require liscenses

  <img src="images/azure_sql-server-hybrid-failover-liscense.png" width="400" alt="Always On AG free DR license" />

- Rely on the underlying Windeos Server Failover Clustering (WSFC)
- SQL Server VMs should be in an availability set, or different availability zones
  - VMs in one availability set could be placed in a proximity placement group, minimize latency
  - VMs in different AZs offer better availability, but a greater network latency
- An AG could be across different Azure regions (for disaster recovery)

#### Failover cluster instance (FCI)

- Relies on WSFC
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

### Backup

- Automated Backup
  - Provied by SQL Server IaaS Agent Extension
  - Stored in a storage account you specify
  - Backups retained up to 90 days
  - With SQL Server 2016 and later: manual backup schedule and time window, backup frequency
  - To restore: locate the backup files and restore using SQL Server Management Studio or Transact-SQL commands

- Azure Backup for SQL VMs
  - Azure Backup benefits: zero-infrastructure, long-term retension, central management
  - Azure Backup installs a workload backup extension on the VM
  - Additional features for SQL Server on VMs:
    - Workload-aware backups that supports - full, differential, and log
    - SQL transaction log backup RPO up to 15 minutes
    - Point in time recovery up to a second
    - Individual database level backup and restore
    - Support for SQL Always  On
  - To restore, do it in Azure Backups, not with SSMS or Transact-SQL

- Manual Backup
  - Back up to attached disks or Blob storage
  - Use SSMS or SQL scripts


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
- You set data masking policy on columns (such as Social security number)

### Always Encrypted

- Protect sensitive data stored in specific database columns
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


## Azure SQL Edge

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
