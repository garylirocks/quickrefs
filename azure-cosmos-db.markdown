# Azure Cosmos DB

- [Overview](#overview)
- [Multi Models (APIs)](#multi-models-apis)
- [Common CLI operations](#common-cli-operations)
- [Request unit](#request-unit)
- [Partitioning](#partitioning)
- [Indexing](#indexing)
- [Stored procedures](#stored-procedures)
- [User-defined functions (UDF)](#user-defined-functions-udf)
- [Global distribution](#global-distribution)
    - [Multi-region writes](#multi-region-writes)
  - [Private endpoint](#private-endpoint)
- [Consistency levels](#consistency-levels)

## Overview

Features

- Multi-model
- Global distribution

## Multi Models (APIs)

![Multi models](images/azure_cosmosdb-multiple-data-models.png)

It supports multiple API and data models(*each account only supports one model*):

- NoSQL
  - For document data model, manages data in JSON format
  - Uses SQL syntax
- PostgreSQL
  - Single node or multiple node clusters
- MongoDB
  - Data stored in Binary JSON (BSON)
  - MongoDB Query Language: `db.products.find({id: 123})`
- Apache Cassandra
  - Column-family storage
- Azure Table
  - key-value
  - for migrating data from Azure Table, Cosmos offers global distribution, high availability, scalable throughput
- Gremlin(graph)

Which DB solution to use?

![DB solution decision tree](images/azure_db-solution-decision-tree.png)

## Common CLI operations

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

## Request unit

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

## Partitioning

- Partitioning is the distribution and grouping of your data across the underlying resources;
- Documents are grouped in a partition based on the partition key;
- A partition key can be a single or multiple fields of a document;
- Partition key can't be changed after a collection is provisioned;
- Documents with the same partition key are in the same logical partition, but possibly multiple **physical partitions**;

## Indexing

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

## Stored procedures

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

## User-defined functions (UDF)

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

## Global distribution

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

### Private endpoint

One private endpoint could put multiple domains in a private DNS zone:

```
cosmon-demo           10.0.0.4
cosmon-demo-eastus    10.0.0.5
cosmon-demo-westus    10.0.0.6
```

The global name CNAME to the privatelink FQDN first:

```
cosmon-demo.mongo.cosmos.azure.com CNAME cosmon-demo.privatelink.mongo.cosmos.azure.com
cosmon-demo.privatelink.mongo.cosmos.azure.com CNAME XXXX.westus.cloudapps.azure.com
...
```

So if you use the global FQDN in your application, it doesn't work well with one global private DNS zone, regional private DNS zone works better.


## Consistency levels

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
