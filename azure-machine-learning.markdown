# Azure Machine Learning

- [Overview](#overview)
- [Workspace](#workspace)
  - [Azure resources](#azure-resources)
  - [Workspace resources](#workspace-resources)
  - [Assets](#assets)
  - [Roles](#roles)
- [Data ingestion](#data-ingestion)
- [Train a model](#train-a-model)
- [Models](#models)
- [Compute](#compute)
  - [CPU vs. GPU](#cpu-vs-gpu)
  - [General purpose vs. memory optimized](#general-purpose-vs-memory-optimized)
  - [Spark](#spark)
- [Model deployment](#model-deployment)
- [Jobs](#jobs)
  - [Command job](#command-job)
  - [Pipeline job](#pipeline-job)
  - [Trigger a job via CLI](#trigger-a-job-via-cli)
- [Azure ML CLI](#azure-ml-cli)


## Overview

- You could use automated ML to find the best model


## Workspace

![Resources overview](images/azure_ml-overview-azure-resources.png)

### Azure resources

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

### Workspace resources

- **Workspace**: stores all logs, metrics, outputs, models and snapshots of your code
- **Compute**
  - Four types:
    - **Compute instance**: ideal as a dev environment to run Jupyter notebooks
    - **Compute cluster**: CPU or GPU compute nodes, ideal for production workloads, automatically scale
    - **Inference cluster**: AKS cluster, ideal to deploy models in production
    - **Attached compute**: attach other Azure compute resources, like Azure Databricks or Synapse Spark pools
  - Most cost-intensive, should only allow admins to create and manage, not data scientists
- **Datastores**
  - References to other data services, like Azure Storage Account and Azure Data Lake Storage (Gen2)
  - Connection info is stored in the Azure Key Vault
  - Two datastores created along with the workspace:
    - `workspacefilestore`, a file share in the storage account, to store files like Jupyter notebooks and Python scripts
    - `workspaceblobstore`, blob storage, to store metrics and output when tracking model training

### Assets

- **Models**
  - Can be trained with Scikit-learn or PyTorch
  - Common storage format is Python pickle file (`.pkl`) or MLModel file (`.mlmodel`)
  - Models and corresponding metadata are saved in binary files
  - To persist those files, you can create or register a model in the workspace

- **Environment**
  - Stored as an image in the Azure Container Registry created with the workspace
  - Specifies software packages, environment variables, and software settings
  - When you run a script, you specify the environment to use by the compute target

- **Data**
  - Refer to a specific file or folder in a datastore

- **Components**
  - Reusable code snippets, often represents a step in a pipline
  - A component consists of *name*, *version*, code and *environment* needed to run the code
  - Can be shared across workspaces

### Roles

AzureML has specific built-in roles:

- **AzureML Data Scientist**
  - all actions within the workspace except creating/deleting compute resources, or editing workspace settings
- **AzureML Compute Operator**
  - create/change/manage compute resources


## Data ingestion

![Data ETL](images/azure_ml-data-etl.png)

- You often need an ETL process to load the data to Azure Blob, Data Lake or SQL
- Usually done with Azure Synapse Analytics or Azure Databricks, which allow transformation to be distributed across compute nodes
- You could also Azure ML pipelines, but may not as performant


## Train a model

Several options to train a model:

- Use the visual designer (building a pipeline using built-in and custom components)
- Automated ML
- Run a Jupyter notebook
- Run a script as a job

Different types of jobs:
- Command: a single script
- Sweep: hyperparameter tuning when executing a single script
- Pipeline
- AutoML experiments


## Models

Common model types:

- Classification: Predict a categorical value.
- Regression: Predict a numerical value.
- Time-series forecasting: Predict future numerical values based on time-series data.
- Computer vision: Classify images or detect objects in images.
- Natural language processing (NLP): Extract insights from text.


## Compute

### CPU vs. GPU

|                   | CPU   | GPU   |
| ----------------- | ----- | ----- |
| Cost              | low   | high  |
| Tabular data      | small | large |
| Unstructured data | no    | yes   |

GPU is more powerful, but cost more

### General purpose vs. memory optimized

- General purpose: for testing and development with smaller datasets
- Memory optimized: higher memory-to-CPU ratio, ideal for larger datasets, or working in notebooks

### Spark

- A Spark cluster consists of a **driver node** and **workder nodes**. Driver nodes distribute the work, and summarize the result.
- You code needs to be written in a Spark-friendly language, such as Scala, SQL, RSpark, or PySpark


## Model deployment

Two types:

- **Real-time**: the compute needs to be running all the time
- **Batch**: the compute could be started/shutdown as needed

Compute:

- ACI
  - Suitable for testing
- AKS
  - For production
  - Must create an *inference cluster* compute target


## Jobs

### Command job

```yaml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
code: src
command: >-
  python main.py
  --diabetes-csv ${{inputs.diabetes}}
inputs:
  diabetes:
    path: azureml:diabetes-data:1
    mode: ro_mount
environment: azureml:basic-env-scikit@latest
compute: azureml:aml-instance
experiment_name: diabetes-data-example
description: Train a classification model on diabetes data using a registered dataset as input.
```

`azureml:diabetes-data:1`
  - `azureml:` is the prefix for an existing registered data asset
  - `diabetes-data` data asset name
  - `1` data asset version

### Pipeline job

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

### Trigger a job via CLI

You could trigger a job with

```sh
az ml job create --file job.yml
```


## Azure ML CLI

- List workspaces

  ```sh
  # install the extension
  az extension add -n ml -y

  az ml workspace list -otable
  ```

- Create dataset

  ```sh
  # upload local data in a folder, create a dataset in the default datastore
  az ml data create \
    --name dataset-test \
    --version 1 \
    --path ./data \
    -w mlw-test-001 \
    -g rg-ml-test

  # list dataset
  az ml data list \
    -w mlw-test-001 \
    -g rg-ml-test
    -otable
  ```

- Create compute

  - List available compute sizes

    ```sh
    az ml compute list-sizes \
      --type ComputeInstance \
      -w mlw-test-001 \
      -g rg-ml-test \
      -otable
    ```

  - Create compute instance

    ```sh
    az ml compute create --name ds1_instance \
      --size Standard_DS1_v2 \
      --type ComputeInstance \
      -w mlw-test-001 \
      -g rg-ml-test
    ```

  - Create compute cluster with a YAML file

    ```yaml
    $schema: https://azuremlschemas.azureedge.net/latest/amlCompute.schema.json
    name: aml-cluster
    type: amlcompute
    size: STANDARD_DS3_v2
    min_instances: 0
    max_instances: 5
    ```

    Then create the compute target:

    ```sh
    az ml compute create --file compute.yml \
        --resource-group my-resource-group \
        --workspace-name my-workspace
    ```