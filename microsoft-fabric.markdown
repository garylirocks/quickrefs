# Microsoft Fabric

- [Overview](#overview)
- [Concepts](#concepts)


## Overview


## Concepts

- OneLake
  ![OneLake](./images/microsoft_fabric-onelake.png)

  - Automatically provisioned in Fabric
  - One instance for the whole tenant
    - Use workspaces for governance boundaries
  - Central repository for all your analytics data: structured or unstructured, any type of file, and allows you to use the same data across multiple analytical engines without data movement or duplication
  - Stores data in **Delta Parquet** format
  - Built upon Azure Data Lake Gen 2, supports existing ADLS Gen2 APIs and SDKs

- Fabric capacity
  - Resources in Azure (`Microsoft.Fabric/capacities`)
  - You can use with your Fabric workspaces
    - Shared by all workloads in a workspace: SQL DB, DW, Spark, MI, etc, NO need for pre-allocation
  - A capacity could be shared by multiple workspaces
  - Charged per capacity unit (CU) (F2 ~ F2048, ~150NZD per unit/month)
  - Each business unit can create their own capacity resources
  - Can be paused, and easily scale up and down
  - Can be purchased in reservation
