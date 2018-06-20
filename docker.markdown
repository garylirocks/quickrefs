Docker
============

docker basics:

[Why You Should Stop Installing Your WebDev Environment Locally - Smashing Magazine](https://www.smashingmagazine.com/2016/04/stop-installing-your-webdev-environment-locally-with-docker/)

## Basic Commands

```bash
# list running containers
docker ps

# list all containers
docker container ls -a

# list images
docker images
```

execute a command in a container
```bash
docker exec node-box "node" "myapp.js"
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



