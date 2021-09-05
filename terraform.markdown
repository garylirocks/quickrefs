# Terraform

- [File structure](#file-structure)
- [Commands](#commands)
- [Authenticate Terraform to Azure](#authenticate-terraform-to-azure)
- [Use a remote state file](#use-a-remote-state-file)
- [Run in CI/CD pipelines](#run-in-cicd-pipelines)
  - [Use remote state file](#use-remote-state-file)
  - [Pipeline](#pipeline)

## File structure

- `main.tf` - the plan

  ```terraform
  # required version
  terraform {
    required_version = "> 0.12.0"
  }

  # which platform/plugin
  provider "azurerm" {
    version = ">=2.0.0"
    features {}
  }

  # variables, will prompt if there's no default value
  variable "resource_group_name" {
    default = "my-rg"
    description = "The name of the resource group"
  }

  ...

  variable "app_service_name_prefix" {
    default     = "my-appsvc"
    description = "The beginning part of the app service name"
  }

  # generate a random integer,
  # which will be written to a state file,
  # so you get the same number each time
  resource "random_integer" "app_service_name_suffix" {
    min = 1000
    max = 9999
  }

  # "my" enables you to refer to this resource in other parts of your plan, it does not appear in your Azure resource
  resource "azurerm_resource_group" "my" {
    name     = var.resource_group_name        # use a variable
    location = var.resource_group_location
  }

  resource "azurerm_app_service_plan" "my" {
    name                = var.app_service_plan_name
    location            = azurerm_resource_group.my.location  # reference another resource
    resource_group_name = azurerm_resource_group.my.name
    kind                = "Linux"
    reserved            = true

    sku {
      tier = "Basic"
      size = "B1"
    }
  }

  resource "azurerm_app_service" "my" {
    name                = "${var.app_service_name_prefix}-${random_integer.app_service_name_suffix.result}"
    location            = azurerm_resource_group.my.location
    resource_group_name = azurerm_resource_group.my.name
    app_service_plan_id = azurerm_app_service_plan.my.id
  }

  # output a generated hostname
  output "website_hostname" {
    value       = azurerm_app_service.my.default_site_hostname
    description = "The hostname of the website"
  }
  ```

- `terraform.tfvars` - variables

  ```sh
  resource_group_location = "northeurope"
  ```

- `terraform.tfstate`
  - Generated after you apply you plan
  - Helps terraform map you plan to your running resources
  - Can holds value that's not in Azure, such as a generated random number


## Commands

- `terraform init`

    Downloads the plug-ins you need and verifies that terraform can access your plan's state file

- `terraform plan`

    Produces an execution plan for you to review

- `terraform apply`

    Runs you plan, it's **idempotent**

- `terraform output`

    - Get the output
    - `terraform output website_hostname` gets a single value, useful to pass the value to other commands

- `terraform destroy`

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

1. Add a `backend` block in Terraform config

    ```terraform
    terraform {
      required_providers {
        azurerm = {
          source = "hashicorp/azurerm"
          version = "2.75.0"
        }
      }

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