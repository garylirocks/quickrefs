# Azure Compute

- [VMs](#vms)
  - [Considerations](#considerations)
  - [Series](#series)
  - [Availability options](#availability-options)
  - [Provisioning](#provisioning)
  - [Use AAD for VM authentication](#use-aad-for-vm-authentication)
  - [Linux Agent](#linux-agent)
  - [Windows VM Agent](#windows-vm-agent)
  - [How to connect to Internet](#how-to-connect-to-internet)
  - [Updating](#updating)
  - [CLI Cheatsheet](#cli-cheatsheet)
- [Disks](#disks)
  - [Overview](#overview)
  - [Host caching](#host-caching)
  - [VM IOPS/MBps limit](#vm-iopsmbps-limit)
  - [Performance troubleshooting](#performance-troubleshooting)
  - [Bursting](#bursting)
    - [Disk bursting](#disk-bursting)
    - [VM-level bursting](#vm-level-bursting)
  - [Behind the scenes](#behind-the-scenes)
  - [Shared disk](#shared-disk)
  - [Initialize data disks](#initialize-data-disks)
    - [Linux](#linux)
    - [Windows](#windows)
  - [Disk encryption](#disk-encryption)
    - [ADE](#ade)
- [VMSS - Virtual Machine Scale Sets](#vmss---virtual-machine-scale-sets)
- [Run Commands](#run-commands)
- [Azure Bastion](#azure-bastion)
- [Azure Batch](#azure-batch)
- [Azure Compute Gallery](#azure-compute-gallery)
- [Docker Container Registry](#docker-container-registry)
  - [Tasks feature](#tasks-feature)
  - [Authentication options](#authentication-options)
    - [Individual AD identity](#individual-ad-identity)
    - [Service principal](#service-principal)
  - [Replication](#replication)
- [Container Instance](#container-instance)
  - [Container groups](#container-groups)

## VMs

### Considerations

Checklist for creating VMs

- Network (vNets)
  - Decide network address space;
  - Break network into sections, e.g. 10.1.0.0 for VMs, 10.2.0.0 for SQL Server VMs;
  - Network security groups (NSG)

- Name
  - Used as the computer name
  - Also defines a manageable Azure resource, not trivial to change later (it could get applied to the associated disks, VNets, network interface, NSGs, public IPs, if those are created along with the VM)
  - A good example `dev-usc-web01` includes environment, location, role and instance of this VM

- Location
  - Consider proximity, compliance, price

- Size
  - Metrics to consider
    - vCPU
    - Memory
    - Temp Storage size
    - Max temp disk IOPS/throughput
    - Max data disks
    - Max data disk IOPS/throughput
    - Max NICs/Network bandwidth

  - Based on workload
    - General purpose: ideal for testing and dev, small to medium DBs, low to medium traffic web servers
    - Compute optimized: medium traffic web servers, network appliances, batch processes, and application servers
    - Memory optimized: DBs, caches, in-memory analytics
    - Storage optimized: DBs
    - GPU: graphics rendering and video editing
    - High performance compute
  - Sizes can be changed

- Costs
  - Compute
    - Billed on per-minute basis
    - Two payment options:
      - Pay as you go
      - Reserved VM instances (with hugh discounts)
    - Linux VMs are cheaper than Windows which includes license charges
    - Two stopped status:
      - **Stopped**: by `az vm stop`, or **shutdown from within the guest OS**, you are still being charged for the compute resources
      - **Stopped (deallocated)**: by `az vm deallocate`, or **"Stop" from the Portal**, compute resources are released, you will not be charged for compute (still paying the related disk storage, etc)

  - Storage for disks are charged separately from VM, you will be charged for storage used by the disks even if the VM were deallocated

- Storage

  - Each VM can have three types of disk:
    - **OS disk** (`/dev/sda` on Linux),
    - **Temporary disk**, is a short-term storage (`D:` on Windows, `/mnt` on Linux, page files, swap files), **local to the server, NOT in a storage account**
    - **Data disk**, for database files, website static content, app code, etc
  - Disks are actually VHDs files (page blobs) in Azure Storage account, two options for managing the relationship between disks and storage accounts:
    - **managed disks**: newer and recommended, you only need to specify the type (Ultra/Premium/Standard SSD, Standard HDD) and size, only show the disks, hide the underlying storage account and page blobs
    - **unmanaged disks**: expose the underlying storage accounts and page blobs, an account is capable of supporting 40 standard VHDs, it's hard to scale out, you need to take care IOPS limit, etc

- OS
  - Multiple versions of Windows and Linux
  - Marketplace has VM images which include popular tech stacks
  - You can create your disk image and upload to Azure storage and use it to create a VM


### Series

- A: entry-level for dev/test
- B: economical, burstable (on accumulated CPU credits)
- D: general purpose
- E:
  - optimized for in-memory applications, high memory-to-core ratios
  - SAP HANA
- F:
  - compute optimized
  - batch processing, web servers, analytics, gaming
- G:
  - memory and storage optimized
  - large SQL/NoSQL DBs, ERP, SAP
- H:
  - high performance computing
- Ls
  - Storaged optimized
- M
  - memory optimized
- M2
  - largest memory optimized
- N
  - GPU enabled
  - simulation, deep learning, redendring, video editing, gaming

Example:

`D4as_v4`, D Series, 4 vCPUs, `a` for AMD-based processor, `s` for premium storage support, `v4` is the version

See naming convention here: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions


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
  - Cloud-init files use YAML format, the following example installs the package `python-pip` and `numpy`


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

### Use AAD for VM authentication

*Works on both Windows and Linux*

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

### Windows VM Agent

- Manages VM interation with Azure fabric controller
- Provides the ability to **enable and execute VM extensions**, which can
  - Enable VM post-deployment configuration of VMs, such as installing and configuring software
  - Enable recovery features such as resetting the admin password of a VM
- The agent requires:
  - access to `168.63.129.16`
  - DHCP enabled inside the guest VM
- Has two parts
  - Azure Windows Provisioning Agent (PA) - must be installed to boot a VM
  - Azure Windows Guest Agent (WinGA) - required by Azure Backup and Azure Security
- Installed by default for any Marketplace image, `WinGA` could be opted-out with `osProfile.WindowsConfiguration.ProvisionVmAgent` property
- Could be installed manually
- `WindowsAzureGuestAgent.exe` is the process in the guest VM
- It spawns `CollectGuestLogs.exe`, which collects some logs, produces a ZIP file that's transferred to the VM's host. Support professionals could use this ZIP file to investigate issues on the request of the VM owner.

### How to connect to Internet

There are a few ways how a VM can connect to the Internet:

- An explicit **public IP** assigned to its NIC
- Via a **public standard load balancer** (it's recommended to use separate public IPs for inbound and outbound connections)
- A **NAT gateway** linked to the VM's subnet
  - It's designed for egress traffic
  - Each NAT GW can have max 16 public IPs (separate or contiguous as a IP prefix), ~64,000 SNAT ports/IP
  - Only handles egress traffic, ingress traffic still come through the VM's public IP or public load balancer
  - Cons: not zone-redundant, you need one for each zone
- **Azure Firewall**
  - Max 250 public IPs, 2496 ports/IP
  - You can link a NAT GW to th Azure Firewall subnet to help scale SNAT ports
- **NVA**
  - Use UDR on the VM's subnet to route traffic to the NVA
- Implicit pubic IP
  - Going to be retired
  - Could be disabled now by setting `defaultOutboundAccess = false` while creating a subnet


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

- List images

  ```sh
  # find available vm images in a region
  az vm image list --location australiaeast -otable

  # Offer         Publisher    Sku        Urn                                      UrnAlias    Version
  # ------------  -----------  ---------  ---------------------------------------  ----------  ---------
  # UbuntuServer  Canonical    18.04-LTS  Canonical:UbuntuServer:18.04-LTS:latest  UbuntuLTS   latest
  ```

- List VM sizes

  ```sh
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

- Accept the legal terms of a Marketplace image

  - In the Portal, you will see the terms at the last step when you create a VM
  - You can also find the offering is enabled in "Programmatic deployment" blade of the subscription
  - Could be created with Terraform resource `azurerm_marketplace_agreement`

  ```sh
  az vm image terms accept \
    --publisher redhat \
    --offer rhel-byos \
    --plan rhel-lvm75
  ```

- Run Command in a VM

  ```sh
  az vm run-command invoke \
    -g rg-test \
    -n vm-test-001 \
    --command-id RunShellScript \
    --scripts "date"
  ```


## Disks

### Overview

Performance metrics:

- Capacity
  - Size in unit of MiB (Mebibyte), GiB (Gibibyte), TiB (Tebibyte) - power of 1024 instead of 1000, `1MiB == 1024 x 1024 Byte`, `1MB == 1000 x 1000 Byte`
- IOPS
- Throughput (IOPS x size per operation)
- Latency

Performance considerations:

- Disk type
- Performance tier
- Bursting
- Performance plus
- VM IOPS/throughput limit
- Host caching

Types:

|              | IOPS, MB/s                   | Bursting                                              | Performance plus | Shareable | For                  | Limit                                                                                                                         |
| ------------ | ---------------------------- | ----------------------------------------------------- | ---------------- | --------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Ultra disk   | customizable                 | N                                                     | N                | Y         |                      |                                                                                                                               |
| Premium SSD  | customizable                 | Credit-based (<=512GiB)<br />or On-demand (>=1024GiB) | >=513GiB         | Y         | production workloads | Can only be attached to specific VM sizes (designated by the `s` feature flag in the VM size, eg. `D2s_v3`, `Standard F2s_v2` |
| Standard SSD | IOPS/throughput tied to size | Y (<=1024GiB)                                         | >=513GiB         | Y         |                      |                                                                                                                               |
| Standard HDD | tied to size                 | N                                                     | >=513GiB         | N         | dev/test             |                                                                                                                               |

- Local SSD (temporary disk)
  - The temporary disk of each VM, size depending on the size of the VM;
  - No extra charge, already included in the VM cost;
  - Local to the VM, performance is high;
  - Data could be lost during a maintenance or redeployment of the VM;
  - Suitable for temporary data storage, eg. page or swap file, tempdb for SQL Server;

Operations:

- Data disk could be detached/attached without stopping the VM
- You could **increase** the disk size
  - You could increase size of an attached disk, either below 4TiB, or above it
  - To increase the size from < 4TiB to > 4TiB, you need to detach it the disk or stop the VM first, this is because the page blob needs to be copied to another storage account if the size goes over 4TiB
- To shrink the size, you need to create a new disk and copy the data over

### Host caching

![Host caching](images/azure_vm-host-caching.drawio.svg)

- Called BlobCache, uses a combination of the host RAM and local SSD
- Available for Premium Storage persistent disks and VM local disks
- Default caching setting:
  - `Read/Write` for OS disks
  - `ReadOnly` for data disks
- Suggested cache setting:
  | Cache     | When to use                                                                                                             |
  | --------- | ----------------------------------------------------------------------------------------------------------------------- |
  | None      | write-only / write-heavy, eg. disks for SQL Server log files                                                            |
  | ReadOnly  | read-only / read-write, eg. disks for SQL Server data files                                                             |
  | ReadWrite | only if your app properly handles writing cached data to persistent disks <br />(eg. SQL Server can do this on its own) |

Limitations:

- NOT supported for disks >= 4TiB (4096GiB, not 4000GiB)
- Changing cache settings will **detach and re-attach** the target disk. If it is OS disk, the VM is **restarted**
- Using `ReadWrite` cache with an application that does not handle persisting the required data can lead to data loss, if the VM crashes.

### VM IOPS/MBps limit

- Each VM size has its own IOPS and throughput limits
- Each disk has its own IOPS and throughput limits as well

So the disk IO performance could be **capped** by limit on either the VM or disk.

For VMs that are enabled for both premium storage and premium storage caching, there are two different storage bandwith limits.

- ***uncached***, when caching is not enabled, only operation to the disk is counted
- ***cached***, a separate limit on top of the *uncached* limit, only operation to the cache is counted

| Size            | vCPU | Temp storage (SSD) GiB | Max data disks | Max cached and temp storage throughput: IOPS/MBps (cache size in GiB) | Max burst cached and temp storage throughput: IOPS/MBps2 | Max uncached disk throughput: IOPS/MBps | Max burst uncached disk throughput: IOPS/MBps1 | Max NICs/ Expected network bandwidth (Mbps) |
| --------------- | ---- | ---------------------- | -------------- | --------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------- | ---------------------------------------------- | ------------------------------------------- |
| Standard_D8s_v3 | 8    | 64                     | 16             | 16000/128 (200)                                                       | 16000/400                                                | 12800/192                               | 16000/400                                      | 4/4000                                      |

* This is **VM level bursting** (not disk bursting), could last up to 30 minutes at a time

Example:

- Standard_D8s_v3
  - Cached IOPS: 16,000
  - Uncached IOPS: 12,800
- P30 OS disk
  - IOPS: 5,000
  - Host caching: Read/write
- Two P30 data disks × 2
  - IOPS: 5,000
  - Host caching: Read/write
- Two P30 data disks × 2
  - IOPS: 5,000
  - Host caching: Disabled

The cached and uncached limits (16,000 and 12,800) could be combined to achieve 25,000 IOPS

![Combined IOPS](images/azure_disk-caching-combined-IOPS.jpg)

### Performance troubleshooting

- Check metrics like: "Data Disk Bandwidth Consumed Percentage", "VM uncached IOPS Consumed Percentage"
- Benchmark tools: https://learn.microsoft.com/en-us/azure/virtual-machines/disks-benchmarks
- Troubleshooting example: https://learn.microsoft.com/en-us/azure/virtual-machines/disks-metrics#storage-io-metrics-example

### Bursting

- Helps in scenarios like:
  - VM startup
  - Traffic spikes
  - Batch jobs, eg. month-end reconciling job
- There are disk bursing and VM bursting, they should match each other to achieve best performance
- Azure provides various bursting metrics, like "Data Disk Used Burst IO Credits Percentage", "VM Uncached Used Burst BPS Credits Percentage", emitted every 5 minutes

#### Disk bursting

- Only for certain sizes of Standard/Premium SSD
- No bursting for Standard HDD, or Ultra

|                 | P20 and below                    | P30 and up                                 |
| --------------- | -------------------------------- | ------------------------------------------ |
| How             | Enabled by default, credit-based | Manual enable per disk                     |
| Max-Performance | Up to 3,500 IOPS and 170MB/s     | Up to 30,000 IOPS and 1000MB/s             |
| Duration        | up to 30min at a time (per day?) | No limit                                   |
| Pricing         | Free                             | Enablement fee and pay per additional IOPS |

#### VM-level bursting

- Enabled by default for most Premium Storage supported VM sizes
- Always credit-based
- Could last up to 30 minutes (per day? seems it can burst whenever there is credit in the bucket)
- Credits are accrued according to the amount of unused IO or MB/s below the provisioned target

![Bursting graph](images/azure_disk-performance-bursting-graph.png)

*Performance drop when burstring credits used up*

<img src="images/azure_disk-bursting-bucket-diagram.jpg" width="600" alt="Bursting bucket" />

*Bursing bucket gets refilled whenever usage is lower than provisioned capacity*

### Behind the scenes

A managed disk is actually an abstraction over a page blob, when you attach it to a VM, a lease is put on the blob.

Grant/Revoke an SAS token of the blob (this put a lease on it as well, so can only do it on an unattached disk):

```sh
Grant-AzDiskAccess -ResourceGroupName 'rg-demo-001' `
                   -Name 'disk-demo-001' `
                   -DurationInSecond 60 `
                   -Access Read

Revoke-AzDiskAccess -ResourceGroupName 'rg-demo-001' `
                    -Name 'disk-demo-001'
```

### Shared disk

Some disks could be attached to multiple VMs at the same time, this could be useful in a failover cluster.

- Limited to ultra disks, premium SSD v2 managed disks, premium SSD managed disks, and standard SSDs
- A shared disk can't be expanded without either deallocating VM or detaching the disk
- Have a `maxShares` limit depending on the disk size
- The VMs using the disk need to be in the same proximity group

### Initialize data disks

Any new disks you attach to a VM need to be initialized and formatted.

#### Linux

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

#### Windows

Use the Disk Management tool

### Disk encryption

Types of encryption:

- **Azure Storage Service Encryption** (SSE, also known as Server-Side Encryption, encryption-at-rest)
- **Azure Disk Encryption** (ADE)
- **Encryption at host**
  - Disk with this aren't encrypted with SSE
  - Instead, the server hosting your VM encrypts your data, then flows into Storage.
  - Your temp disk and OS/data disk caches are stored on the host
  - Does not use your VM's CPU and no impact on your VM's performance
  - Your must enable this feature for your subscription first: `Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"`
- Confidential disk encryption:
  - Encryption keys bound to the VM's TPM
  - Only available for the OS disk

Comparison:

|                    | SSE                                                                         | ADE                                                     |
| ------------------ | --------------------------------------------------------------------------- | ------------------------------------------------------- |
| Algorithm          | 256-bit AES                                                                 | 256-bit AES                                             |
| What               | OS/data disks                                                               | OS/data/temp disks, caches                              |
| Encrypt/Decrypt by | Azure Storage (performed on physical disks, flow decrypted from/to Storage) | VM CPU                                                  |
| Who can access     |                                                                             | Disk image only accessible to the VM that owns the disk |
| How                | Enabled by default for Azure managed disks, can't be disabled               | BitLocker on Windows, DM-Crypt on Linux                 |
| Managed by         | Storage account admin                                                       | VM owner                                                |
| Key management     | PMK or CMK (Key Vault)                                                      | Key Vault                                               |
| Performance        | no noticeable impact                                                        | typically negligible*                                   |

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

Limitations:

- The encryption key must be in a key vault in the **same region** and subscription
- Not available on Basic, A-series VMs
- On some Linux distros, only data disks can be encrypted
- On Windows, only NTFS format disks can be encrypted
- When adding a new disk to an encrypted VM, it's NOT encrypted automatically, it needs to be properly partitioned, formatted, and mounted before encryption
- When enabling encryption on new VMs, you could use an ARM template to ensure data is encrypted at the point of deployment
- ADE is required for VMs backed up to the Recovery Vault
- **SSE with CMK improves on ADE** by enabling you to use any OS types and images for your VMs

Networking requirements:
- To get a token to connect to your key vault, the Windows VM must be able to connect to a Microsoft Entra endpoint, `login.microsoftonline.com`
- To write the encryption keys to your key vault, the Windows VM must be able to connect to the key vault endpoint.
- The Windows VM must be able to connect to an Azure storage endpoint that hosts the Azure extension repository and an Azure storage account that hosts the VHD files.


## VMSS - Virtual Machine Scale Sets

- All instances are created from the same base OS image and configuration.
- Support Load Balancer for layer-4 traffic distribution, and Application Gateway for layer-7 traffic distribution and SSL termination.
- Number of instances can automatically increase or decrease in response to demand or a defined schedule.
- You could use your own custom VM images.
- It has instance repair feature which replaces a VM if it health check fails.


## Run Commands

Two types of commands,

- Action RunCommand
  - The original run command
  - It's a POST action
  - Suitable for one-off actions
  - Run as system account / root
- Managed RunCommand
  - This is the updated run command
  - It's a resource type
  - Run as specified user
  - Multiple scripts could be run in parallel or sequenced
  - Output could be uploaded to an append blob
  - Supports long running (hours/days) scripts
  - Passing secrets (parameters, passwords) in a secure manner
  - Scripts can be published to a gallery


## Azure Bastion

![Bastion architecture](images/azure_bastion-architecture.png)

- You access VMs via Azure Portal
- A bastion can connect to VM in the same or peered vNets
- No need to configure NSGs on `AzureBastionSubnet`


## Azure Batch

Large-scale job scheduling for HPC (High Performance Compute) workload


## Azure Compute Gallery

Organization:

- Gallery: `Microsoft.Compute/galleries`
  - could be either shared with community or not
- Image: `Microsoft.Compute/galleries/images`
  - `osType`: Windows or Linux
  - `osState`: Generalized or Specified
  - `identifier` -> `publisher`, `offer`, `sku`
  - `architecture`, `hyperVGeneration`
  - Recommended vCPUs, memory, disk
- Image Version: `Microsoft.Compute/galleries/images/versions`
  - Replica count in target regions
  - `endOfLifeDate`
  - `StorageAccountType`

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
