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
- [HCL language features](#hcl-language-features)
  - [Resource blocks](#resource-blocks)
    - [Meta-Arguments](#meta-arguments)
  - [Dependencies](#dependencies)
  - [Collections](#collections)
  - [Variables](#variables)
    - [Loading](#loading)
    - [Variable interpolation](#variable-interpolation)
    - [Locals](#locals)
    - [Sensitive variables](#sensitive-variables)
  - [Functions](#functions)
  - [Dynamic expressions](#dynamic-expressions)
  - [Data source blocks](#data-source-blocks)
  - [Output](#output)
  - [Move resources](#move-resources)
- [Modules](#modules)
  - [Create modules](#create-modules)
- [Best practices](#best-practices)
  - [Environment separation](#environment-separation)
- [Automate Terraform](#automate-terraform)
  - [CLI](#cli)
  - [Use remote state file](#use-remote-state-file)
  - [Azure DevOps Pipeline](#azure-devops-pipeline)
- [Internals](#internals)

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

  .terraform.lock.hcl     # version lock file, should be committed to Git, make sure everyone is using the same versions, generated if not present
  ```

- `version`, `variable` and `output` blocks could be included in `main.tf` directly, but it's better to put them in separate files, Terraform would append all of them together

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

- When using Terraform interactively on command line, Terraform uses Azure CLI to authenticate
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

  1. There are multiple ways to authenticate to the Azure storage:

      1. access key

          ```sh
          ARM_ACCESS_KEY=$(az storage account keys list \
                        --resource-group $RESOURCE_GROUP_NAME \
                        --account-name $STORAGE_ACCOUNT_NAME \
                        --query '[0].value' \
                        -o tsv)
          export ARM_ACCESS_KEY
          ```

      1. SAS key

          ```sh
          export ARM_SAS_TOKEN
          ```

  1. A state file will be created in the storage account when you run `terraform apply`


## HCL language features
### Resource blocks
#### Meta-Arguments

Apart from arguments, ech resource block can have meta-arguments:

  - `depends_on`, for specifying hidden dependencies
  - `count`, for creating multiple resource instances according to a count
  - `for_each`, to create multiple instances according to a map, or set of strings
  - `provider`, for selecting a non-default provider configuration
  - `lifecycle`, for lifecycle customizations
  - `provisioner`, for taking extra actions after resource creation

### Dependencies

Implicit dependency is the primary way for managing dependencies:

```terraform
resource "aws_instance" "example_a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}

# implicitly depends on example_a
resource "aws_eip" "ip" {
  vpc = true
  instance = aws_instance.example_a.id
}
```

Explicit dependency uses `depends_on`, could be between resources and modules:

```terraform
resource "aws_s3_bucket" "example" {
  acl    = "private"
}

resource "aws_instance" "example_c" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  depends_on = [aws_s3_bucket.example]
}

# this module depends on two resources
module "example_sqs_queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "2.1.0"

  depends_on = [aws_s3_bucket.example, aws_instance.example_c]
}
```

### Collections

- `count`

  - Use `count` to create a collection of resources, in the block, you could use `count.index` to get the index
  - Use `resource.name[0]` to refer to the first instance in the collection
  - Use `resource.name.*.id` to get a list of attribute values

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

  - Supports map, list and set
  - Use `each.key` and `each.value` in the block to access key and value


    ```terraform
    variable "project" {
      description = "Map of project names to configuration."
      type        = map
      default     = {
        client-webapp = {
          instance_type           = "t2.micro",
          environment             = "dev"
        },
        internal-webapp = {
          instance_type           = "t2.nano",
          environment             = "test"
        }
      }
    }

    module "ec2_instances" {
      source = "./modules/aws-instance"

      for_each = var.project

      project_name = each.key
      environment  = each.value.environment

      instance_type      = each.value.instance_type
    }
    ```

- `for..in`

  Creates a list out of another list or map

  ```terraform
  output "instance_id" {
    description = "ID of the EC2 instance"
    # output a list
    value       = [for instance in aws_instance.app : instance.id]
  }
  ```

  ```sh
  > [ for i in { "a" = { id = 2 }, "b" = { id = 3 } }: i.id ]
  [
    2,
    3,
  ]

  > [ for i in [ { id = 2 }, { id = 3 } ]: i.id ]
  [
    2,
    3,
  ]
  ```

### Variables

#### Loading

Variables could be loaded from:

- `terraform.tfvars` or `*.auto.tfvars` are loaded automatically
- `-var-file` or `-var` flags on command line

#### Variable interpolation

You could use `${var.var_name}` in a string:

```
name = "web-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"
```
#### Locals

  - Used to simplify the config and avoid repetition
  - Can only be used in the module where it is defined

  ```terraform
  locals {
    required_tags = {
      project     = var.project_name,
      environment = var.environment
    }

    # merge user provied and required tags
    tags = merge(var.resource_tags, local.required_tags)

    # combine two variables
    name_suffix = "${var.project_name}-${var.environment}"
  }
  ```

  Locals could be output:

  ```
  output "tags" {
    value = local.tags
  }
  ```

#### Sensitive variables

- Flag a variable as sensitive

  ```
  variable "db_password" {
    type      = string
    sensitive = true
  }
  ```

  its value would be redacted in output, but it's plain text in local state file, so you must keep your state file secure

- Set values with a `.tfvars` file

  You could put sensitive values in a separate file like `secrets.tfvars`

  ```
  db_password = 'my-super-pass'
  ```

  then put it on command line `terraform apply -var-file="secrets.tfvars"`, `.tfvars` file should be git ignored.

- Set values with environment variables

  ```sh
  # Terraform looks for env variables matching the pattern `TF_VAR_*`
  export TF_VAR_db_password='my-super-pass'
  terraform apply
  ```

### Functions

- `lookup` look up a key in a map

  ```sh
  lookup({ gary = 20, henry = 30 }, "gary" )
  # 20
  ```

- `concat`, `merge` combine lists or maps

  ```sh
  > concat(["a", "b"], ["x", "y"])
  [
    "a",
    "b",
    "x",
    "y",
  ]

  > merge({ gary = 20, jack = 30  }, { mike = 40  })
  {
    "gary" = 20
    "jack" = 30
    "mike" = 40
  }
  ```

- `file`, `templatefile`

  ```sh
  # start tf console with a variable
  tf console -var 'user=gary'

  # read file content as it is
  > file("init.tftpl")
  <<EOT

  echo ${userName}

  EOT

  # read a template file and interpolate with variables
  > templatefile("init.tftpl", { userName = var.user })
  <<EOT

  echo gary

  EOT
  ```

### Dynamic expressions

- Conditional expression:

  ```sh
  resource "aws_instance" "ubuntu" {
    count                       = (var.high_availability == true ? 3 : 1)
    associate_public_ip_address = (count.index == 0 ? true : false)
  }
  ```

- `splat` expression:

  `collection[*].attribute` or `collection.*.attribute` retrieves an attribute from a list of maps, could also be done with `for..in` expression

  ```sh
  > [{ name = "gary" }, { name = "jack" }][*].name
  [
    "gary",
    "jack",
  ]

  > [{ name = "gary" }, { name = "jack" }].*.name
  [
    "gary",
    "jack",
  ]


  > [for i in [{name="gary"}, {name="jack"}]: i.name]
  [
    "gary",
    "jack",
  ]
  ```

### Data source blocks

Used to fetch

- Info from cloud provider APIs (such as disk image IDs)
- Info from other workspaces

```terraform
# info from cloud API, get available az zones in current region
data "aws_availability_zones" "available" {
  state = "available"
}
```

Get state data from another workspace

```terraform
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

### Output

Used to
  - For other parts of your infrastructure automation tools
  - As a data source for another workspace
  - Share data from a child module to root module

```terraform
output "lb_url" {
  description = "URL of load balancer"
  value       = "http://${module.elb_http.this_elb_dns_name}/"
}

# sensitive value
output "db_password" {
  description = "Database administrator password"
  value       = aws_db_instance.database.password
  sensitive   = true
}
```

You could query output

```sh
# query one output
terraform output lb_url

# use JSON format
terraform output -json
```

### Move resources

When your infrastructure grows, you may need to refactor your configurations, such as moving part of it to a separate module, in this case, your resource's IDs will change, you need to tell Terraform you intend to move the resources rather than replace them, otherwise Terraform would recreate the resources, see details here https://learn.hashicorp.com/tutorials/terraform/move-config

Use the `moved` block to refactor your configuration:


```terraform
moved {
  from = aws_instance.example
  to   = module.ec2_instance.aws_instance.example
}

moved {
  from = aws_security_group.sg_8080
  to   = module.security_group.aws_security_group.sg_8080
}
```


## Modules

A module usually encapsulates multiple logically related resources, making configurations flexible, reusable and composable.

- Every Terraform configurations should be created with the assumption that it may be used as a module
- The top most Terraform directory is considered the **root module**, a module it uses is a **child module**
- The `source` argument is required, could be local or remote

  ```terraform
  # a remote module from Terraform Registry
  module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "2.21.0"

    ...
  }

  # a local module
  module "web_server" {
    source = "./modules/servers"

    ...
  }
  ```

- Terraform install modules to `.terraform/modules` directory. For local modules, Terraform would create symlinks

  ```
  ...
  main.tf

  .terraform/modules/
  ├── ec2_instances
  ├── modules.json
  └── vpc
  ```

- Module outputs can be referred to by `module.<MODULE NAME>.<OUTPUT NAME>`

### Create modules

A typical file structure for a new module:

```sh
.
├── LICENSE
├── README.md
├── main.tf
├── variables.tf  # arguments in the `module` block
├── outputs.tf
```

- None of these are required, you could create a module with a single `.tf` file
- Do not include `provider` blocks in modules, as a `module` block will inherit the provider from the enclosing configuration


## Best practices

### Environment separation

Two primary ways of separating environments:

1. By directories:

    Pros: Shrink the blast radius

    Cons: Duplicated configurations, creating drift over time

    ```
    .
    ├── assets
    │   ├── index.html
    ├── prod
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfstate
    │   └── terraform.tfvars
    └── dev
      ├── main.tf
      ├── variables.tf
      ├── terraform.tfstate
      └── terraform.tfvars
    ```

2. By workspaces:

    - Pros: same config files and different state files
    - Cons: must be aware of the workspace you are working in

    Create and manage workspaces in a directory

    ```sh
    terraform workspace new dev
    terraform workspace new prod
    terraform workspace list
    #   default
    #   dev
    # * prod
    ```

    The file structure would be like

    ```
    .
    ├── README.md
    ├── assets
    │   └── index.html
    ├── dev.tfvars
    ├── main.tf
    ├── outputs.tf
    ├── prod.tfvars
    ├── terraform.tfstate.d
    │   ├── dev
    │   │   └── terraform.tfstate
    │   ├── prod
    │   │   └── terraform.tfstate
    ├── terraform.tfvars
    └── variables.tf
    ```

    The default workspace has its state in the root folder, other environments have their state files in the `terraform.tfstate.d` folder


## Automate Terraform

- You could pre-install plugins to control what plugins are available and avoid the overhead of re-downloading every time:
  ```sh
  terraform init -input=false -plugin-dir=/path/to/custom-terraform-plugins
  ```

- Plugins can also be provided along with the configuration by creating a `terraform.d/plugins/OS_ARCH` directory, which will be searched before automatically downloading additional plugins. The `-get-plugins=false` flag can be used to prevent Terraform from automatically downloading additional plugins.

- If you run plan and apply on different machines, you should archive the entire working directory after `plan` and pass it to `apply`
- The plan file contains a full copy of the configuration, the state and any variables passed to `terraform plan`
- Relevant environment variables:
  - `TF_WORKSPACE` sets the workspace
  - `TF_IN_AUTOMATION`, if true, Terraform would make some changes to its output, such as de-emphasizing the next command to run


### CLI

```sh
# to initialize the working directory.
terraform init -input=false

# to create a plan and save it to the local file tfplan
# provide -var or -var-file for variable values
terraform plan -out=tfplan -input=false [-var] [-var-file]

# REVIEW and APPROVE the plan

# to apply the plan stored in the file tfplan
terraform apply -input=false tfplan
```

For non-critical infrastructure, you might want to create a plan implicitly and auto approve it:

```sh
terraform apply -input=false -auto-approve
```



### Use remote state file

When provision infrastructure in a pipeline, you need:

- Save state file in a remote storage, so it could be used across multiple runs
- The backend should support state locking to provide safety against race conditions
- Create a service principal for Terraform to authenticate with Azure


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

### Azure DevOps Pipeline

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


## Internals

Terraform is comprised of core and plugins:

![Terraform plugins api](images/terraform_plugins-api.png)

- Core: reads the configurations and builds the resource dependency graph
- Plugins: providers or provisioners
