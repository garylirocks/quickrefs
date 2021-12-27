# Azure Storage

- [Overview](#overview)
  - [Files](#files)
  - [Organization](#organization)
  - [Security](#security)
    - [Access keys](#access-keys)
    - [Shared access signature (SAS)](#shared-access-signature-sas)
    - [Network access](#network-access)
    - [Advanced threat protection](#advanced-threat-protection)
- [Blobs](#blobs)
  - [CLI](#cli)
  - [AzCopy](#azcopy)
  - [.NET Storage Client library](#net-storage-client-library)
  - [Access tiers](#access-tiers)
  - [Properties and Metadata](#properties-and-metadata)
  - [Concurrency](#concurrency)
- [Cosmos DB](#cosmos-db)
  - [Common CLI operations](#common-cli-operations)
  - [Request unit](#request-unit)
  - [Partitioning](#partitioning)
  - [Indexing](#indexing)
  - [Stored procedures](#stored-procedures)
  - [User-defined functions (UDF)](#user-defined-functions-udf)
  - [Global distribution](#global-distribution)
    - [Multi-region writes](#multi-region-writes)
  - [Consistency levels](#consistency-levels)
- [Redis Caching](#redis-caching)

## Overview

![storage services overview](images/azure_storage-services.png)

Blobs, Files, Queues and Tables are grouped together into Azure storage and are often used together

Storage account level settings:

- Subscription
- Location
- Performance
  - Standard: magnetic disk drives
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
  - StorageV2 (general purpose v2): all storage types, latest features
  - Storage (general purpose v1): legacy
  - Blob storage: legacy, allows only block blobs and append blobs
- Deployment model
  - Resource Manager
  - Classic: legacy

### Files

Network files shares, accessed over SMB protocol

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.

### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs, you can set an individual container as public.
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories: technically containers are "flat", there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

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

  RBAC is the Most flexible access option.
  Can be applied to both resource management(e.g. configuration) and data operations(only for Blob and Queue).

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

- support expiration and limited permissions
- suitable for external third-party applications
- can be applied to only containers or objects

Two typical designs for using Azure Storage to store user data:

  - Front end proxy: all data pass through the proxy

  ![Front end proxy](images/azure_storage-design-front-end-proxy.png)

  - SAS provider: only generates a SAS and pass it to the client

  ![SAS provider](images/azure_storage-design-lightweight.png)


#### Network access

By default, connections from clients on any network are accepted. You can restrict access to specific IP addresses, ranges or virtual networks.

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

Three kinds of blobs:

- Block blobs: for files that are read from beginning to end, files larger than 100MB must be uploaded as small blocks which are then consolidated into the final blob.
- Page blobs: to hold random-access files up to 8 TB in size, used primarily as storage for the VHDs used to provide durable disks for Azure VMs. They provide random read/write access to 512-byte pages.
- Append blobs: specialized block blobs, but optimized for append operations, frequently used for logging from one or more sources.

Many Azure components use blobs behind the scenes, Cloud Shell stores your files and configuration in blobs, VMs use blobs for hard-disk storage.

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

### Access tiers

- Hot and Cool can be set as account or blob level;
- Archive
  - can only be set at blob level;
  - data is offline, only metadata available for online query;
  - to access data, the blob must first be **rehydrated** (changing the blob tier from Archive to Hot or Cool, this can take hours);
- Premium: only available for BlobStorage accounts (legacy);

From Hot to Cool to Archive, the cost of storing data decreases but the cost of retrieving data increses.

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


## Cosmos DB

Features

- Multi-model

  It supports multiple API and data models(*each account only supports one model*):

    - Core (SQL) *this is for NoSQL document DB as well, and is recommended, other APIs are mainly for migration purposes*
    - MongoDB
    - Cassandra
    - Azure Table (for migrating data from Azure Table, Cosmos offers global distribution, high availability, scalable throughput)
    - Gremlin(graph)

- Global distribution

### Common CLI operations

```sh
export NAME=cosmos$RANDOM

az cosmosdb create \
    --name $NAME \
    --kind GlobalDocumentDB

az cosmosdb sql database create \
    --account-name $NAME \
    --name "Products"

az cosmosdb sql container create \
    --account-name $NAME \
    --database-name "Products" \
    --name "Clothing" \
    --partition-key-path "/productId" \
    --throughput 1000
```

### Request unit

- You can provision throughput on a database or a container;
- Throughput is meseaured with request units per second (**RU/s**);
- If your request consumes all provisioned throughput, then Azure will rate-limit your requests, you need to retry your request;
- Billing is based on provisioned RUs, whether you use them or not;

A single RU is equal to the approximate cost of performing a single GET request on a 1-KB document using a document's ID. Creating, replacing or deleting the same item requires additional processing, thus more RUs.

The number of RUs consumed by an operation is depending on a range of factors:

- item size
- item indexing
- item property count
- indexed properties
- data consistency level (strong and bounded staleness consume approximately two times more RUs on read)
- complexity of a query (same query on the same data always costs the same amount of RUs)
- script usage (stored procedures and triggers)

### Partitioning

- Partitioning is the distribution and grouping of your data across the underlying resources;
- Documents are grouped in a partition based on the partition key;
- A partition key can be a single or multiple fields of a document;
- Partition key can't be changed after a collection is provisioned;
- Documents with the same partition key are in the same logical partition, but possibly multiple **physical partitions**;

### Indexing

- By default, all document properties are indexed;
- Indexing mode:
  - **Consistent**, index is updated synchronously every time a new document is written
  - **Lazy**, when the index is fully updated depends on the demand
  - **None**

A sample indexing policy:

```sh
{
    "indexingMode": "consistent",
    "automatic": true,
    "includedPaths": [
        {
            "path": "/Item/id/?"
        },
        {
          "path": "/Customer/email/?"
        },
        ...
    ],
    "excludedPaths": [
        {
            "path": "/"
        }
    ]
}
```

### Stored procedures

- Written in JS, stored in container;
- Have acccess to the context object, CAN read/write documents;
- The **only way to ensure ACID transactions**, the client-side SDKs do not support transactions;
- Recommended for batch operations;
- Only works within a **single partition**, so you need to give it a partition key value when executing;

```js
// a sample that sends a simple response
function helloWorld() {
    var context = getContext();
    var response = context.getResponse();

    response.setBody("Hello, World");
}
```

### User-defined functions (UDF)

- To extend SQL query grammar and implement custom business logic, such as calculations on properties or documents;
- Can only be called from queries, do not have access to context object, so they **CAN NOT** read or write documents;

```js
// use a UDF to calculate tax based on price
function producttax(price) {
    if (price == undefined  )
        throw 'no input';

    var amount = parseFloat(price);

    if (amount < 1000)
        return amount * 0.1;
    else if (amount < 10000)
        return amount * 0.2;
    else
        return amount * 0.4;
}
```

Then you can use this UDF in a query

```sql
SELECT c.id, c.productId, c.price, udf.producttax(c.price) AS producttax FROM c
```

### Global distribution

You Cosmos DB can be replicated to multiple regions around the globe. It is recommended to add regions based on Azure Paired Regions.

Common scenarios:
- Deliver low-latency data access
- Add regional resiliency for business continuity and disaster recovery (BCDR)

![Comsos DB global distribution](images/azure_cosmosdb-global-distribution.png)

#### Multi-region writes

AKA multi-master support, when you perform writes in a write-enabled region world-wide, written data is propagated to all other regions immediately.

Rarely, conflicts can happen when an item is changed simultaneously in multiple regions. There are three conflict resolution modes offered by Cosmos DB.

- **Last-Writer-Wins (LWW)** - this is the default mode, based on the `_ts` timestamp
- **Custom - User-defined function** - a user-defined function is a special type of stored procedure
- **Custom - Async** - all conflicts are registered in the read-only conflicts feed for deferred resolution

### Consistency levels

![Consistency spectrum](images/azure_cosmosdb-consistency-spectrum.png)

- Consistency levels are guaranteed for all operations regardless of the region from which the reads and writes are served, the number of regions or whether the account is configured with a single or multiple write regions.
- *You set the default consistency level on your Azure Cosmos DB account, which can be overridden by a specific read request.*

| Consistency Level | Guarantees                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------- |
| Strong            | Linearizability. Reads are guaranteed to return the most recent version of an item.          |
| Bounded Staleness | Consistent Prefix. Reads lag behind writes by at most k prefixes or t interval.              |
| Session           | Consistent Prefix. Monotonic reads, monotonic writes, read-your-writes, write-follows-reads. |
| Consistent Prefix | Updates returned are some prefix of all the updates, with no gaps.                           |
| Eventual          | Out of order reads.                                                                          |

## Redis Caching

Tiers:

- Basic: single server, ideal for dev/testing, no SLA;
- Standard: supports two servers (master/slave), 99.99% SLA;
- Premium: persistence, clustering and scale-out, virtual network;

Best practices:

- Redis works best with data that is 100K or less
- Longer keys cause longer lookup times because they're compared byte-by-byte

Transactions:

- Use `MULTI`, `EXEC` to init and commit a transaction
  - If a command is queued with incorrect syntax, the transaction will be automatically discarded;
  - If a command fails, the transaction will complete as normal;
- There is no rollback;
