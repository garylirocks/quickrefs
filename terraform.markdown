# Terraform

- [File structure](#file-structure)
- [Commands](#commands)
- [Run in CI/CD pipelines](#run-in-cicd-pipelines)
  - [Use remote state file](#use-remote-state-file)
  - [Create a service principal for Terraform](#create-a-service-principal-for-terraform)

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

### Create a service principal for Terraform

```sh
# get default subscription id
ARM_SUBSCRIPTION_ID=$(az account list \
  --query "[?isDefault][id]" \
  --all \
  --output tsv)
```

```sh
# create a sp and get the secret
ARM_CLIENT_SECRET=$(az ad sp create-for-rbac \
  --name http://tf-sp-$UNIQUE_ID \
  --role Contributor \
  --scopes "/subscriptions/$ARM_SUBSCRIPTION_ID" \
  --query password \
  --output tsv)
```
- Name needs to start with `http://`
- `Contributor` is the default role for a service principal, which has full permissions to read and write to an Azure subscription
- This is the ONLY opportunity to retrieve the generated password

```sh
# get service principal id
ARM_CLIENT_ID=$(az ad sp show \
  --id http://tf-sp-$UNIQUE_ID \
  --query appId \
  --output tsv)

# get tenant id
ARM_TENANT_ID=$(az ad sp show \
  --id http://tf-sp-$UNIQUE_ID \
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
