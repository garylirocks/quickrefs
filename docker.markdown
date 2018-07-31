Docker
============
- [Docker](#docker)
    - [General](#general)
        - [Overview](#overview)
    - [Images vs. Containers](#images-vs-containers)
        - [Images](#images)
        - [Containers](#containers)
    - [Dockerfile](#dockerfile)
        - [`RUN`](#run)
        - [`CMD`](#cmd)
        - [.dockerignore](#dockerignore)
    - [Docker Compose](#docker-compose)
        - [`docker-compose.yml`](#docker-composeyml)


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

    # remove image
    docker rmi [IMAGE_ID]

    # remove dangling images
    docker image prune
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

    # execute a command in a container
    docker exec node-box "node" "myapp.js"

    # remove a container
    docker rm [CONTAINER_ID]
    ```

## Dockerfile

### `RUN`

`RUN` will execute commands in a new layer on top of current image and commit the results, the resulting image will be used for the next step in the `Dockerfile`

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

* `RUN` actually runs a command and commits the result, `CMD` does not execute at build time, but specifies the intended command for the image;
* there can be multiple `RUN` command in one `Dockerfile`, but there should only be one `CMD`;


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



