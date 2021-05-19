# Azure CLI

- [Cheatsheats](#cheatsheats)
  - [General](#general)
  - [Login and accounts](#login-and-accounts)
  - [Configurations](#configurations)
  - [Groups and resources](#groups-and-resources)
  - [VM](#vm)

## Cheatsheats

### General

```sh
az vm --help

# this uses AI to get usage examples:
az find `az vm`

# upgrade version
az upgrade
```

### Login and accounts

```sh
az login

# list subscriptions
az account list

# set active subscription
az account set --subscription gary-default

# logout a specific user
az logout --username gary@foo.com
```
### Configurations

```sh
# set default group and location
az configure \
  --defaults group=<groupName> location=australiasoutheast

# list default configs
az configure -l
```
### Groups and resources

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
### VM

```sh
# create a simple ubuntu vm
# and 
#   - enable system assigned managed identity
#   - it would have the 'Contributor' role in the specified scope
#   - this creates vnet, subnet, ip, etc
az vm create \
  --name myVM \
  --image ubuntuLTS \
  --size Standard_B1ms \
  -g myRG
  --assign-identity '[system]' \
  --scope $principalId

# by default, 
#   - it would use your local username
#   - and ~/.ssh/id_rsa.pub
#   - and port 22 is accessible
# so you could login to it using
ssh vm-public-ip
```
