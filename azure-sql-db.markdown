# Azure SQL DB

- [Overview](#overview)
- [SQL Database](#sql-database)
  - [Concepts](#concepts)
  - [Purchasing models](#purchasing-models)
  - [High availability](#high-availability)
  - [Scaling](#scaling)
  - [Networking](#networking)
  - [Free offer](#free-offer)
- [SQL Managed Instance](#sql-managed-instance)
  - [High availability](#high-availability-1)
- [Shared between SQL, SQL MI](#shared-between-sql-sql-mi)
  - [Disaster recovery](#disaster-recovery)
    - [Notes](#notes)
    - [Failover groups](#failover-groups)
  - [Backup](#backup)
- [SQL Server on Azure VM](#sql-server-on-azure-vm)
  - [HADR](#hadr)
    - [Always On availability group](#always-on-availability-group)
    - [Failover cluster instance (FCI)](#failover-cluster-instance-fci)
  - [Backup](#backup-1)
- [Authentication and authorization](#authentication-and-authorization)
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

### Concepts

- **Elastic pools**: you buy a set of compute and storage resources that are shared among all the databases in the pool
- **SQL DB Server**: a logic container for databases (could be a mix of single databases and elastic pools), it defines
  - Access: connection string (FQDN), location, authentication method (SQL auth, Entra auth, or both)
  - Backup settings
  - Business continuity management: failover groups
  - Security: networking, TDE, Defender for Cloud, identity, auditing

### Purchasing models

![Purchasing models](./images/azure_sql-db-purchasing-models.png)

- DTU: a bundled measure of compute, storage and I/O resources
- vCore: select compute and storage resources independently, allows you to use Azure Hybrid Benefit for SQL Server

| Service tier            | Basic (DTU) | Standard (DTU) | Premium (DTU) | General Purpose (vCore) | Business Critical (vCore) | Hyperscale (vCore) |
| ----------------------- | ----------- | -------------- | ------------- | ----------------------- | ------------------------- | ------------------ |
| Local redundant support | Yes         | Yes            | Yes           | Yes                     | Yes                       | Yes                |
| Zone redundant support  | No          | No             | Yes           | Yes                     | Yes                       | Yes                |

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

### High availability

Has General Purpose and Business Critical service tiers, and high availability options are similar to the options of Azure SQL Databases, see details here https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/high-availability-sla


## Shared between SQL, SQL MI

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
  - Each DB can have 4 replicas
  - SQL DB only, not for SQL MI
- Automatic failover group
  - Is an abstraction over geo replicas
  - A SQL server can have multiple failover groups
  - A failover group can include multiple databases
  - A databases can only be in one group
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

### Backup

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

- Rely on the underlying Windows Server Failover Clustering (WSFC)
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


## Authentication and authorization

This section applies to Azure SQL Database, Azure SQL Managed Instance, or Azure Synapse.

### Authentication

SQL logins and users:

- A **login** is an individual **account** in the `master` database, to which a user account in one or more databasese can be linked. Credential stored with the login in `master`.
- A **user account** is an individual **account** in any database that may be, but not have to be, linked to a login. If not linked, credential is stored in the database.

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

- To use Entra auth, you need create a Entra ID-based contained database user
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

  The `CREATE USER "<identity-name>" FROM EXTERNAL PROVIDER` command requires **access from SQL to Entra on behalf of the logged-in user**, the user needs MS Graph permissions to read user/group/apps (see the [applications section](#applications) below.
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
