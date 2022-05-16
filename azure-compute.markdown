# Azure Compute

- [VMs](#vms)
  - [Disks](#disks)
  - [Initialize data disks](#initialize-data-disks)
  - [Disk encryption](#disk-encryption)
    - [ADE](#ade)
  - [Availability options](#availability-options)
  - [Scaling](#scaling)
  - [Provisioning](#provisioning)
  - [Use AAD for Linux VM authentication](#use-aad-for-linux-vm-authentication)
  - [Linux Agent](#linux-agent)
  - [Updating](#updating)
  - [CLI Cheatsheet](#cli-cheatsheet)
- [App Service](#app-service)
  - [App Service plans](#app-service-plans)
    - [SKUs](#skus)
  - [Deployment](#deployment)
  - [Deployment slots](#deployment-slots)
    - [Swap](#swap)
  - [Scaling](#scaling-1)
  - [Node app](#node-app)
  - [App Logs](#app-logs)
  - [Backup](#backup)
- [Static Web Apps](#static-web-apps)
- [Docker Container Registry](#docker-container-registry)
  - [Tasks feature](#tasks-feature)
  - [Authentication options](#authentication-options)
    - [Individual AD identity](#individual-ad-identity)
    - [Service principal](#service-principal)
  - [Replication](#replication)
- [Container Instance](#container-instance)
  - [Container groups](#container-groups)
- [Azure Functions](#azure-functions)
  - [Durable functions](#durable-functions)

## VMs

Checklist for creating VMs

- Network (vNets)
  - Decide network address space;
  - Break network into sections, e.g. 10.1.0.0 for VMs, 10.2.0.0 for SQL Server VMs;
  - Network security groups (NSG)

- Name
  - used as the computer name
  - also defines a manageable Azure resource, not trivial to change later (it can be applied to the associated storage account, VNets, network interface, NSGs, public IPs)
  - a good example `dev-usc-web01` includes environment, location, role and instance of this VM

- Location
  - consider proximity, compliance, price

- Size
  - based on workload
    - general purpose: ideal for testing and dev, small to medium DBs, low to medium traffic web servers
    - compute optimized: medium traffic web servers, network appliances, batch processes, and application servers
    - memory optimized: DBs, caches, in-memory analytics
    - storage optimized: DBs
    - GPU: graphics rendering and video editing
    - high performance compute
  - sizes can be changed

- Costs
  - Compute
    - Billed on per-minute basis
    - Stop the VM only shuts down the guest OS, doesn't release the compute resource
    - Deallocating releases the compute resource and stops charging
    - Linux VMs are cheaper than Windows which includes license charges
    - Two payment options:
      - Pay as you go
      - Reserved VM instances

  - Storage
    - charged separately from VM, you will be charged for storage used by the disks even if the VM is deallocated

- Storage

  - Each VM can have three types of disk:
    - **OS disk** (`/dev/sda` on Linux),
    - **Temporary disk**, is a short-term storage (`D:` on Windows, `/mnt` on Linux, page files, swap files), **local to the server, NOT in a storage account**
    - **Data disk**, for database files, website static content, app code, etc
  - VHDs are page blobs in Azure Storage
  - Two options for managing the relationship between the storage account and each VHD:
    - **unmanaged disks**: expose the underlying storage accounts and page blobs, an account is capable of supporting 40 standard VHDs, it's hard to scale out
    - **managed disks**: newer and recommended, you only need to specify the type (Ultra/Premium/Standard SSD, Standard HDD) and size, only show the disks, hide the underlying storage account and page blobs

- OS
  - Multiple versions of Windows and Linux
  - Marketplace has VM images which include popular tech stacks
  - You can create your disk image and upload to Azure storage and use it to create a VM

### Disks

Types:

- Local SSD (temporary disk)
  - The temporary disk of each VM, size depending on the size of the VM;
  - No extra charge, already included in the VM cost;
  - Local to the VM, performance is high;
  - Data could be lost during a maintenance or redeployment of the VM;
  - Suitable for temporary data storage, eg. page or swap file, tempdb for SQL Server;
- Standard HDD
  - Inconsistent latency or lower levels of throughput;
  - Suitable for dev/test workload;
- Standard SSD
- Premium SSD
  - Consistent low latency, high levels of throughput and IOPS;
  - Recommended for all production workloads;
  - Can only be attached to specific VM sizes (designated by a 's' in the name, eg. D2s_v3, Standard F2s_v2)

Operations:

- Data disk could be detached/attached without stopping the VM

### Initialize data disks

Any additional drives you create from scratch need to be initialized and formatted.

```sh
# list block devices, 'sdc' is not mounted
lsblk
# NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda       8:0    0   16G  0 disk
# └─sda1    8:1    0   16G  0 part /mnt
# sdb       8:16   0   30G  0 disk
# ├─sdb1    8:17   0 29.9G  0 part /
# ├─sdb14   8:30   0    4M  0 part
# └─sdb15   8:31   0  106M  0 part /boot/efi
# sdc       8:32   0    1T  0 disk
# sr0      11:0    1  628K  0 rom

# create a new primary partition
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc

# write a file system to the partition
sudo mkfs -t ext4 /dev/sdc1

# create a mount point and mount
sudo mkdir /data && sudo mount /dev/sdc1 /data
```

### Disk encryption

Types of encryption:

- Azure Storage Service Encryption (SSE, also known as Server-Side Encryption, encryption-at-rest)
- Azure Disk Encryption (ADE)
- Encryption at host:
  - Encryption starts at the Azure server that your VM is hosted on
  - Your temp disk and OS/data disk caches are stored on the host
  - Does not use your VM's CPU and no impact on your VM's performance
  - Your must enable this feature for your subscription first: `Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"`

Comparison:

|                    | SSE                                                                   | ADE                                     |
| ------------------ | --------------------------------------------------------------------- | --------------------------------------- |
| Algorithm          | 256-bit AES                                                           | 256-bit AES                             |
| What               | OS/data disks                                                         | OS/data/temp disks, caches              |
| Encrypt/Decrypt by | Azure Storage (data decrypted at Storage, before it flows to Compute) | VM CPU                                  |
| How                | Enabled by default for Azure managed disks, can't be disabled         | BitLocker on Windows, DM-Crypt on Linux |
| Managed by         | Storage account admin                                                 | VM owner                                |
| Key management     | PMK or CMK (Key Vault)                                                | Key Vault                               |
| Performance        | no noticeable impact                                                  | typically negligible*                   |

`*` For a CPU-intensive application, there may be a case for leaving the OS disk un-encrypted to maximize performance, and storing application data on a separate encrypted data disk.

#### ADE

To encrypt existing VM disks:

1. Create a key vault (need to be in the same region as the VM)
1. Set the key vault access policy to support disk encryption
1. Encrypt VM disk using the key vault to store the key

```sh
az keyvault create \
    --name "myKeyVault" \
    --resource-group <resource-group> \
    --location <location> \
    --enabled-for-disk-encryption True

# you could encrypt just the OS disk, data or all disks
az vm encryption enable \
    --resource-group <resource-group> \
    --name <vm-name> \
    --disk-encryption-keyvault <keyvault-name> \
    --volume-type [all | os | data]

# check encryption status
az vm encryption show --resource-group <resource-group> --name <vm-name>

# decrypt
az vm encryption disable --resource-group <resource-group> --name <vm-name>

# encrypt/decrypt could also be done with an ARM template
az deployment group create \
    --resource-group <my-resource-group> \
    --name <my-deployment-name> \
    --template-uri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/201-encrypt-running-windows-vm-without-aad/azuredeploy.json
```

Note:

- Basic size VMs do not support ADE
- On some Linux distros, only data disks can be encrypted
- On Windows, only NTFS format disks can be encrypted
- When adding a new disk to an encrypted VM, it's NOT encrypted automatically, it needs to be properly partitioned, formatted, and mounted before encryption
- When enabling encryption on new VMs, you could use an ARM template to ensure data is encrypted at the point of deployment
- ADE is required for VMs backed up to the Recovery Vault
- **SSE with CMK improves on ADE** by enabling you to use any OS types and images for your VMs


### Availability options

![Availability Options](images/azure-availability-options.png)

- Single instance VM
  - 99.9% SLA when using premium storage for all OS and Data Disks

- Availability sets (different racks within a datacenter)

  - 99.95% SLA (connectivity to at least one instance 99.95% of the time)
  - Multiple VMs in an availability set are spread across Fault Domains and Update Domains
    - The maximum fault domain count is depended on region
    - The maximum update domain count is 20
  - The VMs in a set should perform identical functionalities and have the same software installed
  - You can only add a VM to an availability set when creating a VM, you can't add an existing VM to an availability set
  - Combine a Load Balancer with an availability set

  ![Availability Sets](images/azure-vm_availability_sets.png)


- Availability zones (one or multiple datacenters within a region equipped with independent power, cooling and networking)

  - minimum three separate zones for each enabled region

  ![Availability Zones](images/azure-availability-zones.png)


### Scaling

- Virtual Machine Scale Sets

  - All instances are created from the same base OS image and configuration.
  - Support Load Balancer for layer-4 traffic distribution, and Application Gateway for layer-7 traffic distribution and SSL termination.
  - Number of instances can automatically increase or decrease in response to demand or a defined schedule.
  - You could use your own custom VM images.

- Azure Batch
  - large-scale job scheduling and compute management;

### Provisioning

- Custom Script Extension

  - Imperative, you specify a custom script to be run on a VM, it can update configuration, install software, etc
  - Doesn't work if reboot is required

  ```sh
  # run an custom script extension
  az vm extension set \
    --resource-group $RESOURCEGROUP \
    --vm-name simpleLinuxVM \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --settings '{"fileUris":["https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-nginx.sh"]}' \
    --protected-settings '{"commandToExecute": "./configure-nginx.sh"}'
  ```

  Or add the custom script extension as a resource in the template, *specify that it dependsOn the VM*, so it runs after the VM is deployed
  ```sh
  {
    "name": "[concat(parameters('vmName'),'/', 'ConfigureNginx')]",
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "apiVersion": "2018-06-01",
    "location": "[parameters('location')]",
    "properties": {
      "publisher": "Microsoft.Azure.Extensions",
      "type": "customScript",
      "typeHandlerVersion": "2.0",
      "autoUpgradeMinorVersion": true,
      "settings": {
        "fileUris": [
          "https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-nginx.sh"
        ]
      },
      "protectedSettings": {
        "commandToExecute": "./configure-nginx.sh"
      }
    },
    "dependsOn": [
      "[resourceId('Microsoft.Compute/virtualMachines/', parameters('vmName'))]"
    ]
  }
  ```

- Desired State Configuration

  - PowerShell only (could be used on Linux)
  - You specify your required VM state in a configuration file

    ```
    Configuration MyDscConfiguration {
      Node "localhost" {
          WindowsFeature MyFeatureInstance {
              Ensure = 'Present'
              Name = 'Web-Server'
          }
      }
    }
    MyDscConfiguration -OutputPath C:\temp\
    ```

  - Better to be used with Azure Automation State Configuration, otherwise you need to manage your own DSC configuration and orchestration

    ![Azure DSC setup](images/azure_dsc-setup.png)
    ![Azure DSC pull](images/azure_dsc-pull.png)

    By default, every 15 minutes, LCM on each VM polls Azure Automation for any changes to the DSC configuration file.

- Chef

  - You specify a Chef server and recipes to run
  - It uses a Ruby-based DSL

- Cloud-init

  - A way to customize a Linux VM as it boots for the first time, you can use it to install packages, write files, and configure users
  - Cloud-init files use YAML format, the following example installs the package `pythong-pip` and `numpy`


  ```yaml
  #cloud-config
  packages:
    - python-pip
  runcmd:
    - pip install numpy
  ```
  (*the comment on first line is required*)

  ```sh
  az vm create \
    --resource-group my-rg \
    --name my-vm \
    --admin-username azureuser \
    --image UbuntuLTS \
    --custom-data cloud-init.txt \
    --generate-ssh-keys
  ```

- Terraform

  - Infrastructure as code
  - Supports Azure, AWS, GCP
  - Use Hashicorp Configuration Language (HCL), also supports JSON
  - Managed separate from Azure, you might not be able to provision some types of resources

  ```
  # Configure the Microsoft Azure as a provider
  provider "azurerm" {
      subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }

  # Create a resource group
  resource "azurerm_resource_group" "myterraformgroup" {
      name     = "myResourceGroup"
      location = "eastus"

      tags = {
          environment = "Terraform Demo"
      }
  }

  # Create the virtual machine
  resource "azurerm_virtual_machine" "myterraformvirtual machine" {
      name                  = "myvirtual machine"
      location              = "eastus"
      resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
      network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
      virtual machine_size               = "Standard_DS1_v2"

      storage_os_disk {
          name              = "myOsDisk"
          caching           = "ReadWrite"
          create_option     = "FromImage"
          managed_disk_type = "Premium_LRS"
      }

      storage_image_reference {
          publisher = "Canonical"
          offer     = "UbuntuServer"
          sku       = "16.04.0-LTS"
          version   = "latest"
      }

      os_profile {
          computer_name  = "myvirtual machine"
          admin_username = "azureuser"
      }

      os_profile_linux_config {
          disable_password_authentication = true
          ssh_keys {
              path     = "/home/azureuser/.ssh/authorized_keys"
              key_data = "ssh-rsa AAAAB3Nz{snip}hwhaa6h"
          }
      }

      boot_diagnostics {
          enabled     = "true"
          storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
      }

      tags = {
          environment = "Terraform Demo"
      }
  }
  ```

### Use AAD for Linux VM authentication

1. Insure System assigned managed identity is enabled:

    ```sh
    az vm identity assign -g myResourceGroup -n myVm
    ```

2. Install extension to VM

    ```sh
    az vm extension set \
          --publisher Microsoft.Azure.ActiveDirectory \
          --name AADSSHLoginForLinux \
          --resource-group myResourceGroup \
          --vm-name myVM
    ```

3. Assign roles

    To login via SSH, a user needs to have either 'Virtual Machine Administrator Login' or 'Virtual Machine User Login' role

    ```sh
    userPrincipalName=$(az ad signed-in-user show --query userPrincipalName -o tsv)
    vm=$(az vm show --resource-group myResourceGroup --name myVM --query id -o tsv)

    az role assignment create \
        --role "Virtual Machine Administrator Login" \
        --assignee $userPrincipalName \
        --scope $vm
    ```

4. Login

    Now you can login with Az CLI

    ```sh
    # ensure the ssh extension is installed
    az extension add --name ssh

    # login with az ssh
    az ssh vm -n myVM -g myGroup

    # OR export configuration to use your usual ssh client
    az ssh config --file ~/.ssh/config -n myVM -g myGroup
    ```

    - You have your own uid, gid, home directory, etc;
    - If you have the `Virtual Machine Administrator Login` role, you would be in `aad_admins` group, which has **sudo** permission (`%aad_admins ALL=(ALL) NOPASSWD:ALL` is in file `/etc/sudoers.d/aad_admins`)

### Linux Agent

There's an agent in each Linux vm, called `walinuxagent`, pre-built in most Linux images.

It manages Linux provisioning and VM interaction with the Azure Fabric Controller. Provides the following functionality for Linux VMs:

- Provisioning
  - Creation of a user account
  - Configuring SSH authentication types
  - Deployment of SSH public keys and key pairs
  - Setting the host name
  - Publishing the host name to the platform DNS
  - Formatting and mounting the resource disk
  - ...

- Networking
  - Manages routes to improve compatibility with platform DHCP servers
  - Ensures the stability of the network interface name

- VM Extension (*password reset, ssh key updates and backups depend on VM extensions*)
  - Inject component authored by Microsoft and Partners into Linux VM to enable software and configuration automation

- Telemetry
  - Collects usage data and sends it to Microsoft

- ...

It requires:

  - Python 2.6+
  - OpenSSL 1.0+
  - OpenSSH 5.3+
  - Filesystem utilities: `sfdisk`, `fdisk`, `mkfs`, `parted`
  - Password tools: `chpasswd`, `sudo`
  - Text processing tools: `sed`, `grep`
  - Network tools: `ip-route`


Update the agent:

```sh
apt list --installed | grep walinuxagent
sudo apt-get -qq update

# install latest version
sudo apt-get install walinuxagent

# to enable auto update, set it in /etc/waagent.conf
# AutoUpdate.Enabled=y

# restart
systemctl restart walinuxagent.service
```


### Updating

Azure has a solution for updating VMs called Update Management

- It works with both Windows and Linux virtual machines that are deployed in Azure, on-premises, or even in other cloud providers
- There are no agents or additional configuration within the virtual machine
- You can run updates without logging into the VM. You also don't have to create passwords to install the update

![Update Management data flow](images/azure_update-management-data-flow.png)

### CLI Cheatsheet

- Create a basic Linux vm for testing

  ```sh
  # - this creates vnet, subnet, ip, etc
  # - it would use your local username
  # - and ~/.ssh/id_rsa.pub
  # - and port 22 is accessible
  # - Standard_B1s has 1 vCore, 1024M RAM
  az vm create \
    -g my-rg \
    --name vm1 \
    --image ubuntuLTS \
    --size Standard_B1s

  # so you could login to it using
  ssh vm-public-ip
  ```

- Create a VM with specified username and SSH key

  ```sh
  az vm create \
    --resource-group my-rg \
    --name vm1 \
    --admin-username azureuser \
    --image UbuntuLTS \
    --ssh-key-values ~/.ssh/azure_rsa.pub \
    --no-wait
  ```

  *Use `--no-wait` to move on to next command and avoid blocking*

- Create a VM with system assigned identity

  ```sh
  # - enable system assigned managed identity
  # - it would have the 'Contributor' role in the specified scope
  az vm create \
    -g my-rg \
    --name vm1 \
    --image ubuntuLTS \
    --size Standard_B1s \
    --assign-identity '[system]' \
    --scope $principalId
  ```

- List images/VM sizes

  ```sh
  # find vm images by offer, sku, location, publisher
  az vm image list \
    --offer ubuntu \
    --sku lts \
    --location australiaeast \
    --publisher Canonical \
    -otable

  # Offer         Publisher    Sku        Urn                                      UrnAlias    Version
  # ------------  -----------  ---------  ---------------------------------------  ----------  ---------
  # UbuntuServer  Canonical    18.04-LTS  Canonical:UbuntuServer:18.04-LTS:latest  UbuntuLTS   latest

  # list vm sizes, filter by number of cores
  az vm list-sizes \
    --location australiaeast \
    --query '[? numberOfCores==`1`]' \
    -otable
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





## App Service

Fully managed web application hosting platform, PaaS.

### App Service plans

A plan's **size** (aka **sku**, **pricing tier**) determines
  - the performance characteristics of the underlying virtual servers
  - features available to apps in the plan

#### SKUs

| Usage      | Tier                 | Instances | New Features                                  |
| ---------- | -------------------- | --------- | --------------------------------------------- |
| Dev/Test   | Free                 | 1         |                                               |
| Dev/Test   | Shared(Windows only) | 1         | Custom domains                                |
| Dev/Test   | Basic                | <=3       | Custom domains/SSL                            |
| Production | Standard             | <=10      | Staging slots, Daily backups, Traffic Manager |
| Production | Premium              | <=30      | More slots, backups                           |
| Isolated   | Isolated             | <=100     | Isolated network, Internal Load Balancing     |

- **Shared compute**: **Free**, **Shared** and **Basic**, VM shared with other customers
- **Dedicated compute**: only apps in the same plan can share the same compute resources
- **Isolated**: network isolation on top of compute isolation, using App Service Environment(ASE)

Plans are the unit of billing. How much you pay for a plan is determined by the plan size(sku) and bandwidth usage, not the number of apps in the plan.

You can start from an cheaper plan and scale up later.

### Deployment

There are multiple ways to deploy an app:

- Azure DevOps
- GitHub (App Service can setup a GitHub action for you)
- BitBucket
- Local Git: You will be given a remote git url, pushing to it triggers a build.
- OneDrive
- Dropbox
- FTP
- CLI (`az webapp up`)

  Example:

  ```sh
  # get all variables
  APPNAME=$(az webapp list --query [0].name --output tsv)
  APPRG=$(az webapp list --query [0].resourceGroup --output tsv)
  APPPLAN=$(az appservice plan list --query [0].name --output tsv)
  APPSKU=$(az appservice plan list --query [0].sku.name --output tsv)
  APPLOCATION=$(az appservice plan list --query [0].location --output tsv)

  # go to your app directory
  cd ~/helloworld

  # deploy current working directory as an app
  # create a new app if there isn't one
  az webapp up \
    --name $APPNAME \
    --resource-group $APPRG \
    --plan $APPPLAN \
    --sku $APPSKU \
    --location "$APPLOCATION"

  # set as default
  az configure --defaults web=garyapp

  # open the app
  az webapp browse

  # live logs
  az webapp log tail
  ```

If your app is based on a docker container, then there will be a webhook url, which allows you to receive notifications from a docker registry when an image is updated. Then App Service can pull the latest image and restart your app.

If you are using an image from Azure Container Registry, when you enable '**Continuous Deployment**', the webhook is automatically configured in Container Registry.

### Deployment slots

- A slot is a separate instance of your app, has its own hostname
- Each slot shares the resources of the App Service plan
- Only available in the Standard, Premium or Isolated tier
- You can create a new slot by cloning the config of an existing slot, but you can't clone the content, which needs to be deployed

If you app name is `garyapp`, the urls would be like

- production: https://garyapp.azurewebsites.net/
- staging: https://garyapp-staging.azurewebsites.net/


#### Swap

- You can create a **staging** slot, after testing, you can **swap** the staging slot with production slot, this happens instantly without any downtime.
- If you want rollback, swap again.
- App Service warms up the app by sending a request to the root of the site after a swap.
- When swapping two slots, configurations get swapped as well, unless a configuration is '**Deployment slot settings**', then it sticks with the slot (this allows you to config different DB connection strings or `NODE_ENV` for production and staging and make sure they don't swap with the app)
- 'Auto Swap' option is available for Windows.

### Scaling

- Built-in auto scale support
- Scale up/down: increasing/decreasing the resources of the underlying machine
- Scale out: increase the number of machines running your app, each tier has a limit on how many instances can be run

### Node app

If it's node, Azure will run `yarn install` automatically to install packages

You need to make sure the app:

- Is listening on `process.env.PORT`
- Uses `start` in `package.json` to start the app

### App Logs

|            | Windows                                 | Linux            |
| ---------- | --------------------------------------- | ---------------- |
| Log levels | Error, Warning, Information, Verbose    | Error            |
| Storage    | Filesystem, Blob                        | Filesystem       |
| Location   | A virtual drive at `D:\Home\LogFiles`   | Docker log files |
| Options    | Application, IIS server, Detailed Error | STDERR, STDOUT   |

On Linux, you need to open an SSH connection to the Docker container to get messages of underlying processes (such as Apache)

```sh
# tail live logs
az webapp log tail \
  --resource-group my-rg \
  --name my-web-app

# download logs
az webapp log download \
  --log-file logs.zip \
  --resource-group my-rg \
  --name my-web-app
```

### Backup

- You could do a full or partial backup
- Backup goes to a storage account and container in the same subscription
- Backup contains app configuration, files, and database connected to your app

## Static Web Apps

![Static Web Apps overview](images/azure_static-web-apps-overview.png)

When you create a Static Web App, GitHub Actions or Azure DevOps workflow is added in the app's source code repository. It watches a chosen branch, everytime you push commits or create pull requests into the branch, the workflow builds and deploys your app and its API to Azure.

- Globally distributed web hosting
- Integrated API support by Azure Functions (the `/api` route points to it)
  - Locally, you could use the `func` tool to run API functions, it would be on another port, so need CORS configuration, put this in `api/local.settings.json`

    ```json
    {
      "Host": {
        "CORS": "http://localhost:3000"
      }
    }
    ```
  - On Auzre, a reverse proxy would be setup for you automatically, so any call to `/api` is on the same origin, and proxied to the Azure Functions
- Free SSL certificates for custom domains
- Staging envrionment created automatically from pull request

```sh
az staticwebapp create \
    -g $resourceGroupName \
    -n $webAppName \
    -l 'westus2'
    -s $appRepository \       # repo
    -b main \                 # branch
    --token $githubToken      # github PAT token
```

This
  - adds a workflow file in the GitHub repo
  - a token for the staticwebapp is added to GitHub secrets
  - A staging environment is automatically created when a pull request is generated,
  - and are promoted into production once the pull request is merged.



```yaml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_GREEN_GLACIER_0BAB5B71E }}
          repo_token: ${{ secrets.GITHUB_TOKEN }} # this is auto-generated, used for Github integrations (i.e. PR comments)
          action: "upload"
          app_location: "."         # App source code path
          output_location: "dist"   # Optional: build artifacts path, relative to app_location
          api_location: "api"       # Optional: API source path, relative to root

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_GREEN_GLACIER_0BAB5B71E }}
          action: "close"
```

Notes:

  - When you close the pull request, it actually triggers 2 workflow runs, each runs a single job:
    - one for the PR closing action, the `close_pull_request_job` closes the staging environment
    - the `main` branch is updated as well, so the `build_and_deploy_job` updates the live environment

  - *When you create an app in the Azure Portal, you specify the build presets (such as, React, Vue, Gatsby etc), and the `app_location`, `api_location`, `output_location`, so your app would be automatically built and uploaded by GitHub Actions*

  - Here is an example of live and staging URLs:

    | Source          | Description                | URL                                                   |
    | --------------- | -------------------------- | ----------------------------------------------------- |
    | main branch     | Live web site URL (global) | https://my-app-23141.azurestaticapps.net/             |
    | Pull Request #3 | Staging URL (one region)   | https://my-app-23141-3.centralus.azurestaticapps.net/ |

  - For a static web app, you likely need to respond all routes with `index.html`, you need a `staticwebapp.config.json` file in the build output directory for this:

    ```json
    // fall back to `index.html`
    {
      "navigationFallback": {
        "rewrite": "index.html",
        "exclude": ["/images/*.{png,jpg,gif,ico}", "/*.{css,scss,js}"]
      }
    }
    ```


## Docker Container Registry

Like Docker Hub

Unique benefits:

- Runs in Azure, the registry can be replicated to store images where they're likely to be deployed
- Highly scalable, enhanced thoroughput for Docker pulls

```sh
# create a registry
az acr create --name garyrepo --resource-group mygroup --sku standard --admin-enabled true

# instead of building locally and pushing to it
# you can also let the registry build an image for you
# just like 'docker build'
az acr build --file Dockerfile --registry garyrepo --image myimage .

# you can enable 'Admin user' for the registry
# then you can login from your local machine
docker login -u garyrepo garyrepo.azurecr.io

# pull an image
docker pull garyrepo.azurecr.io/myimage:latest
```

### Tasks feature

You can use the tasks feature to rebuild your image whenever its source code changes.

```sh
# `--name` here is the task name, not image name
az acr task create
  --name buildwebapp \
  --registry <container_registry_name> \
  --image webimage \
  --context https://github.com/MicrosoftDocs/mslearn-deploy-run-container-app-service.git --branch master \
  --file Dockerfile \
  --git-access-token <access_token>
```

The above command creates a task `buildwebapp`, creates a webhook in the GitHub repo using an access token, this webhook triggers image rebuild in ACR when repo changes.

### Authentication options

| Method                               | How                                                                                                   | Scenarios                                                                                                                                | RBAC                            | Limitations                                                     |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | --------------------------------------------------------------- |
| Individual AD identity               | `az acr login`                                                                                        | interactive push/pull by dev/testers                                                                                                     | Yes                             | AD token must be renewed every 3 hours                          |
| Admin user                           | `docker login`                                                                                        | interactive push/pull by individual dev/tester                                                                                           | No, always pull and push access | Single account per registry, not recommended for multiple users |
| Integrate with AKS                   | Attach registry when AKS cluster created or updated                                                   | Unattended pull to AKS cluster                                                                                                           | No, pull access only            | Only for AKS cluster                                            |
| Managed identity for Azure resources | `docker login` / `az acr login`                                                                       | Unattended push from Azure CI/CD, Unattended pull to Azure services                                                                      | Yes                             | Only for Azure services that support managed identities         |
| AD service principal                 | `docker login` / `az acr login` / Registry login settings in APIs or tooling / Kubernetes pull secret | Unattended push from CI/CD, Unattended pull to Azure or external services                                                                | Yes                             | SP password default expiry is 1 year                            |
| Repository-scoped access token       | `docker login` / `az acr login`                                                                       | Interactive push/pull to repository by individual dev/tester, Unattended push/pull to repository by individual system or external device | Yes                             | Not integrated with AD                                          |


#### Individual AD identity

```sh
az acr login --name <acrName>
```

- The CLI uses the token created when you executed `az login` to seamlessly authenticate your session with your registry;
- Docker CLI and daemon must by running in your env;
- `az acr login` uses the Docker client to set an Azure AD token in the `docker.config` file;
- Once logged in, your credentials are cached, valid for 3 hours;

If Docker daemon isn't running in your env, use `--expose-token` parameter

```sh
# expose an access token
az acr login -name <acrName> --expose-token
# {
#   "accessToken": "eyJhbGciOiJSUzI1NiIs[...]24V7wA",
#   "loginServer": "myregistry.azurecr.io"
# }

# use a special username and accessToken as password to login
docker login myregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password eyJhbGciOiJSUzI1NiIs[...]24V7wA
```


#### Service principal

Best suited for **headless scenarios**, that is, any application/service/script that must push or pull container images in an automated manner.

Create a service principal with the following script, which output an ID and password (also called *client ID* and *client secret*)

*Note that this principal's scope is limited to a specific registry*

```sh
#!/bin/bash

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
ACR_NAME=<container-registry-name>
SERVICE_PRINCIPAL_NAME=acr-service-principal

# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show \
                    --name $ACR_NAME \
                    --query id \
                    --output tsv)

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
SP_PASSWD=$(az ad sp create-for-rbac \
              --name $SERVICE_PRINCIPAL_NAME \
              --scopes $ACR_REGISTRY_ID \
              --role acrpull \
              --query password \
              --output tsv)

SP_APP_ID=$(az ad sp list \
              --display-name $SERVICE_PRINCIPAL_NAME \
              --query '[].appId' \
              --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
```

For existing principal

```sh
#!/bin/bash

ACR_NAME=mycontainerregistry
SERVICE_PRINCIPAL_ID=<service-principal-ID>

ACR_REGISTRY_ID=$(az acr show \
                    --name $ACR_NAME \
                    --query id \
                    --output tsv)

# Assign the desired role to the service principal. Modify the '--role' argument
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_ID \
  --scope $ACR_REGISTRY_ID \
  --role acrpull
```

Then you can

- Use with docker login

  ```sh
  # Log in to Docker with service principal credentials
  docker login myregistry.azurecr.io \
    --username $SP_APP_ID \
    --password $SP_PASSWD
  ```

- Use with certificate

  ```sh
  # login with service principal certificate file (which includes the private key)
  az login --service-principal
    --username $SP_APP_ID \
    --tenant $SP_TENANT_ID \
    --password /path/to/cert/pem/file

  # then authenticate with the registry
  az acr login --name myregistry
  ```

### Replication

A registry can be replicated to multiple regions, this allows for
- Network-close registry access
- No additional egress fees, as images are pulled from the same region as your container host

```sh
az acr replication create --registry $ACR_NAME --location japaneast
az acr replication list --registry $ACR_NAME --output table
```


## Container Instance

- Fit for executing run-once tasks like image rendering or building/testing applications;
- Billed by seconds;

Some options:

- `--restart-policy` one of 'Always', 'Never' or 'OnFailure'
- `--environment-variables`: environment variables
- `--secure-environment-variables`: secure environment variables


```sh
az container create \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer \
  --image microsoft/aci-helloworld \
  --ports 80 \
  --dns-name-label $DNS_NAME_LABEL \
  --location eastus

# OR
# create a container instance using an image from ACR
# you need to provide registry url/username/password
az container create \
    --resource-group learn-deploy-acr-rg \
    --name acr-tasks \
    --image $ACR_NAME.azurecr.io/helloacrtasks:v1 \
    --ip-address Public \
    --location <location> \
    --registry-login-server $ACR_NAME.azurecr.io \
    --registry-username [username] \
    --registry-password [password]

# get ip/domain name/state of a container
az container show \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer \
  --query "{IP:ipAddress.ip,FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" \
  --out table

# IP            FQDN                                     ProvisioningState
# ------------  ---------------------------------------  -------------------
# 40.71.238.13  aci-demo-12631.eastus.azurecontainer.io  Succeeded

# get container logs
az container logs \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer-restart-demo
```

### Container groups

![Container groups](images/azure_container-groups.png)

- Top-level resource in ACI
- Similar to a pod in K8s, containers in a group share a lifecycle, resources, local network and storage volumes
- Could be deployed using ARM teamplates(recommended when additional Azure resources are needed) or a YAML file
- Share an external-facing IP address, a FQDN
- Common scenarios:
  - An app container with a logging/monitoring container
  - A front-end container with a back-end container

## Azure Functions

Benefits:

- Auto scaling, pay for what you use
- No need to manage servers
- Stateless logic
- Event driven

Drawbacks:

- Execution time limits (5 ~ 10min)
- Execution frequency (if need to be run continuously, may be cheaper to use a VM)

Triggers:

- Timer
- HTTP
- Blob (file uploaded/updated)
- Queue messages
- Cosmos DB (a document changes in a collection)
- Event Hub (receives a new event)

Bindings:

- A declarative way to connect to data (so you don't need to write the connection logic)
- Input bindings and output bindings
- Triggers are special types of input bindings
- Configured in a JSON file _function.json_

Example:

![Azure Functions bindings flow](./images/azure-functions_bindings_example.png)

Pass in an `id` and `url` from a HTTP request, if a bookmark with the id does not already exist, add to DB and push to a queue for further processing

`function.json`

```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    },
    {
      "name": "bookmark",
      "direction": "in",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "id": "{id}",
      "partitionKey": "{id}"
    },
    {
      "name": "newbookmark",
      "direction": "out",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "partitionKey": "{id}"
    },
    {
      "name": "newmessage",
      "direction": "out",
      "type": "queue",
      "queueName": "bookmarks-post-process",
      "connection": "storageaccountlearna8ff_STORAGE"
    }
  ]
}
```

`index.js`

```js
module.exports = function (context, req) {
  var bookmark = context.bindings.bookmark;
  if (bookmark) {
    context.res = {
      status: 422,
      body: 'Bookmark already exists.',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  } else {
    // Create a JSON string of our bookmark.
    var bookmarkString = JSON.stringify({
      id: req.body.id,
      url: req.body.url
    });

    // Write this bookmark to our database.
    context.bindings.newbookmark = bookmarkString;
    // Push this bookmark onto our queue for further processing.
    context.bindings.newmessage = bookmarkString;
    // Tell the user all is well.
    context.res = {
      status: 200,
      body: 'bookmark added!',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  }
  context.done();
};
```

- `id` in `req` will be available as `id` to the `cosmosDB` binding;
- If `id` is found in the DB, `bookmark` will be set;
- `"connectionStringSetting": "gary-cosmos_DOCUMENTDB"` is an application setting in app scope, not restricted to current function, available to the function as an env variable;
- Simply assign a value to `newbookmark` and `newmessage` for output

### Durable functions

![Durable function patterns](./images/azure-durable_function_workflow_patterns.png)

There are three different functions types, the table below show how to use them in the human interactions workflow:

| Workflow function                    | Durable Function Type             |
| ------------------------------------ | --------------------------------- |
| Submitting a project design proposal | Client Function (trigger)         |
| Assign an Approval task              | Orchestration Function (workflow) |
| Approval task                        | Activity Function                 |
| Escalation task                      | Activity Function                 |

- You need to run `npm install durable-functions` from the `wwwroot` folder of your function app in Kudu
