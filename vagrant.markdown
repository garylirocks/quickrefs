Vagrant
=========

Quickly start virtual machines for
  - development environment
  - testing infrastructure management scripts (like shell scripts, Chef cookbooks, Puppet modules, Ansible playbooks, ...)

## Quick Start

  ```sh
  mkdir vagrant-demo
  cd ./vagrant-demo

  # Create Vagrantfile, use `hashicorp/bionic64` as the base image
  vagrant init hashicorp/bionic64

  # start the virtual machine
  vagrant up

  # SSH into the machine
  vagrant ssh

  # your project directory on the host is synced to `/vagrant` in the virtual machine,
  # so you can see 'Vagrantfile' here
  ls /vagrant/
  # Vagrantfile
  ```

## Networking

- Forwarded ports

  ```sh
  Vagrant.configure("2") do |config|
    # forward host port 8080 to guest port 80
    config.vm.network "forwarded_port", guest: 80, host: 8080
  end
  ```

- Private network

  Allow you to access guest machines by a private network, multiple machines on the same network can communicate with each other

  ```sh
  Vagrant.configure("2") do |config|
    config.vm.network "private_network", type: "dhcp"
  end
  ```

  Or use a static ip

  ```sh
  Vagrant.configure("2") do |config|
    config.vm.network "private_network", ip: "192.168.100.2"
  end
  ```

  The you could reach the maching on `192.168.100.2` and SSH to it in this way:

  ```sh
  vagrant ssh-config
    #   Host default
    #     HostName 127.0.0.1
    #     User vagrant
    #     Port 2222
    #     UserKnownHostsFile /dev/null
    #     StrictHostKeyChecking no
    #     PasswordAuthentication no
    #     IdentityFile /home/gary/downloads/vagrant-demo/.vagrant/machines/default/virtualbox/private_key
    #     IdentitiesOnly yes
    #     LogLevel FATAL

  ssh -i /home/gary/downloads/vagrant-demo/.vagrant/machines/default/virtualbox/private_key vagrant@192.168.100.2
    ```

## Boxes

```sh
# list base images downloaded
vagrant box list
```