# Azure CLI

- [Cheatsheats](#cheatsheats)
  - [General](#general)
  - [Login and accounts](#login-and-accounts)
  - [Configurations](#configurations)
  - [Groups and resources](#groups-and-resources)
  - [VM](#vm)
  - [Network](#network)
    - [DNS](#dns)
  - [ARM templates](#arm-templates)

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

# new command, like "git config"
az config set defaults.location="australiaeast"
az config get defaults.location
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

- Create a VM with specified username and SSH key

  ```sh
  az vm create \
    --resource-group my-rg \
    --name vm1 \
    --admin-username azureuser \
    --image UbuntuLTS \
    --ssh-key-values ~/.ssh/azure_rsa.pub
  ```

- Create a VM with system assigned identity

  ```sh
  # create a simple ubuntu vm
  # and
  #   - enable system assigned managed identity
  #   - it would have the 'Contributor' role in the specified scope
  #   - this creates vnet, subnet, ip, etc
  az vm create \
    -g my-rg \
    --name vm1 \
    --image ubuntuLTS \
    --size Standard_B1ms \
    --assign-identity '[system]' \
    --scope $principalId

  # by default,
  #   - it would use your local username
  #   - and ~/.ssh/id_rsa.pub
  #   - and port 22 is accessible
  # so you could login to it using
  ssh vm-public-ip
  ```

- List images/VM sizes

  ```sh
  # filter by publisher
  az vm image list --publisher Microsoft --all --output table

  # filter by location
  az vm image list --location eastus --output table

  # vm sizes
  az vm list-sizes --location eastus --output table
  ```

- Resize a VM

  ```sh
  # list available sizes
  az vm list-vm-resize-options \
    --resource-group my-rg \
    --name vm1 \
    --output table

  # resize a vm
  az vm resize \
    --resource-group my-rg \
    --name vm1 \
    --size Standard_D2s_v3
  ```

- Query a VM

  ```sh
  # get ip address
  az vm list-ip-addresses -n vm1 -o table

  # query a property
  az vm show \
    --resource-group my-rg \
    --name vm1 \
    --query osProfile.adminUsername \
    -otsv

  # open a port (on the NSG attached to the VM's NIC)
  az vm open-port \
    --resource-group my-rg \
    --name vm1 \
    --port 80
  ```

### Network

#### DNS

```sh
az network dns zone list \
    --output table

az network dns record-set list \
    -g <resource-group> \
    -z <zone-name> \
    --output table
```

### ARM templates

```sh
# deploy an ARM **template**
az deployment create --template-file test.json

# validate a template file
az deployment group validate \
    --resource-group my-rg \
    --template-file basic-template.json
    --parameters @params.json

# deploy to a resource group
az deployment group create \
    --name MyDeployment \
    --resource-group my-rg \
    --template-file basic-template.json
    --parameters @params.json

# verify
az deployment group show \
    --name MyDeployment \
    --resource-group my-rg
```