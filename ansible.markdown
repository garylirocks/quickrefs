Ansible
=========

- [Overview](#overview)
- [Commands](#commands)
- [Inventory](#inventory)
- [Playbook](#playbook)
- [Tasks](#tasks)
- [Variables](#variables)
- [Loops](#loops)
- [Testing](#testing)
- [Roles](#roles)
  - [Example](#example)
- [Collections](#collections)
- [Secrets](#secrets)
  - [File-level encryption](#file-level-encryption)
  - [Variable-level encryption](#variable-level-encryption)
- [Configs](#configs)
- [Work with Azure](#work-with-azure)
  - [Install az collection](#install-az-collection)
  - [Azure credentials](#azure-credentials)
  - [Run](#run)
- [Work with Windows hosts](#work-with-windows-hosts)
  - [Setup Windows remote hosts](#setup-windows-remote-hosts)
  - [Connect](#connect)

## Overview

- Sponsored by Red Hat
- Automates cloud provisioning, configuration management and application deployments
- Agentless, but nodes and the control machine needs Python
- Connect to each node through SSH (WinRM for Windows)
- Idempotent

## Commands

- `ansible` run ad-hoc tasks
- `ansible-inventory` list hosts
- `ansible-playbook` run playbooks

## Inventory

The *inventory* is a file that defines the hosts upon which the tasks in a playbook operate.

- Static inventory

  ```yaml
  hosts:
    vm1:
      ansible_host: 13.79.22.89
    vm2:
      ansible_host: 40.87.135.194
  ```

- Dynamic inventory, see https://docs.ansible.com/ansible/latest/collections/azure/azcollection/azure_rm_inventory.html

  ```yaml
  plugin: azure_rm
  include_vm_resource_groups:
    - learn-ansible-rg
  auth_source: auto
  keyed_groups:
    # places each host in a group named 'tag_(tag name)_(tag value)' for each tag on a VM.
    - prefix: tag
      key: tags

  # adds variables to each host found by this inventory plugin
  hostvar_expressions:
    my_host_var:
    # A statically-valued expression has to be both single and double-quoted, or use escaped quotes, since the outer
    # layer of quotes will be consumed by YAML. Without the second set of quotes, it interprets 'staticvalue' as a
    # variable instead of a string literal.
    some_statically_valued_var: "'staticvalue'"
    # overrides the default ansible_host value with a custom Jinja2 expression, in this case, the first DNS hostname, or
    # if none are found, the first public IP address.
    ansible_host: (public_dns_hostnames + public_ipv4_addresses) | first
  ```

  - *the file name needs to end with `azure_rm.(yml|yaml)’`*
  - Uses Azure CLI for auth by default

  Verify that Ansible can discover your inventory

  ```sh
  ansible-inventory --inventory azure_rm.yml --graph

  # @all:
  # |--@tag_env_dev:
  # |  |--vm_dev_1
  # |  |--vm_dev_2
  # |--@tag_env_prod:
  # |  |--vm_prod_1
  # |  |--vm_prod_2
  # |--@ungrouped:
  ```

  You can use `ping` module to verify that Ansible can connect to each VM and Python is correctly installed on each node. (*`ping` actually connects over SSH, not ICMP as the name suggests*)

  ```sh
  # ping a specified group
  ansible \
    --inventory azure_rm.yml \
    --user azureuser \
    --private-key ~/.ssh/ansible_rsa \
    --module-name ping \
    tag_Ansible_mslearn
  ```

## Playbook

Here is an example playbook that configures service accounts

```yaml
# playbook.yml
---
- hosts: all
  become: yes                   # apply with `sudo` privilege
  tasks:
    - name: Add service accounts
      user:                     # 'user' module
        name: "{{ item }}"
        comment: service account
        create_home: no
        shell: /usr/sbin/nologin
        state: present
      loop:   # looping
        - testuser1
        - testuser2
```

Run the playbook

```sh
ansible-playbook \
  --inventory azure_rm.yml \
  --user azureuser \
  --private-key ~/.ssh/ansible_rsa \
  playbook.yml
```

Verify by running a command on each host

```sh
ansible \
  --inventory azure_rm.yml \
  --user azureuser \
  --private-key ~/.ssh/ansible_rsa \
  --args "/usr/bin/getent passwd testuser1" \
  tag_Ansible_mslearn
```

Example modules:

```yaml
---
- hosts: demoGroup
  become: true

  tasks:
    - name: Ping
      ping:                  # 'ping' module, no arguments required

    - name: Install nginx
      apt:                   # 'apt' module, install a package
        name: nginx
        state: present

    - name: Find nginx configs
      find:                 # 'find' module, find files
        path: /etc/nginx/conf.d/
        file_type: file

    - name: Ensure Nginx is running
      service:              # 'service' module
        name: nginx
        state: started
```

## Tasks

There are many ways to filter tasks, by tags, by conditions, etc

```yaml
---
  ...
  tasks:
    - name: Install nginx
      apt:                   # 'apt' module, install a package
        name: nginx
        state: present
      tag: nginx

    - name: Find nginx configs
      find:                 # 'find' module, find files
        path: /etc/nginx/conf.d/
        file_type: file
      tag: config

    - name: Ensure Nginx is running
      service:              # 'service' module
        name: nginx
        state: started
      tag: nginx-start
```

```sh
# list available tags in a playbook
ansible-playbook playbook.yml --list-tags

# run tasks tagged 'nginx'
ansible-playbook playbook.yml --tags nginx

# skip tags
ansible-playbook playbook.yml --skip-tags nginx

# start from a task
ansible-playbook playbook.yml --start-at-task 'Find nginx configs'

# run tasks one-by-one
ansible-playbook playbook.yml --step
```

Task conditions using `when`:

```yaml
tasks:
  - name: Upgrade in Redhat
    when: ansible_os_family == "Redhat"
    yum: name=* state=latest

  - name: Upgrade in Debian
    when: ansible_os_family == "Debian"
    apt: upgrade=dist update_cache=yes
```

## Variables

Define variables in inventory files

```ini
[my-hosts]
vm1
vm2
vm3
vm4

[webservers]
vm1
vm2

# variables for 'all'
[all:vars]
temp_file=/tmp/temp1

# variables for 'webserver'
[webservers:vars]
temp_file=/tmp/temp2
```

Use variables in playbooks

```yaml
- hosts: webservers

  tasks:
    - name: Create a file
      file:
        dest: '{{temp_file}}'
        state: '{{file_state}}'
      when: temp_file is defined
```

You can also pass in a variable in command line

```sh
ansible-playbook demo.yml -e file_state=touch
```

## Loops

```yaml
- hosts: localhost
  vars:
    fruits: [apple,orange,banana]

  tasks:
    - name: Show fruits
      debug:
        msg: I have a {{item}}
      with_items: '{{fruits}}'
```

## Testing

Using `--check` flag

```sh
ansible-playbook demo.yml --check
```


## Roles

- Roles is a way to organize your Ansible code and make it reusable and modular.
- Ansible Galaxy is a public repository for Ansible roles and collections.
- Use `ansible-galaxy` command to create a role, install roles/collections from Galaxy.


```sh
# init a role, this creates a bunch of folders and files
ansible-galaxy init testrole1

ls -AF
# .travis.yml  README.md  defaults/  files/  handlers/  meta/  tasks/  templates/  tests/  vars/
```

- `defaults/` for default variable values
- `vars/` override default variable values
- `tasks/` tasks for this role
- `templates/` jinja2 template files for the `template` task

### Example

Define and use a role called `webserver-config`

File structure:

```
playbook.yml
roles
|- webserver-config
   |- tasks
      |- main.yml
```

`main.yml` for `webserver-config` role, defining two tasks

```yaml
---
- name: Install Apache
  apt:
    name: apache2
    state: latest

- name: Enable Apache service
  systemd:
    name: apache2
    enabled: yes
```

`playbook.yml` using the `webserver-config` role

```yaml
---
- name: Playbook with Role Example
  hosts: webserver
  become: yes
  roles:
    - webserver-config
```


## Collections

Example: using `azure.azcollection` to read resource groups

```sh
# install
ansible-galaxy collection install azure.azcollection

# install required Python packages of the collection
pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt

ansible-playbook rg.yml --extra-vars "subscription_id=<sub-id> client_id=<client-id> secret=<secret> tenant=<tenant> cloud_environment=AzureCloud"
```

```yaml
# rg.yml
# a playbook using the `azure.azcollection.azure_rm_resourcegroup_info` module
---
- name: Example playbook using the azure.azcollection
  hosts: localhost
  tasks:
    - name: Get resource groups in the Azure subscription
      azure.azcollection.azure_rm_resourcegroup_info:
        cloud_environment: "{{ cloud_environment }}"
        tenant: "{{ tenant }}"
        subscription_id: "{{ subscription_id }}"
        client_id: "{{ client_id }}"
        secret: "{{ secret }}"
      register: rg_info

    - name: Print the list of resource groups
      debug:
        var: rg_info.resourcegroups
```


## Secrets

"Vault" is a feature that allows you to encrypt sensitive data in your playbooks and roles. The encrypted data can then be safely stored in a source control system.

### File-level encryption

You can encrypt any file

```sh
# encrypt a file
ansible-vault encrypt demo-playbook.yml

# edit
ansible-vault edit demo-playbook.yml

# run an encrypted playbook
ansible-playbook demo-playbook.yml --ask-vault-pass
```

### Variable-level encryption

```sh
ansible-vault encrypt_string --vault-id @prompt mysupersecretstring
```

Use the secret in a playbook

```yaml
- hosts: localhost
  vars:
    secret: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66613333646138636537363536373431633333353631646164353031303933316533326437366564
          6430613461323339316130626533336165376238316134310a303836356162633363666439353534
          39653865646130346239316137373565623934663238343061663239383139613032636262363565
          6138613861613031650a326230616637396232623630323362386430326464373364323531303631
          32393362326164343566383936633838336166363535383333366237636639636535
  tasks:
  - name: Test variable
    debug:
      var: secret
```

Run the playbook

```sh
ansible-playbook use-secret.yml --ask-vault-pass
```

## Configs

Ansible configs are in `/etc/ansible/ansible.cfg`

```
[defaults]

# control the output format
stdout_callback = yaml
```

## Work with Azure

### Install az collection

```sh
# Install Ansible az collection for interacting with Azure.
ansible-galaxy collection install azure.azcollection

# Install Ansible modules for Azure
sudo pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
```

### Azure credentials

Use an service principal, it should have proper permissions on the target subscription, two ways for credentials:

1. Put it in `~/.azure/credentials`

    ```ini
    [default]
    subscription_id=<subscription_id>
    client_id=<service_principal_app_id>
    secret=<service_principal_password>
    tenant=<service_principal_tenant_id>
    ```

2. Environment variables:

    ```sh
    export AZURE_SUBSCRIPTION_ID=<subscription_id>
    export AZURE_CLIENT_ID=<service_principal_app_id>
    export AZURE_SECRET=<service_principal_password>
    export AZURE_TENANT=<service_principal_tenant_id>
    ```

### Run

You could use ad-hoc commands or playbooks

1. Ad-hoc command

    ```sh
    ansible localhost \
          --module-name azure.azcollection.azure_rm_resourcegroup \
          --args "name=rg-by-ansible-001 location=australiaeast"
    ```

2. Playbooks

    ```yml
    # create-rg.yml
    - hosts: localhost
      connection: local
      collections:
        - azure.azcollection
      tasks:
        - name: Creating resource group
          azure_rm_resourcegroup:
            name: "rg-ansible-002"
            location: "westus"
    ```

    ```sh
    ansible-playbook create-rg.yml
    ```

## Work with Windows hosts

### Setup Windows remote hosts

Full details: https://docs.ansible.com/ansible/latest/os_guide/windows_setup.html

Quick setup:

```powershell
wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -o .\x.ps1

.\x.ps1

# check the listeners are running
winrm enumerate winrm/config/Listener
# Listener
#     Address = *
#     Transport = HTTP
#     Port = 5985
#     Hostname
#     Enabled = true
#     URLPrefix = wsman
#     CertificateThumbprint
#     ListeningOn = ...

# Listener
#     Address = *
#     Transport = HTTPS
#     Port = 5986
#     Hostname = vm-demo
#     Enabled = true
#     URLPrefix = wsman
#     CertificateThumbprint = 832A4CA59901EE8DD4060123E2D669F9FB71C578
#     ListeningOn = ...
```

### Connect

- Install collection, Python package

  ```sh
  # install collection
  ansible-galaxy collection install ansible.windows

  # install pywinrm
  pip show pywinrm
  ```

- Set appropriate host variables, like `ansible_connection` etc:

  ```
  [win]
  172.16.2.5
  172.16.2.6

  [win:vars]
  ansible_user=vagrant
  ansible_password=<password>
  ansible_connection=winrm
  ansible_winrm_server_cert_validation=ignore   # ignore cert validation
  ```

- Password could be passed in the command line, or you could encrypt the inventory file

  ```sh
  ansible -i ../inventories/windows-hosts -m win_ping all -e "ansible_password=<pass>"

  # 20.5.202.140 | SUCCESS => {
  #     "changed": false,
  #     "ping": "pong"
  # }
  ```

- Windows reboot playbook example

  ```yaml
  ---
  - name: win_reboot module demo
    hosts: all
    become: false
    gather_facts: false
    tasks:
      - name: reboot host(s)
        ansible.windows.win_reboot:
          msg: "Reboot by Ansible" # this message will be showing on a popup
          pre_reboot_delay: 120 # how long to wait before rebooting
          shutdown_timeout: 3600
          reboot_timeout: 3600
  ```