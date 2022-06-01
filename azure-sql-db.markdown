# Azure SQL DB

- [Overview](#overview)
- [SQL Database](#sql-database)
  - [Purchasing models](#purchasing-models)
  - [Service tiers](#service-tiers)
  - [Scaling](#scaling)
- [SQL Managed Instance](#sql-managed-instance)
- [SQL Server on VM](#sql-server-on-vm)
- [Data security](#data-security)
  - [Transparent data encryption (TDE)](#transparent-data-encryption-tde)
  - [Dynamic data masking](#dynamic-data-masking)
  - [Always Encrypted](#always-encrypted)

## Overview

Deployment options:

![Deployment options](./images/azure_sql-db-deployment-options.png)

|            | SQL Databases         | SQL Managed Instance     | SQL Server on VM |
| ---------- | --------------------- | ------------------------ | ---------------- |
| Type       | PaaS                  | PaaS                     | IaaS             |
| Why choose | Modern cloud solution | Instance-scoped features | OS level access  |

## SQL Database

- PaaS, abstracts both the OS and SQL Server instance
- Hyperscale storage: up to 100TB
- Autoscaling for unpredictable workloads (serverless)

**Elastic pools**: you buy a set of compute and storage resources that are shared among all the databases in the pool

### Purchasing models

![Purchasing models](./images/azure_sql-db-purchasing-models.png)

- DTU: a bundled measure of compute, storage and I/O resources
- vCore: select compute and storage resources independently, allows you to use Azure Hybrid Benefit for SQL Server

### Service tiers

- General Purpose
  ![General purpose architecture](./images/auzre_general-purpose-architecture.png)

  - tempdb in locally attached SSD
  - data and log files are in Azure Premium Storage

- Business Critical

  - like deploying an Always On availability group (AG) behind the scenes
  - data and log files are stored on direct-attached SSD

- Hyperscale
  ![Hyperscale architecture](./images/azure_hyperscale-architecture.png)

  - Page servers serve database pages out to the compute nodes on demand
  - Data changes from the primary compute replica are propagated through the log service: it gets logs from primary compute replica, persists them, forwards them to other compute replicas and relevant page servers

### Scaling

- Vertical scaling
- Horizontal scaling
  - Read Scale-out
  - Sharding

Read Scale-out in a business critical service tier:

![Read Scale-out](images/azure_sql-db-business-critical-service-tier-read-scale-out.png)

- You set **connection string option** to decide whether the connection is routed to the write replica or a read-only replica.
- Data-changes are propagated asynchronously, reads are always transcationally consistent


## SQL Managed Instance

No need to manage a VM, most of the SQL Server instance-scoped features are still available:

- SQL Server Agent
- Service Broker
- Common language runtime (CLR)
- Database Mail
- Linked servers
- Distributes transcations
- Machine Learning Services


## SQL Server on VM

A version of SQL Server that runs in an Azure VM

- Access to full capabilities of SQL Server
- Responsible for updating and patching the OS and SQL Server


## Data security

| Data State      | Encryption Method         |
| --------------- | ------------------------- |
| Data-at-rest    | TDE, Always Encrypted     |
| Data-in-motion  | SSL/TSL, Always Encrypted |
| Data-in-process | Dynamic data masking      |

### Transparent data encryption (TDE)

- Encrypt/decrypt at the data page level
- Backups are encrypted as well (*backup operation just copies the data pages from the database file to the backup device*)
- Encrypts the storage of an entire database by using a symmetric key called the Database Encryption Key (DEK)
- Service-mangaged TDE: DEK is protected by a built-in server certificate
- Customer-managed TDE: the TDE Protector that encrypts the DEK is stored in a customer managed Key Vault

### Dynamic data masking

- A presentation layer feature
- Data in the database is not changed, admins can always view the unmasked data
- You set data masking policy on columns

### Always Encrypted

- Protect sensitive data stored in specific database columns
- Data can only be decrypted by client applications with access to the encryption key
- Could be used in cases like: you want a third-party to manage the DB for you without exposing all the data
- Can't be used together with dynamic data masking

Steps:

- Two types of keys: column encyrption keys and column master keys
- Column encryption key is used to encrypt data in a column. A column master key is a key-protecting key that encrypts one or more column encryption keys
- The DB engine only stores the encrypted values of column encryption keys and the information about the location of column master keys (eg. Azure Key Vault, Windows Certificate Store)
- To access data stored in an encrypted column in plaintext, an application must use an *Always Encrypted enabled client driver*. Encryption and decryption occurs via the driver.
- The drive gets from the DB engine the encrypted value of the column encryption key and the location of the corresponding column master key
- The driver contacts the key store, to decrypt the encrypted column encryption key value
- The driver uses the plaintext column encryption key to encrypt the parameter
- The driver substitutes the plaintext values of the parameters with their encrypted values, and it sends the query to the server for processing
- The server computes the result set
- The driver decrypts the results and returns plaintext values to the application