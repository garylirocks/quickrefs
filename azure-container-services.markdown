# Azure container services

- [Docker Container Registry](#docker-container-registry)
  - [Tasks feature](#tasks-feature)
  - [Authentication options](#authentication-options)
    - [Individual AD identity](#individual-ad-identity)
    - [Service principal](#service-principal)
  - [Replication](#replication)
- [Container Instance](#container-instance)
  - [Container groups](#container-groups)
- [Container Apps (ACA)](#container-apps-aca)
- [Container security best practices](#container-security-best-practices)


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


## Container Apps (ACA)

// TODO


## Container security best practices

- Enforce least privileges in runtime
  - Avoid privileged containers (run as root)
- Preapprove files and executables that the container is allowed to access or run
- Enforce network segmentation on running containers
- Monitor container activity and user access
- Monitor resources accessed by your containers
- Log all container administrative user access for auditing
