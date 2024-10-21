# Terraform

- [Overview](#overview)
- [File structure](#file-structure)
  - [`main.tf` - the plan](#maintf---the-plan)
  - [`variables.tf` - variable definition](#variablestf---variable-definition)
    - [`terraform.tfvars`](#terraformtfvars)
  - [`outputs.tf`](#outputstf)
  - [`terraform.tfstate`](#terraformtfstate)
- [Commands](#commands)
- [Authenticate to Azure providers](#authenticate-to-azure-providers)
  - [`azurerm` provider](#azurerm-provider)
  - [`azuread` provider](#azuread-provider)
  - [Add permissions to a service principal](#add-permissions-to-a-service-principal)
- [State file](#state-file)
- [Remote runs and state](#remote-runs-and-state)
  - [Terraform Cloud](#terraform-cloud)
  - [`azurerm` backend (Blob Storage)](#azurerm-backend-blob-storage)
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
  - [`lifecycle`](#lifecycle)
  - [Providers](#providers)
    - [`alias`](#alias)
- [The `random` provider](#the-random-provider)
- [Provisioners](#provisioners)
- [Modules](#modules)
  - [Create modules](#create-modules)
  - [Providers within modules](#providers-within-modules)
    - [Implicit provider inheritance](#implicit-provider-inheritance)
    - [Passing providers explicitly](#passing-providers-explicitly)
- [Best practices](#best-practices)
  - [Environment separation](#environment-separation)
- [Automate Terraform](#automate-terraform)
  - [CLI](#cli)
  - [Use remote state file](#use-remote-state-file)
  - [Azure DevOps Pipeline](#azure-devops-pipeline)
- [Internals](#internals)
- [Import existing infrastructure to Terraform configs](#import-existing-infrastructure-to-terraform-configs)
  - [Azure Terrafy](#azure-terrafy)
  - [Terraformer](#terraformer)
    - [Installation](#installation)
    - [Run](#run)
- [CDK for Terraform](#cdk-for-terraform)
- [Troubleshooting](#troubleshooting)
- [Azure](#azure)
  - [Azure Verified Modules](#azure-verified-modules)
  - [`AzAPI` provider](#azapi-provider)
  - [ARM template deployment](#arm-template-deployment)
  - [`azurerm` v4 changes](#azurerm-v4-changes)
  - [Gotchas](#gotchas)

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

# settings for a provider, empty in this case
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
- `version` key is recommended, it's recommended to pin to either
  - A fixed version: `version = "=1.2.3"`
  - Or a major version: `version = "~> 4.0"`, (don't do this in a reusable module, see the [module section](#modules))
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
  - `terraform init -migrate-state`: after you updated the backend(eg. from local to `azurerm`), use this to migrate the state file to the new backend

- `terraform plan`
  - Produces an execution plan for you to review
  - `terraform plan -refresh-only` outputs a plan showing what has been changed to the remote resources, you need to apply the plan to bring the changes to the state file.
    ```sh
    terraform plan -refresh-only -output "refresh.plan"
    terraform apply "refresh.plan"
    ```

- `terraform apply`
  - Runs you plan, it's **idempotent**
  - `terraform apply -var "resource_group_name=myNewResourceGroupName"` to override a variable
  - `tf apply -target 'azurerm_resource_group.rg' -target 'azurerm_resource_group.rg2'` only targets specified resources, you may need to use this to fix errors, sort out dependency issues, etc
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
- `terraform show [ADDRESS]` show details of a resource
- `terraform providers` show providers for this config


## Authenticate to Azure providers

- This section covers authentication to a provider, for authentication to remote runner or state storage, see [Remote run and state](#remote-runs-and-state) section
- When using Terraform interactively on command line, Terraform uses Azure CLI to authenticate, this ONLY works with user account (no need to set `ARM_*` env variables), NOT service principals (need to set `ARM_*` env variables)
- In a non-interactive context, use a service principal or managed identity, there are several ways for the authentication:
  - Client secret/certificate
  - OpenID Connect
    - This is recommended, you don't need to create and renew a secret or certificate
    - See here on how to use with GitHub actions: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc
    - See here on how to use with Terraform Cloud: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration
      - You'll need one federated credential for "plan", another for "apply"
      - In some cases, you may want one service principal for "plan", another for "apply"


### `azurerm` provider

To use a service principal for `azurerm` provider

```sh
export ARM_SUBSCRIPTION_ID
export ARM_CLIENT_SECRET
export ARM_CLIENT_ID
export ARM_TENANT_ID
```

### `azuread` provider

No need for subscription id in this case

```sh
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="MyCl1eNtSeCr3t"
export ARM_TENANT_ID="10000000-2000-3000-4000-500000000000"
```

### Add permissions to a service principal

To grant this service principal permissions to read/write AAD objects, see https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/service_principal_configuration. There are two methods:

1. Add API permissions to the application, then add consent to the service principal
    - This is more granular, **recommended** for service principals
2. Assign AAD roles to the service principal
    - Go to AAD's "Roles and administrators" blade, find the role, click on it
    - Add an assignment to the service principal
    - **Roles listed in the service principal's "Roles and administrators" blade are NOT roles assigned to this service principal!**
    - This is recommended for **user principals**


## State file

Why state file is required:

- Ensures a one-to-one mapping from resource instances to remote objects
- Tracks metadata such as resource dependencies
  - Terraform could use your configuration to determine dependencies when creating objects
  - However, after you removed some resources from your configuration, Terraform could only rely on the state file to determine how to destroy the resources in correct order
- Performance: Terraform stores a cache of the attribute values for all resources in the state
  - When running `terrafrom plan`, Terraform must know the current state of resources to effectively determine the changes it needs
  - The default behavior: for every plan and apply, Terraform query providers and sync the latest attributes for all resources in your state file
  - For large infrastructures, it could be too slow due to API restrictions (no API for multiple resources at once, rate limiting, etc). So people use `-refresh=false` or `-target` to walk around this. In these scenarios, the cached state is treated as the record of truth.


## Remote runs and state

In a collaborative or CI/CD context, you may want to run Terraform plan/apply or store state files remotely

### Terraform Cloud

Terraform Cloud supports remote run, storing state file, input variables, environment variables, private module registry, policy as code, etc

1. Add a `terraform.cloud` block

    ```terraform
    terraform {
      ...

      cloud {
        organization = "garylirocks"

        workspaces {
          // use name for a single workspace
          name = "my-workspace"
          // or tags for multiple workspaces
          // tags = ["cli", "prod"]
        }
      }
    }
    ```

    Deprecated syntax:

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

1. Run `terraform login`, this saves a token to `~/.terraform.d/credentials.tfrc.json`

    ```json
    {
      "credentials": {
        "app.terraform.io": {
          "token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
      }
    }
    ```

3. Run `plan` or `apply`, this runs remotely in Terraform Cloud (or locally, if configure so), so the workspace should have credentials configured as workspace env variables (eg. `ARM_CLIENT_ID` for `azurerm`)

Note:

- When you use `tags` (instead of `name`) to specify workspaces, you could list (`tf workspace list`) or select a workspace (`tf workspace select dev`)
- You should create one workspace for each environment (dev, test, prod)
- For workspaces configured with VCS-driven workflow, you can trigger `plan` from local CLI, but **not** `apply`
- When running a remote `plan` or `apply`, a copy of your directory is uploaded to Terraform Cloud, you could use `.terraformignore` to exclude paths (`.git/` and `.terraform/` are ignored by default)

### `azurerm` backend (Blob Storage)

Three methods of authentication, see https://developer.hashicorp.com/terraform/language/settings/backends/azurerm#authentication

- Access Key (default)
  - Explicitly set `access_key = <xxxx>` (in config or as env var)
  - Or with an Entra principal: TF will try to retrieve the access key from the storage account (use the specified client ID or Azure CLI)
    - `use_oidc=true`
    - `use_msi=true`
    - `client_secret=true` or `client_certificate_path=true`
    - Azure CLI
- Azure AD
  - Must set `use_azuread_auth = true`, and
    - `use_oidc=true`
    - `use_msi=true`
    - `client_secret=true` or `client_certificate_path=true`
    - Azure CLI
- SAS Token
  - Explicitly set `sas_key = <xxxx>` (in config or as env var)

How to configure

- Add a `backend` block in `terraform` block

  ```terraform
  terraform {
    ...

    backend "azurerm" {
      resource_group_name  = "StorageAccount-ResourceGroup"  # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
      storage_account_name = "abcd1234"                      # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
      container_name       = "tfstate"                       # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
      key                  = "prod.terraform.tfstate"        # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
    }
  }
  ```

- Create a separate file `backend.tfvars`, and use it with `terraform init -backend-config="backend.tfvars"`

  ```
  resource_group_name  = "learning-rg"
  storage_account_name = "tfstatey2hkc"
  container_name       = "tfstate"
  key                  = "terraform.tfstate"
  subscription_id      = "00000000-0000-0000-0000-000000000000"   # optional
  # access_key         = 'xxxx'
  # sas_key            = 'xxxx'
  ```

  It's better to set `access_key` and `sas_key` as environment variables

  ```sh
  export ARM_ACCESS_KEY
  # or
  export ARM_SAS_TOKEN
  ```

- Use env vars
  - `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, `ARM_CLIENT_ID`, ...


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

  - Accepts a map or a **set** of strings (list needs to be converted with `toset()` function)
  - Can be used in a resource or module block to create multiple instances, each instance is associated with a distinct infrastructure
  - Use `each.key` and `each.value` in the block to access key and value (`each.key` and `each.value` is the same when a set is provided)

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

    # a list of strings converted to a set
    resource "aws_iam_user" "the-accounts" {
      for_each = toset( ["Todd", "James", "Alice", "Dottie"] )
      name     = each.key
    }
    ```

  - To refer to the instances, **`<TYPE>.<NAME>`** refers to all the instances as a map, **`<TYPE>.<NAME>[INDEX]`** refer to a single instance, eg. `aws_iam_user.the-accounts["Todd"]`


- For expressions: `for..in`

  - Creates a list out of another list or map

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

  - Or create a map (**use `if` for filtering**)

    ```sh
    > { for k,v in {a = {age = 20}, b = {age = 30}}: k => v.age }
    {
      "a" = 20
      "b" = 30
    }

    # use 'if' for filtering
    > { for k,v in {a = {age = 20}, b = {age = 30}}: k => v.age if v.age > 25}
    {
      "b" = 30
    }

    # use '...' to group by key
    > { for v in [ {name = "gary", color = "red"}, {name = "gary", color = "green"}, {name = "jack", color="white"} ]: v.name => v.color... }
    {
      "gary" = [
        "red",
        "green",
      ]
      "jack" = [
        "white",
      ]
    }
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
  lookup({ gary = 20, henry = 30 }, "gary"  )
  # 20

  # provide a default value
  lookup(var.fruits, "apple", "Red")
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

- `jsonencode` encode a value to a JSON string

  ```sh
  > jsonencode({ name = "gary", age = 20 })
  "{\"age\":20,\"name\":\"gary\"}"
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

- `fileset`

  ```sh
  fileset("${path.module}/files", "**")

  #[
  #  "hello.txt",
  #  "world.txt",
  #  "subdirectory/anotherfile.txt",
  #]
  ```


- Provider-defined functions
  - Defined within the provider's schema using Terraform provider plugin framework
  - Available since Terraform 1.8
  - Example: AWS provider has a function `arn_parse`, use it like `provider::aws::arn_parse(aws_ecr_repository.hashicups.arn).account_id`

### Dynamic expressions

- Conditional expression:

  ```sh
  resource "aws_instance" "ubuntu" {
    count                       = (var.high_availability == true ? 3 : 1)
    associate_public_ip_address = (count.index == 0 ? true : false)
  }
  ```

- `dynamic` blocks

  ```terraform
  resource "azurerm_key_vault" "main" {
    ...

    dynamic "access_policy" {
      for_each = var.access_policies
      // iterator = iter

      content {
        tenant_id               = var.tenant_id
        object_id               = access_policy.value.object_id
        secret_permissions      = access_policy.value.secret_permissions
        ...
      }
    }
  }
  ```

  - This creates repeatable nested blocks inside `resource`, `data`, `provider` or `provisioner` blocks
  - Different from the `for_each` meta argument, which doesn't accept a list, this `for_each` accepts any collection type
  - The block label `access_policy` is the default iterator variable name in the block, you could customize it with `iterator` argument

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

- Info about current client, subscription

  ```terraform
  # get config of the AzureRM default provider
  # you could also pass in a provider attribute to target other subscriptions
  data "azurerm_client_config" "current" {
  }

  # you can get client_id, tenant_id, subscription_id, object_id
  # CAUTION: the "subscription_id" is just a GUID, not the full ID
  output "account_id" {
    value = data.azurerm_client_config.current.client_id
  }
  ```

  ```terraform
  data "azurerm_subscription" "current" {
  }

  output "sub_id" {
    # CAUTION: this is the full ID, like "/subscriptions/<GUID>"
    value = data.azurerm_subscription.current.id
  }

  output "sub_guid" {
    # CAUTION: this is only the GUID
    value = data.azurerm_subscription.current.subscription_id
  }
  ```

  ```terraform
  # get available zones in current region
  data "aws_availability_zones" "available" {
    state = "available"
  }
  ```

- Info from other workspaces (`terraform_remote_state` is a Terraform builtin provider)

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

Or update the state file about what changed with:

```sh
# show a list of resource IDs in the current state
tf state list

# move resource IDs
tf state mv [options] SOURCE DESTINATION
```

### `lifecycle`

- The `ignore_changes` block allows you to ignore changes to certain attributes
  - Must be a list of static attribute names, no functions, expressions, etc
  - Can have sub-attribute, like `tags["tag1"]`, *does not support the dot syntax `tags.tag1`*
  - Example:

    ```terraform
    resource "azurerm_resource_group" "rg" {
      name     = "rg-testing"
      location = "australiaeast"
      tags     = {
        tag1 = "foo"
        tag2 = "bar"
      }

      lifecycle {
        ignore_changes = [
          tags["tag2"],
          tags["extra"]
        ]
      }
    }
    ```

### Providers

```terraform
provider "google" {
  project = "acme-app"
  region  = "us-central1"
}
```

- `google` is the local name of the provider, should already be included in a `required_providers` block
- arguments are specific to the provider, you could use variables as values
- `provider` block may be omitted if no explicit configurations are needed

#### `alias`

```terraform
provider "aws" {          # 1
  region = "us-east-1"
}

provider "aws" {          # 2
  alias  = "west"
  region = "us-west-2"
}
```

- #1 the default(un-aliased) provider configuration, can be referenced as `aws`, resources that begin with `aws_` will use it as its provider
- #2 has an `alias` argument, can be referenced as `aws.west`
- If every provider block has an `alias` argument, Terraform would create a default empty configuration as that provider's default configuration

```terraform
resource "aws_instance" "foo" {
  provider = aws.west             # 1
  # ...
}

module "aws_vpc" {
  providers = {                   # 1
    aws = aws.west
  }
  # ...
}
```

- #1: To use an alternate provider, use the `provider` or `providers` meta-argument in `resource`, `module` or `data` blocks

In most cases, **only root modules** should define provider configurations, with all child modules obtaining their configurations from their parents


## The `random` provider

The "random" provider allows you to generate random strings/passwords/UUIDs/pet names.

- It works entirely within Terraform's logic, and doesn't interact with any other services.
- It has resources like: `random_id`, `random_integer`, `random_password`, `random_pet`, `random_shuffle`, `random_string`, `random_uuid`
- The generated random value is kept in the state file
- They all have a map argument called `keepers`, if you change anything in it, the random value will be regenerated

```yaml
resource "random_id" "server" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = "${var.ami_id}"
  }

  byte_length = 8
}

resource "aws_instance" "server" {
  tags = {
    Name = "web-server ${random_id.server.hex}"
  }

  # Read the AMI id "through" the random_id resource to ensure that
  # both will change together.
  ami = random_id.server.keepers.ami_id

  # ... (other aws_instance arguments) ...
}
```


## Provisioners

- Used to run actions on local or remote machines
- Built-in provisioners:
  - `file`: for copying files to remote machines
  - `local-exec`: run something on localhost
  - `remote-exec`: run something on remote host
- **Use it as a last resort**: when building VMs, most cloud provider allows you to utilize tools like `cloud-init` to pass in user data
- Mostly used within a resource block, you could also use it within **`terraform_data`**, **`null_resource` (legacy)**
- You could have multiple `provisioner` block in a containing block, executed in order of definition
- Use `self` object to access the parent resource's attributes
- `file` and `remote-exec` needs a `connection` block, you could use either `ssh` or `winrm`

Example:

```terraform
resource "aws_instance" "web" {
  # ...

  # Establishes connection to be used by all
  # generic remote provisioners (i.e. file/remote-exec)
  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "puppet apply",
      "consul join ${aws_instance.web.private_ip}",
    ]
  }
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
- **Try to avoid `data` block (such as a resource group data block) in a module, if it reads a resource managed by the same configuration, there could be dependencies issues: it tries to read a resource at the plan stage, before the resource is even created.**

### Providers within modules

```terraform
terraform {
  required_providers {
    aws = {                                           # 1
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.alternate ]       # 2
    }
  }
}

# provider "aws" {                                    # 3
#   region = "us-east-1"
# }
```

- #1 a modules needs to declare its provider version requirements
  - **Only specify a minimum version**, NOT the maximum version
  - The maximum version should be specified by the root module
- #2 optional, declare an expected alias provider configuration named `aws.alternate`, the calling module should provide this
- #3 no need for `provider` block, it should be defined in the root module

#### Implicit provider inheritance

```terraform
# root module

provider "aws" {
  region = "us-west-1"                    # 1
}

provider "aws" {
  alias  = "use1
  region = "us-east-1"                    # 2
}

module "child" {
  source = "./child"
}
```

```terraform
# child module

resource "aws_s3_bucket" "example" {     # 3
  bucket = "provider-inherit-example"
}
```

- #1 Root module's default (un-aliased) provider configuration is implicitly inherited by a child module at #3
- #2 alias provider is not automatically inherited

#### Passing providers explicitly

```terraform
# root module

provider "aws" {
  alias  = "usw1"                                   # 1
  region = "us-west-1"
}

provider "aws" {
  alias  = "usw2"                                   # 1
  region = "us-west-2"
}

module "tunnel" {
  source    = "./tunnel"
  providers = {                                     # 2
    aws.src = aws.usw1
    aws.dst = aws.usw2
  }
}
```

```terraform
# child module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.src, aws.dest ]  # 3
    }
  }
}
```

- #1 Root module defines aliases
- #2 Passes down by the `providers` meta-argument in a `module` block
- #3 Child module declares its expected alias names


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

    - Pros:
      - Same config files and different variable values, state files
      - This aligns with the concept of workspaces in Terraform Cloud
      - When connected to Terraform Cloud, the command `terraform workspace select|new` works on workspaces in Terraform Cloud
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
subscription_id      = "00000000-0000-0000-0000-000000000000"   # optional
```

Init with backend

```sh
terraform init -backend-config="backend.tfvars"
```

### Azure DevOps Pipeline

- Use a extension, which provides Terraform tasks, such as https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform

- Use custom script:

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

              # Get output
              WebAppNameDev=$(terraform output appservice_name_dev)

              # Write the WebAppNameDev variable to the pipeline.
              echo "##vso[task.setvariable variable=WebAppNameDev;isOutput=true]$WebAppNameDev"
            name: "RunTerraform"
            displayName: "Run Terraform"
            # set env variables for Azure authentication
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


## Import existing infrastructure to Terraform configs

### Azure Terrafy

- Only import resources supported by Terraform AzureRM provider
- Imports into Terraform state
- And generates corresponding Terraform configuration

```sh
# import a resource group in non-interactive way
aztfy rg \
  -output-dir configs \
  --overwrite \
  --batch \
  --continue \
  rg-gary-001

# import another RG with append mode
# use another name pattern to avoid resource name conflicts
aztfy rg \
  -output-dir configs \
  --append \
  --batch \
  --continue \
  --name-pattern 'spoke-' \
  rg-gary-002
```

### Terraformer

Terraformer (https://github.com/GoogleCloudPlatform/terraformer) can be used to generate Terraform configs from existing resources.

#### Installation

If you are using Azure CLI for authentication to Azure, there is an issue to run this on Linux (see https://github.com/GoogleCloudPlatform/terraformer/issues/1149), Azure CLI 2.28.0 works on Windows, follow these steps:

1. Install Azure CLI 2.28.0 on Windows
   1. remove existing one first if needed
   1. download https://azcliprod.blob.core.windows.net/msi/azure-cli-2.28.0.msi
2. Install Terraform - https://www.terraform.io/downloads
   1. Download exe file for required provider from here - https://github.com/GoogleCloudPlatform/terraformer/releases
   2. Add the exe file path to path variable
3. Create a folder and initialize the terraform provider and run terraformer commands from there

#### Run

In PowerShell

```powershell
az login

# set subscription id
$env:ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# list supported resources
terraformer-azure-windows-amd64.exe import azure list

# generate Terraform code
#   - limit to "my-rg" resource group
#   - specify resource types
#   - filter by full resource ids
#
# In this case, storage_account resources are filtered, not other resources
terraformer-azure-windows-amd64.exe import azure `
  --resource-group my-rg `
  --resources resource_group,storage_account,storage_container,keyvault `
  --filter "storage_account=<full-resource-id1>:<full-resource-id2>"

# or exclude a resource type
terraformer-azure-windows-amd64.exe import azure `
  --resource-group my-rg `
  --excludes "keyvault"
```


## CDK for Terraform

![CDK for Terraform](images/terraform_cdk-for-terraform.png)

You write configs in Typescript, Python, Java, GO, etc, then convert it to JSON, which can be used by Terraform.

Install:

```sh
npm install --global cdktf-cli@latest
```

Init a project:

```sh
# use Typescript, use local state file
cdktf init --template=typescript --local

# install Docker provider for CDKTF
npm install @cdktf/provider-docker

# write code in main.ts

# deploy
cdktf deploy

# destroy
cdktf destroy
```


## Troubleshooting

To troubleshoot issues, you could turn on debugging info with:

```sh
export TF_LOG=DEBUG
```


## Azure

### Azure Verified Modules

Microsoft maintain verified Bicep and Terraform modules, see https://azure.github.io/Azure-Verified-Modules/

Two types
  - Resource modules, eg. VM, vNet, KV, Firewall, ...
  - Pattern modules, eg. Virtual WAN, VNet Gateways, Landing Zones, ...

Sample code:

```
module "avm-ptn-virtualwan" {
  source  = "Azure/avm-ptn-virtualwan/azurerm"
  version = "0.4.1"
  # insert the 4 required variables here
}
```


### `AzAPI` provider

- A thin layer on top of the Azure ARM REST APIs
- Compliments the AzureRM provider, allows you to manage an Azure service that is not yet supported by the AzureRM provider, such as private/public preview services and features
- Two resources:
  - `azapi_resource`: manage a resource
  - `azapi_update_resource`: manage a subset of any existing resource's properties, **WON'T remove the properties when this resource is removed**
  - `azapi_resource_action`: triggers an action on a resource, such as generating SSH keys


```terraform
# providers.tf

terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "=0.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.2"
    }
  }
}

provider "azapi" {
  default_location = "eastus"
  default_tags = {
    team = "Azure deployments"
  }
}

provider "azurerm" {
  features {}
}
```

```terraform
# main.tf

resource "azurerm_resource_group" "qs101" {
  name     = "rg-qs101"
  location = "westus2"
}

# Provision a Lab Service Account and a Lab that are in public preview
resource "azapi_resource" "qs101-account" {
  type      = "Microsoft.LabServices/labaccounts@2018-10-15"
  name      = "qs101LabAccount"
  parent_id = azurerm_resource_group.qs101.id

  body = jsonencode({
    properties = {
      enabledRegionSelection = false
    }
  })
}

resource "azapi_resource" "qs101-lab" {
  type      = "Microsoft.LabServices/labaccounts/labs@2018-10-15"
  name      = "qs101Lab"
  parent_id = azapi_resource.qs101-account.id

  body = jsonencode({
    properties = {
      maxUsersInLab  = 10
      userAccessMode = "Restricted"
    }
  })
}
```

```
resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}
```

### ARM template deployment

There is one resource for each scope level:

| Resource                                       | Deployment mode             | Delete deployed resources with the deployment resource ?     |
| ---------------------------------------------- | --------------------------- | ------------------------------------------------------------ |
| `azurerm_resource_group_template_deployment`   | `Complete` or `Incremental` | Yes, unless `delete_nested_items_during_deletion` is `false` |
| `azurerm_subscription_template_deployment`     | always `Incremental`        | No                                                           |
| `azurerm_management_group_template_deployment` | always `Incremental`        | No                                                           |
| `azurerm_tenant_template_deployment`           | always `Incremental`        | No                                                           |

A few things to note:

- If you delete the deployment resource, rerun will re-create the deployment resource, and the end resources if needed.
- If you delete the end resources, but not the deployment resource itself, Terraform will not detect any changes during rerun, so the end resources won't be re-created.
- If a parameter references a KV secret, without the `secretVersion` field, if you only update the secrets, Terraform will not detect any changes during rerun, so it won't pick up the latest secret
  - If another parameter changes, Terraform will update the deployment object, which will pick up the latest secret

### `azurerm` v4 changes

- You can customize what resource providers to register
  - `resource_provider_registrations = core|extended|all|none|legacy`
  - `resource_providers_to_register`, extra RPs to register besides `resource_provider_registrations`

- When using Azure CLI auth, subscription ID is mandatary in a provider block
  - Use either `subscription_id` attribute or `ARM_SUBSCRIPTION_ID` environment variable
  - Other auth methods already require this

- Provider functions
  - `provider::azurerm::normalise_resource_id`: Fixing casing
  - `provider::azurerm::parse_resource_id`: see [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide#example-usage)


### Gotchas

- `azurerm_management_group`

  You need to explicitly set `subscription_ids` to `[]` to clear all subscriptions from a management group, setting to `null` won't work

  ```
  resource "azurerm_management_group" "my" {
    display_name               = "my-mg"
    parent_management_group_id = azurerm_management_group.parent.id

    subscription_ids = []
  }
  ```

- `azuread_group`

  ```terraform
  data "azuread_client_config" "current" {}

  resource "azuread_group" "example" {
    display_name     = "MyGroup"
    owners           = [
      data.azuread_client_config.current.object_id
      /* more owners */
    ]
    security_enabled = true

    members = [
      azuread_user.example.object_id,
      /* more users */
    ]
  }
  ```

  - If you don't specify `owners` field, then the current principal will be added as the sole owner, the principal only needs `Group.Create` permission to create/delete the group
  - If current principal is one of the `owners`, same as above
  - If you specify `owners` field, and current principal is not in it, then current principal needs `Group.ReadWrite.All` permission
