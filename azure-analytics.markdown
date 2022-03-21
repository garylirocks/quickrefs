# Azure Analytics


## Azure Data Factory

Cloud-base ETL (*extract-transform-load*) and data integration service, it can:

- **Ingest**: Create and schedule data-driven workflows (piplines) that can ingest data from disparate data stores
- **Transform**: Build complex ETL processes that transform data visually with data flows or by using services such as Azure HDInsight Hadoop, Azure Databricks and Azure SQL Database
- **Publish**: Publish your transformed data to data stores such as Azure Synapse Analytics for BI applications to consume

Concepts

- **Pipelines**: a logical grouping of activities
- **Activities**: a single step in the pipeline, three types:
  - Data movement
  - Data transformation
  - Control
- **Datasets**
- **Linked services**:
  - Data sources for ingest
  - Compute resources for transformation
- **Mapping data flows**
- **Integration runtime (IR)**: compute infrastructure used by ADF, three types
  - Self-hosted
  - Azure-SSIS
  - Azure
