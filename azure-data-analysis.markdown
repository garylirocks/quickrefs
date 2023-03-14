# Azure data analysis

- [Overview](#overview)
- [Azure Synapse Analytics](#azure-synapse-analytics)
  - [Deployment](#deployment)
  - [SQL](#sql)
  - [Spark](#spark)
- [Databricks](#databricks)
- [HDInsight](#hdinsight)
- [Stream Analytics](#stream-analytics)
- [Azure Data Explorer](#azure-data-explorer)
- [Microsoft Purview](#microsoft-purview)
- [Power BI](#power-bi)
- [On-prem data gateways](#on-prem-data-gateways)
  - [Auth](#auth)
  - [Networking](#networking)
  - [Installation](#installation)
- [Virtual network data gateways](#virtual-network-data-gateways)
  - [Create](#create)


## Overview

//TODO


## Azure Synapse Analytics

A comprehensive, unified data analytics solutions that provides a single service interface for multiple analytical capabilities:

- Pipelines, same technology as ADF
- SQL, optimized for data warehouse workloads
- Apache Spark
- Azure Synapse Data Explorer

The UI of Synapse Studio is very similar to ADF's

### Deployment

- Requires two resource groups, including a managed one
- Requires a Data Lake storage account, to store data, scripts and other artifacts
  - A linked service is created to this storage account, using the workspace's managed identity, which has the "Storage Blob Data Contributor" role
- Deploys a serverless SQL pool by default, you need to set the SQL admin username, password, AAD admin, etc
  - The SQL server's endpoint is like: `<synapse-workspace-name>.sql.azuresynapse.net`
  - A linked service is created to this SQL server, using the workspace's managed identity
- One instance can have multiple
  - Dedicated SQL pools
  - Apache Spark pools
  - Data Explorer pools

### SQL

You can use SQL to query CSV data in the storage account:

```sql
SELECT
    Category, Count(*) as ProductCount
FROM
    OPENROWSET(
        BULK 'https://mydatalake.dfs.core.windows.net/fs-synapse/products.csv',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE
    ) AS [result]
Group by Category;
```

### Spark

- You could create a Spark pool, 3 nodes at minimum
- You could load CSV data to a DataFrame and query it using the Spark pool

  ```
  %%pyspark
  df = spark.read.load('abfss://fs-synapse@mydatalake.dfs.core.windows.net/products.csv', format='csv', header=True)
  display(df.limit(10))

  df_counts = df.groupBy(df.Category).count()
  display(df_counts)
  ```


## Databricks

- Could be used on multiple clouds
- Run big data pipelines using both batch and real-time data
  - Batch data from Data Factory
  - Real-time data from Event Hub, IoT hub
- Train machine-learning models
- Uses Spark


## HDInsight

- Not as user-friendly as Azure Synapse Analytics and Azure Databricks
- Support multiple Apache open-source data analytics cluster types:
  - Apache Spark: distributed data processing system
  - Apache Hadoop: distributed system that uses *MapReduce* jobs to process large volumes of data efficiently across multiple cluster nodes
  - Apache HBase: large-scale NoSQL data storage and querying
  - Apache Kafka: message broker for data stream processing


## Stream Analytics

Real-time stream processing engine


## Azure Data Explorer

- An end-to-end solution for data ingestion, query, visualization and management.
- Features:
  - Uses Kusto query language.
  - Full text search
  - Dynamic schema
  - Advanced analytics: anomaly detection, root cause analysis, regression, geospatial analysis, embedding Python code in KQL queries
  - Data visualization: integrate with Power BI, Grafana, Kibana, etc
- A good fit for:
  - Interactive, near real-time analytics
  - High volume, varied data
- Not a good fit for:
  - Real-time analytics
  - Long running tasks including recurring ETL and large ML model training
  - Classis data warehouse, Star schema

![ADX Overview](./images/azure_adx-overview.png)

- All data is automatically indexed and partitioned (to shards) based on the ingestion time
- There are no primary foreign key and uniqueness constraints
- A database can have tables and external tables (underlying storage is in other locations such as Azure Data Lake)
- KQL supports:
  - Cross-cluster and cross-database queries
  - Parsing JSON, XML etc
  - Advanced analytics
- There are control commands for creating new clusters or databases, data connections, auto scaling, managing permissions, security policies, etc


## Microsoft Purview

A solution for enterprise-wide data governance and discoverability.

Create a map of your data and track data lineage across multiple data sources and systems.


## Power BI

A platform for analytical data modeling and reporting, create and share interactive data visualizations.


## On-prem data gateways

Quick and secure data transfer between on-prem data and Microsoft cloud services, seems mainly intended for **Power BI**, could also be used by Azure Logic Apps, Power Apps, Power Automate, Azure Analysis Services

Data gateway is different to Data Management Gateway (Self-hosted integration runtime) used by Azure Machine Learning Studio and Data Factory

Two types:
- Standard: multiple users to connect to multiple on-prem data sources
- Personal mode: Power BI only, one user only

Condiderations:
- There are limits on read/write payload size, GET URL length

![Data gateway architecture](./images/azure_on-prem-data-gateway-how-it-works.png)

### Auth

- Data source credentials are encrypted and stored in the gateway cloud service, decrypted by the on-prem gateway.
- When using OAuth2 credentials, the gateway currently doesn't support refreshing tokens automatically when access tokens expire (one hour after the refresh started). This limitation for long running refreshes exists for VNET gateways and on-premises data gateways.

### Networking

See: https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-communication

- There is **NO inbound connections to the gateway**
- The gateway uses **outbound connections to Azure Relay** (IPs and FQDNs)
  - You need to configure your on-prem firewall to unblock Azure Datacenter IP list
- By default, the gateway communicates with Azure Relay using direct TCP, but you can force HTTPS communication
- Even with ExpressRoute, you still need a gateway to connect to on-prem data sources

### Installation

- Can't be on a domain controller
- The standard gateway need to be installed on a machine:
  - domain joined
  - always turned on
  - wired rather than wireless
- You can't have more than one gateways running in the same mode on the same computer
- You can install multiple gateways (on different machines) to setup a cluster
- During installation, you need to **sign in** to your organization account, this registers the gateway to the cloud services, then you manage gateways from within the associated services
- For Logic Apps, after the gateway is installed on-prem, you need to add a corresponding resource in Azure as well.


## Virtual network data gateways

![vNet data gateway](images/azure_vnet-data-gateway-overview.png)

Helps connect to your Azure data services within a VNet without the need of an on-prem data gateway.

![vNet data gateway architecture](images/azure_vnet-data-gateway-architecture.png)

- A subnet is delegated to the data gateway service
- At step 2, the Power Platform VNet injects a container running the VNet data gateway in to the subnet
- The gateway *obeys NSG and NAT rules*
- The gateway *doesn't* require any Service Endpoint or open ports back to Power BI, it uses the SWIFT tunnel, which is a feature existing on the infrastructure VM

### Create

- Register `Microsoft.PowerPlatform` as a resource provider
- Associate the subnet to Microsoft Power Platform
  - Don't use subnet name "gatewaysubnet", it's reserved for Azure Gateway Subnet
  - The IP range could not overlap with `10.0.1.0/24`
- Create a VNet data gateway in Power Platform admin center
  - You can see the delegated subnet there
  - You can create multiple gateways (max. 3) for HA and load balancing


VNet gateways are in the same region as the VNet, the metadata (name, details, encrypted credentials) are in your tenant's default region.
