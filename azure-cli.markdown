# Azure CLI

- [General](#general)
- [Login and accounts](#login-and-accounts)
- [Configurations](#configurations)
- [Groups and resources](#groups-and-resources)
- [Storage](#storage)
- [Providers](#providers)
- [REST API](#rest-api)
  - [AccessToken for other scopes](#accesstoken-for-other-scopes)
- [Preview features](#preview-features)
- [Azure Cloud Shell](#azure-cloud-shell)
  - [File persistence](#file-persistence)
  - [PowerShell](#powershell)

## General

```sh
az vm --help

# this uses AI to get usage examples:
az find `az vm`

# upgrade version
az upgrade
```

Common parameters and shorthand syntax:

- `--resource-group / -g`
- `--output / -o`
- `--name / -n`
- `--query`, uses [JMESPath](https://jmespath.org/) to query JSON data

## Login and accounts

```sh
az login

# login to tenants without subscriptions (eg. Microsoft 365 Developer Program account),
# could be useful to run tenant level commands, like "az ad"
az login --allow-no-subscriptions

# list subscriptions
az account list -otable

# set active account/subscription
az account set --subscription gary-default

# logout a specific user
az logout --username gary@foo.com

# get tenant id of your default account
az account show --query 'tenantId' -otsv
```

After login, tokens (AccessToken, IdToken, RefreshToken) are saved in `~/.azure/msal_token_cache.json`

## Configurations

```sh
# set default group and location
az configure \
  --defaults group=<groupName> location=australiasoutheast

# list default configs
az configure -l

# new command, like "git config"
az config set defaults.location="australiaeast"
az config get defaults.location
```

## Groups and resources

```sh
# list resource groups
az group list

# create a resource group, <location> here is only for group metadata, resources in the group can be in other locations
az group create \
  --name <name> \
  --location <location>

# delete a resource group
az group delete -g learn-rg

# list resouces
az resource list \
  -g learn-rg \
  -o table

# show details of a resource
az resource show
  -g learn-rg \
  --name simpleLinuxVMPublicIP \
  --resource-type Microsoft.Network/publicIPAddresses
```


## Storage

```sh
# === START create / manage a storage account

# get a random account name
STORAGE_NAME=storagename$RANDOM

# create a storage account
az storage account create \
  --name $STORAGE_NAME \
  --sku Standard_RAGRS \
  --encryption-service blob

# list access keys
az storage account keys list \
  --account-name $STORAGE_NAME

# get connection string (key1 is in the string)
az storage account show-connection-string \
  -n $STORAGE_NAME

# create a container in the account
az storage container create \
  -n messages \
  --connection-string "<connection string here>"
```


## Providers

```sh
# list providers on a subscription
az provider list \
  -otable \
  --subscription sub-gary

# list resource types under a provider
az provider show \
  --namespace "Microsoft.Network" \
  --subscription sub-gary
```


## REST API

Use `az rest` to query REST API.

```sh
az rest -u "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-temp-001?api-version=2022-01-01"
```

Delete something

```sh
az rest -m delete -u "/providers/Microsoft.CostManagement/scheduledActions/mydailycostview?api-version=2023-03-01"
```

Seems there are some inconsistencies in the API, usually for a non existent resource, "GET" call returns 404, but the Private DNS Zone Group API returns 200.

```sh
az rest --method get --url "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-temp-001/providers/Microsoft.Network/privateEndpoints/pe-vault-temp-001/privateDnsZoneGroups/nonExistGroup?api-version=2022-01-01" --debug
```

### AccessToken for other scopes

By default AZ CLI gets token in the ARM scope, this can be changed, see https://techcommunity.microsoft.com/t5/healthcare-and-life-sciences/just-give-me-an-access-token/ba-p/3292215


```sh
$azCliAppId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46" #global appId for az CLI
$apiAppId = "your-app-id-here" #appId of your custom API
$requestScope = "api://your-app-id-here/.default" #scope exposed by your custom API app registration

## First time only
az login
az ad sp create --id $azCliAppId
az ad app permission grant `
  --id $azCliAppId `
  --api $apiAppId `
  --scope "your-scope-name" #example: "access_as_user" or "user_impersonation"

## Get new token
az account get-access-token --scope $requestScope --query accessToken
```


## Preview features

```sh
# list registered preview features on a subscription
az feature list \
  --namespace "Microsoft.Network" \
  --query "[? properties.state=='Registered'].{Name: name, State: properties.state}" \
  -otable \
  --subscription "sub-gary"

# Name                                                          State
# ------------------------------------------------------------  ----------
# Microsoft.Network/AllowCortexAccess                           Registered
# Microsoft.Network/AllowRegionalGatewayManagerForExpressRoute  Registered
# Microsoft.Network/AllowTcpPort25Out                           Registered

# register a feature on current subscription
az feature register \
  --namespace="Microsoft.Network" \
  --name="AllowNetworkWatcher"
```

For the query parameter `--query "[? properties.state=='Registered'].{Name: name, State: properties.state}"`, make sure **use single quotes for the string literal** in the JMESPATH expression, otherwise won't work


## Azure Cloud Shell

- You could use either Bash or PowerShell terminal
- Comes with common dev tools pre-installed: zsh, tmux, Azure CLI, AzCopy, vim, git, npm, kubectl, helm, MySQL client, sqlcmd, iPython, Terraform, Ansible, etc
- Runs on a temporary host on a per-user, per-session basis
  - Multiple sessions are run on the same machine
  - You could open a port, and preview whatever is served by it in browser
- Requires an Azure file share to be mounted (same share used for both Bash and PowerShell)
- Persists `$HOME` using a 5GB image held in the file share
- You can find information regarding your Cloud Shell container by inspecting environment variables prefixed with `ACC_`, eg. `ACC_LOCATION` is the region or your container
- By default, Cloud Shell runs in a container in a Microsoft network separate from your resources. This means it cannot access private resources. You could deploy Cloud Shell into your own VNet, see: https://docs.microsoft.com/en-us/azure/cloud-shell/private-vnet

### File persistence

- On first launch, you are prompted to associate a new or existing file share to persist files across sessions.
- For security reason, each user should provision their own storage account.

*Azure storage firewall is not supported for cloud shell storage account.*

Files are persisted in two ways:
  - **File share**: mounted at `$HOME/clouddrive`, which maps to the file share
    - `//stdemo001.file.core.windows.net/garyli`  mounted at `/usr/csuser/clouddrive`
    - `$HOME/clouddrive` is a symlink to `/usr/csuser/clouddrive`
  - **Disk image**: for your `$HOME` directory, a 5GB image, at `<fileshare>/.cloudconsole/acc_<user>.img`, changes sync automatically

    ```sh
    du -sh clouddrive/.cloudconsole/acc_gary.img
    5.0G
    ```

You could use `clouddrive` command to unmount current file share or mount a new share

```sh
# show current mounts
df -h

# unmount current file share, this terminate current sessions
clouddrive unmount

# mount a new file share
clouddrive mount \
  -s mySubscription \
  -g myRG \
  -n storageAccountName \
  -f fileShareName
```

### PowerShell

- Runs PowerShell Core 6 in a Linux environment
- File names are case-sensitive, while cmdlet, parameter and values are not case-sensitive
- `$HOME` is still at `/home/gary`, same as Bash
- Some Azure resources are mapped to directories in a **special `Azure:` drive**

  ```powershell
  PS Azure:\> dir

  #     Directory: Azure:/my-subscription

  # Mode Name
  # ---- ----
  # +    AllResources
  # +    ResourceGroups
  # +    StorageAccounts
  # +    VirtualMachines
  # +    WebApps

  # Azure:/my-subscription
  PS Azure:\> cd ./ResourceGroups/
  # Azure:/my-subscription/ResourceGroups
  PS Azure:\> dir

  #     Directory: Azure:/my-subscription/ResourceGroups

  # Mode ResourceGroupName Location      ProvisioningState Tags
  # ---- ----------------- --------      ----------------- ----
  # +    general           australiaeast Succeeded
  # +    NetworkWatcherRG  australiaeast Succeeded
  ```

  - Force refresh your resources with `dir -Force`
