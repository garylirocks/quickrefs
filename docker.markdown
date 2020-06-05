# Docker

- [General](#general)
  - [Overview](#overview)
  - [Commands](#commands)
- [Images vs. Containers](#images-vs-containers)
  - [Images](#images)
  - [Containers](#containers)
- [Dockerfile](#dockerfile)
  - [Example](#example)
  - [`RUN`](#run)
  - [`CMD`](#cmd)
  - [`ENTRYPOINT`](#entrypoint)
  - [`ENV`](#env)
  - [`ADD` vs. `COPY`](#add-vs-copy)
  - [`.dockerignore`](#dockerignore)
- [Data Storage](#data-storage)
  - [Volumes](#volumes)
    - [Data Sharing](#data-sharing)
    - [Backup, restore, or migrate data volumes](#backup-restore-or-migrate-data-volumes)
    - [Remove volumes](#remove-volumes)
    - [`-v`, `--mount` and volume driver](#-v---mount-and-volume-driver)
  - [Bind mounts](#bind-mounts)
    - [Commands](#commands-1)
  - [`tmpfs`](#tmpfs)
  - [Usage](#usage)
- [Network](#network)
  - [Basic commands](#basic-commands)
  - [DNS](#dns)
  - [Swarm](#swarm)
  - [Network Driver Types](#network-driver-types)
  - [Port Publishing Mode](#port-publishing-mode)
- [Docker Compose](#docker-compose)
  - [`docker-compose.yml`](#docker-composeyml)
    - [`volumes`](#volumes-1)
    - [`deploy`](#deploy)
  - [`env_file`](#env_file)
  - [Variable substitution](#variable-substitution)
  - [Networking](#networking)
    - [Custom networks](#custom-networks)
  - [Name collision issue](#name-collision-issue)
- [Docker machine](#docker-machine)
- [Context](#context)
- [Swarm mode](#swarm-mode)
  - [Swarm on a single node](#swarm-on-a-single-node)
  - [Multi-nodes swarm example](#multi-nodes-swarm-example)
  - [Multi-service stacks](#multi-service-stacks)
- [Configs](#configs)
  - [Basic usage using `docker config` commands](#basic-usage-using-docker-config-commands)
  - [Use for Nginx config](#use-for-nginx-config)
  - [Rotate a config](#rotate-a-config)
  - [Usage in `compose` files](#usage-in-compose-files)
- [Secrets](#secrets)
  - [Example: Use secrets with a WordPress service](#example-use-secrets-with-a-wordpress-service)
  - [Rotate a secret](#rotate-a-secret)
  - [Example compose file](#example-compose-file)
- [Tips / Best Practices](#tips--best-practices)

docker basics:

[Why You Should Stop Installing Your WebDev Environment Locally - Smashing Magazine](https://www.smashingmagazine.com/2016/04/stop-installing-your-webdev-environment-locally-with-docker/)

## General

### Overview

- docker has a client-server architecture;
- client and server can be on the same system or different systems;
- client and server communicates via sockets or a RESTful API;

![Docker Architecture Overview](./images/docker-architecture.svg)

a more detailed view of the workflow

![Docker Workflow](./images/docker-workflow.png)

### Commands

```sh
# show installation info
docker info

# search images
docker search <query>

# monitoring (show container events, such as: start, network connect, stop, die, attach)
docker events

# it provides various sub-commands to help manage different entities

# image, container
docker [image|container|volume|network] <COMMAND>

# service, stack, swarm
docker [service|stack|swarm|node|config] <COMMAND>

# other
docker [plugin|secret|system|trust] <COMMAND>
```

## Images vs. Containers

A container is a running instance of an image, when you start an image, you have a running container of the image, you can have many running containers of the same image;

### Images

- created with `docker build`;
- can be stored in a registry, like Docker Hub;
- images can't be modified;
- a image is composed of layers of other images, allowing minimal amount of data to be sent when transferring images over the network;

  for example, in the following `Dockerfile`, each line creates a new layer above the previous layer

  ```
  FROM ubuntu             # This has its own number of layers say "X"
  MAINTAINER FOO          # This is one layer
  RUN mkdir /tmp/foo      # This is one layer
  RUN apt-get install vim # This is one layer
  ```

  ![Docker layers](images/docker-layers.png)

- commands

  ```bash
  # list images
  docker images

  # list images, including intermediate ones
  docker images -a

  # build an image, from the Dockerfile in the current directory
  docker build -t einstein:v1 .

  # show history (building layers) of an image
  docker history node:slim

  # inspect an image
  docker inspect node:slim

  # remove image
  docker rmi [IMAGE_ID]

  # remove dangling images
  docker image prune

  # start the image in daemon mode, expose 80, bind it to 8080 on host
  # '--expose' is optional here, 80 is exposed automatically when you specify the ports mapping
  docker run [--expose 80] -p 8080:80 -itd my-image echo 'hello'

  # bind only to the 127.0.0.1 network interface on host
  docker run -p 127.0.0.1:8080:80 -itd my-image echo 'hello'

  # give the container a meaningful name
  docker run --name my-hello-container -itd my-image echo 'hello'

  # access the shell of an image
  docker run -it node:slim bash
  ```

- about image tags

  ```bash
  docker images

  REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
  node                9.7.1               993f38da6c6c        4 months ago        677MB
  node                8.5.0               de1099630c13        10 months ago       673MB
  ```

  an image's full tag is of this format `[REGISTRYHOST/][USERNAME/]NAME[:TAG]`, the `REPOSITORY` column above is just the `NAME` part, you specify a tag with `-t` option when building an image, the version tag will be `latest` by default

### Containers

- conatiners can be started and stopped, the filesystem changes are persisted in a stopped container, they are still there when the container restarts;

- you can create a new image from a container's changes with `docker commit`;

- commands:

  ```bash
  # list running containers
  docker ps

  # list all containers
  docker ps -a

  # inspect a container
  docker inspect <container>

  # get a specific value using a Go template string
  docker inspect testweb --format="{{.NetworkSettings.IPAddress}}"

  # start/stop/restart/pause/unpause/attach
  # attach: connecting local stdin, stdout, stderr to a running container
  # pause|unpause: pause or unpause running processes in a container
  docker start|stop|restart|pause|unpause|attach <container>

  # show the output logs of a container
  docker logs <container>

  # convert a container to an image file
  docker commit -a 'Albert Einstein <albert@example.com>' -m 'theory of relativity' <container> einstein/relativity:v1

  # execute a command in a running container
  docker exec node-box "node" "myapp.js"

  # access the command line of a running container
  docker exec -it [CONTAINER] bash

  # remove a container
  docker rm [CONTAINER_ID]

  # force remove a running container
  docker rm -f [CONTAINER_ID]
  ```

## Dockerfile

### Example

```docker
FROM ubuntu:xenial
MAINTAINER einstein <einstein@example.com>

# add a user to the image and use it, otherwise root is used for everything
RUN useradd -ms /bin/bash einstein
USER einstein

# install required tools, it's a good practice to chain shell commands together, reducing intermediate images created
RUN apt-get update && \
    apt-get install --yes openssh-server
```

```bash
# run an image using a specified user (`0` for `root`)
docker run -u 0 -it <image> /bin/bash
```

### `RUN`

- `RUN` will execute commands in a new layer on top of current image and commit the results, the resulting image will be used for the next step in the `Dockerfile`;
- the command is ran by root user by default, if a `USER` directive is present, following `RUN` commands will be ran by that user;

it has two forms:

- `RUN <command>` (_shell_ form)

  - use `/bin/sh -c` by default on Linux;
  - the default shell can be changed using the `SHELL` command;
  - you can use a `\` to continue a single instruction on the next line

    ```
    RUN /bin/bash -c 'source $HOME/.bashrc; \
    echo $HOME'

    # equivalent to
    RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
    ```

- `RUN ["executable", "param1", "param2"]` (_exec_ form)

  - make it possible to avoid shell string munging, and to `RUN` commands using a base image that does not contain the specified shell executable;
  - it's parsed as a JSON array, so you must use double-quotes `"`;

the cache for `RUN` instructions isn't invalidated automatically during the next build, use a `--no-cache` flag to invalidate it

### `CMD`

- `CMD` sets the command to be executed when running the image, it is not executed at build time;
- arguments to `docker run` will overide `CMD`;

has three forms:

- `CMD ["executable", "param1", "param2"]` (_exec_ from, preferred)

  - must use double quotes;
  - the "executable" must be in full path;

- `CMD ["param1", "param2"]` (as _default_ params to `ENTRYPOINT`)

  - in this form, an `ENTRYPOINT` instruction should be specified with the JSON array format;
  - this form should be used when you want your container to run the same executable every time;

- `CMD command param1 param2` (_shell_ form)

**differencies to `RUN`**

- `RUN` actually runs a command and commits the result, `CMD` does not execute at build time, but specifies what to be ran when instantiating a container out of the image;
- there can be multiple `RUN` command in one `Dockerfile`, but there should only be one `CMD`;

### `ENTRYPOINT`

like `CMD`, it specifies an application to run when instantiating a container, the difference is `ENTRYPOINT` is always ran (like always run `apache` for an apache image), can't be overriden, even you specify a command to run in the command line

```dockerfile
...

# CMD and ENTRYPOINT can be used together, when both are in exec form
CMD ["CMD is running"]
ENTRYPOINT ["echo", "ENTRYPOINT is running"]
```

```bash
docker run <imagename>

# CMD params are appended to the ENTRYPOINT exec
ENTRYPOINT is running CMD is running
```

### `ENV`

```docker
ENV MY_NAME gary
```

add environment variable in the container, it's **system wide**, no specific to any user

### `ADD` vs. `COPY`

they are basically the same, only difference is `ADD` will extract TAR files or fetching files from remote URLs

```
ADD example.tar.gz /add     # Will untar the file into the ADD directory
COPY example.tar.gz /copy   # Will copy the file directly
```

files pulled in by `ADD` and `COPY` are owned by `root` by default, **DON'T** honor `USER`, [use a `--chwon` flag to specify user](https://github.com/moby/moby/pull/9934):

```
ADD --chown=someuser:somegroup /foo /bar
COPY --chown=someuser:somegroup /foo /bar
```

Syntax:

For either `<src>` or `<dest>`, if its a directory, add a trailings slash to avoid any confusion:

```
# copy a file to a folder
copy package.json /app/

# only copy the files in src/ to /var/www/, not src/ folder itself
COPY src/ /var/www/

# this will create /var/www/src/ folder in the image
COPY src/ /var/www/src/
```

### `.dockerignore`

config what files and directories should be ignored when sending to the docker daemon and ignored by `ADD` and `COPY`

```
.gitignore

# ignore any .md file
*.md

# but include .md files with a name starts with 'README'
!README*.md

# ignore any .temp file that's in a one-level deep subfolder
*/*.temp

# any file with a '.cache' extension
**/.cache
```

## Data Storage

By default, all files created inside a container are stored on a writable container layer:

- Those data doesn't persist, it's hard to move it out of the container or to another host;
- A _storage drive_ is required to manage the filesystem, **it's slower comparing to writing to the host filesystem using _data volumes_**;
- Docker can store files in the host, using _volumes_, _bind mounts_ or _tmpfs (Linux only)_;

![Storage types](images/docker-storage.png)

### Volumes

- Created and managed by Docker;
- You can create/manage them explicitly using `docker volume` commands;
- Docker create a volume during container or service creation if the volume does not exist yet;
- Stored in a Docker managed area on the host filesystem (`/var/lib/docker/volumes` on Linux), non-Docker processes should not modify it;
- A volume **can be mounted into multiple containers simultaneously**, it doesn't get removed automatically even no running container is using it (**So volumes can be mounted into a container, but they are not depended on any conatiner**);
- Volumes can be _named_ or _anonymous_, an anonymous volume get a randomly generated unique name, otherwise they behave in the same ways;
- They support _volume drivers_, which **allow you to store data on remote hosts or cloud providers**;
- _Best way_ to persist data in Docker;

#### Data Sharing

![data sharing](images/docker-volumes-shared-storage.svg)

If you want to configure multiple replicas of the same service to access the same files, there are two ways:

- Add logic to your application to store data in cloud (e.g. AWS S3);
- Create volumes with a driver that supports writing files to an external storage system like NFS or AWS S3 (in this way, you can abstract the storage system away from the application logic);

#### Backup, restore, or migrate data volumes

You can use `--volumes-from` to create a container that mounts volumes from another container;

- Backup `dbstore:/dbdata` to current directory

  ```sh
  docker run --rm --volumes-from dbstore -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata
  ```

- Restore `backup.tar` in current directory to a new container `dbstore2`

```sh
# create dbstore2 and a new volume with it
docker run -v /dbdata --name dbstore2 ubuntu /bin/bash

# restore the backup file to the volume
docker run --rm --volumes-from dbstore2 -v $(pwd):/backup ubuntu bash -c "cd /dbdata && tar xvf /backup/backup.tar --strip 1"
```

#### Remove volumes

```sh
# use `--rm` to let Docker remove the anonymous volume /foo when the container is removed
# the named `awesome` volume is NOT removed
docker run --rm -v /foo -v awesome:/bar busybox top

# remove all unused volumes
docker volume prune
```

#### `-v`, `--mount` and volume driver

```sh
# start a container using `-v`
docker run -d \
  --name devtest \
  -v myvol2:/app \
  nginx:latest

# start a service using `--mount`
docker service create -d \
  --replicas=4 \
  --name devtest-service \
  --mount source=myvol2,target=/app \
  nginx:latest

# install a volume driver plugin
docker plugin install --grant-all-permissions vieux/sshfs

# use a volume driver
docker run -d \
  --name sshfs-container \
  --volume-driver vieux/sshfs \
  --mount src=sshvolume,target=/app,volume-opt=sshcmd=test@node2:/home/test,volume-opt=password=testpassword \
  nginx:latest
```

### Bind mounts

- Available since early days of Docker;
- A file or directory on the _host machine_ is mounted into a container;
- It **does not** need to exist on the host already, Docker will create it if not exist;
- Can be anywhere on the host system;
- May be important system files or directories;
- Both non-Docker processes on the host or the Docker container can modify them at any time, so it have security implications;
- Can't be managed by Docker CLI directly;
- **Consider using named volumes instead**;

#### Commands

```sh
docker run -it -v /home/gary/code/super-app:/app ubuntu
```

### `tmpfs`

- Not persisted on disk;
- Can be used by a container to store non-persistent state or sensitive info;
  - Swarm services use `tmpfs` to mount secrets into a service's containers;

### Usage

- Use `-v` or `--volume` to mount volumes or bind mounts;
- In Dokcer 17.06+, `--mount` is recommended, syntax is more verbose, and it's required for creating services;
- Volumes are good for:

  - Sharing data among multiple running containers;
  - When the Docker host is not guaranteed to have a given directory or file structure;
  - Store a container's data on a remote host or a cloud provider;
  - You need to backup, restore or migrate data from one Docker host to another, you can stop the containers using the volume, then back up the volume's directory (such as `/var/lib/docker/volumes/<volume-name>`);

- Bind mounts are good for:
  - Sharing config files from the host machine to containers, by default Docker mount `/etc/resolv.conf` from host to container for DNS resolution;
  - Sharing source code or build artifacts between a development env on the host and a container (**Your production Dockerfile should copy the production-ready artifacts into the image directly, instead of relying on a bind mount**);

* If you mount an **empty volume** into a directory in the container in which files or directories exist, these files or directories are copied into the volume, if you start a container and specify a volume which does not already exist, an empty volume is created;
* If you mount a **bind mount or non-empty volume** into a directory in which soe file or directories exist, these files or directories are obscured by the mount;

## Network

### Basic commands

```bash
# list networks
docker network ls

# create a subnet (looks like this will create a virtual network adapter on a Linux host, but not a Mac)
docker network create \
                --subnet 10.1.0.0/16 \
                --gateway 10.1.0.1 \
                --ip-range=10.1.0.0/28 \
                --driver=bridge \
                bridge04

# start a container with a network, specifying a static IP for it
docker run \
        -it \
        --name test \
        --net bridge04 \
        --ip 10.1.0.2 \
        ubuntu:xenial /bin/bash

# OR
# connect a running container to a network,
# you can specify an IP address, and a network scoped alias for the container
docker network connect \
                --ip 10.1.0.2 \
                --alias ACoolName \
                bridge04 <container_name>

# show network settings and containers in this network
docker network inspect bridge04
```

### DNS

- By default, Docker passes the host's DNS config(`/etc/resolv.conf`) to a container;

- You can specify DNS servers by

  - Adding command line option `--dns`

  ```sh
  # specify DNS servers
  docker run -d \
          --dns=8.8.8.8 \
          --dns=8.8.4.4 \
          --name testweb \
          -p 80:80 \
          httpd
  ```

  - Adding configs in `/etc/docker/daemon.json` (affects all containers);

  ```js
  // in /etc/docker/daemon.json
  {
      ...
      "dns": ["8.8.8.8", "8.8.4.4"]
      ...
  }
  ```

### Swarm

After `docker swarm init`, Docker will create an overlay network called `ingress` and a bridge network called `docker_gwbridge` on every node.

```sh
docker network ls
# NETWORK ID          NAME                DRIVER              SCOPE
# ...
# hzmie3wc2krb        ingress             overlay             swarm
# a08d8933c9cf        docker_gwbridge     bridge              local

# show nodes in the ingress network
docker network inspect ingress
```

You can create your own overlay network:

```sh
# create another overlay network, this netowrk will be available to all nodes
docker network create \
                --driver=overlay \
                --subnet 192.168.1.0/24 \
                overlay0

# start a service using the above overlay network
docker service create \
                --name testweb \
                -p 80:80 \
                --network=overlay0 \
                --replicas 3 \
                httpd

# inspect the network, it will show containers in this network
docker network inspect overlay0
```

- An overlay network will be available to all nodes in a swarm;
- If the above service `testweb` runs on `node1.example.com` and `node2.exmaple.com`, you can access it from either domain;

### Network Driver Types

- bridge

  - default on stand-alone Docker hosts;
    - The default bridge network is `docker0` on the host, which has config:
      ```
      {
          "Subnet": "172.17.0.0/16",
          "Gateway": "172.17.0.1"
      }
      ```
    - The host is the gateway, has ip `172.17.0.1`;
  - all containers on this host will use this network by default, getting ips within `172.17.0.0/16`;
  - external access is granted by port exposure of the container's services and accessed by the host;

- none

  - when absolutely no networking is needed;
  - can only be accessed on the host;
  - can `docker attach <container-id>` or `docker exec -it <container-id>`;

- gateway bridge

  - automatically created when initing or joining a swarm;
  - special bridge network that allows overlay networks access to an individual Docker daemon's physical network;
  - all service containers running on a node is in this network;

- overlay

  - it is a 'swarm' scope driver: it extends itself to all daemons in the swarm (building on workers if needed);

- ingress

  - **A Special overlay network that load balances network traffic amongst a given service's working nodes**;
  - Maintains a list of all IP addresses from nodes of a service, when a request comes in, routes to one of them;
  - Provides '**routing mesh**', allows services to be exposed to the external network without having a replica running on every node in the Swarm;

![Swarm networking](images/docker-swarm-networking.png)

- When init/join a swarm, `docker_gwbridge` and `ingress` networks are created on each node, and there is a virtual `ingress-endpoint` container, which is part of both networks;
- When creating a service `web`, its containers are attached to both the `docker_gwbridge` and `ingress` network;
- When deploying a stack `xStack`, which have two services `s1` (2 replicas) and `s2` (1 replica), all three containers are in the `ingress` network, and the `docker_gwbridge` network of respective owning host;
  - There is an additional overlay network `xStack_default`, which is non-ingress;
  - Inside the stack, services are accessible by name `s1` and `s2`, so in `xStack_s1.1` you can `ping s2`;
  - But in `web.1`, you can't `ping s2`;
- Let's say `web` has a port binding `9000:80`, then when you visit `192.168.0.1:9000`, thru the `docker_gwbridge` network, it reaches `ingress-endpoint`, which keeps record of all ips of the `web` service, thru the `ingress` network, it routes the request to either `web.1` (10.0.0.6) or `web.2` (10.0.0.5);

### Port Publishing Mode

- Host

  - `mode=host` in deployment;
  - used in single host environment or in environment where you need complete control over routing;
  - ports for containers are only available on the underlying host system and are NOT avaliable for services which don't have a replica on this host;
  - in `docker-compose.yml` :

    ```yaml
    ports:
    - target: 80
        published: 8080
        rotocol: tcp
        mode: host      # specify mode here
    ```

- Ingress
  - provides 'routing mesh', makes all published ports available on all hosts, so that service is accessible from every node regardless whether there is a replica running on it or not;

## Docker Compose

A tool for defining and running multi-container Docker applications. Officially supported by Docker.

Steps for using Compose:

1. Define your app's environment with a `Dockerfile`;
2. Define the services that make up your app in `docker-compose.yml` so they can be run together (you may need to run `docker-compose build` as well);
3. Run `docker-compose up` to start your app;

```bash
# rebuild and updating a container
docker-compose up -d --build

# the same as
docker-compose build

docker-compose up -d

# make sure no cached images are used and all intermediate images are removed
#  use this when you updated package.json, see '--renew-anon-volumes' below as well
docker-compose build --force-rm --no-cache

## specicy a project name
docker-compose up -p myproject

# you can specify multiple config files, this allows you extending base configs in different environments
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### `docker-compose.yml`

- `docker-compose up|run` use this file to create containers;
- `docker stack deploy` use this file to deploy stacks to a swarm as well (the old way is to use `docker service create`, adding all options on the command line);
- Options specified in the `Dockerfile`, such as `CMD`, `EXPOSE`, `VOLUME`, `ENV` are respected;
- Network and volume definitions are analogous to `docker network create` and `docker volume create`;
- Options for `docker-compose up|run` only:

  - `build`: options applied at build time, if `image` is specified, it will be used as the name of the built image;

- Options for `docker stack deploy` only:

  - `deploy`: config the deployment and running of services;

#### `volumes`

```yaml
version: '2'

services:
  app:
    build:
    #...

    volumes:
      - .:/app # mount current directory to the container at /app
      - /app/node_modules # for "node_modules", use the existing one in the image, don't mount from the host

    #...
```

in the above example,

- the mounted volumes will override any existing files in the image, current directory `.` is mounted to `/app`, and will override existing `/app` in the image;
- but the image's `/app/node_modules` is preserved, not mounted from the host machine;

see details here: [Lessons from Building a Node App in Docker](http://jdlm.info/articles/2016/03/06/lessons-building-node-app-docker.html)

**There is a problem with this config**

see here: ["docker-compose up" not rebuilding container that has an underlying updated image](https://github.com/docker/compose/issues/4337)

- after you update `package.json` on your local, and run `docker-compose up --build`, the underlying images do get updated, because Docker Compose is using an old anonymous volume for `/app/node_modules` from the old container, so the new package you installed is absent from the new container;
- add a `--renew-anon-volumes` flag to `docker-compose up --build` will solve this issue;

#### `deploy`

- `restart_policy`
  - `condition`
    - `none` - never restart containers;
    - `on-failure` - when container exited with error;
    - `any` - always restart container, even when the host rebooted;
  - `max_attempts`
  - `delay`
  - `window`

### `env_file`

```sh
# api.env
NODE_ENV=test
```

```yaml
version: '3'
services:
  api:
    image: 'node:6-alpine'

    env_file:
     - ./api.env

    environment:
     - NODE_ENV=production
     - APP_VERSION          # get this value from shell env
```

This allows you provide a set of environment variables to the container, the precedence order of env variables:

1. Compose file;
2. Shell environment variable;
3. `env_file`;
4. Dockerfile;

In the above example, inside the container, `NODE_ENV` will be 'production', and `APP_VERSION` will be whatever value in the shell when you start the container;

### Variable substitution

```yaml
db:
  image: 'postgres:${POSTGRES_VERSION}'
  extra_hosts:
    sql: ${SQL}
```

```sh
# .env

POSTGRES_VERSION=10.2
SQL=1.2.3.4
```

Variables in a compose file get their value from either the running shell, or `.env` file.

Please note:

  - **Values in `.env` are used for variable substitution automatically, but they don't get set in the container's environment if you don't specify it with `env_file` in the compose file**;
  - In later versions of `docker-compose`, there is a new CLI option `--env-file`, which allows you to specify another file instead of `.env`, it's not the same as the `env_file` option in compose file;
  - `.env` file **doesn't** work with `docker stack deploy`;


### Networking

By default:

- Compose sets up a single network, every service is reachable by other services, using the service name as the hostname;

- In this example

  ```yaml
  # /path/to/myapp/docker-compose.yml

  version: '3'
  services:
    web:
      build: .
      ports:
        - '8000:8000'
      links:
        - 'db:database'
    db:
      image: mysql
      ports:
        - '8001:3061'
  ```

  - The network will be called `myapp_default`;
  - `web` can connect to the `db` thru `db:3061`;
  - Host can access the `db` thru `<docker_ip>:8001`;
  - The `links` directive defines an alias, so `db` can be accessed by `database` as well, it is not required;

#### Custom networks

```yaml
version: '3'
services:
  proxy:
    build: ./proxy
    networks:
      - frontend
  app:
    build: ./app
    networks:
      - frontend
      - backend
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    # Use a custom driver
    driver: custom-driver-1
  backend:
    # Use a custom driver which takes special options
    driver: custom-driver-2
    driver_opts:
      foo: '1'
      bar: '2'
```

- Define custom networks by top-level `networks` directive;
- Each service can specify which networks to join;
- In the example above, `proxy` and `db` are isolated to each other, `app` can connect to both;

See https://docs.docker.com/compose/networking/ for configuring the default network and connecting containers to external networks;

### Name collision issue

for the following example:

```yaml
# /path/to/MyProject/docker-compose.yml
version: '2'

services:
  app:
    build:
      #...
    #...
```

when you run

```bash
docker-compose up
```

it will create a container named `MyProject_app_1`, if you got another docker compose file in the same folder (or another folder with the same name), and the service is called `app` as well, the container name will collide, you need to specify a `--project-name` option:

```bash
docker-compose --project-name <anotherName> up
```

see [Proposal: make project-name persistent](https://github.com/docker/compose/issues/745)

## Docker machine

Docker Machine is a tool that lets you install Docker Engine on virtual/remote hosts, and manage the hosts with `docker-machine` commands.

![Docker machine](images/docker-machine.png)

```sh
# create a machine named 'default', using virtualbox as the driver
docker-machine create --driver virtualbox default

# list docker machines
docker-machine ls
# NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
# default   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.06.1-ce

# one way to talk to a machine: run a command thru ssh on a machine
docker-machine ssh <machine-name> "docker images"

# another way to talk to a machine: this set some 'DOCKER_' env variables, which make the 'docker' command talk to the specified machine
eval "$(docker-machine env <machine-name>)"

# get ip address
docker-machine ip

# stop and start machines
docker-machine stop <machine-name>
docker-machine start <machine-name>

# unset 'DOCKER_' envs
eval $(docker-machine env -u)
```

## Context

TODO

## Swarm mode

![Swarm-architecture](images/docker-swarm-architecture.png)

- A swarm consists of multiple Docker hosts which run in **swarm mode** and act as managers or/and workers;
- Advantage over standalone containers: You can modify a service's configuration without manually restart the service;
- You can run one or more nodes on a single physical computer, in production, nodes are typically distributed over multiple machines;
- A Docker host can be a manager, a worker or both;
- You can run both swarm services and standalone containers on the same Docker host;

```sh
# init a swarm
docker swarm init

# show join tokens
docker swarm join-token [worker|manager]

# join a swarm as a node (worker or manager), you can join from any machine
docker swarm join

# show nodes in a swarm (run on a manager node)
docker node ls

# leave the swarm
docker swarm leave
```

### Swarm on a single node

```yaml
version: '3'
services:
  web:
    image: garylirocks/get-started:part2
    deploy:
      replicas: 3 # run 3 instance
      resources:
        limits:
          cpus: '0.1'
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - '4000:80'
    networks:
      - webnet
networks:
  webnet: # this is a load-balanced overlay network
```

- **service**: A service only runs one image, but it specifies the way that image runs -- what ports it should use, how many replicas of the container should run, etc;
- **task**: A single container running in a service is called a task, a service contains multiple tasks;

```sh
# init a swarm
docker swarm init

# start the service, the last argument is the app/stack name
docker stack deploy -c docker-compose.yml getstartedlab
# creates a network named 'getstartedlab_webnet'
# creates a service named 'getstartedlab_web'

# list stacks/apps
docker stack ls

# list all services
docker service ls

# list tasks for this service
docker service ps getstartedlab_web
# ID                  NAME                 IMAGE                           NODE                    DESIRED STATE       CURRENT STATE           ERROR               PORTS
# o4u5rpngt6lq        getstartedlab_web.1   garylirocks/get-started:part2   linuxkit-025000000001   Running             Running 4 minutes ago
# oqaep03q6gkf        getstartedlab_web.2   garylirocks/get-started:part2   linuxkit-025000000001   Running             Running 4 minutes ago
# tebeg1r7mb9o        getstartedlab_web.3   garylirocks/get-started:part2   linuxkit-025000000001   Running             Running 4 minutes ago

# show containers
docker ps   # container ids and names are different from task ids and names
# CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                                     NAMES
# fb1ae6433344        garylirocks/get-started:part2   "python app.py"          8 minutes ago       Up 8 minutes        80/tcp                                    getstartedlab_web.1.o4u5rpngt6lqmv44io3k269tn
# 8a1b8a50ea52        garylirocks/get-started:part2   "python app.py"          8 minutes ago       Up 8 minutes        80/tcp                                    getstartedlab_web.2.oqaep03q6gkfy3rv09vvqk2ul
# e2523c31d341        garylirocks/get-started:part2   "python app.py"          8 minutes ago       Up 8 minutes        80/tcp                                    getstartedlab_web.3.tebeg1r7mb9odm2lf9mlx217e

# scale the app: update the replicas value in the compose file, then deploy again, no need to manually stop anything
docker stack deploy -c docker-compose.yml getstartedlab

# take down the app
docker stack rm getstartedlab

# take down the swarm
docker swarm leave --force
```

- Docker Swarm keeps history of each task, so `docker service ps <service>` will list both running and shutdown services, you can add a filter option to only show running tasks: `docker service ps -f "DESIRED-STATE=Running" <service>`;
- Or you can use `docker swarm update --task-history-limit <int>` to update the task history limit;

### Multi-nodes swarm example

![Swarm services diagram](images/docker-services-diagram.png)

```sh
# create docker machines
docker-machine create --driver virtualbox myvm1
docker-machine create --driver virtualbox myvm2

# list the machines, NOTE: 2377 is the swarm management port, 2376 is the Docker daemon port
docker-machine ls

# init a swarm on myvm1, it becomes a manager
docker-machine ssh myvm1 "docker swarm init --advertise-addr <myvm1 ip>"

# let myvm2 join as a worker to the swarm
docker-machine ssh myvm2 "docker swarm join --token <token> <ip>:2377"

# list all the nodes in the swarm
docker-machine ssh myvm1 "docker node ls"
# ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
# skcuugxvjltou1dvhzgogprs4 *   myvm1               Ready               Active              Leader              18.06.1-ce
# t57kref0g1zye30qrpabsexkk     myvm2               Ready               Active                                  18.06.1-ce

# connect to myvm1, so you can use your local `docker-compose.yml` to deploy an app without copying it
eval $(docker-machine env myvm1)

# deploy the app on the swarm
docker stack deploy -c docker-compose.yml getstartedlab

# list stacks
docker-demo docker stack ls
# NAME                SERVICES            ORCHESTRATOR
# getstartedlab       1                   Swarm

# list services
docker-demo docker service ls
# ID                  NAME                MODE                REPLICAS            IMAGE                           PORTS
# s6978kvj671c        getstartedlab_web   replicated          3/3                 garylirocks/get-started:part2   *:4000->80/tcp

# show tasks
docker-demo docker service ps getstartedlab_web
# ID                  NAME                  IMAGE                           NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
# bt422r4gsp3p        getstartedlab_web.1   garylirocks/get-started:part2   myvm2               Running             Running 4 minutes ago
# z6q4wzex8x4z        getstartedlab_web.2   garylirocks/get-started:part2   myvm1               Running             Running 4 minutes ago
# 3805vovw1ioq        getstartedlab_web.3   garylirocks/get-started:part2   myvm2               Running             Running 4 minutes ago

# now, you can visit the app by 192.168.99.100:4000 or 192.168.99.101:4000, it's load-balanced, meaning one node may redirect a request to another node

# you can also: update the app, then rebuild and push the image;
#               or, update docker-compose.yml and deploy again;

# tear down the stack
docker stack rm getstartedlab
```

![Swarm ingress routing](images/docker-swarm-ingress-routing-mesh.png)

### Multi-service stacks

Add `visualizer` and `redis` service to the stack,

- `visualizer` doesn't depend on anything, but it should be run on a manager node;
- `redis` need data persistence, we put it on the manager node, and add volume mapping as well;

```yml
version: '3'
services:
  web:
    # replace username/repo:tag with your name and image details
    image: username/repo:tag
    deploy:
      replicas: 5
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: '0.1'
          memory: 50M
    ports:
      - '80:80'
    networks:
      - webnet

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - '8080:8080'
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet

  redis:
    image: redis
    ports:
      - '6379:6379'
    volumes:
      - '/home/docker/data:/data'
    deploy:
      placement:
        constraints: [node.role == manager]
    command: redis-server --appendonly yes
    networks:
      - webnet

networks: webnet:
```

```sh
# add the data folder on the manager node
docker-machine ssh myvm1 "mkdir ./data"

# deploy again
docker stack deploy -c docker-compose.yml getstartedlab

# list services
docker service ls
# ID                  NAME                       MODE                REPLICAS            IMAGE                             PORTS
# t3g55qxamxnv        getstartedlab_redis        replicated          1/1                 redis:latest                      *:6379->6379/tcp
# 6h3c994a1evq        getstartedlab_visualizer   replicated          1/1                 dockersamples/visualizer:stable   *:8080->8080/tcp
# xzqj0epf49eq        getstartedlab_web          replicated          3/3                 garylirocks/get-started:part2     *:4000->80/tcp
```

## Configs

- Store non-sensitive info (e.g. config files) outside image or running containers;
- **Don't neet to bind-mount**;
- Added or removed from a service at any time, and services can share a config;
- Config values can be **generic strings or binary content** (up to 500KB);
- **Only available to swarm services**, not standalone containers;
- Configs are managed by swarm managers, when a service been granted access to a config, the config is mounted as a file in the container. (`/<config-name>`), you can set `uid`, `pid` and `mode` for a config;

### Basic usage using `docker config` commands

```sh
# create a config
echo "This is a config" | docker config create my-config -

# create a service and grant it access to the config
docker service create --name redis --config my-config redis:alpine

# inspect the config file in the container
docker container exec $(docker ps --filter name=redis -q) ls -l /my-config
# -r--r--r--    1 root     root            12 Jun  5 20:49 my-config

docker container exec $(docker ps --filter name=redis -q) cat /my-config
# This is a config

# update a service, removing access to the config
docker service update --config-rm my-config redis

# remove a config
docker config rm my-config
```

### Use for Nginx config

You have already got two secret files: `site.key`, `site.crt` and a config file `site.conf`:

```nginx
server {
    listen                443 ssl;
    server_name           localhost;
    ssl_certificate       /run/secrets/site.crt;
    ssl_certificate_key   /run/secrets/site.key;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
```

```sh
# create secrets and config
docker secret create site.key site.key
docker secret create site.crt site.crt
docker config create site.conf site.conf

# create a service using the secrets and config
docker service create \
     --name nginx \
     --secret site.key \
     --secret site.crt \
     --config source=site.conf,target=/etc/nginx/conf.d/site.conf,mode=0440 \
     --publish published=3000,target=443 \
     nginx:latest \
     sh -c "exec nginx -g 'daemon off;'"
```

in the running container, the following three files now exist:

- `/run/secrets/site.key`
- `/run/secrets/site.crt`
- `/etc/nginx/conf.d/site.conf`

### Rotate a config

Update `site.conf`:

```sh
# create a new config using the updated file
docker config create site-v2.conf site.conf

# update the service, removing old config, adding new one
docker service update \
  --config-rm site.conf \
  --config-add source=site-v2.conf,target=/etc/nginx/conf.d/site.conf,mode=0440 \
  nginx

# remove old config from the swarm
docker config rm site.conf
```

### Usage in `compose` files

- short syntax

  ```yml
  version: '3.3'
  services:
    redis:
      image: redis:latest
      deploy:
      replicas: 1
      configs:
        - my_config
        - my_other_config

  configs:
    my_config:
      file: ./my_config.txt
    my_other_config:
      external: true
  ```

- long syntax

  ```yml
  version: "3.3"
  services:
    redis:
      image: redis:latest
      deploy:
      replicas: 1
      configs:
        - source: my_config
          target: /redis_config
          uid: '103'
          gid: '103'
          mode: 0440

  configs:
    my_config:
      file: ./my_config.txt
    my_other_config:
      external: true
  ```

## Secrets

Sensitive data a container needs at runtime, should not be stored in the image or in source control:

- Usernames and passwords;
- TLS certificates and keys;
- SSH keys;
- Name of a database or internal server;
- Generic strings or binary content (up to 500kb);

Usage:

- Secret is encrypted in transition and at rest, it's replicated across all managers;
- Decrypted secret is mounted into the container in an in-memory filesystem, the mount point defaults to `/run/secrets/<scret_name>`;
- Management commands:

  - `docker secret create`;
  - `docker secret inspect`;
  - `docker secret ls`;
  - `docker secret rm`;
  - `--secret` flag for `docker service create`;
  - `--secret-add` and `--secret-rm` flags for `docker service update`;

**Secrets are persistent, they still exists after you restart docker daemon**

### Example: Use secrets with a WordPress service

the `mysql` and `wordpress` image has been created in a way that you can pass in environment variable for the password directly (`MYSQL_PASSWORD`) or for a secret file (`MYSQL_PASSWORD_FILE`).

```sh
# generate a random string as a secret 'mysql_password'
openssl rand -base64 20 | docker secret create mysql_password -

# root password, not shared with Wordpress service
openssl rand -base64 20 | docker secret create mysql_root_password -

# create a custom network, MySQL service doesn't need to be exposed
docker network create -d overlay mysql_private

# create a MySQL service using the above secrets
docker service create \
     --name mysql \
     --replicas 1 \
     --network mysql_private \
     --mount type=volume,source=mydata,destination=/var/lib/mysql \
     --secret source=mysql_root_password,target=mysql_root_password \
     --secret source=mysql_password,target=mysql_password \
     -e MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql_root_password" \
     -e MYSQL_PASSWORD_FILE="/run/secrets/mysql_password" \
     -e MYSQL_USER="wordpress" \
     -e MYSQL_DATABASE="wordpress" \
     mysql:latest

# create a Wordpress service
docker service create \
     --name wordpress \
     --replicas 1 \
     --network mysql_private \
     --publish published=30000,target=80 \
     --mount type=volume,source=wpdata,destination=/var/www/html \
     --secret source=mysql_password,target=wp_db_password,mode=0400 \
     -e WORDPRESS_DB_USER="wordpress" \
     -e WORDPRESS_DB_PASSWORD_FILE="/run/secrets/wp_db_password" \
     -e WORDPRESS_DB_HOST="mysql:3306" \
     -e WORDPRESS_DB_NAME="wordpress" \
     wordpress:latest

# verify the services are running
docker service ls
```

### Rotate a secret

Here we rotate the password of the `wordpress` user, not the root password:

```sh
# create a new password and store it as a secret
openssl rand -base64 20 | docker secret create mysql_password_v2 -

# remove old secret and mount it again under a new name, add the new password secret, which is still needed for actually updating the password in MySQL
docker service update \
     --secret-rm mysql_password mysql
docker service update \
     --secret-add source=mysql_password,target=old_mysql_password \
     --secret-add source=mysql_password_v2,target=mysql_password \
     mysql

# update MySQL password using the `mysqladmin` CLI
docker container exec $(docker ps --filter name=mysql -q) \
    bash -c 'mysqladmin --user=wordpress --password="$(< /run/secrets/old_mysql_password)" password "$(< /run/secrets/mysql_password)"'

# update WP service, this triggers a rolling restart of the WP service and make it use the new secret
docker service update \
     --secret-rm mysql_password \
     --secret-add source=mysql_password_v2,target=wp_db_password,mode=0400 \
     wordpress

# remove old secret
docker service update \
     --secret-rm mysql_password \
     mysql
docker secret rm mysql_password
```

### Example compose file

```yaml
version: '3.1'

services:
  db:
    image: mysql:latest
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_root_password
      - db_password

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - '8000:80'
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: db_password.txt
  db_root_password:
    file: db_root_password.txt

volumes: db_data:
```

## Tips / Best Practices

- On Mac, you can talk to a container through port binding, but you may **NOT** be able to ping the container's IP address;

- Don't put `apt-get update` on a different line than `apt-get install`, the result of the `apt-get update` will get cached and won't run every time, the following is a good example of how this should be done:

  ```
  # From https://github.com/docker-library/golang
  RUN apt-get update && \
      apt-get install -y --no-install-recommends \
      g++ \
      gcc \
      libc6-dev \
      make \
      && rm -rf /var/lib/apt/lists/*
  ```

- To utilize Docker's caching capability better, install dependencies first before copying over everything, this makes sure other changes don't trigger a rebuild (e.g. non `package.json` changes don't trigger node package downloads)

  ```
  COPY ./my-app/package.json /home/app/package.json   # copy over dependency config first
  WORKDIR /home/app/
  RUN npm install                 # result get cached here

  COPY ./my-app/ /home/app/       # copy over other stuff
  ```
