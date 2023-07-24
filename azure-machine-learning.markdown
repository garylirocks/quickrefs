# Azure Machine Learning


## Overview

- You could use automated ML to find the best model

Concepts:

- **Environment**: a collection of Python packages needed to run a script
- **Pipeline**: a collection of ML components or Python scripts


## Workspace

![Resources overview](images/azure_ml-overview-azure-resources.png)

When a workspace is created, a few supporting resources are created with it in the same resource group.

- Storage account:
  - files and notebooks
  - metadata of jobs and models
- Key Vault:
  - store credentials used by the workspace
- Application Insights:
  - monitor predictive services
- Container Registry:
  - created when needed
  - to store images for ML environments

### Roles

AzureML has specific built-in roles:

- AzureML Data Scientist:
  - all actions within the workspace except creating/deleting compute resources, or editing workspace settings
- AzureML Compute Operator:
  - create/change/manage compute resources

### Resources

- **Workspace**: stores all logs, metrics, outputs, models and snapshots of your code
- **Compute**
  - Four types:
    - Compute instance: ideal as a dev environment to run Jupyter notebooks
    - Compute cluster: CPU or GPU compute nodes, ideal for production workloads, automatically scale
    - Inference cluster: AKS cluster, ideal to deploy models in production
    - Attached compute: attach other Azure compute resources, like Azure Databricks or Synapse Spark pools
  - Most cost-intensive, should only allow admins to create and manage, not data scientists
- **Datastores**
  - References to other data services, like Azure Storage Account and Azure Data Lake Storage (Gen2)
  - Connection info is stored in the Azure Key Vault
  - Two datastores created along with the workspace:
    - `workspacefilestore`, a file share in the storage account, to store files like Jupyter notebooks and Python scripts
    - `workspaceblobstore`, blob storage, to store metrics and output when tracking model training


## Deploy a predictive service

Can be deployed to

- ACI
  - Suitable for testing
- AKS
  - For production
  - Must create an *inference cluster* compute target


## Pipelines

A sample pipeline in YAML:

```yaml
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: nyc-taxi-pipeline-example
experiment_name: nyc-taxi-pipeline-example

jobs:
  transform-job:
    type: command
    inputs:
      raw_data:
          type: uri_folder
          path: ./data
    outputs:
      transformed_data:
        mode: rw_mount
    code: src/transform
    environment: azureml:AzureML-sklearn-0.24-ubuntu18.04-py37-cpu@latest
    compute: azureml:cpu-cluster
    command: >-
      python transform.py
      --raw_data ${{inputs.raw_data}}
      --transformed_data ${{outputs.transformed_data}}

  train-job:
    type: command
    inputs:
      training_data: ${{parent.jobs.transform-job.outputs.transformed_data}}
    outputs:
      model_output:
        mode: rw_mount
      test_data:
        mode: rw_mount
    code: src/train
    environment: azureml:AzureML-sklearn-0.24-ubuntu18.04-py37-cpu@latest
    compute: azureml:cpu-cluster
    command: >-
      python train.py
      --training_data ${{inputs.training_data}}
      --test_data ${{outputs.test_data}}
      --model_output ${{outputs.model_output}}
```

A script step specifies:

- The code, inputs, outputs
- Which compute target to use

You could trigger a pipeline with

```sh
az ml job create --file pipeline-job.yml
```
