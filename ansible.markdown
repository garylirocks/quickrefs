Ansible
=========

- Sponsored by Red
- Automates cloud provisioning, configuration management and application deployments
- Agentless, but nodes and the control machine needs Python
- Connect to each node through SSH (WinRM for Windows)
- Idempotent

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

- Dynamic inventory

  ```yaml
  plugin: azure_rm
  include_vm_resource_groups:
    - learn-ansible-rg
  auth_source: auto
  keyed_groups:
    - prefix: tag
      key: tags
  ```

  Verify that Ansible can discover your inventory

  ```sh
  ansible-inventory --inventory azure_rm.yml --graph

  # @all:
  # |--@tag_Ansible_mslearn:
  # |  |--vm1_1bbf
  # |  |--vm2_867a
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
# users.yml
---
- hosts: all
  become: yes # apply with `sudo` privilege
  tasks:
    - name: Add service accounts
      user:   # Ansible's 'user' module
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
  users.yml
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


