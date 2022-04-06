# Azure Analytics

- [Azure Data Factory](#azure-data-factory)
- [Integration Runtime](#integration-runtime)
- [Security](#security)
- [Object definition examples](#object-definition-examples)

## Azure Data Factory

Cloud-base ETL (*extract-transform-load*) and data integration service, it can:

- **Ingest**: Create and schedule data-driven workflows (piplines) that can ingest data from disparate data stores
- **Transform**: Build complex ETL processes that transform data visually with data flows or by using services such as Azure HDInsight Hadoop, Azure Databricks and Azure SQL Database
- **Publish**: Publish your transformed data to data stores such as Azure Synapse Analytics for BI applications to consume

Concepts

![ADF Concepts](images/azure_adf-concepts.png)

- **Pipelines**: a logical grouping of activities
- **Activities**: a single step in the pipeline, three types:
  - Data movement
  - Data transformation
  - Control
- **Datasets**: data structure in inputs or outputs
- **Linked services**
  - Data sources for ingest
  - Compute resources for transformation
- **Data flows**: activities within pipelines, data transformation logic (could be created using a graphical interface) that run on Spark cluster
- **Integration runtimes (IR)**: (see below)


## Integration Runtime

- The compute infrastructure used by ADF, providing the following capabilities:
  - Data Flow
  - Data movement
  - Activity dispatch
  - SSIS package execution: execute SSIS (SQL Server Integration Service) packages in a managed Azure compute environment
- Bridge between the activity and linked services, provides the compute environment where the activity either runs on or gets dispatched from
- When an ADF instance is created, a default IR is created, can be viewed when the integration runtime is set to *Auto-Resolve*

IR types and functions:

| IR type     | Public network                              | Private network                  |
| ----------- | ------------------------------------------- | -------------------------------- |
| Azure       | Data Flow, Data movement, Activity dispatch |
| Self-hosted | Data movement, Activity dispatch            | Data movement, Activity dispatch |
| Azure-SSIS  | SSIS package execution                      | SSIS package execution           |


## Security

- To create ADF instances: *contributor/owner/administrator* on subscription
- To create and manage child resources:
  - in portal: *Data Factory Contributor* role at resource group or above
  - with PowerShell or SDK: *contributor* role at the resource level or above


## Object definition examples

- Linked service

  - SQL database

    ```json
    {
      "name": "AzureSqlLinkedService",
      "properties": {
        "type": "AzureSqlDatabase",
        "typeProperties": {
          "connectionString": "Server=tcp:<server-name>.database.windows.net,1433;Database=ctosqldb;User ID=ctesta-oneill;Password=P@ssw0rd;Trusted_Connection=False;Encrypt=True;Connection Timeout=30"
        }
      }
    }
    ```

  - Blob Storage

    ```json
    {
      "name": "StorageLinkedService",
      "properties": {
        "type": "AzureStorage",
        "typeProperties": {
          "connectionString": "DefaultEndpointsProtocol=https;AccountName=ctostorageaccount;AccountKey=<account-key>"
        }
      }
    }
    ```

- Dataset

  ```json
  {
    "name": "InputDataset",
    "properties": {
      "linkedServiceName": {
        "referenceName": "AzureStorageLinkedService",
        "type": "LinkedServiceReference"
      },
      "annotations": [],
      "type": "Binary",
      "typeProperties": {
        "location": {
          "type": "AzureBlobStorageLocation",
          "fileName": "emp.txt",
          "folderPath": "input",
          "container": "adftutorial"
        }
      }
    }
  }
  ```

- Activity

  ```json
  {
    "name": "Execution Activity Name",
    "description": "description",
    "type": "<ActivityType>",
    "typeProperties": {
      ...
    },
    "linkedServiceName": "MyLinkedService",
    "policy": {
      ...
    },
    "dependsOn": {
      ...
    }
  }
  ```

- Pipeline

  ```json
  {
    "name": "MyFirstPipeline",
    "properties": {
      "description": "My first Azure Data Factory pipeline",
      "activities": [
        {
          "type": "HDInsightHive",
          "typeProperties": {
            "scriptPath": "adfgetstarted/script/partitionweblogs.hql",
            "scriptLinkedService": "StorageLinkedService",
            "defines": {
              "inputtable": "wasb://adfgetstarted@ctostorageaccount.blob.core.windows.net/inputdata",
              "partitionedtable": "wasb://adfgetstarted@ctostorageaccount.blob.core.windows.net/partitioneddata"
            }
          },
          "inputs": [
            {
              "name": "AzureBlobInput"
            }
          ],
          "outputs": [
            {
              "name": "AzureBlobOutput"
            }
          ],
          "policy": {
            "concurrency": 1,
            "retry": 3
          },
          "scheduler": {
            "frequency": "Month",
            "interval": 1
          },
          "name": "RunSampleHiveActivity",
          "linkedServiceName": "HDInsightOnDemandLinkedService"
        }
      ],
      "start": "2017-04-01T00:00:00Z",
      "end": "2017-04-02T00:00:00Z",
      "isPaused": false,
      "hubName": "ctogetstarteddf_hub",
      "pipelineMode": "Scheduled"
    }
  }
  ```