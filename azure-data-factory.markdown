# Azure Data Factory

- [Overview](#overview)
- [Integration Runtime](#integration-runtime)
  - [Azure IR](#azure-ir)
    - [With Managed VNet and private endpoints](#with-managed-vnet-and-private-endpoints)
  - [Self-hosted IR](#self-hosted-ir)
    - [Sharing](#sharing)
  - [Which IR is used ?](#which-ir-is-used-)
- [Linked services](#linked-services)
  - [Storage account](#storage-account)
- [Security](#security)
- [Git integration](#git-integration)
- [CI/CD process](#cicd-process)
- [Object definition examples](#object-definition-examples)

## Overview

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
- **Data flows**: data transformation logic that runs on ADF-managed Spark clusters, could be created using a graphical interface
- **Integration runtimes (IR)**: (see below)


## Integration Runtime

- The compute infrastructure used by ADF, providing the following capabilities:
  - Data Flow
  - Data movement (copy activities)
  - Activity dispatch (could be dispatched to Databricks, HDInsight, SQL Database, SQL Server, etc)
  - SSIS package execution: execute SSIS (SQL Server Integration Service) packages in a managed Azure compute environment
- Bridge between the activity and linked services, provides the compute environment where the activity either runs on or gets dispatched from
- Integration runtimes can be referenced by activities, datasets or data flows

IR types and functions:

| IR type     | Public network                                                                                    | Private network                  |
| ----------- | ------------------------------------------------------------------------------------------------- | -------------------------------- |
| Azure       | Data Flow, Data movement (between cloud data stores), Activity dispatch                           |
| Self-hosted | Data movement (between a cloud data store and a data store in private network), Activity dispatch | Data movement, Activity dispatch |
| Azure-SSIS  | SSIS package execution                                                                            | SSIS package execution           |

### Azure IR

- Fully managed, serverless compute, scales automatically according to how many data integration units are set on the copy activity
- When an ADF instance is created, a default IR is created: *AutoResolveIntegrationRuntime*
- An Azure IR have two sub-types:
  - Public:
    - connect to data stores and compute services via public accessible endpoints
    - Azure provides a range of static public IP addresses which could be added to allowlist of the target data store firewalls
  - With managed VNet: *see below*
- Two options for region: "Auto Resolve" or a specific region
- For "Auto Resolve" IRs, the location of the IR depends on the sub-type and activities:
  - Public
    - Copy activity: automatically detect **sink data store's location**, use the IR in either the same region, or closest one, falling back to the ADF instance's region
    - Other activities: same region as the ADF instance
  - With managed VNet
    - IR is in the same region as the instance

#### With Managed VNet and private endpoints

See details here: https://docs.microsoft.com/en-us/azure/data-factory/managed-virtual-network-private-endpoint

An Azure IR could be placed within an managed vNet, and use private endpoints to securely connect to supported data stores.

<img src="images/azure_adf-integration-runtime-with-managed-virtual-network.png" width="800" alt="Manged vNet" />

- Private endpoints can't be shared across environments
- Private endpoints can be used to access
  - Data stores
  - External compute resources (Azure Databricks, Azure Functions, etc)
  - On-prem private link service
- The managed VNet can't be peered to your own VNet

### Self-hosted IR

- Could be installed on-prem behind a fireall, or inside a VNet
- Supports data stores that require bring-your-own driver, such as SAP Hana, MySQL
- To ensure sufficient isolation, you generally should have a separate integration runtime for each environment

  <img src="images/azure_adf-self-hosted-integration-runtime-across-environments.png" width="600" alt="Self-hosted integration runtime across environments" />

#### Sharing

Within each environment, a self-hosted IR could be shared by ADFs across projects

![Shared self-hosted integration runtime](./images/azure_adf-self-hosted-integration-runtime-sharing.png)

- SHIR could be installed on-prem or in a VNet
- On-prem SHIR can access cloud data store through
  - either public endpoints
  - or private endpoints (when there is ExpressRoute or S2S VPN)
- How SHIR is shared:
  - A primary ADF reference it as shared SHIR OR use a ternary factory just to contain the shared SHIR
  - Other ADFs refer to it as a linked SHIR
- A SHIR can have multiple nodes in a cluster, primary nodes communicate with ADF, and distribute work to secondary nodes
- Credentials of on-prem data stores could be stored in either local machine or an Azure Key Vault (recommended)
- Communication between SHIR and ADF can go through private link. But currently, interactive authoring and automatic updating form the download center don't support private link, the traffic goes through the on-prem firewall.
  - Private link is only required for the primary ADF

### Which IR is used ?

If an activity associates with multiple IRs, it will **resolve to one of them**, the precedence is like:

**Self-hosted IR > Azure IR (managed VNet) > Azure IR (public)**

**Azure IR (regional) > Azure IR (auto resolve)**

In a copy activity, if source linked service is associated to Self-hosted IR, sink linked service is associated with Azure IR (public), then Self-hosted IR is used


## Linked services

### Storage account

| IR                           | Storage account access control                                                                                                                                                                     |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Azure IR (Public)            | <li>Enable from all networks</li> <li>Enabled from selected virtual networks and IP addresses (with exception: Allow Azure services)</li> <li>Disabled (with exception: Allow Azure services)</li> |
| Azure IR (with managed VNet) | Managed private endpoint                                                                                                                                                                           |
| Self Hosted IR               | public endpoint, storage firewall or private endpoint                                                                                                                                              |

- Seems like with the "Allow Azure services" exception still applies even when "Public network access" is "Disabled"
  - With the exception, you must use the "Managed Identity" credential
- You could have "AutoResolve" IR access a storage account through exception, and another Azure IR in managed VNet access it via a managed private endpoint.

A few ways to authenticate an IR to a storage account:

- Account key
- SAS URI
- Service Principal
- System Assigned Managed Identity (of the ADF instance)
- User Assigned Managed Identity (of the ADF instance)

If you use a self-hosted IR, then the credentials would be saved in the IR. If you use managed identity, it means the **identity of the ADF instance, not the IR VM**.


## Security

- To create ADF instances: *contributor/owner/administrator* on subscription
- To create and manage child resources:
  - in portal: *Data Factory Contributor* role at resource group or above
  - with PowerShell or SDK: *contributor* role at the resource level or above


## Git integration

- ADF uses ARM templates to store the configuration of various ADF entities (pipelines, datasets, data flows, etc), these could be put in a Git repo
- ADF natively supports integration with Azure Repos and GitHub, you could export your existing ADF configs to a new repo
- You would usually have several branches in the repo:
  - **Feature/working branch**, the branch you work on, any changes you've done in the UI is saved to this branch automatically, when you are ready, create a pull request to the collaboration branch
  - **Collaboration branch**: `master` by default, don't change it directly, should only accept pull request, **the "Publish" button always publishes from this branch, no matter which branch is currently loaded**
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
                    "secretName": "<secret-name>"
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
