# Azure Storage

- [Overview](#overview)
  - [Services](#services)
  - [Usages](#usages)
  - [Account level settings](#account-level-settings)
  - [Access](#access)
  - [Security](#security)
    - [Access keys](#access-keys)
    - [Shared access signature (SAS)](#shared-access-signature-sas)
    - [Network access](#network-access)
    - [Advanced threat protection](#advanced-threat-protection)
- [Blobs](#blobs)
  - [Blob types](#blob-types)
  - [Access tiers](#access-tiers)
  - [Organization](#organization)
  - [Life cycle management rules](#life-cycle-management-rules)
  - [Object replication](#object-replication)
  - [CLI](#cli)
  - [AzCopy](#azcopy)
  - [.NET Storage Client library](#net-storage-client-library)
  - [Properties and Metadata](#properties-and-metadata)
  - [Concurrency](#concurrency)
- [Files](#files)

## Overview

### Services

![storage services overview](images/azure_storage-services.png)

- Azure Containers (Blobs): unstructured text or binary data
- Azure Files: network file shares
- Azure Queues
- Azure Tables: *now part of Azure Cosmos DB*

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
- Performance tiers
  - Standard: HDD, low cost
  - Premium:
    - SSD
    - additional services: unstructured object data as block blobs or append blobs, specialized file storage
- Replication
  - LRS: locally-redundant storage, three copies within a datacenter
  - GRS: geo-redundant storage
- Access tier
  - Hot or cool
  - *Only apply to blobs*
  - Can be specified for each blob
- Secure transer required: whether HTTPS is enforced
- Virtual networks: only allow inbound access request from the specified network(s)
- Account kind
  - Standard (general-purpose v2): all services and Data Lake Storage
  - Premium block blobs
  - Premium page blobs: VM disks
  - Premium file shares
- Redundancy
  - LRS: three copies in one location
  - ZRS (not available in all regions)
  - GRS: replicated async to the secondary region, LRS in both regions, secondary region data _ONLY_ readable if Microsoft initiates a failover
  - RA-GRS (default): read from secondary region any time
  - GZRS/RA-GZRS: combines ZRS and GRS

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

Security features:

- Encryption at rest

  - All data is automatically encrypted by Storage Service Encryption (SSE) with a 256-bit AES cipher. This can't be disabled.
  - For VMs, Azure let's you encrypt virtual hard disks(VHDs) by using Azure Disk Encryption (BitLocker for Windows images, `dm-crypt` for Linux)
  - Azure Key Vault stores the keys automatically.

- Encryption at tansit

  You can enforce HTTPS on an account. This flag will also enforce secure transfer over SMB by requiring SMB 3.0 for all file share mounts.

- CORS support

  An optional flag you can enable on Storage accounts. Apply only for GET requests.

- Role-based access control

  RBAC is the Most flexible access option. Can be applied to
    - resource management(e.g. configuration)
    - and data operations(only for Blob and Queue)

- Auditing access

  Using the built-in Storage Analytics service, which logs every operation in real time.

#### Access keys

- Like a root password, allow **full access**.
- Typically stored within env variables, database, or configuration file.
- *Should be private, don't include the config file in source control or store in public repos*
- Each storage account has two access keys, this allows key to be rotated:
  1. update connection strings in your app to use secondary access key
  2. Regenerate primary key using Azure portal or CLI.
  3. Update connection string in your code to reference the new primary key.
  4. Regenerate the secondary access key.

#### Shared access signature (SAS)

- Grant access to storage resources for a specific time range without sharing your account keys
- Suitable for external third-party applications
- An SAS can be generated at different levels:
  - Account level, you could specify:
    - Allowed services: Blob, File, Queue, Table
    - Allowed resource types: Service, Container, Object
    - Allowed permissions: Read, Write, Delete, List, ...
  - Blob Container level
  - Blob object level

Two typical designs for using Azure Storage to store user data:

  - Front end proxy: all data pass through the proxy

    ![Front end proxy](images/azure_storage-design-front-end-proxy.png)

  - SAS provider: only generates a SAS and pass it to the client

    ![SAS provider](images/azure_storage-design-lightweight.png)


#### Network access

By default, connections from clients on any network are accepted.

- You can restrict access to an account from specific public IP addresses, or subnets on Virtual Networks.
- Subnets and Virtual Networks must exist in the same Region or Region Pair as the Storage Account.

#### Advanced threat protection

- Detects anomalies in account activity
- Only for Blob currently
- Security alerts are integrated with Azure Security Center

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
- **Append blobs**: like block blobs, but optimized for append operations, frequently used for logging from one or more sources.
- **Page blobs**: can be up to 8 TB in size, more efficient for frequent read/write operations. They provide random read/write access to 512-byte pages. Azure VMs use page page blobs as OS and data disks.

### Access tiers

For block blobs, there are three access tiers: "hot", "cool" and "archive", from hot to cool to archive, the cost of storing data decreases but the cost of retrieving data increses.

- An account has a default tier, either hot or cool
- A blob can be at any tier
- Archive
  - can only be set at blob level;
  - data is offline, only metadata available for online query;
  - to access data, the blob must first be **rehydrated** (changing the blob tier from Archive to Hot or Cool, this can take hours);


### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs, its public access level can be:
    - Private: no anonymous access
    - Blob: anonymous read access for blobs
    - Container: anonymous **read and list** access to the entire container and blobs
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories: technically containers are "flat", there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

### Life cycle management rules

- You could define rules to move blobs to a cooler tier when they are not modified for X days (hot -> cool/archive, cool -> archive)
- Or delete blobs at the end of their life cycle
- Apply rules to containers or a subset of blobs

### Object replication

You could add replication rules to replicate blobs to another storage account, the destination could be in another region, subscription, even another tenant.

- Blob content, versions, properties and metadata are all copied from source container to the destination container. Snapshots are not replicated.
- Blob versioning needs to be enabled on both accounts.

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

- All operations are async;
- Suitable for bulk operations, if interrupted, can resume from the point of failure;
- Supports hierarchical containers;
- Supports pattern matching selection;
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


## Files

Network files shares

- Accessed over SMB protocol
- Multiple VMs can share the same files with both read and write access

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.
