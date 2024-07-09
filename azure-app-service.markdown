# Azure App Service

- [App Service](#app-service)
  - [App Service plans](#app-service-plans)
    - [SKUs](#skus)
  - [vNet integration](#vnet-integration)
    - [Networking](#networking)
    - [Routing](#routing)
    - [Permissions](#permissions)
    - [How](#how)
  - [Deployment](#deployment)
  - [App settings and connection strings](#app-settings-and-connection-strings)
  - [Deployment slots](#deployment-slots)
    - [Swap](#swap)
  - [Scaling](#scaling)
  - [Node app](#node-app)
  - [App Logs](#app-logs)
  - [Authentication](#authentication)
    - [Authentication flow](#authentication-flow)
    - [Authorization behavior](#authorization-behavior)
    - [Azure AD](#azure-ad)
    - [Token store](#token-store)
  - [Backup](#backup)
- [App Service Environment (ASE)](#app-service-environment-ase)
  - [Cost](#cost)
  - [Networking](#networking-1)
    - [Subnet](#subnet)
  - [Inbound](#inbound)
  - [Outbound](#outbound)
  - [Private endpoint](#private-endpoint)
  - [Domain](#domain)
    - [Custom domain](#custom-domain)
- [Kudu service](#kudu-service)
  - [RBAC permissions](#rbac-permissions)
- [Static Web Apps](#static-web-apps)
- [Azure Functions](#azure-functions)
  - [Durable functions](#durable-functions)

## App Service

Fully managed web application hosting platform, PaaS.

### App Service plans

A plan's **size** (aka **sku**, **pricing tier**) determines
  - the performance characteristics of the underlying virtual servers
  - features available to apps in the plan

#### SKUs

| Usage      | Tier                 | Instances | New Features                                   |
| ---------- | -------------------- | --------- | ---------------------------------------------- |
| Dev/Test   | Free                 | 1         |                                                |
| Dev/Test   | Shared(Windows only) | 1         | Custom domains                                 |
| Dev/Test   | Basic                | <=3       | Custom domains/SSL                             |
| Production | Standard             | <=10      | Staging slots, Daily backups, Traffic Manager  |
| Production | Premium              | <=30      | More slots, backups                            |
| Isolated   | Isolated             | <=100     | ASE, Isolated network, Internal Load Balancing |

- **Shared compute** (Free, Shared): VM shared with other customers
- **Dedicated compute** (Basic, Standard, Premium): run on dedicated Azure VMs, some resources are still shared, such as load balancer, file system, public IP, etc
- **Isolated**: dedicated VMs in dedicated vNets

Notes:

- Plans are the **unit of billing**. How much you pay for a plan is determined by the plan size(sku) and bandwidth usage, not the number of apps in the plan.
- You can start from an cheaper tier and scale up later.
- **Azure Functions** could be run in an App Service Plan as well.

### vNet integration

- Allows your app to make outbound calls to resources in or through a vNet
- **DOESN'T** grant inbound private access to your apps from the vNet, use **Private site access**
- This is for **Basic, Standard and Premium** tiers
  - Doesn't support Free, Shared tiers
  - Isolated tier apps are deployed into App Service Environment (ASE), which has all compute instances in your vNet already
- Features:
  - Support TCP and UDP.
  - Work with Azure App Service apps and function apps, and Logic Apps Standard.
  - No support for mounting a drive
- vNet integration is at the App Service plan level
  - Each app has its own settings about what should be routed via the integration
- Windows plans can have two vNet integrations, Linux plans only have one.
  - An integration can be shared by multiple apps in the same plan
  - An app can only have a single vNet integration at a given time

#### Networking

- Allow access to resources in:
  - Integration vNet
  - Peered vNets
  - On-prem via ExpressRoute or S2S VPN
  - Across Service Endpoints
- The integration subnet will be delegated to `Microsoft.Web/serverFarms`
- **Subnet size** considerations:
  - Each instance in your app plan needs a private IP in the subnet
  - If you use Windows Containers, you need one extra IP per app per instance
  - When you scale up/down in size (in/out in instances), the required address space is doubled for a short period of time
  - Minimum size is `/28`
- The private IP of an instance is exposed via environment variable `WEBSITE_PRIVATE_IP`
- No matter whether or not you route Internet traffic via the vNet, the destination determines the source address:
  - destination in integration vNet or peered vNet, the source address is the private IP
  - otherwise, source address is listed in your app properties
- After integration, your app uses the same DNS servers configured for your vNet, so it could be using Azure provided or custom DNS
- Limitations:
  - The integration vNet
    - Must be in the **same region** as the app
    - No IPv6 address space
  - The integration subnet
    - Can't have service endpoint policies enabled
    - Can only be used by one App Service Plan
  - You must "Disconnect" the integration first before you can update/delete the subnet/vnet

#### Routing

- Three types of routing:
  - **Application routing** defines what traffic is routed from your app and into the virtual network.
  - **Configuration routing** affects operations that happen before or during startup of your app. Examples are container image pull and app settings with Key Vault reference.
  - **Network routing** the routing appied at the subnet via NSG and UDR

- **Application routing**:
  - By default, your app only routes RFC1918 and service endpoints traffic into your vNet, if outbound internet traffic routing is enabled (`WEBSITE_VNET_ROUTE_ALL=1`), all outbound traffic is routed to the vNet
  - You could add a NAT gateway to the integration subnet for connection to the Internet
- **Configuration routing** (via public route by default, can be configured for individual components)
  - Content share (`properties.vnetContentShareEnabled`): often used by Functions app (often via port 443 or 445)
  - Container image pull (`properties.vnetImagePullEnabled`)
  - Backup/restore (`properties.vnetBackupRestoreEnabled`):
    - Custom backup to your own storage account
    - Database backup isn't supported over vNet integration
  - App settings using Key Vault references
    - Attempted if the KV blocks public access and the app is using vNet integration
    - Configure SSL/TLS certificate from private KV is not supported
  - App Service logs to private storage account is not supported, recommendation is using Diagnostic Logging and allowing trusted services for the storage account
  - If you use a private-endpoint only storage account for Standard Logic App, you need to set `WEBSITE_CONTENTOVERVNET = 1` to allow the app to access the storage account
- **Network routing**
  - NSG and route tables only apply to traffic routed through the integration subnet
  - NSG
    - inbound rules do not have any effect
    - outbound rules always in effect regardless of any route tables
  - Route tables apply to outbound calls, **do not** apply to replies to inbound app requests
  - Apart from endpoints your app needs to reach, some derived endpoints need to be considered:
    - CRL check endpoints
    - Identity/auth endpoints (eg. Microsoft Entra ID)
  - Service endpoints and private endpoints are supported

#### Permissions

- Need these permissions on the subnet: `Microsoft.Network/virtualNetworks/read`, `Microsoft.Network/virtualNetworks/subnets/read`, `Microsoft.Network/virtualNetworks/subnets/join/action`

#### How

- vNet integration works by mounting virtual interfaces to the worker roles with addresses in the delegated subnet. Customers don't have direct access to the virtual interfaces.
- Because the from address is in your vNet, it can access most things in or through your vNet like a VM in your virtual network would.

### Deployment

There are multiple ways to deploy an app:

- Azure DevOps
- GitHub (App Service can setup a GitHub action for you)
- BitBucket
- Local Git: You will be given a remote git url, pushing to it triggers a build.
- OneDrive
- Dropbox
- FTP
- CLI (`az webapp up`)

  Example:

  ```sh
  # get all variables
  APPNAME=$(az webapp list --query [0].name --output tsv)
  APPRG=$(az webapp list --query [0].resourceGroup --output tsv)
  APPPLAN=$(az appservice plan list --query [0].name --output tsv)
  APPSKU=$(az appservice plan list --query [0].sku.name --output tsv)
  APPLOCATION=$(az appservice plan list --query [0].location --output tsv)

  # go to your app directory
  cd ~/helloworld

  # deploy current working directory as an app
  # create a new app if there isn't one
  az webapp up \
    --name $APPNAME \
    --resource-group $APPRG \
    --plan $APPPLAN \
    --sku $APPSKU \
    --location "$APPLOCATION"

  # set as default
  az configure --defaults web=garyapp

  # open the app
  az webapp browse

  # live logs
  az webapp log tail
  ```

If your app is based on a docker container, then there will be a webhook url, which allows you to receive notifications from a docker registry when an image is updated. Then App Service can pull the latest image and restart your app.

If you are using an image from Azure Container Registry, when you enable '**Continuous Deployment**', the webhook is automatically configured in Container Registry.

### App settings and connection strings

App settings are passed to app code as environment variables, your app restarts when you update them
  - Linux/Container: passed as `--env` flags
  - ASP.NET/ASP.NET Core, like setting them in `Web.config` or `appsettings.json`, the values in App Service override the ones in the files

*Connection strings are similar to App settings, mainly for ASP.NET/ASP.NET Core app, for other language stack, it's better to use App settings.*

### Deployment slots

- A slot is a separate instance of your app, has its own hostname
- Each slot shares the resources of the App Service plan
- Only available in the Standard, Premium or Isolated tier
- You can create a new slot by cloning the config of an existing slot, but you can't clone the content, which needs to be deployed

If you app name is `garyapp`, the urls would be like

- production: https://garyapp.azurewebsites.net/
- staging: https://garyapp-staging.azurewebsites.net/


#### Swap

- You can create a **staging** slot, after testing, you can **swap** the staging slot with production slot, this happens instantly without any downtime.
- If you want rollback, swap again.
- App Service warms up the app by sending a request to the root of the site after a swap.
- When swapping two slots, configurations get swapped as well, unless a configuration is '**Deployment slot settings**', then it sticks with the slot (this allows you to config different DB connection strings or `NODE_ENV` for production and staging and make sure they don't swap with the app)
- 'Auto Swap' option is available for Windows.

### Scaling

- Built-in auto scale support
- Scale up/down: increasing/decreasing the resources of the underlying machine
- Scale out: increase the number of machines running your app, each tier has a limit on how many instances can be run

### Node app

If it's node, Azure will run `yarn install` automatically to install packages

You need to make sure the app:

- Is listening on `process.env.PORT`
- Uses `start` in `package.json` to start the app

### App Logs

|            | Windows                                 | Linux            |
| ---------- | --------------------------------------- | ---------------- |
| Log levels | Error, Warning, Information, Verbose    | Error            |
| Storage    | Filesystem, Blob                        | Filesystem       |
| Location   | A virtual drive at `D:\Home\LogFiles`   | Docker log files |
| Options    | Application, IIS server, Detailed Error | STDERR, STDOUT   |

On Linux, you need to open an SSH connection to the Docker container to get messages of underlying processes (such as Apache)

```sh
# tail live logs
az webapp log tail \
  --resource-group my-rg \
  --name my-web-app

# download logs
az webapp log download \
  --log-file logs.zip \
  --resource-group my-rg \
  --name my-web-app
```

### Authentication

You could turn on the built-in authentication and authorization middleware component.

![App authentication architecture](./images/azure_app-service-auth-architecture.png)

This module

- Is a feature of the platform that runs on the same VM as your app.
- Validates, stores and refreshes OAuth tokens issued by the configured IdP.
- Manages the authenticated session.
- Inject identity information into HTTP request headers, so your app code has access to current user's info.
- Runs separately, you don't need to modify your code.
- In Windows, it's a native IIS module, in Linux/Container, it's in a separate container.
- Each deployment slot should have its own config.

#### Authentication flow

| Step                               | Without provider SDK                                                                             | With provider SDK                                                                                                                               |
| ---------------------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Sign user in                    | Redirects client to `/.auth/login/<provider>`.                                                   | Client code signs user in directly with provider's SDK and receives an authentication token. For information, see the provider's documentation. |
| 2. Post-authentication             | Provider redirects client to `/.auth/login/<provider>/callback`.                                 | Client code posts token from provider to `/.auth/login/<provider>` for validation.                                                              |
| 3. Establish authenticated session | App Service adds authenticated cookie to response.                                               | App Service returns its own authentication token to client code.                                                                                |
| 4. Serve authenticated content     | Client includes authentication cookie in subsequent requests (automatically handled by browser). | Client code presents authentication token in `X-ZUMO-AUTH` header (automatically handled by Mobile Apps client SDKs).                           |

#### Authorization behavior

You could either

- Allow unauthenticated requests: then handles this in your code, such as presenting multiple sign-in providers
- Require authentication

You can inspect the user's claims for finer authorization. App service pass these two headers to your app code: `X-MS-CLIENT-PRINCIPAL-NAME`, `X-MS-CLIENT-PRINCIPAL-ID`


#### Azure AD

- If you use Azure AD, then an app registration is created
- The sign-in endpoint is at `/.auth/login/aad`, where user is redirected to automatically when un-authenticated
- By default, every user in your tenant can login/access the app, you could configure the application in AAD to restrict access to a defined set of users
  - Turn on the "Assignment required?" property
  - Assign the users/groups who need access

#### Token store

Tokens are cached in the store and passed to app code in headers like: `X-MS-TOKEN-AAD-ACCESS-TOKEN`, see https://docs.microsoft.com/en-us/azure/app-service/configure-authentication-oauth-tokens

### Backup

- You could do a full or partial backup
- Backup goes to a storage account and container in the same subscription
- Backup contains app configuration, files, and database connected to your app


## App Service Environment (ASE)

Comparing to app service plan:

- Larger scale: allows >30 compute instances
- More isolated: in your own vNet

You own isolated environment, dedicated to your organization, with the following benefits:

- External (behind a ELB) or internal (behind an ILB)
  - For external access, a good practice is using an internal ASE and put an AGW in front of it
- Host group
- Zone redundant
- No need for vNet integration, it's still in a vNet

After ASE is created,

- you can choose it as "Region" when you create a web app
- you still need to create app service plans in it

Limits:

- Up to 200 instances per ASE
- 1 - 100 instances in one app service plan

How:

- Apart from your own vNet, there is a hidden infrastructure vNet underneath, which is how the various ASE components talking to each other

### Cost

- You pay for the app service plans in the ASE
- The plans must be Isolated v2 SKUs, depending on the cores and RAM, SKUs could be like `I1v2`, `I1mv2`, `I2v2`,  `I2mv2`, etc
- If ASE is empty, you pay for 1 Isolated v2 SKU (if zone redundant, you pay for 9 Isolated v2 SKUs)

### Networking

#### Subnet

- You must delegate an empty subnet to `Microsoft.Web/hostingEnvironments`
- Size:
  - `/27` minimum
  - `/24` is recommended
  - use `/23` if you want to scale up to the max capacity of 200 instances
- Specific addresses used by an app in the subnet will change over time

### Inbound

- You can put an AGW in front of an internal ASE

### Outbound

- Apps use one of the default outbound addresses for egress traffic to public endpoints
- You can add an NAT gateway to the subnet
- You can also use a route table to direct traffic to a firewall/NVA
- Outbound SMTP (port 25) is supportted for ASEv3 (determined by a setting on the containing subscription of the vNet)

### Private endpoint

- To allow private endpoints for apps, you need to enabled this at the ASE level

  ```sh
  az appservice ase update --name <my-ase> --allow-new-private-endpoint-connections true
  ```

### Domain

- Internal apps will have domains like `<app-name>.<ase-name>.appserviceenvironment.net`
  - If you choose to use Azure Private DNS zones when creating ASE, it will be created for you
  - If you use your own custom DNS, and want to use this default domain, you need to add the zone to your custom DNS
- If you have custom domain for the ASE, the app will also have a domain like `<app-name>.<ase-custom-domain>`
  - For custom domain name to work for the `scm` site, you'll need `<app-name>.<ase-name>.appserviceenvironment.net` to be resolveable
- App name is truncated at 40 characters because of DNS limits, slot name is truncated at 19 characters
- By default, apps in ASE use the DNS configured on the vNet, but it could be customized on a per app basis with app settings: `WEBSITE_DNS_SERVER` and `WEBSITE_DNS_ALT_SERVER`

#### Custom domain

Apart from the default domain, you can add a custom domain

- The certificate needs to be stored in a key vault, the ASE needs a managed identity to retrieve it
- The key vault must be public accessible
- The certificate must be a wildcard certificate, such as `*.example.com`


## Kudu service

Anytime you create an app, App Service creates a companion app for it that's secured by HTTPS. This Kudu app is accessible at these URLs:

- App not in the Isolated tier: `https://<app-name>.scm.azurewebsites.net`
- Internet-facing app in the Isolated tier (ASE): `https://<app-name>.scm.<ase-name>.p.azurewebsites.net`
- Internal app in the Isolated tier (ASE for ILB): `https://<app-name>.scm.<ase-name>.appserviceenvironment.net`

Features:

- Run command in Kudu console
- Access
  - App settings
  - Connection strings
  - Environment variables
  - Server variables
  - HTTP headers
  - Logs

### RBAC permissions

- Built-in: Website Contributor, Contributor, Owner
- Custom: `Microsoft.Web/sites/publish/Action`


## Static Web Apps

![Static Web Apps overview](images/azure_static-web-apps-overview.png)

When you create a Static Web App, GitHub Actions or Azure DevOps workflow is added in the app's source code repository. It watches a chosen branch, everytime you push commits or create pull requests into the branch, the workflow builds and deploys your app and its API to Azure.

- Globally distributed web hosting
- Integrated API support by Azure Functions (the `/api` route points to it)
  - Locally, you could use the `func` tool to run API functions, it would be on another port, so need CORS configuration, put this in `api/local.settings.json`

    ```json
    {
      "Host": {
        "CORS": "http://localhost:3000"
      }
    }
    ```
  - On Azure, a reverse proxy would be setup for you automatically, so any call to `/api` is on the same origin, and proxied to the Azure Functions
- Free SSL certificates for custom domains
- Staging environment created automatically from pull request

```sh
az staticwebapp create \
    -g $resourceGroupName \
    -n $webAppName \
    -l 'westus2'
    -s $appRepository \       # repo
    -b main \                 # branch
    --token $githubToken      # github PAT token
```

This
  - adds a workflow file in the GitHub repo
  - a token for the staticwebapp is added to GitHub secrets
  - A staging environment is automatically created when a pull request is generated,
  - and are promoted into production once the pull request is merged.



```yaml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_GREEN_GLACIER_0BAB5B71E }}
          repo_token: ${{ secrets.GITHUB_TOKEN }} # this is auto-generated, used for Github integrations (i.e. PR comments)
          action: "upload"
          app_location: "."         # App source code path
          output_location: "dist"   # Optional: build artifacts path, relative to app_location
          api_location: "api"       # Optional: API source path, relative to root

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_GREEN_GLACIER_0BAB5B71E }}
          action: "close"
```

Notes:

  - When you close the pull request, it actually triggers 2 workflow runs, each runs a single job:
    - one for the PR closing action, the `close_pull_request_job` closes the staging environment
    - the `main` branch is updated as well, so the `build_and_deploy_job` updates the live environment

  - *When you create an app in the Azure Portal, you specify the build presets (such as, React, Vue, Gatsby etc), and the `app_location`, `api_location`, `output_location`, so your app would be automatically built and uploaded by GitHub Actions*

  - Here is an example of live and staging URLs:

    | Source          | Description                | URL                                                   |
    | --------------- | -------------------------- | ----------------------------------------------------- |
    | main branch     | Live web site URL (global) | https://my-app-23141.azurestaticapps.net/             |
    | Pull Request #3 | Staging URL (one region)   | https://my-app-23141-3.centralus.azurestaticapps.net/ |

  - For a static web app, you likely need to respond all routes with `index.html`, you need a `staticwebapp.config.json` file in the build output directory for this:

    ```json
    // fall back to `index.html`
    {
      "navigationFallback": {
        "rewrite": "index.html",
        "exclude": ["/images/*.{png,jpg,gif,ico}", "/*.{css,scss,js}"]
      }
    }
    ```

## Azure Functions

Benefits:

- Auto scaling, pay for what you use
- No need to manage servers
- Stateless logic
- Event driven

Drawbacks:

- Execution time limits (5 ~ 10min)
- Execution frequency (if need to be run continuously, may be cheaper to use a VM)

Triggers:

- Timer
- HTTP
- Blob (file uploaded/updated)
- Queue messages
- Cosmos DB (a document changes in a collection)
- Event Hub (receives a new event)

Bindings:

- A declarative way to connect to data (so you don't need to write the connection logic)
- Input bindings and output bindings
- Triggers are special types of input bindings
- Configured in a JSON file _function.json_

Example:

![Azure Functions bindings flow](./images/azure-functions_bindings_example.png)

Pass in an `id` and `url` from a HTTP request, if a bookmark with the id does not already exist, add to DB and push to a queue for further processing

`function.json`

```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    },
    {
      "name": "bookmark",
      "direction": "in",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "id": "{id}",
      "partitionKey": "{id}"
    },
    {
      "name": "newbookmark",
      "direction": "out",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "partitionKey": "{id}"
    },
    {
      "name": "newmessage",
      "direction": "out",
      "type": "queue",
      "queueName": "bookmarks-post-process",
      "connection": "storageaccountlearna8ff_STORAGE"
    }
  ]
}
```

`index.js`

```js
module.exports = function (context, req) {
  var bookmark = context.bindings.bookmark;
  if (bookmark) {
    context.res = {
      status: 422,
      body: 'Bookmark already exists.',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  } else {
    // Create a JSON string of our bookmark.
    var bookmarkString = JSON.stringify({
      id: req.body.id,
      url: req.body.url
    });

    // Write this bookmark to our database.
    context.bindings.newbookmark = bookmarkString;
    // Push this bookmark onto our queue for further processing.
    context.bindings.newmessage = bookmarkString;
    // Tell the user all is well.
    context.res = {
      status: 200,
      body: 'bookmark added!',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  }
  context.done();
};
```

- `id` in `req` will be available as `id` to the `cosmosDB` binding;
- If `id` is found in the DB, `bookmark` will be set;
- `"connectionStringSetting": "gary-cosmos_DOCUMENTDB"` is an application setting in app scope, not restricted to current function, available to the function as an env variable;
- Simply assign a value to `newbookmark` and `newmessage` for output

### Durable functions

![Durable function patterns](./images/azure-durable_function_workflow_patterns.png)

There are three different functions types, the table below show how to use them in the human interactions workflow:

| Workflow function                    | Durable Function Type             |
| ------------------------------------ | --------------------------------- |
| Submitting a project design proposal | Client Function (trigger)         |
| Assign an Approval task              | Orchestration Function (workflow) |
| Approval task                        | Activity Function                 |
| Escalation task                      | Activity Function                 |

- You need to run `npm install durable-functions` from the `wwwroot` folder of your function app in Kudu
