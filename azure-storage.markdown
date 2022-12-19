# Azure Storage

- [Overview](#overview)
  - [Services](#services)
  - [Usages](#usages)
  - [Account level settings](#account-level-settings)
  - [Access](#access)
  - [Security](#security)
    - [Features](#features)
    - [Network access](#network-access)
    - [Exceptions](#exceptions)
    - [Microsoft Defender for Cloud](#microsoft-defender-for-cloud)
  - [Authorization Options](#authorization-options)
    - [Public read access for containers and blobs](#public-read-access-for-containers-and-blobs)
    - [RBAC](#rbac)
    - [Access keys](#access-keys)
    - [Shared access signature (SAS)](#shared-access-signature-sas)
  - [CLI](#cli)
- [Blobs](#blobs)
  - [Blob types](#blob-types)
  - [Access tiers](#access-tiers)
  - [Organization](#organization)
  - [Life cycle management rules](#life-cycle-management-rules)
  - [Versioning vs. snapshot](#versioning-vs-snapshot)
  - [Object replication](#object-replication)
  - [Immutable storage for Azure Blobs](#immutable-storage-for-azure-blobs)
  - [CLI](#cli-1)
  - [AzCopy](#azcopy)
  - [.NET Storage Client library](#net-storage-client-library)
  - [Properties and Metadata](#properties-and-metadata)
  - [Concurrency](#concurrency)
- [Disks](#disks)
  - [Bursting](#bursting)
- [Files](#files)
  - [Create and mount a share](#create-and-mount-a-share)
  - [Authentication](#authentication)
  - [Snapshots](#snapshots)
  - [File Sync](#file-sync)
    - [Components](#components)
- [NetApp Files](#netapp-files)
- [Troubleshooting](#troubleshooting)

## Overview

### Services

![storage services overview](images/azure_storage-services.png)

- Azure Containers (Blobs): unstructured text or binary data
- Azure Files: network file shares
- Azure Queues
- Azure Tables: *now part of Azure Cosmos DB*
- Azure Data Lake Storage
  - Based on Apache Hadoop, is designed for large data volumes and can store unstructured and structured data.
  - Azure Data Lake Storage Gen1 is a dedicated service.
  - Azure Data Lake Storage Gen2 is **Azure Blob Storage with the hierarchical namespace** feature enabled on the account.

### Usages

Azure Storage can be used to store files, messages, tables and other types of information.

Azure Storage is also used by IaaS VMs, and PaaS services:
- VM
  - Disks: page blobs
  - File shares: Azure Files
- Unstructured Data
  - Blobs
  - Data Lake Store: Hadoop Distributed File System (HDFS) as a service
- Structured Data
  - Azure Tables: key/value, autoscaling NoSQL store
  - Cosmos DB
  - Azure SQL DB

### Account level settings

- Subscription
- Location
- Secure transer required: whether HTTPS is enforced
- Virtual networks: only allow inbound access request from the specified network(s)
- Account kind
  - **Standard (general-purpose v2)**: all services and Data Lake Storage
  - **Premium block blobs**: for low-latency, high-rate, small transactions
  - **Premium file shares**: supports NFS
  - **Premium page blobs**: high performance, VM disks

  *Premium accounts use SSD, but do not support GRS, GZRS*

- Default access tier (*Standard accounts only, Does not apply to Premium accounts*)
  - Hot or cool
  - *Only applies to blobs*
  - Can be specified for each blob (Hot/Cool/Archive)

- Redundancy

  ![Redundancy in the primary region](images/azure_data-redundancy-primary-region.png)

  - LRS: three copies in one location
  - ZRS (not available in all regions)

  ![Redundancy in a secondary region](images/azure_geo-redundant-storage.png)
  - GRS: replicated async to the secondary region (the paired region), LRS in both regions, secondary region data _ONLY_ readable if Microsoft initiates a failover
  - GZRS: ZRS in both regions
  - RA-GRS, RA-GZRS: you could read from secondary region any time

### Access

Default service endpoints:

- Container service: `//mystorageaccount.blob.core.windows.net`
- Table service: `//mystorageaccount.table.core.windows.net`
- Queue service: `//mystorageaccount.queue.core.windows.net`
- File service: `//mystorageaccount.file.core.windows.net`

Note:
- Account names must be globally unique
- You could configure a custom domain

### Security

#### Features

- Encryption at rest

  - All data is automatically encrypted by Storage Service Encryption (SSE) with a 256-bit AES cipher. This can't be disabled.
  - You could use either
    - Microsoft managed keys
    - Customer managed keys
      - you specify a key in a key vault (the key vault must have soft-delete and purge protection enabled)
      - the storage account needs a user-assigned or system-assigned identity to access the key

- Encryption at tansit

  You can enforce HTTPS on an account. This flag will also enforce secure transfer over SMB by requiring SMB 3.0 for all file share mounts.

- CORS support

  An optional flag you can enable on Storage accounts. Apply only for GET requests.

- Azure AD and RBAC

- Shared Access Signatures (see below)

- Auditing access

  Using the built-in Storage Analytics service, which logs every operation in real time.

#### Network access

By default, connections from clients on any network are accepted.

- You can restrict access to an account from specific public IP addresses, or subnets on Virtual Networks.
- Subnets and Virtual Networks must exist in the same Region or Region Pair as the Storage Account.

The settings in the Portal actually corresponds to two properties, could be a bit confusing, the following is the mapping:

| Portal                                                  | `publicNetworkAccess` | `networkAcls.defaultAction` |
| ------------------------------------------------------- | --------------------- | --------------------------- |
| Enabled from all networks                               | `Enabled`             | `Allow`                     |
| Enabled from selected virtual networks and IP addresses | `Enabled`             | `Deny`                      |
| Disabled                                                | `Disabled`            | `Deny`                      |

*`publicNetworkAccess=Disabled` takes precedence, disables access from any IP or virtual network rule, means you could only access this storage account from private endpoints*

#### Exceptions

See: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security

There are two ways to manage network ACL exceptions:

1. "Allow Azure services on the **trusted services list** to access this storage account", this allows:

   - Trusted access for select operations to resources that are registered in your subscription.
   - Trusted access to resources based on a managed identity. (**All instances** are allowed, as long as their managed identity has proper permissions)

   ```sh
   az storage account update \
    --resource-group rg-demo \
    --name stdemo001 \
    --bypass AzureServices
   ```

1. (**Recommended**) Grant access from Azure resource instances

    You specify which resource instance could access based on its managed identity

    ```sh
    az storage account network-rule add \
      -g rg-demo \
      --account-name stdemo001 \
      --resource-id /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.Synapse/workspaces/testworkspace \
      --tenant-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    ```

#### Microsoft Defender for Cloud

- Could be enabled either on an individual account or at the subscription level
- Detects anomalies in account activity
- Only for Blob currently

### Authorization Options

#### Public read access for containers and blobs

- Only for read access
- The `AllowBlobPublicAccess` property at account level must be enabled
- A container's public access level can be:
  - Private: no anonymous access
  - Blob: anonymous read access for blobs
  - Container: anonymous **read and list** access to the entire container and blobs
- Both account and container settings are required to enable public access, so an account can have both public and private containers
- No separate settings at the blob object level

#### RBAC

Can be used for

- Control plane (Resource management operations): such as key management
- Data plane: data operations on the Blob and Queue services, eg. you need *Storage Blob Data Contributor* role to write to a blob

Use this when you are
- running an app with managed identities
- or using security principals (users, service principals)

#### Access keys

- Like a root password, allow **full access**
- Generally a bad idea, you **should avoid them**, there's now account level settings to disable these keys
- Typically stored within env variables, database, or configuration file.
- Should be private, don't include the config file in source control or store in public repos
- It's recommended that you manage access keys in Azure Key Vault
- Each storage account has two access keys, this allows key to be rotated:
  1. update connection strings in your app to use secondary access key
  2. Regenerate primary key using Azure portal or CLI.
  3. Update connection string in your code to reference the new primary key.
  4. Regenerate the secondary access key.

#### Shared access signature (SAS)

SAS grants access to storage resources for a specific time range without sharing your account keys. Suitable for external third-party applications.

There are three types:

- **Account SAS**

  You could specify:
    - Allowed services: Blob, File, Queue, Table
    - Allowed resource types: Service, Container, Object
    - Allowed permissions: Read, Write, Delete, List, ...
- **Service SAS**: scoped at container level, which can be a blob container, a file share, a queue or a table
- **User delegation SAS**
  - Secured with Azure AD credentials and also permissions specified for the SAS
  - For Blob only: could be at container or blob level
  - Recommended over signing with an access key

NOTE: *Account SAS and Service SAS are signed by account key, so if you disable account key, they won't work*

There are two forms:

- Ad hoc SAS

  An ad hoc SAS URI looks like `https://myaccount.blob.core.windows.net/?restype=service&comp=properties&sv=2015-04-05&ss=bf&srt=s&st=2015-04-29T22%3A18%3A26Z&se=2015-04-30T02%3A23%3A26Z&sr=b&sp=rw&sip=168.1.5.60-168.1.5.70&spr=https&sig=F%6GRVAZ5Cdj2Pw4txxxxx`, it contains:

  - The start/expiry time and permissions
  - The `sig=F%6GRVAZ5Cdj2Pw4txxxxx` part is an HMAC computed over a string-to-sign and key using SHA256, then encoded using Base64

  The only way to revoke an ad-hoc SAS is to change the account access keys.

- Service SAS with stored access policy

  - Instead of specify the permissions and time on each SAS, you define a **stored access policy** at the container level (blob container, file share, queue or table). You can have a maximum of five stored access policies per container.
  - Then reference this policy when you create a service SAS, *seems you can only do this programmatically, not in the Portal*
  - This allows you to change the permissions or duration without having to regenerate the storage account keys.
  - Create a policy using CLI

    ```sh
    az storage container policy create \
      --name <stored access policy identifier> \
      --container-name <container name> \
      --start <start time UTC datetime> \
      --expiry <expiry time UTC datetime> \
      --permissions <(a)dd, (c)reate, (d)elete, (l)ist, (r)ead, or (w)rite> \
      --account-key <storage account key> \
      --account-name <storage account name>
    ```

Two typical designs for using Azure Storage to store user data:

  - Front end proxy: all data pass through the proxy

    ![Front end proxy](images/azure_storage-design-front-end-proxy.png)

  - SAS provider: only generates a SAS and pass it to the client

    ![SAS provider](images/azure_storage-design-lightweight.png)

### CLI

```sh
# Create a storage account
#  - use `--hns` to enable hierarchical namespaces (Data Lake Gen2)
az storage account create \
    --name mystorageaccount \
    --resource-group my-rg \
    --location westus2 \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hns
```

## Blobs

Object storage solution optimized for storing massive amounts of unstructured data, ideal for:

- serving images or documents directly to a browser, including full static websites.
- storing files for distributed access.
- streaming video and audio.
- storing data for backup, disaster recovery and archiving.
- storing data for analysis.

You could specify the blob type and access tier when you create a blob.

### Blob types

- **Block blobs (default)**: blocks of data assembled to make a blob, used in most scenarios
- **Append blobs**: specialized block blobs optimized for append operations, frequently used for logging from one or more sources (*the `add` permission is for adding a block to an append blob*)
- **Page blobs**: can be up to 8 TB in size, more efficient for frequent read/write operations. They provide random read/write access to 512-byte pages. Azure VMs use page blobs as OS and data disks.

### Access tiers

For block blobs, there are three access tiers: "hot", "cool" and "archive", from hot to cool to archive, the cost of storing data decreases but the cost of retrieving data increses.

- An account has a default tier, either hot or cool
- A blob can be at any tier
- Archive
  - can only be set at blob level
  - data is **offline**, only metadata available for online query
  - to access data, the blob must first be **rehydrated** (changing the blob tier from Archive to Hot or Cool, this can take hours)


### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories: technically containers are "flat", there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

### Life cycle management rules

- You could define rules to move blobs to a cooler tier when they are not modified for X days (hot -> cool/archive, cool -> archive)
- Or delete blobs at the end of their life cycle
- Apply rules to containers or a subset of blobs

### Versioning vs. snapshot

- When blob versioning is enabled: A blob version is created automatically on a write or delete operation
- A blob snapshot is created manually, not necessary if versioning is enabled

### Object replication

You could add replication rules to replicate blobs to another storage account.

- The destination could be in another region, subscription, even another tenant (`AllowCrossTenantReplication` property controls whether this is allowed).
- Only one replication policy may be created for each source account/destination account pair.
- Each policy can have multiple rules
- Blob content, versions, properties and metadata are all copied from source container to the destination container. Snapshots are not replicated.
- Blob versioning needs to be enabled on both accounts.

### Immutable storage for Azure Blobs

![Immutable storage policies](images/azure_blob-immutable-policies.png)

For compliance or legal reasons, you could configure immutability policies for blob data, protecting it from overwrites and deletes.

There are two types of policies:
  - **Time-based retention policy**: during the retention period, objects can be created and read, but not modified or deleted. After the period has expired, objects can be deleted but not overwritten.
  - **Legal hold policies**: data is immutable until the legal hold is explicitly cleared

Immutability policies can be scoped to a blob version or to a container.

- Version-level scope:
  - You must enable support for version-level immutability on either the storage account or a container.
  - Configure a default version-level immutability policy for the account or container.
  - A blob version supports one version-level immutability policy and one legal hold. A policy on a blob version can override a default policy specified on the account or container.
- Container-level scope:
  - When support for version-level immutability has not been enabled for a storage account or a container, then any immutability policies are scoped to the container. Policies apply to all objects within the container.

### CLI

- Can't resume if upload/download fails, so NOT suitable for large files
- `az storage` commands require an account name and key to authenticate, you can either specify them everytime or use environment variables `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY`
- There are options to specify overwritting behavior based on ETag or modification date, eg. `--if-unmodified-since`

```sh
# get account keys
az storage account keys list \
  --account-name <Account> \
  --output table

# specify default account and key
export AZURE_STORAGE_ACCOUNT=<Account>
export AZURE_STORAGE_KEY=<Key>

# (sync) upload file to a blob
az storage blob upload \
  --container-name MyContainer \
  --file /path/to/file \
  --name MyBlob \
  --if-unmodified-since 2019-05-26T10:30Z

# (sync) batch upload
az storage blob upload-batch \
  --destination myContainer \
  --source myFolder \
  --pattern *.bmp

# list
az storage blob list ...

# archive a blob
az storage blob set-tier \
  --container-name myContainer \
  --name myPhoto.png \
  --tier Archive
```

Copy blobs, there are options for selecting source blobs, e.g. use `--source-if-unmodified-since` to copy old blobs from hot storage to cool storage

```sh
# (async) start copying between containers/accounts
# only
az storage blob copy start \
  ... \
  --source-if-unmodified-since [date]

# check state of dest blob
az storage blob show ...
```

To move a blob, you need to copy it, then delete the source blob.

```sh
# delete a blob
az storage blob delete --name sourceBlob

# batch delete blobs older than 6 months
date=`date -d "6 months ago" '+%Y-%m-%dT%H:%MZ'`
az storage blob delete-batch \
  --source sourceContainer \
  --if-unmodified-since $date
```

### AzCopy

- All operations are async, each instance creates a job, you can view and restart previous jobs and resume failed jobs;
- Automatically retry a transfer after a failure;
- Supports copying an entire account (Blob service only) to another account;
- Supports hierarchical containers;
- Supports authentication with Azure AD or SAS tokens;
- Supports wildcard patterns in a path, `--include`, `--exclude` flags;
- Use `--include-after` to only include files changed after a specific date/time;

```sh
# upload file
azcopy copy "myfile.txt" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>"

# upload folder recursively
azcopy copy "myfolder" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>" \
  --recursive=true

# transfer between accounts
azcopy copy "https://sourceaccount.blob.core.windows.net/sourcecontainer/*?<source sas token>" \
  "https://destaccount.blob.core.windows.net/destcontainer/*?<dest sas token>"

# sync data
azcopy sync ...

# list data/create new container/remove blobs
azcopy [list|make|remove] ...

# show job status
azcopy jobs list
```

### .NET Storage Client library

- Suitable for complex, repeated tasks
- Provides full access to blob properties
- Supports async operations

### Properties and Metadata

- Both containers and blobs have properties and metadata.
- Can be accessed/updated by Portal, CLI, PowerShell, SDK, REST API.

| Properties                     | Metadata                      |
| ------------------------------ | ----------------------------- |
| system-defined                 | user-defined name-value pairs |
| read-only or read-write        | read-write                    |
| `Length`, `LastModifined`, ... | `docType`, `docClass`, ...    |

```sh
export AZURE_STORAGE_ACCOUNT=<account>
export AZURE_STORAGE_SAS_TOKEN=<token>

# get details of a blob
az storage blob show -c myContainer -n 'file.txt'

# set a property on a blob
# this will make CDN don't cache this file
az storage blob update -c myContainer -n 'file.txt' --content-cache-control 'no-cache'
# can be done during upload as well
az storage blob upload -c myContainer -n 'file.txt' -f file.txt -p cacheControl="no-cache"
# using azcopy
azcopy cp file.txt <remote-address> --cache-control 'no-cache'

# get metadata of a blob
az storage blob metadata show -c myContainer -n 'file.txt'

# properties for the whole blob service, not a specific blob
az storage blob service-properties show
```

### Concurrency

Three concurrency strategies:
  - optimistic concurrency;
    - Get the ETag, when saving data, send back this ETag, Azure only updates the blob if the ETag still matches the blob's current ETag;
    - It's not enforced, every app needs to adopt it;

    ![Blob concurrency using ETag](images/azure_blob-concurrency-etag.png)
  - pessimistic concurrency;
    - An app require a lease for a set period of time, no one else can modify the blob before the lease is released or expired;
    - Lease time is from 15s to 60s, so it's more suitable for programmatic processing of records;
    - An app can also renew or break a lease before it expires;

    ![Blob concurrency using lease](images/azure_blob-concurrency-lease.png)


## Disks

- Managed disks are recommended
- Managed disks run on top of page blob (the underlying storage account is hidden)
- Types:
  - Ultra-disk
    - You could customize size, IOPS and throughput
  - Premium SSD
    - A disk could be shared by multiple VMs
    - You can pick a performance level without increase the disk size
  - Standard SSD / Standard HDD
    - Performance (IOPS/throughput) is tied to capacity, so you may need to increase the disk size simply because you need higher IOPS

- You could increase disk size, but can't decrease it (workaround: create a new one and copy data to it)

Caching settings

- **None**: for write-only and write-heavy disks
- **Ready only**: for read-only and read-write disks, improves read latency and IOPS
- **Ready & Write**: only use if your app properly handles writing cached data

### Bursting

- Only for certain sizes of Standard/Premium SSD
- No bursting for standard HDD, or Ultra

- For P20 disks and smaller:
  - Enabled by default
  - Credit-based bursting (you accumulate credits when you disk is under-used, spend credits while bursting)
  - Up to 3500 IOPS and 170MB/s
  - Up to 30min

- For P30 disks and larger
  - There's monthly enablement fee and a burst transaction fee (pay by additional IOPS)
  - Up to 30,000IOPS and 1000MB/s


## Files

Network files shares

- Accessed over SMB/CIFS/NFS protocol
- Multiple VMs can share the same files with both read and write access
- Can be used to replace your on-prem NAS devices or file servers

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.

Tiers:

- Premium: backed by SSD, SMB and NFS protocols
- Transaction optimized
- Hot
- Cool

Compare to Blobs and Disks

- Files have true directory objects, Blobs have a flat namespace.
- File shares can be mounted concurrently by multiple cloud or on-prem machines, Disks are exclusive to a single VM (except shared disks).
- Files shares are best suited for random access workloads.

### Create and mount a share

```sh
az storage share create \
  --account-name stdemo001 \
  --account-key xxxxxx \
  --name "share-demo-001"

# on client VM
mkdir Azureshare
sudo mount -t cifs \
  //stdemo001.file.core.windows.net/erp-data-share Azureshare \
  -o vers=3.0,username=[my-username],password=xxxxxxxx,dir_mode=0777,file_mode=0777,sec=ntlmssp

findmnt -t cifs
```

### Authentication

You can use Active Directory for permissions management at file-share level:

- On-prem AD (incl. AD servers hosted in Azure)
- Azure AD DS
- Azure AD (Kerberos auth from Azure AD joined clients, user accounts must be hybrid identities)

### Snapshots

To protect against unintended changes, accidental deletions, or for backup/auditing purpose, you could take snapshots.

- A snapshot captures a point-in-time, read-only copy of your data.
- Snapshots are created at the file share level, retrieval is at the individual file level.
- You cannot delete a share without deleting all the snapshots first.
- Snapshots are incremental, only data changed after last snapshot  is saved.
- But you only need to retain the most recent snapshot to restore the share.

### File Sync

- Centralizes file shares in Azure Files, and transforms Windows Server into a quick cache of your file shares.
- You can use any available protocols to aceess your data locally, such as SMB, NFS, and FTPS.

#### Components

![Azure File Sync](images/azure_file-sync-components.png)

- Storage Sync Service is the top-level Azure resource for Azure File Sync.
- A Storage Sync Service instance can connect to multiple storage accounts via multiple sync groups.


## NetApp Files

- Fully managed, with advanced management capabilities
- Support NFS and SMB
- Example scenarios:
  - Enterprise NAS migration
  - Latency sensitive workloads, eg. SAP HAHA
  - IOPS intensive high performance compute
  - Simultaneous multi-protocol access


## Troubleshooting

- Delete a locked file in Azure File Share

  A file may get locked and you cannot delete it, you need to find and close file handle on the file. See https://infra.engineer/azure/65-azure-clearing-the-lock-on-a-file-within-an-azure-file-share

  ```powershell
  # get storage account context
  $Context = New-AzStorageContext -StorageAccountName "StorageAccountName" -StorageAccountKey "StorageAccessKey"

  # find all open handles of a file share
  Get-AzStorageFileHandle -Context $Context -ShareName "FileShareName" -Recursive

  # close a handle
  Close-AzStorageFileHandle -Context $Context -ShareName "FileShareName" -Path 'path/to/file' -CloseAll
  ```
