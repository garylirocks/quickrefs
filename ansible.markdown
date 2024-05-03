Ansible
=========

- [Overview](#overview)
- [Commands](#commands)
- [Inventory](#inventory)
- [Playbook](#playbook)
- [Tasks](#tasks)
  - [Blocks](#blocks)
- [Tags](#tags)
- [Variables](#variables)
  - [Ansible facts](#ansible-facts)
  - [Magic variables](#magic-variables)
  - [Filters](#filters)
- [Loops](#loops)
- [Testing](#testing)
  - [Test with localhost](#test-with-localhost)
- [Error handling](#error-handling)
- [Debugging](#debugging)
  - [`debugger` keyword](#debugger-keyword)
- [Roles](#roles)
  - [Example](#example)
- [Collections](#collections)
- [Importing and including](#importing-and-including)
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
- [AAP](#aap)
  - [Concepts](#concepts)
- [Interaction with Terraform](#interaction-with-terraform)
  - [Call Terraform from Ansible](#call-terraform-from-ansible)
  - [Call Ansible from Terrafrom](#call-ansible-from-terrafrom)
  - [Provision Ansible assets from Terraform](#provision-ansible-assets-from-terraform)
  - [Use Terraform in AAP](#use-terraform-in-aap)

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

### Blocks

Blocks could be used to apply common directives to a group of tasks, such as `tags`, `when`, `become`, `ignore_errors`
  - `when` is checked for each task in the block, not at the block level

```yaml
tasks:
  - name: Install, configure, and start Apache
    block:
      - name: Install httpd and memcached
        ansible.builtin.yum:
          name:
          - httpd
          - memcached
          state: present

      - name: Apply the foo config template
        ansible.builtin.template:
          src: templates/src.j2
          dest: /etc/foo.conf

      - name: Start service bar and enable it
        ansible.builtin.service:
          name: bar
          state: started
          enabled: True
    when: ansible_facts['distribution'] == 'CentOS'
    become: true
    become_user: root
    ignore_errors: true
    tags: [tag1, tag2]
```


## Tags

You can add tags to task or play, and filter tasks by tags

```sh
# list available tags in a playbook
ansible-playbook playbook.yml --list-tags

# run tasks tagged 'nginx'
ansible-playbook playbook.yml --tags nginx

# skip tags
ansible-playbook playbook.yml --skip-tags nginx
```

There are two special tags: `always` and `never`

- `always` tagged task is always run, unless skipped specifically with `--skip-tags always`
- `never` tagged task is always skipped, unless included specifically with `--tags never`

```yaml
tasks:
  - name: Run the rarely-used debug task
    ansible.builtin.debug:
     msg: '{{ aVar }}'
    tags:
      - never
      - debug
```

If you specify `--tags debug`, the task will run as well


## Variables

Could be defined in `group_vars` folder

```
- group_vars
  |- all/
  |- group1/
  |- group2/
```

Variables in `all/` will be applied to all hosts, in `group1/` for hosts in `group`, ...

Could be also defined in inventory files directly

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

### Ansible facts

The `ansible_facts` variable contains info about remote system

```yaml
- name: Print all available facts
  ansible.builtin.debug:
    var: ansible_facts
```

Some important facts:

```json
"ansible_facts": {
  "all_ipv4_addresses": [
    "172.16.16.16"
  ],
  "date_time": {
    "date": "2023-05-05",
    ...
  },
  "default_ipv4": {
    "address": "172.16.16.16",
    ...
  },
  "distribution": "Ubuntu",
  "distribution_file_variety": "Debian",
  "distribution_major_version": "20",
  "domain": "gary.com",
  "env": {
    "HOME": "/home/gary",
    ...
  },
  "fqdn": "demo.gary.com",
  "hostname": "demo",
  "machine": "x86_64",
  "pkg_mgr": "apt",
  "python_version": "3.8.2",
  "system": "Linux",
  "user_id": "gary",
  ...
}
```

- You can reference an env variable by `{{ ansible_facts['env']['HOME'] }}`
- Facts are cached (in memory by default), and available to all hosts, you can accessible fact of one remote host in another host like `{{ hostvars['vm1']['ansible_facts']['os_family'] }}`
- `set_fact` set fact about current host, by default, you can not access it via `ansible_facts`, unless you set `cacheable: yes`

  ```yaml
  - name: Set a temporary fact
    set_fact:
      my_fact: "my value"
      cacheable: yes

  - debug:
      var: my_fact

  - debug:
      var: ansible_facts['my_fact']
  ```

- The infomation gathering could be disabled by `gather_facts: false`

  ```yaml
  ---
  - name: Testing
    gather_facts: false
    hosts: all
  ```

### Magic variables

They contain information about ansible operations.

- `hostvars` contains
  - all variables about each host, including variables defined in inventory files, variables defined in playbooks
  - and `ansible_facts` gathered for each host

  ```json
  "hostvars": {
    "vm1": {
      "my_custom_var": "my custom value",
      "groups_names": ["group1", "group2"],
      "inventory_file": "/path/to/inventory.ini",
      "ansible_facts": {
        ...
      },
      "ansible_run_tags": [
          "all"
      ],
      "ansible_skip_tags": [],
      "ansible_verbosity": 0,
      "ansible_version": {
          "full": "2.9.6",
          "major": 2,
          "minor": 9,
          "revision": 6,
          "string": "2.9.6"
      },
      ...
    }
    ...
  }
  ```

- `groups`
- `group_names`
- `inventory_hostname`, the name defined in inventory file (could be alias, FQDN, IP, etc)
  - `ansible_host` IP or FQDN in inventory files
  - `ansible_hostname` this is short hostname gathered from the remote host
- `ansible_play_hosts` is the list of all hosts still active in the current play.
- `ansible_play_batch` is a list of hostnames that are in scope for the current 'batch' of the play. The batch size is defined by serial, when not set it is equivalent to the whole play (making it the same as ansible_play_hosts).
- `inventory_dir`
- `inventory_file`
- `playbook_dir`
- `role_path`
- `ansible_check_mode` is a boolean, set to True if you run Ansible with --check.
- `ansible_version`


### Filters

- `default`

  ```
  # default to 5
  {{ some_variable | default(5) }}

  # default value if any field undefined
  {{ foo.bar.baz | default('DEFAULT') }}

  # default to "admin" if the variable exists, but evaluates to false or an empty string
  {{ lookup('env', 'MY_USER') | default('admin', true) }}

  # making an variable optional
  {{ item.mode | default(omit) }}

  # making an variable mandatory, when `DEFAULT_UNDEFINED_VAR_BEHAVIOR` is set to false
  {{ item.mode | mandatary }}
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

### Test with localhost

It's often easier to test with localhost first

- Create an inventory file, specify `ansible_connection=local`, you may need to specify a password if you use `become` in you playbook

  ```yaml
  localhost ansible_connection=local ansible_become_password=<password>
  ```

- Test your playbook with `ansible-playbook -i ./localhost.localonly.ini my_playbook.yml`
- Use `-K, --ask-become-pass` if it needs root password:  `ansible-playbook -i ./localhost.localonly.ini -K my_playbook.yml`


## Error handling

- By default if a command returns non-zero code, the task fails, but this could be customized

  ```yaml
  - name: Fail task when both files are identical
    ansible.builtin.raw: diff foo/file1 bar/file2
    register: diff_cmd
    failed_when: (diff_cmd.rc == 0) or (diff_cmd.rc >= 2)
  ```

- By default a error would stop tasks on the host, but you can change this behavior

  ```yaml
  - name: Do not count this as a failure
    ansible.builtin.command: /bin/false
    ignore_errors: true
  ```

- Customize `changed`

  ```yaml
  - name: Report 'changed' when the return code is not equal to 2
    ansible.builtin.shell: /usr/bin/billybass --mode="take me to the river"
    register: bass_result
    changed_when: "bass_result.rc != 2"
  ```


## Debugging

To enable the debugger:

- use `debugger` keyword (task, block, play or role level)
- in configuration or environment variable
- as a strategy

### `debugger` keyword

```yaml
- name: My play
  hosts: all
  tasks:
    - name: Execute a command
      debugger: always
      ansible.builtin.command: "true"
      when: False
```

when the debugger is triggered, you print out and update task variables, arguments, then rerun it (see https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html#available-debug-commands)

```
p task.args
p task_vars

task.args['arg1'] = 'new arg value'

redo
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
  - could be overwritten by group_vars or host_vars
- `vars/` override default variable values
  - could not be overwritten by group_vars or host_vars
  - CAN be overwritten by block/task vars, `-e`
  - see https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence for full details
- `tasks/` tasks for this role
- `templates/` jinja2 template files for the `template` task
- `handlers/` handlers are only fired when certain tasks report changes, and are run at the end of each play
  - usually used to restart services/machines
  - `handlers` could be in the same playbook file
  - Use the handler `name` field in `notify`

  ```yaml
  ---
  - name: This is a play within a playbook
    hosts: all
    tasks:
      - name: Task 1
        module_name:
          param1: "foo"
        notify: restart a service

      - name: Task 2
        module_name_2:

    handlers:
      - name: restart a service
        ansible.windows.win_service:
          name: service_a
          state: restarted
          start_mode: auto
  ```


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


## Importing and including

Compare `include_*` and `import_*`:

|                                                             | Include_*                                                                                                                      | Import_*                                         |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| Type of re-use                                              | Dynamic                                                                                                                        | Static                                           |
| When processed                                              | At runtime, when encountered                                                                                                   | Pre-processed during playbook parsing            |
| Keywords                                                    | `include_role`, `include_tasks`, `include_vars`                                                                                | `import_role`, `import_tasks`, `import_playbook` |
| Context                                                     | task                                                                                                                           | task or play (`import_playbook`)                 |
| Tags                                                        | Not inherited, you could **filter which tasks to run** by add tags to both the `include_*` task and tasks in the included file | Inherited, applies to all imported tasks         |
| Task options                                                | Apply only to include task itself                                                                                              | Apply to all child tasks in import               |
| Calling from loops                                          | Executed once for each loop item                                                                                               | Cannot be used in a loop                         |
| Works with `--list-tags`, `--list-tasks`, `--start-at-task` | No                                                                                                                             | Yes                                              |
| Notifying handlers                                          | Cannot trigger handlers within includes                                                                                        | Can trigger individual imported handlers         |
| Using inventory variables                                   | Can `include_*: {{ inventory_var }}`                                                                                           | Cannot `import_*: {{ inventory_var }}`           |
| With variables files                                        | Can include variables files                                                                                                    | Use `vars_files:` to import variables            |

- Playbooks can be imported (static)

  ```yaml
  - import_playbook: "/path/to/{{ import_from_extra_var }}"
  - import_playbook: "{{ import_from_vars }}"
    vars:
      import_from_vars: /path/to/one_playbook.yml
  ```

- The bare `include` keyword is deprecated
- Avoid using both includes and imports in a single playbook, it can lead to difficult-to-diagnose bugs
- If you use roles at play level, they are treated as static imports, tags are applied to all tasks within the role:
  ```yaml
  ---
  - hosts: webservers
    roles:
      - role: my-role
        vars:
          app_port: 5000
        tags: typeA
      - role: another-role
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


## AAP

![AAP architecture](images/ansible_aap-architecture.png)

### Concepts

- **Project**: usually a link to a Git repo
- **Inventories**:
  - could be added manually, from supported cloud providers or through dynamic inventory scripts
  - you can add variables for groups and individual hosts
- **Credentials**: credentials for machines, Git repos, etc
- **Job Templates**:
  - what inventory to run against
  - what playbook to run, and survey for variables
  - waht credentials to use
- **Workflow Templates**:
  - you can build a workflow by joining multiple steps together(each step could be job templates, other workflow templates, repo sync, inventory source sync, approvals, etc), similar to Azure Logic Apps
  - the included job templates could have different inventories, playbooks, credentials, etc
  - You could add a survey to a workflow template

- **RBAC**
  - Entity hierarchy: organization -> team -> user
  - Built-in roles: Normal User, Administrator, Auditor
  - Scenarios: give user read and execute access to a job template, no permission to change anything

- **Automation Hub**
  - Host private Ansible collections
  - And execution environments


## Interaction with Terraform

### Call Terraform from Ansible

You could use `cloud.terraform.terraform` Ansible module to run Terraform commands

```yaml
- name: Run Terraform Deploy
  cloud.terraform.terraform:
    project_path: '{{ project_dir }}'
    state: present
    force_init: true
```

### Call Ansible from Terrafrom

- Use `local-exec` provisioner to run Ansible playbooks

### Provision Ansible assets from Terraform

- Use `ansible/ansible` provider in Terraform
- It could create Ansible inventory host/group, playbook, vault

Example: add a VM to Ansible inventory

```hcl
resource "aws_instance" "my_ec2" {
  ...
}

resource "ansible_host" "my_ec2" {
  name   = aws_instance.my_ec2.public_dns
  groups = ["nginx"]

  variables = {
    ansible_user                 = "ec2-user",
    ansible_ssh_private_key_file = "~/.ssh/id_rsa",
    ansible_python_interpreter   = "/usr/bin/python3",
  }
}
```

Then in `inventory.yml`, use the `cloud.terraform.terraform_provider` plugin, which reads the Terraform state file to get the host information

```yaml
---
plugin: cloud.terraform.terraform_provider
```

You can validate this by:

```sh
ansible-inventory -i inventory.yml --graph --vars

# @all:
#   |--@nginx:
#   |  |--ec2-13-41-80-241.eu-west-2.compute.amazonaws.com
#   |  |  |--{ansible_python_interpreter = /usr/bin/python3}
#   |  |  |--{ansible_ssh_private_key_file = ~/.ssh/id_rsa}
#   |  |  |--{ansible_user = ec2-user}
#   |--@ungrouped:
```

### Use Terraform in AAP

Build a workflow template, with steps:

1. Build Terraform config files with variables
2. Run Terraform to provision VMs
3. Sync dynamic inventory (this will add the new VM instance to the inventory)
4. Run Ansible Playbook to configure the new VM
