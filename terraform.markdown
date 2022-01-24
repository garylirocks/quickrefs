# Terraform

- [Overview](#overview)
- [File structure](#file-structure)
  - [`main.tf` - the plan](#maintf---the-plan)
  - [`variables.tf` - variable definition](#variablestf---variable-definition)
    - [`terraform.tfvars`](#terraformtfvars)
  - [`outputs.tf`](#outputstf)
  - [`terraform.tfstate`](#terraformtfstate)
- [Commands](#commands)
- [Authenticate Terraform to Azure](#authenticate-terraform-to-azure)
- [Remote runs and state](#remote-runs-and-state)
  - [Terraform Cloud](#terraform-cloud)
  - [Azure blob storage](#azure-blob-storage)
- [Run in CI/CD pipelines](#run-in-cicd-pipelines)
  - [Use remote state file](#use-remote-state-file)
  - [Pipeline](#pipeline)
- [HCL language features](#hcl-language-features)

## Overview

![Overview](images/terraform_overview.png)

The above is the usual workflow: Create IaC config -> Plan -> Apply

When dealing with existing infrastructure, you use the 'import' workflow:

![Import workflow](images/terraform_import-workflow-diagram.png)

- Import infrastructure into Terraform state
- Write config that matches the infrastructure
- Review and apply

## File structure

- A typical file structure in a Terraform workspace:

  ```
  main.tf                 # main config
  versions.tf             # terraform and provider versions
  variables.tf            # variable definition
  outputs.tf              # output definition

  terraform.tfvars        # actual variable values (should be in .gitignore)
  terraform.tfstate       # generated state file (should be in .gitignore)

  .terraform.lock.hcl     # version lock file, make sure everyone is using the same versions, generated if not present
  ```

- `version`, `variable` and `output` blocks could be included in `main.tf` directly, but it's better to put them in separate files

### `main.tf` - the plan

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


### `variables.tf` - variable definition

A variable can be of type string, number, bool, list, map, set, tuple and object

```terraform
# without a default value
variable "ec2_instance_type" {
  description = "AWS EC2 instance type."
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets."
  type        = number
  default     = 2
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
  ]
}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)

  default     = {
    project     = "project-alpha",
    environment = "dev"
  }

  # validation rules
  validation {
    condition     = length(var.resource_tags["project"]) <= 16 && length(regexall("[^a-zA-Z0-9-]", var.resource_tags["project"])) == 0
    error_message = "The project tag must be no more than 16 characters, and only contain letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.resource_tags["environment"]) <= 8 && length(regexall("[^a-zA-Z0-9-]", var.resource_tags["environment"])) == 0
    error_message = "The environment tag must be no more than 8 characters, and only contain letters, numbers, and hyphens."
  }
}
```

You could evaluate variable expressions with `terraform console`

```sh
> var.public_subnet_cidr_blocks[1]
"10.0.2.0/24"

# use function 'slice'
> slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)
tolist([
  "10.0.1.0/24",
  "10.0.2.0/24",
])

> var.resource_tags.project
"project-alpha"

# variable interpolation in strings
> "app-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"
"app-project-alpha-dev"
```

#### `terraform.tfvars`

- Variable values, so you don't need to enter them manually every time
- DON'T include it in version control

```
resource_tags = {
  project     = "new-project",
  environment = "test",
  owner       = "me@example.com"
}

ec2_instance_type = "t3.micro"

instance_count = 3
```

### `outputs.tf`

- `output` block can be in the main config file, but it's better to put it into a seprate file called `outputs.tf`
- Outputs allow you to
  - share data between Terraform workspaces,
  - with other tools and automation,
  - only way to share data from a child module to your config's root module
- You could use string interpolation and functions
- Sensitive output is **not always** redacted, it's plain text in state file, in JSON output, or queried by name

```terraform
output "vpc_id" {
  description = "ID of project VPC"
  value       = module.vpc.vpc_id
}

output "lb_url" {
  description = "URL of load balancer"
  value       = "http://${module.elb_http.this_elb_dns_name}/"
}

output "web_server_count" {
  description = "Number of web servers provisioned"
  value       = length(module.ec2_instances.instance_ids)
}

# sensitive value
output "db_password" {
  description = "Database administrator password"
  value       = aws_db_instance.database.password
  sensitive   = true
}

```

```sh
# get all outputs
terraform output

# in JSON format
terraform output -json

# get a paticular output
terraform output lb_url
# "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"

# output in raw mode
terraform output -raw lb_url
# http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/
```

### `terraform.tfstate`

- Generated after you apply you plan, contains IDs and properties of the resources
- Helps terraform map you plan to your running resources
- Can holds value that's not in Azure, such as a generated random number
- Do NOT put it in version control
- In production, the state file should be kept secure and encrypted

## Commands

- `terraform init`

    - Downloads the plug-ins you need (eg. `azurerm`, `docker`) and verifies that terraform can access your plan's state file
    - `terraform init -upgrade` update provider versions in `.terraform.lock.hcl`

- `terraform plan`

    - Produces an execution plan for you to review

- `terraform apply`

    - Runs you plan, it's **idempotent**
    - `terraform apply -var "resource_group_name=myNewResourceGroupName"` to override a variable
    - `terraform apply -replace="aws_instance.example"` force replace a paticular resource

- `terraform output`
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
- `terraform plan -refresh-only` refresh state file to reflect infrastructure changes
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

## Remote runs and state

In a collaborative or CI/CD context, you may want to run and save state files remotely

### Terraform Cloud

  Terraform Cloud supports remote run, storing state file, input variables, environment variables, private module registry, policy as code, etc

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

  1. By default, `terraform apply` runs remotely in Terraform Cloud, so you need to put credentials Terraform needs as workspace env variables (eg. `ARM_CLIENT_SECRET` for `azurerm`)

### Azure blob storage

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

```terraform
terraform {
  required_version = "> 0.12.0"

  backend "azurerm" {
    // leave empty
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

## HCL language features


- Collections

  - `count`

    ```terraform
    resource "random_pet" "object_names" {
      count = 4

      length    = 5
      separator = "_"
      prefix    = "learning"
    }

    resource "aws_s3_bucket_object" "objects" {
      count = 4

      key          = "${random_pet.object_names[count.index].id}.txt"
      content      = "Example object #${count.index}"
      content_type = "text/plain"
      ...
    }
    ```

  - `for_each`

    ```terraform
    locals {
      names = {
        name1 = "Name 1",
        name2 = "Name 2",
      }
    }

    resource "aws_instance" "app" {
      # use a map
      for_each               = local.names
      ami                    = data.aws_ami.ubuntu.id
      instance_type          = "t2.micro"
      ...
    }
    ```

  - `for .. in`

    ```terraform
    output "instance_id" {
      description = "ID of the EC2 instance"
      # output a list
      value       = [for instance in aws_instance.app : instance.id]
    }
    ```

- `locals`

  Used to simplify the config and avoid repetition

  ```terraform
  locals {
    required_tags = {
      project     = var.project_name,
      environment = var.environment
    }

    tags = merge(var.resource_tags, local.required_tags)
  }
  ```

- Data source blocks

  A module can provide both resources and data sources

  ```terraform
  data "aws_availability_zones" "available" {
    state = "available"
  }

  # load state from another workspace
  data "terraform_remote_state" "vpc" {
    backend = "local"

    config = {
      path = "../learn-terraform-data-sources-vpc/terraform.tfstate"
    }
  }

  # reference data
  provider "aws" {
    region = data.terraform_remote_state.vpc.outputs.aws_region
  }
  ```

- Modules

  Combines your code into a logical group, a module definition should have:

  ```sh
  main.tf
  variables.tf
  outputs.tf
  README.md
  ```

  then use it like a custom resource:

  ```terraform
  module "web_server" {
    # a module in a local folder
    source = "./modules/servers"

    web_ami = "ami-12345"
    server_name = "prod-web"
  }
  ```