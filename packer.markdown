# Packer

- [Overview](#overview)
- [Config file](#config-file)


## Overview

Packer automates the creation of any type of machine image, including Docker images.

## Config file

```HCL
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source = "github.com/hashicorp/docker"
    }
  }
}

# specify a builder and a name
source "docker" "ubuntu" {
  image  = "ubuntu:xenial"
  commit = true
}

build {
  name    = "learn-packer"
  sources = [
    "source.docker.ubuntu"
  ]
}
```

Packer starts a container, then takes an image out of the container.

Run:

```sh
packer init .

# optionally format and validate configs
packer fmt .
packer validate .

# build
packer build docker-ubuntu.pkr.hcl
```

You can find the image with

```sh
docker images
```

*Packer doesn't manage the image for you*
