Docker
============
- [Docker](#docker)
    - [General](#general)
        - [Overview](#overview)
        - [commands](#commands)
    - [Images vs. Containers](#images-vs-containers)
        - [Images](#images)
        - [Containers](#containers)
    - [Dockerfile](#dockerfile)
        - [Example](#example)
        - [`RUN`](#run)
        - [`CMD`](#cmd)
        - [`ENTRYPOINT`](#entrypoint)
        - [`ENV`](#env)
        - [.dockerignore](#dockerignore)
    - [Volumns](#volumns)
    - [Network](#network)
    - [Docker Compose](#docker-compose)
        - [`docker-compose.yml`](#docker-composeyml)
    - [Misc](#misc)


docker basics:

[Why You Should Stop Installing Your WebDev Environment Locally - Smashing Magazine](https://www.smashingmagazine.com/2016/04/stop-installing-your-webdev-environment-locally-with-docker/)

## General

### Overview

* docker has a client-server architecture;
* client and server can be on the same system or different systems;
* client and server communicates via sockets or a RESTful API;

![Docker Architecture Overview](./images/docker-architecture.svg)

a more detailed view of the workflow

![Docker Workflow](./images/docker-workflow.png)


### commands

```bash
# show installation info
docker info

# search images
docker search <query>

# monitoring (show container events, such as: start, network connect, stop, die, attach)
docker events
```

## Images vs. Containers

A container is a running instance of an image, when you start an image, you have a running container of the image, you can have many running containers of the same image;

### Images

* created with `docker build`;
* can be stored in a registry, like Docker Hub;
* images can't be modified;
* a image is composed of layers of other images, allowing minimal amount of data to be sent when transferring images over the network;
  
    for example, in the following `Dockerfile`, each line creates a new layer above the previous layer

    ```
    FROM ubuntu             # This has its own number of layers say "X"
    MAINTAINER FOO          # This is one layer 
    RUN mkdir /tmp/foo      # This is one layer 
    RUN apt-get install vim # This is one layer 
    ```

    ![Docker layers](images/docker-layers.png)
     
* commands
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

* about image tags

    ```bash
    docker images

    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    node                9.7.1               993f38da6c6c        4 months ago        677MB
    node                8.5.0               de1099630c13        10 months ago       673MB
    ```

    an image's full tag is of this format `[REGISTRYHOST/][USERNAME/]NAME[:TAG]`, the `REPOSITORY` column above is just the `NAME` part, you specify a tag with `-t` option when building an image, the version tag will be `latest` by default

### Containers

* conatiners can be started and stopped, the filesystem changes are persisted in a stopped container, they are still there when the container restarts;

* you can create a new image from a container's changes with `docker commit`;
  
* commands:

    ```bash
    # list running containers
    docker ps

    # list all containers
    docker ps -a

    # inspect a container
    docker inspect <container>

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

    # remove a container
    docker rm [CONTAINER_ID]
    ```


## Dockerfile

### Example

```docker
FROM ubuntu:xenial
MAINTAINER einstein <einstein@example.com>

# add a user to the image
RUN useradd -ms /bin/bash einstein

# use this username when running any command, (root is always created)
USER einstein

RUN apt-get update
RUN ate-get install --yes openssh-server
```

```bash
# run an image using a specified user (`0` for `root`)
docker run -u 0 -it <image> /bin/bash
```

### `RUN`

* `RUN` will execute commands in a new layer on top of current image and commit the results, the resulting image will be used for the next step in the `Dockerfile`;
* the command is ran by root user by default, if a `USER` directive is present, following `RUN` commands will be ran by that user;


it has two forms:

* `RUN <command>` (*shell* form)

    * use `/bin/sh -c` by default on Linux;
    * the default shell can be changed using the `SHELL` command;
    * you can use a `\` to continue a single instruction on the next line

        ```
        RUN /bin/bash -c 'source $HOME/.bashrc; \
        echo $HOME'

        # equivalent to 
        RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
        ```

* `RUN ["executable", "param1", "param2"]` (*exec* form)

    * make it possible to avoid shell string munging, and to `RUN` commands using a base image that does not contain the specified shell executable;
    * it's parsed as a JSON array, so you must use double-quotes `"`;

the cache for `RUN` instructions isn't invalidated automatically during the next build, use a `--no-cache` flag to invalidate it

### `CMD`

* `CMD` sets the command to be executed when running the image, it is not executed at build time;
* arguments to `docker run` will overide `CMD`;
* 

has three forms:

* `CMD ["executable", "param1", "param2"]` (*exec* from, preferred)

    * must use double quotes;
    * the "executable" must be in full path;

* `CMD ["param1", "param2"]` (as *default* params to `ENTRYPOINT`)

    * in this form, an `ENTRYPOINT` instruction should be specified with the JSON array format;
    * this form should be used when you want your container to run the same executable every time;

* `CMD command param1 param2` (*shell* form)
  

**differencies to `RUN`**

* `RUN` actually runs a command and commits the result, `CMD` does not execute at build time, but specifies what to be ran when instantiating a container out of the image;
* there can be multiple `RUN` command in one `Dockerfile`, but there should only be one `CMD`;

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

### .dockerignore

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

## Volumns

mount a host directory to a container

```bash
docker run -it -v /home/gary/code/super-app:/app ubuntu
```

## Network

* by default, docker assigns IP address starting from `172.17.0.2` to container instances;

```bash
# list networks
docker network ls

# create a subnet (looks like this will create a virtual network adapter on a Linux host, but not a Mac)
docker network create --subnet 10.1.0.0/16 --gateway 10.1.0.1 --ip-range=10.1.4.0/24 --driver=bridge --label=host4network bridge04

# use a network, and specify a static IP for it
docker run -it --name test --net bridge04 --ip 10.1.4.100 ubuntu:xenial /bin/bash
```


## Docker Compose

A tool for defining and running multi-container Docker applications. Officially supported by Docker.

Steps for using Compose:

1. Define your app's environment with a `Dockerfile`;
2. Define the services that make up your app in `docker-compose.yml` so they can be run together (you may need to run `docker-compose build` as well);
3. Run `docker-compose up` to start your app;


```bash
# rebuil and updating a container
docker-compose up -d --build 

# the same as
docker-compose build 

docker-compose up -d
```

### `docker-compose.yml`

```yaml
version: "2"

services:
    app:
        build: 
            #...

        volumes:
            - .:/app                # mount current directory to the container at /app
            - /app/node_modules     # for "node_modules", use the existing one in the image, don't mount from the host

        #...
```

in the above example, the mounted volumes will override any existing files in the image, current directory `.` is mounted to `/app`, and will override existing `/app` in the image, but the image's `/app/node_modules` is preserved, not mounted from the host machine


## Misc

* on Mac, you can talk to a container through port binding, but you may **NOT** be able to ping the container's IP address;
