# Azure Analytics

- [Azure Data Factory](#azure-data-factory)
- [Integration Runtime](#integration-runtime)
- [Security](#security)
- [Git integration](#git-integration)
- [CI/CD process](#cicd-process)
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


## Git integration

- ADF uses ARM templates to store the configuration of various ADF entities (pipelines, datasets, data flows, etc), these could be put in a Git repo
- ADF natively supports integration with Azure Repos and GitHub, you could export your existing ADF configs to a new repo
- You would usually have several branches in the repo:
  - **Feature/working branch**, the branch you work on
  - **Collaboration branch**: `master` by default, don't change it directly, should only accept pull request
  - **Publish branch**: `adf_publish` by default
    - created/manged by ADF, don't update manually
    - when you click the "Publish" button in the portal, ADF creates/updates this branch
    - contains ARM templates for all the published entities in ADF
- In the portal, you could load different branches, make changes, validate and save


## CI/CD process

![ADF CI/CD process](images/azure_adf-ci-cd.png)


- The `adf_publish` branch serves as the artifact for the release pipeline, which runs an ARM task to deploy resources to Test/Prod ADF
- A file named `arm-template-parameters-definition.json` controls what properties get parametrized when ADF generates the ARM templates
- In the `adf_publish` branch, you get two versions of the templates, full and linked, you could use either of them to deploy to Test/Prod:
  - `ARMTemplatedForFactory.json`: the full ARM template
  - `linkedTemplates/`: a folder containing linked templates, to bypass resource number limitations on a single template, need to be uploaded to a storage account, so Azure can access them during deployment


Best practices:

- Only associate the dev ADF with a git repo, the test and prod factories shouldn't have a git repo associated, should *ONLY* be updated via an Azure DevOps pipeline or an ARM template
- It's recommended to put secrets in Key Vault,
  - Use a separate key vault for each environment, use the same secret name in each vault for the same linked service
  - Reference secret in the parameters file

    ```json
    {
        "parameters": {
            "azureSqlReportingDbPassword": {
                "reference": {
                    "keyVault": {
                        "id": "/subscriptions/<subId>/resourceGroups/<resourcegroupId> /providers/Microsoft.KeyVault/vaults/<vault-name> "
                    },
                    "secretName": " < secret - name > "
                }
            }
        }
    }
    ```

- Active triggers need to be stopped before the deployment and restarted afterwards, use a PowerShell task

  ```powershell
  $triggersADF = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName

  $triggersADF | ForEach-Object { Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $_.name -Force }
  ```

- Use `_` or `-` in resource names instead of spaces


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
