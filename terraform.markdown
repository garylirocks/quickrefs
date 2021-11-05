# Terraform

- [Overview](#overview)
- [File structure](#file-structure)
- [Commands](#commands)
- [Authenticate Terraform to Azure](#authenticate-terraform-to-azure)
- [Use a remote state file](#use-a-remote-state-file)
- [Run in CI/CD pipelines](#run-in-cicd-pipelines)
  - [Use remote state file](#use-remote-state-file)
  - [Pipeline](#pipeline)

## Overview

![Overview](images/terraform_overview.png)

## File structure

- `main.tf` - the plan

  ```terraform
  # Configure the Azure provider
  terraform {
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 2.65"
      }
    }

    required_version = ">= 0.14.9"
  }

  provider "azurerm" {
    features {}
  }

  resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = "westus2"
  }

  output "resource_group_id" {
    value = azurerm_resource_group.rg.id
  }
  ```

  - Terraform installs providers from [Terraform Registry](https://registry.terraform.io) by default
  - `version` key is recommended
  - You can have multiple providers in one file
  - `azurerm_resource_group` is the resource type, prefixed with resource provider name, `azurerm_resource_group.rg` is a unique ID of the resource

- `terraform.tfvars` - variables

  ```sh
  variable "resource_group_name" {
    default = "myTFResourceGroup"
  }
  ```

- `terraform.tfstate`
  - Generated after you apply you plan, contains IDs and properties of the resources
  - Helps terraform map you plan to your running resources
  - Can holds value that's not in Azure, such as a generated random number
  - Do NOT put it in version control
  - In production, the state file should be kept secure and encrypted

## Commands

- `terraform init`

    Downloads the plug-ins you need (eg. `azurerm`, `docker`) and verifies that terraform can access your plan's state file

- `terraform plan`

    Produces an execution plan for you to review

- `terraform apply`

    - Runs you plan, it's **idempotent**
    - To override a variable:

      `terraform apply -var "resource_group_name=myNewResourceGroupName"`

- `terraform output`

    - Get the output
    - `terraform output resource_group_id` gets a single value, useful to pass the value to other commands

- `terraform destroy`

- `terraform import ADDRESS ID`

  - Import existing resources which were not created by Terraform into the state, does not generate configuration
  - Example:

    ```sh
    terraform import azurerm_resource_group.my '/subscriptions/xxx/resourceGroups/my-rg'
    ```

- `terraform fmt` format files
- `terraform validate` validate files
- `terraform state list` list resources in state file
- `terraform show [ADDRESS]` show details of a resource
- `terraform providers` show providers for this config


## Authenticate Terraform to Azure

- When using Terraform in command line, Terraform uses Azure CLI to authenticate;
- In a non-interactive context, create a service principal for Terraform

  ```sh
  SP_NAME='terraform-sp-20210905'

  # get default subscription id
  ARM_SUBSCRIPTION_ID=$(az account list \
    --query "[?isDefault][id]" \
    --all \
    --output tsv)

  # create a sp and get the secret
  # - `Contributor` is the default role for a service principal, which has full permissions to read and write to an Azure subscription
  # - get the service principal id
  ARM_CLIENT_ID=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role Contributor \
    --scopes "/subscriptions/$ARM_SUBSCRIPTION_ID" \
    --query appId \
    --output tsv)

  # password was generated in the last step, which we used to get the appId
  # so we reset the password and get it here
  ARM_CLIENT_SECRET=$(az ad sp credential reset \
    --name $SP_NAME \
    --query password \
    --output tsv)

  # get tenant id
  ARM_TENANT_ID=$(az ad sp show \
    --id $ARM_CLIENT_ID \
    --query appOwnerTenantId \
    --output tsv)
  ```

  Export variables, Terraform looks for them when it runs

  ```sh
  export ARM_SUBSCRIPTION_ID
  export ARM_CLIENT_SECRET
  export ARM_CLIENT_ID
  export ARM_TENANT_ID
  ```

## Use a remote state file

In a collaborative or CI/CD context, you want to use a remote state file:

- With Terraform Cloud

  Terraform Cloud can be a simple backend for storing state files, you can also run terraform remotely on it

  1. `terraform login`

  1. Add a `backend` to config

      ```terraform
      terraform {
        ...

        backend "remote" {
          organization = "garylirocks"

          workspaces {
            name = "learning"
          }
        }
      }
      ```

  1. By default, `terraform apply` runs remotely in Terraform Cloud, so you need to put credentials Terraform needs as workspace env variables (eg. `ARM_CLIENT_SECRET` for `azurerm')

- Use Azure blob storage

  1. Add a `backend` block in Terraform config

      ```terraform
      terraform {
        ...

        backend "azurerm" {
          resource_group_name  = "learning-rg"
          storage_account_name = "tfstatey2hkc"
          container_name       = "tfstate"
          key                  = "terraform.tfstate"
        }
      }
      ```

  1. Set access key in an environment variable

      ```sh
      ARM_ACCESS_KEY=$(az storage account keys list \
                    --resource-group $RESOURCE_GROUP_NAME \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --query '[0].value' \
                    -o tsv)
      export ARM_ACCESS_KEY
      ```

  1. A state file will be created in the storage account when you run `terraform apply`


## Run in CI/CD pipelines

When provision infrastructure in a pipeline, you need:

- Save state file in a remote storage, so it could be used across multiple runs
- Create a service principal for terraform to authenticate with Azure

### Use remote state file

In `main.tf`

```yaml
terraform {
  required_version = "> 0.12.0"

  backend "azurerm" {
  }
}
```

A variables file `backend.tfvars` specifies a state file to use, which is in an Azure storage account

```yaml
resource_group_name = "tf-storage-rg"
storage_account_name = "tfsa4962"
container_name = "tfstate"
key = "terraform.tfstate"
```

Init with backend

```sh
terraform init -backend-config="backend.tfvars"
```
### Pipeline

In the following example,
- you use pipeline secrets to construct a `backend.tfvars` file,
- then terraform could access the state file,
- then run `terraform apply` and get the output,
- which is used in the next step for deplying an app

```yaml
  - stage: "Dev"
    displayName: "Deploy to the dev environment"
    dependsOn: Build
    jobs:
      - job: Provision
        displayName: "Provision Azure App Service"
        pool:
          vmImage: "ubuntu-18.04"
        variables:
          - group: Release
        steps:
          - script: |
              # Exit when any command returns a failure status.
              set -e

              # Write terraform.tfvars.
              echo 'resource_group_location = "'$(ResourceGroupLocation)'"' | tee terraform.tfvars

              # Write backend.tfvars.
              echo 'resource_group_name = "tf-storage-rg"' | tee backend.tfvars

              echo 'storage_account_name = "'$(StorageAccountName)'"' | tee -a backend.tfvars
              echo 'container_name = "tfstate"' | tee -a backend.tfvars
              echo 'key = "terraform.tfstate"' | tee -a backend.tfvars

              # Initialize Terraform.
              terraform init -input=false -backend-config="backend.tfvars"

              # Apply the Terraform plan.
              terraform apply -input=false -auto-approve

              # Get the App Service name for the dev environment.
              WebAppNameDev=$(terraform output appservice_name_dev)

              # Write the WebAppNameDev variable to the pipeline.
              echo "##vso[task.setvariable variable=WebAppNameDev;isOutput=true]$WebAppNameDev"
            name: "RunTerraform"
            displayName: "Run Terraform"
            # make pipline variable available in Bash
            env:
              ARM_CLIENT_ID: $(ARM_CLIENT_ID)
              ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
              ARM_TENANT_ID: $(ARM_TENANT_ID)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
      - deployment: Deploy
        dependsOn: Provision
        variables:
          # use a variable set by 'RunTerraform' task in job 'Provision'
          WebAppNameDev: $[ dependencies.Provision.outputs['RunTerraform.WebAppNameDev'] ]
        pool:
          vmImage: "ubuntu-18.04"
        environment: dev
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: drop
                - task: AzureWebApp@1
                  displayName: "Azure App Service Deploy: website"
                  inputs:
                    azureSubscription: "Resource Manager - Tailspin - Space Game"
                    appName: "$(WebAppNameDev)"
                    package: "$(Pipeline.Workspace)/drop/$(buildConfiguration)/*.zip"
```