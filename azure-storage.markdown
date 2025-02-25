# Azure Storage

- [Overview](#overview)
  - [Services](#services)
  - [Usages](#usages)
  - [Account level settings](#account-level-settings)
  - [Security](#security)
    - [Encryption](#encryption)
    - [Other security features](#other-security-features)
  - [Endpoints](#endpoints)
  - [Networking](#networking)
    - [Exceptions](#exceptions)
  - [Authorization Options](#authorization-options)
    - [Public read access for containers and blobs](#public-read-access-for-containers-and-blobs)
    - [RBAC](#rbac)
    - [Access keys](#access-keys)
    - [Shared access signature (SAS)](#shared-access-signature-sas)
  - [View data in Azure Portal](#view-data-in-azure-portal)
  - [CLI and curl commands with different auth methods](#cli-and-curl-commands-with-different-auth-methods)
  - [Microsoft Defender for Cloud](#microsoft-defender-for-cloud)
  - [CLI](#cli)
- [Blobs](#blobs)
  - [Blob types](#blob-types)
  - [Access tiers](#access-tiers)
  - [Organization](#organization)
  - [Properties, metadata](#properties-metadata)
  - [Index tags](#index-tags)
  - [Life cycle management rules](#life-cycle-management-rules)
  - [Data protection](#data-protection)
    - [Account](#account)
    - [Snapshot](#snapshot)
    - [Soft delete](#soft-delete)
    - [Versioning vs. soft-delete](#versioning-vs-soft-delete)
    - [Recommended settings](#recommended-settings)
    - [ADLS Gen 2](#adls-gen-2)
  - [Immutable storage for Azure Blobs](#immutable-storage-for-azure-blobs)
  - [Point-in-time restore](#point-in-time-restore)
  - [Operational backup](#operational-backup)
  - [Vaulted backup](#vaulted-backup)
  - [Object replication](#object-replication)
  - [CLI](#cli-1)
  - [AzCopy](#azcopy)
  - [.NET Storage Client library](#net-storage-client-library)
  - [Leases](#leases)
  - [Concurrency](#concurrency)
- [Azure Data Lake Storage Gen2](#azure-data-lake-storage-gen2)
  - [Authorization](#authorization)
  - [ACLs](#acls)
    - [Common scenarios](#common-scenarios)
    - [Users and identities](#users-and-identities)
    - [Permission evaluation](#permission-evaluation)
    - [Mask](#mask)
    - [CLI](#cli-2)
    - [Best practices](#best-practices)
    - [RBAC and ACL](#rbac-and-acl)
- [Files](#files)
  - [Billing](#billing)
  - [Create and mount a share](#create-and-mount-a-share)
  - [Authentication](#authentication)
  - [Snapshots](#snapshots)
  - [File Sync](#file-sync)
    - [Components](#components)
- [NetApp Files](#netapp-files)
- [Elastic SAN](#elastic-san)
- [Tables](#tables)
- [Azure Storage Actions](#azure-storage-actions)
- [Troubleshooting](#troubleshooting)

## Overview

### Services

![storage services overview](images/azure_storage-services.png)

- Azure Containers (Blobs): unstructured text or binary data
- Azure Files: network file shares
- Azure Queues
- Azure Tables: *could be migrated to Azure Cosmos DB, which has a API for Azure Tables*
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
- Secure transer required
  - Whether HTTPS is enforced
  - Azure file share over SMB without encryption fails
  - Custom domain names doesn't support HTTPS, this option does not apply when using custom domains
- Virtual networks: only allow inbound access request from the specified network(s)
- Tiers and kinds
  - **Standard** tier
    - **StorageV2**
      - Suitable for most scenarios
      - Includes all services and Data Lake Storage
      - Has Standard or Premium performance tier
    - **BlobStorage**
      - Block and append blobs, only standard performance tier
  - **Premium** tier
    - **BlockBlobStorage**: for low-latency, high-rate, small transactions
    - **PageBlobStorage**: high performance, VM disks
    - **FileStorage**: supports NFS, use provisional billing model

  *Premium tier use SSD, but do not support GRS, GZRS redundancy*

- Default access tier (*Standard accounts only, Does not apply to Premium accounts*)
  - Hot or cool
  - *Only applies to blobs*
  - Can be specified for each blob individually

- Redundancy

  ![Redundancy in the primary region](images/azure_data-redundancy-primary-region.png)

  - LRS: three copies in one location
  - ZRS (not available in all regions)

  ![Redundancy in a secondary region](images/azure_geo-redundant-storage.png)
  - GRS: replicated async to the secondary region (the paired region), LRS in both regions, secondary region data _ONLY_ readable if Microsoft initiates a failover
  - GZRS: ZRS in both regions
  - RA-GRS, RA-GZRS: you could read from secondary region any time

### Security

#### Encryption

- Encryption at rest

  - All data (including metadata) is automatically encrypted by Storage Service Encryption (SSE) with a 256-bit AES cipher. This can't be disabled.
  - Keys:
    - Data Encryption Key (DEK): this is encrypted by KEK and stored as metadata in Storage service
    - Key Encryption Key (KEK): used to envelope encrypt (wrap) the DEK, it never leaves a Key Vault
  - This applies to all services (blobs, files, tables, queues, etc) in the account
  - You could use either
    - Microsoft managed keys
      - Works for all services
    - Customer managed keys (CMK)
      - Only works for Blob and File services
      - You specify a key in a key vault (the key vault must have soft-delete and purge protection enabled)
      - The storage account needs a user-assigned or system-assigned identity to access the key
      - A CMK could be scoped to the whole account or only a specified service
    - Customer-provided key
      - For Blob storage operations. A client making a read or write request against Blob storage can include an encryption key on the request for granular control over how blob data is encrypted and decrypted.
  - Double encryption
    - This is encryption at infrastructure level
    - Always use Microsoft managed keys
    - SSE should be sufficient in most cases, use this only when necessary for compliance
    - Could be for the entire storage account or a custom **encryption scope**
      - Account level infrastructure encryption can only be enabled when creating the account
      - If account level infrastructure encryption is not enabled, when you create an encryption scope, you can still enable infrastructure encryption for the scope
  - **Encryption scope**
    - Encryption scopes enable you to manage encryption with a key that is scoped to a container or an individual blob.
      - When create a container, you can choose a default encryption scope, and whether to enforce this scope for all blobs uploaded to this container
      - When you upload a blob
        - If the container has an enforced encryption scope, you cannot specify another encryption scope
        - Otherwise, you can specify a any encryption scope in the storage account
    - Allows you to create secure boundaries between data that resides in the same storage account but belongs to different customers.
    - A scope could use either Microsoft-managed or customer-managed key
      - CMK key version could be updated either automatically or manually
    - Limitations:
      - A blob in an encryption scope always uses the default access tier, can't be changed
      - An scope could be disabled, but NOT deleted

- Encryption at tansit

  You can enforce HTTPS on an account. This flag will also enforce secure transfer over SMB by requiring SMB 3.0 for all file share mounts.

#### Other security features

- CORS support

  An optional flag you can enable on Storage accounts. Apply only for GET requests.

- Azure AD and RBAC

- Shared Access Signatures (see below)

- Auditing access

  Using the built-in "Storage Analytics" service, which logs every operation in real time.

### Endpoints

Default service endpoints:

- Container service: `//mystorageaccount.blob.core.windows.net`
- Table service: `//mystorageaccount.table.core.windows.net`
- Queue service: `//mystorageaccount.queue.core.windows.net`
- File service: `//mystorageaccount.file.core.windows.net`

Note:
- Account names must be globally unique
- You could configure a custom domain

### Networking

By default, connections from clients on any network are accepted.

- You can restrict access to an account from specific public IP addresses, or subnets on Virtual Networks.
- Subnets and Virtual Networks must exist in the same Region or Region Pair as the Storage Account.

The settings in the Portal actually corresponds to two properties, could be a bit confusing, the following is the mapping:

| Portal                                                  | `publicNetworkAccess` | `networkAcls.defaultAction` |
| ------------------------------------------------------- | --------------------- | --------------------------- |
| Enabled from all networks                               | `Enabled`             | `Allow`                     |
| Enabled from selected virtual networks and IP addresses | `Enabled`             | `Deny`                      |
| Disabled                                                | `Disabled`            | `Deny`                      |

*`publicNetworkAccess=Disabled` takes precedence, disables access from any IP or virtual network rule, means you could only access this storage account from*
  - private endpoints
  - specified resource instances
  - or from Trusted Azure Services (seems Exceptions still apply, though the setting is hidden from the Portal)

You can also have **Grant access for Azure resource instances**, see: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security

You specify which resource instances could access based on its managed identity, could be specific instances, or all from current resource group, subscription, or tenant.

```sh
az storage account network-rule add \
  -g rg-demo \
  --account-name stdemo001 \
  --resource-id /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.Synapse/workspaces/testworkspace \
  --tenant-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### Exceptions

"Allow Azure services on the **trusted services list** to access this storage account", this allows:

- Resources of some services that are registered *in the same subscription* can access this storage account for selected operations, like writing log or running backups.
- Trusted access based on a managed identity. (**All instances** are allowed, as long as their managed identity has proper permissions)

```sh
az storage account update \
--resource-group rg-demo \
--name stdemo001 \
--bypass AzureServices
```

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

Two types:

| Type          | Roles                                                   | Use                                       |
| ------------- | ------------------------------------------------------- | ----------------------------------------- |
| Control plane | Owner, Contributor, Storage Account Contributor, Reader | manage the account settings, keys         |
| Data plane    | Storage Blob/Table/Queue Data Owner/Contributor/Reader  | read/write access to containers and files |

- *Control plane roles (except "Reader") can access data because they can get the access keys, and most clients (Azure Portal, CLI, Storage Explorer etc) support access data via access those keys*
  - `az storage blob download --auth-mode key ...` retrieves an account key first
  - `az storage blob download --auth-mode login ...` uses your RBAC roles
- Does not support File shares, see the "Files" section
- Managed identity, service principals usually should only have data plane roles

#### Access keys

- Like a root password, allow **full access**
- Client doesn't need an identity in Azure AD
- Generally a bad idea, you **should avoid them**, there's now account level settings to disable these keys
- Typically stored within env variables, database, or configuration file.
- Should be private, don't include the config file in source control or store in public repos
- It's recommended that you manage access keys in Azure Key Vault
- Each storage account has two access keys, this allows key to be rotated:
  1. update connection strings in your app to use secondary access key
  2. Regenerate primary key using Azure portal or CLI.
  3. Update connection string in your code to reference the new primary key.
  4. Regenerate the secondary access key.
- You could set rotation reminder in the portal
  - Shows a notification banner in the Portal when any key expires
  - You can also use a built-in Azure policy to audit key expiration

#### Shared access signature (SAS)

SAS grants access to storage resources for a specific time range without sharing your account keys. Suitable for external third-party applications.

There are three types:

- **Account SAS**

  You could specify:

    - Allowed services: Blob, File, Queue, Table
    - Allowed resource types: Service, Container, Object
    - Allowed permissions: Read, Write, Delete, List, ...
      - "Add" permission is for adding a block to an append blob
    - No support for stored access policies

- **Service SAS**
  - Could be scoped at container level (blob container, file share, queue or table)
  - Or at individual blob level
  - Could associate a stored access policy

- **User delegation SAS**
  - Only for **Blob Storage and ADLS Gen2**: could be at container or blob level
  - Stored access policies not supported
  - Recommended over signing with an access key
  - How:
    - Use RBAC to grant the desired permissions to the security principal who will request the user delegation key.
    - Acquire an OAuth 2.0 token from Microsoft Entra ID.
    - Use the token to request the **user delegation key** by calling the Get User Delegation Key operation.
      - Need to specify the start and expiry time in the request body
      - Need permission `Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey` at the storage account level
    - Use the user delegation key to construct the SAS token with the appropriate fields.
      - The SAS valid time should be within the user delegation key valid time
  - How to revoke the SAS:
    - Revoke the "**user delegation key**"
    - Or remove RBAC permission from the service principal
  - The permissions are the intersection of the users' permissions and the permission specified in the SAS (`signedPermissions` field)

NOTE: *Account SAS and Service SAS are signed by account access key, so if you disable account key, they won't work*

There are two forms:

- Ad hoc SAS

  An ad hoc SAS URI looks like `https://myaccount.blob.core.windows.net/?restype=service&comp=properties&sv=2015-04-05&ss=bf&srt=s&st=2015-04-29T22%3A18%3A26Z&se=2015-04-30T02%3A23%3A26Z&sr=b&sp=rw&sip=168.1.5.60-168.1.5.70&spr=https&sig=F%6GRVAZ5Cdj2Pw4txxxxx`, it contains:

  - The start/expiry time and permissions
  - The `sig=F%6GRVAZ5Cdj2Pw4txxxxx` part is an HMAC computed over a string-to-sign and key using SHA256, then encoded using Base64

  The only way to revoke an ad-hoc SAS is to change the account access keys.

- Service SAS with stored access policy

  - Instead of specify the permissions and time on each SAS, you define a **stored access policy** at the container level (blob container, file share, queue or table). You can have a maximum of five stored access policies per container.
  - Then reference this policy when you create a service SAS
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

### View data in Azure Portal

See: https://learn.microsoft.com/en-us/azure/storage/blobs/authorize-data-operations-portal#permissions-needed-to-access-blob-data

When you try to view data (blob, files) in the Portal,

1. You need a "**Reader**" role on the storage account (or above) to navigate to it in the Portal
1. If you have a role with the `Microsoft.Storage/storageAccounts/listkeys/action` permission, then the portal uses access key for accessing data
    - When there is a "ReadOnly" lock on the account, the `listkeys` action, which is a POST action, would NOT be allowed, the user must use Entra credentials
1. Otherwise, the portal attempts to use Entra credentials

Note:

The setting "*Default to Microsoft Entra authorization in the Azure portal*" allows you to make Microsoft Entra authorization the default option, a user can still use access key authorization.

### CLI and curl commands with different auth methods

Some parameters can be set via environment variables:

  - `AZURE_STORAGE_ACCOUNT`
  - `AZURE_STORAGE_SERVICE_ENDPOINT`
  - `AZURE_STORAGE_AUTH_MODE`
  - `AZURE_STORAGE_CONNECTION_STRING`
  - `AZURE_STORAGE_KEY`
  - `AZURE_STORAGE_SAS_TOKEN`

With CLI, if nothing specified explicitly, environment variables or config files are tried in this order:

1. auth_mode
1. connection_string
1. storage key
1. sas_token

Examples:

- RBAC (**data plane RBAC role** assigned to current Entra principal, ALSO works with "**Contributor**" role on the storage account)

  ```sh
  az storage container list --account-name sttest001 --auth-mode login
  ```

  or if using curl

  ```sh
  accessToken=$(az account get-access-token \
                          --resource='https://storage.azure.com/' \
                          --query accessToken \
                          -otsv)

  curl --header "Authorization: Bearer $accessToken" \
       --header "x-ms-version: 2017-11-09" \
       "https://sttest001.blob.core.windows.net/?comp=list"
  ```

- Access keys (you need control plane RBAC role, eg. Contributor, to get the key)

  ```sh
  az storage container list --account-name sttest001 --auth-mode key
  ```

  or

  ```sh
  export AZURE_STORAGE_KEY=$(az storage account keys list \
                                  --account-name sttest001 \
                                  --query '[0].value' \
                                  -otsv)

  # List containers
  az storage container list --account-name sttest001

  # Download a blob
  az storage blob download --account-name sttest001 \
                           --container-name mycontainer \
                           --name test.txt \
                           --file downloaded.txt

  # curl
  # Requires an "Authorization" header like
  #   Authorization="[SharedKey|SharedKeyLite] <AccountName>:<Signature>"
  ```

- SAS

  ```sh
  # List containers
  az storage container list --connection-string <connection-string>
  az storage container list --account-name sttest001 --sas-token <sas-token>

  # Download a blob
  az storage blob download --container-name mycontainer \
                           --name test.txt \
                           --file downloaded.txt \
                           --connection-string <connection-string>
  az storage blob download --account-name sttest001 \
                           --container-name mycontainer \
                           --name test.txt \
                           --file downloaded.txt \
                           --sas-token <sas-token>

  # curl
  curl 'https://sttest001.blob.core.windows.net/?comp=list&<sas-token>'
  curl 'https://sttest001.blob.core.windows.net/mycontainer/test.txt?<sas-token>'
  ```

### Microsoft Defender for Cloud

- Could be enabled either on an individual account or at the subscription level
- Detects anomalies in account activity
- Only for Blob currently

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

- **Block blobs (default)**
  - The block is the smallest amount of data that can be read or written as an individual unit.
  - Blocks vary in size, from 64KiB to 100MiB.
  - A blob can contain up to 50,000 blocks, giving a max size of 4.7TB.
  - Best used for discrete, large, binary objects that change infrequently.
- **Append blobs**:
  - Specialized block blobs
  - Only supports "add" operation, no updating or deleting existing blocks (*the `add` permission is for adding a block to an append blob*)
  - Block size up to 4MB, blob size up to 195GB.
- **Page blobs**:
  - Fixed size 512-byte pages.
  - Optimized for random read and write operations.
  - Can be up to 8 TB in size.
  - Used for virtual disks.

### Access tiers

For block blobs, there are four access tiers: "hot", "cool", "cold" and "archive", from hot to archive, the cost of storing data decreases but the cost of retrieving data increses.

- An account has a default tier, either hot or cool
- A blob can be at any tier
- Archive
  - can only be set at blob level
  - data is **offline**, only metadata available for online query
  - to access data, the blob must first be **rehydrated**, two methods
    - Copying it to a new blob in the hot or cool tier
    - Changing the blob tier from Archive to hot or cool (this can take hours)

### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories
  - Technically containers are **"flat"** there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

### Properties, metadata

- Both containers and blobs have properties and metadata.
- Some properties correspond to certain standard HTTP headers, such as
  - "ETag"
  - "Last-Modified"
  - "Content-Length"
  - "Content-Type"
  - "Content-MD5"
  - "Content-Encoding"
  - "Content-Language"
  - "Cache-Control"
  - "Origin"
  - "Range"
- Metadata
  - are for your own purposes only
  - they show up in HTTP headers, eg. `x-ms-meta-<metatag>: <metavalue>`
  - updating metadata changes the blob's last-modified-time
  - not indexed and queryable by default, unless you use something like Azure Search

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

### Index tags

See [here](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-manage-find-blobs?tabs=azure-portal)

Similar to metadata, they are key-value pairs, but they are indexed, so let you:

- Find blobs across containers in an account
- Use `x-ms-if-tags` HTTP header for conditional blob operations
- Filter blobs in lifecycle management rules

Operations:

- Updating tags doesn't modify the blob's last-modified-time or eTag
- Index tags is a subresource of blob (`Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags`)
  - It could be retrived independently
  - You needs separate permissions, see below
  - For any blobs with at least one blob index tag, `x-ms-tag-count` is returned with "Get Blob" operation, indicating the count of tags
- If versioning is enabled, when you update/replace a blob, the tags will be preserved on the previous version, not the current version
- When copying blobs, index tags are not copied over
- Blob subtypes:
  - Base blobs: tags can be created or modified
  - Versions: tags preserved, can't be queried
  - Snapshots and soft-deleted: tags can't be modified

Permissions required:

- RBAC: "Storage Blob Data Owner" or `Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write` permission
- The `t` flag in SAS permission

Compare metadata and tags

|                           | Metadata     | Tags               |
| ------------------------- | ------------ | ------------------ |
| Limits                    | max. 8KB     | max. 10 tags       |
| Change last-modified-time | Yes          | No                 |
| Native indexing/quering   | No           | Yes                |
| In HTTP header            | Yes          | `x-ms-tag-count`   |
| Permissions               | Same as blob | Additional         |
| Encryption                | Same as blob | Microsoft-managed  |
| Pricing                   | Storage cost | Fixed cost per tag |

### Life cycle management rules

- You could define rules to move blobs to a cooler tier (hot -> cool -> cold -> archive) or deletion, after X days of creation or modification
- Could be filtered by:
  - Type: block / append blob
  - Subtypes: Base blobs / versions / snapshots
  - Filter: prefix, index tags
- Apply rules to containers or a subset of blobs
- **Changing a blob's tier doesn't affect its last modified time**. If there is a lifecycle management policy in effect for the storage account, then rehydrating a blob with "Set Blob Tier" can result in a scenario where the lifecycle policy moves the blob back to the archive tier after rehydration because the last modified time is beyond the threshold set for the policy.  To avoid this scenario, add the `daysAfterLastTierChangeGreaterThan` condition to the `tierToArchive` action of the policy. Alternatively, you can rehydrate the archived blob by copying it instead, copy operation creates a new instance of the blob with an updated last modified time, so it won't trigger the lifecycle management policy.

### Data protection

A container could have three types of data, each could be in normal or soft-deleted state:
- Active blobs
- Versions
- Snapshots

See various options [here](https://learn.microsoft.com/en-us/azure/storage/blobs/data-protection-overview)

#### Account

A deleted storage account is retained for 14 days, can be restored.

#### Snapshot

A blob snapshot is created manually, not necessary if versioning is enabled
- If you delete/undelete a blob, same action applies to the snapshots
- Depending on how often you overwrite blobs, versioning could be costly

#### Soft delete

- Container soft delete

  - When you restore a container, the blobs in it are still there

- Blob soft delete

  - Blob/snapshot/version could all be in soft-deleted state and restored

#### Versioning vs. soft-delete

|           | Versioning enabled    | Soft-delete only                                          |
| --------- | --------------------- | --------------------------------------------------------- |
| Overwrite | A new version created | A new snapshot (soft-deleted) created for every overwrite |
| Delete    | A new version created | Blob and snapshots became soft-deleted                    |
| Manage    | life cycle management | life cycle management                                     |

#### Recommended settings

- Resource lock on the storage account (prevent deletion and config changes)
  - This doesn't protect containers or blobs from being deleted or overwritten
- Container soft delete
- Blob versioning for Blob Storage
- Manual snapshots for ADLS

#### ADLS Gen 2
- Snapshot is supported (in preview)
- Blob soft delete is supported
- Versioning is NOT supported

### Immutable storage for Azure Blobs

![Immutable storage policies](images/azure_blob-immutable-policies.png)

For compliance or legal reasons, you could configure immutability policies for blob data, protecting it from overwrites and deletes.

There are two types of policies:
  - **Time-based retention policy**: during the retention period, objects can be created and read, but not modified or deleted. After the period has expired, objects can be deleted but not overwritten.
  - **Legal hold policies**: data is immutable until the legal hold is explicitly cleared

Levels:

- You can enable version-level immutability support on account/container
  - Blob versioning must be enabled
  - You could apply a default policy (time-based retention) on the account/container
  - If the support is enabled on a container (no default policy), and the container is NOT empty, you cannot delete the container or account
  - Once a policy is created and locked, you cannot change the policy or delete the container/account
- Or you can set policies for specific blob versions

Notes:

- A blob's storage tier could still be changed (eg. from hot to cool) with an applied immutability policy.
- Blob overwrites are be allowed, but Azure will maintain immutable versions of each blob.

### Point-in-time restore

- Restore one or more containers
- If point-in-time restore is enabled, then versioning, change feed, and blob soft delete must also be enabled
- Only support block blobs, NOT page blobs, or append blobs

### Operational backup

You can turn on this feature, you need a backup policy in a Backup vault, this enables soft delete for blobs, and blob versioning automatically

### Vaulted backup

- Data backed up to a Microsoft tenant with no-direct access
- Individual containers could be restored to a different storage account

### Object replication

You could add replication rules to replicate blobs to another storage account.

- The destination could be in another region, subscription, even another tenant (`AllowCrossTenantReplication` property controls whether this is allowed).
- Only one replication policy may be created for each source account/destination account pair.
- Each policy can have multiple rules
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

- All operations are async, each instance creates a job, you can view and restart previous jobs and resume failed jobs;
  - "copy" operation is synchronous
- Automatically retry a transfer after a failure;
- Supports copying an entire account (Blob/ADLS service only) to another account;
- Supports hierarchical containers;
- Authentication:
  - With Entra ID (user, managed identity, service principal), you need **data level permissions** (like Blob Data Contributor, etc), see [here](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-authorize-azure-active-directory)
    - Use environment variable to specify auth method, eg `export AZCOPY_AUTO_LOGIN_TYPE=AZCLI`
  - Append an SAS token to every endpoint URL
- Supports wildcard patterns in a path
- Optional flags
  - `--include`, `--exclude` for filtering
  - `--include-after` to only include files changed after a specific date/time
  - `--blob-type`, `--block-blob-tier` to config destination blobs type and tier

```sh
# upload file
azcopy copy "myfile.txt" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>"

# upload folder recursively
azcopy copy "myfolder" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>" \
  --recursive=true

# copy between accounts
# - copy data between servers directly
# - could copy individual blob, a virtual folder, a container or the entire account
# - client needs network access to both source and destination accounts
# - index tags are not copied, you can add tags using `--blob-tags` parameter
azcopy copy "https://sourceaccount.blob.core.windows.net/sourcecontainer/*?<source sas token>" \
  "https://destaccount.blob.core.windows.net/destcontainer/*?<dest sas token>"

# sync data, similar to copy, but it can compare timestamp/MD5 to determine if a file needs to be copied
azcopy sync ...

# create new container
azcopy make ...

# list/remove files
azcopy [list|remove] ...

# change access tier
azcopy set-properties '<url>' --block-blob-tier=[hot|cool|cold|archive]
# update metadata
azcopy set-properties '<url>' --metadata=mykey1=myvalue1;mykey2=myvalue2
# update index tags
azcopy set-properties '<url>' --blob-tags=mytag1=mytag1value;mytag2=mytag2value

# show job status
azcopy jobs list
```

### .NET Storage Client library

- Suitable for complex, repeated tasks
- Provides full access to blob properties
- Supports async operations

### Leases

- On container: prevents it from being deleted, doesn't affect operations on blobs in it
- On blob: prevents a blob from being modified by other apps

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


## Azure Data Lake Storage Gen2

Build on top of blob storage. Support big data analytics.

- Has real folders, you could
  - Rename a folder
  - Set ACL permissions on a folder
  - Genearate a SAS token on a folder
- You can upgrade a storage account to ADLS Gen2 (can't revert back), some features aren't supported:
  - Page blob
  - Container soft delete
  - Blob versioning
  - Blob-version level immutability policy
  - Point-in-time restore
  - Blob tagging
  - ...

### Authorization

Four mechanisms:

- Shared Key
- SAS
- RBAC: "coarse-grained", at storage account or container level
- Access control lists (ACL): "fine-grained", at root/directory/file level

RBAC and ACL do not apply when using a Shared Key or SAS token, because the caller do not have an associated identity.
  - Shared Key: means 'super-user' access, can access data, setting owner, changing ACLs
  - SAS: whatever permissions included in the SAS token

### ACLs

![An example ACL](images/azure_storage-adls2-acls.png)

- Each container has a root folder
- Root/Folders can have default ACLs, which are copied to:
  - A child directory's access ACL and default ACL
  - A child file's access ACL
- The "Execute" permission only has effects on directories, allowing you to traverse the child items of a directory.
- ACLs do not inherit:
  - Default ACLs can be used to set ACLs for child items
  - For existing items, you will need to add/update/remove ACLs recursively for the directory

#### Common scenarios

| Scenario                 | ACL                                                                  |
| ------------------------ | -------------------------------------------------------------------- |
| Read a file              | `R--` on the file                                                    |
| Append to a file         | `RW-` on the file                                                    |
| List file in a directory | `R-X` on the directory                                               |
| Create/delete file       | `-WX` on the containing directory, no permssion required on the file |

Always required: *`--X` on from root to parent directory*

#### Users and identities

| Identity     | Who                                                                                               | Can                                                                    | Can't        |
| ------------ | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------ |
| Owner        | OAuth: current user, otherwise: `$superuser`                                                      | change ACLs, change owning group (to another one the owner belongs to) | change owner |
| Owning group | <li>Root: OAuth: current user, otherwise: `$superuser`</li><li>Otherwise: copied from parent</li> | similar to other named groups                                          | change ACLs  |

#### Permission evaluation

Order:

1. Superuser
1. Owner
1. Named user, SP, managed identity
1. Owning group or named group
1. All other

Algorithm (https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-access-control#how-permissions-are-evaluated):

1. If super user, allow, stop
2. If owner, check owner permission (without mask), stop
3. If named user, check permission (with mask), stop
4. Go through named/owning groups the user belongs to, if any group has the right permissions (with mask), then allow, otherwise go next
5. Consider "Other" permissions (with mask)

#### Mask

- Mask limits access for names users, owning/named groups, and other
- For root directory, defaults to 750 for directories and 640 for files
- May be specified on a per-call basis, overrides the default mask

#### CLI

```sh
# Get ACL permissions of a folder
az storage fs access show \
  --file-system data \
  --path myfolder \
  --account-name adsl2gary \
  --auth-mode login

# {
#   "acl": "user::rwx,user:4abac5a4-ae5f-4f63-8c62-4d7d307c28fd:r-x,group::r-x,mask::r-x,other::---,default:user::rwx,default:group::r-x,default:other::---",
#   "group": "$superuser",
#   "owner": "$superuser",
#   "permissions": "rwxr-x---+"
# }

# Update ACLs recursively
az storage fs access set-recursive ...
```

#### Best practices

- Always use groups in an ACL entry, instead of individual users

#### RBAC and ACL

RBAC roles are evaluated first, eg. `Storage Blob Data Contributor` can always read/write a file, regardless of ACLs

Some RBAC roles allow a user to change ACLs:

| RBAC                                       | ACL                                     |
| ------------------------------------------ | --------------------------------------- |
| Owner/Contributor, Storage Blob Data Owner | set the owner, modify ACLs of all items |
| Storage Blob Data Contributor              | can modify ACLs of owned items          |


## Files

Overview

- A *FileStorage* storage account can have both SMB and NFS shares, but a share can only be accessed with one protocol
- Multiple VMs can share the same files with both read and write access
- Can be used to replace your on-prem NAS devices or file servers
- Up to 1TB for a single file, 100TB in a storage account, 2000 concurrent connections per shared file

Protocols:

- SMB:
  - Supports SMB v3.0, SMB v2.1
  - Supports:
    - Kerberos auth, ACLs, and encryption-in-transit
    - Data plane REST API (view file in the Portal)
      - REST API supports SAS token, SMB protocol does not
    - Share level RBAC
    - Azure Backup / share snapshots
- NFS
  - *Premium* tier, *FileStorage* type storage account only
  - Supports NFS v4.1
  - Features:
    - POSIX-compliant
    - Hard link / symbolic link
    - Permissions for NFS file shares are enforced by the client OS rather than the Azure Files service
  - Scenarios:
    - Storage for Linux/Unix applications
    - POSIX-compliant file shares, case sensitivity, or Unix style permissions
  - NO support for
    - Kerberos auth
    - ACLs
    - Encryption-in-transit (must disable **Secure transfer required**)
    - Data plane REST API (view file in the Portal)
    - Share level RBAC
    - Azure Backup / share snapshots
    - Azure File Sync
    - GRS or GZRS
    - Soft delete
    - AzCopy / Azure Storage Explorer
    - Windows

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.

Tiers:

- Premium: backed by SSD, supports NFS protocol
- Standard:
  - Transaction optimized
  - Hot
  - Cool

Compare to Blobs and Disks

- Files have true directory objects, Blobs have a flat namespace (excluding ADLS v2).
- File shares can be mounted concurrently by multiple cloud or on-prem machines, Disks are exclusive to a single VM (except shared disks).
- Files shares are best suited for random access workloads.

### Billing

You need to select the tier when creating the storage account, not for individual file shares

- Standard tier
  - Actual capacity usage
  - or Provisioned v2 (size, IOPS, and throughput could be changed independently)

- Premium tier
  - Provisioned
    - Minimum size: 100GiB, incremental unit 1GiB
    - IOPS and throughput increase along with the provisioned size

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

- Access Key
  - Works for all OS: Windows, Mac, Linux
  - Use the primary key of the storage account as password

- Identity-based access (Windows only, SMB shares only)
  - From AD DS or Microsoft Entra Domain Services domain-joined VMs
  - Share-level permissions can be performed on Microsoft Entra users/groups via RBAC model (eg. Storage File Data SMB Share Reader)
    - With RBAC, the credentials you use for file access should be available or synced to Microsoft Entra ID
  - At directory/file level, Azure Files supports preserving, inheriting, and enforcing Windows DACLs just like any Windows file servers. Windows ACLs can be preserved when back up a file share to Azure Files.

![Identity based authentication data flow](images/azure_file-share-authentication.png)

*The Domain Services at step 1 could be either on-prem AD DS or Entra DS*

### Snapshots

To protect against unintended changes, accidental deletions, or for backup/auditing purpose, you could take snapshots.

- A snapshot captures a point-in-time, read-only copy of your data.
- Snapshots are created at the file share level, retrieval is at the individual file level.
- You **cannot delete** a share without deleting all the snapshots first.
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


## Elastic SAN

- A block storage solution, can be attached to any compute workload via network (iSCSI protocol)
- Useful when you want to pool your storage, so no need to over-provision for each workload
- Redundancy: LRS or ZRS
- A SAN can have both base and capacity units:
  - Base units (0 - 400): each unit comes with 1TiB capacity, 5000 IOPS, 200 MBps throughput
  - Capacity units (0 - 600): 1TiB capacity per unit
- Networking
  - Public endpoint, connect via service endpoint in vNets
  - Private endpoint
- Volume Group:
  - A boundary of networking and encryption (PMK or CMK) options
- Volume
  - Each has its own size, IOPS and throughput
  - IOPS and throughput can be set as the same as the maximum limit of the SAN, but they will be throttled if the sum exceeds the limit at a paticular time
  - You run a script in a VM to connect to a volume
  - A volume can have a max of 128 sessions
  - A client can have a max of 32 sessions to a volume
- Snapshots
  - At volume level
  - The first one is a full snapshot, the followings ones are delta
- Scenarios
  - On-prem migration
  - High performance
  - AVS (Azure VMWare Solution)
  - Azure Container Storage


## Tables

A NoSQL solution, makes use of tables containing key/value data items

![Azure Storage Account tables](images/azure_storage-tables.png)

- A row always has three columns `PartitionKey`, `RowKey` and `Timestamp` (last update time)
- The composite of `PartitionKey` and `RowKey` uniquely identifies a row
- No foreign keys, stored procedures, views, or other objects
- You can set RBAC permissions at table level


## Azure Storage Actions

Serverless framework to perform common data operations on millions of objects across multiple storage accounts.

- You create storage tasks, which are individual resources (`Microsoft.StorageActions/storageTasks`)
- Comparing to life cycle management, this is
  - More flexible
  - Could be applied across storage accounts
  - But there will be cost (Life cycle management is free)
- Each task has
  - Conditions (access tier, name, tag, access time, etc)
  - Operations (set tier, set tag, delete, etc)
    - Optionally, you could have operations for un-matched blobs as well
- Each task could be assigned to multiple storage accounts, each assignment (`Microsoft.StorageActions/storageTasks/<task-name>/assignments`) specify:
  - Storage account
  - What role to assign to the managed identity of the storage task
  - Filter: include/exclude blob prefixes
  - Schedule: single-run or recurring
- If a single-run assignment has completed, you can't update it, you need to duplicate and edit


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
