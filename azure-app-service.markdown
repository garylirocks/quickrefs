# Azure App Service

- [App Service](#app-service)
  - [App Service plans](#app-service-plans)
    - [SKUs](#skus)
  - [vNet integration](#vnet-integration)
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

| Usage      | Tier                 | Instances | New Features                                  |
| ---------- | -------------------- | --------- | --------------------------------------------- |
| Dev/Test   | Free                 | 1         |                                               |
| Dev/Test   | Shared(Windows only) | 1         | Custom domains                                |
| Dev/Test   | Basic                | <=3       | Custom domains/SSL                            |
| Production | Standard             | <=10      | Staging slots, Daily backups, Traffic Manager |
| Production | Premium              | <=30      | More slots, backups                           |
| Isolated   | Isolated             | <=100     | Isolated network, Internal Load Balancing     |

- **Shared compute** (Free, Shared): VM shared with other customers
- **Dedicated compute** (Basic, Standard, Premium): run on dedicated Azure VMs
- **Isolated**: dedicated VMs in dedicated vNets

Plans are the unit of billing. How much you pay for a plan is determined by the plan size(sku) and bandwidth usage, not the number of apps in the plan.

Azure Functions could be run in an App Service Plan as well.

You can start from an cheaper plan and scale up later.

### vNet integration

- Allows your app to make outbound calls to resources in or through a vNet
- **DOESN'T** grant inbound private access to your apps from the vNet
- This is for **Standard and Premium** plans
  - Doesn't support Free, Shared and Basic plans
  - Isolated plan apps are deployed into App Service Environment, which has all compute instances in your vNet already
- Behaves differently depending on whether the vNet is in the same or other regions:
  - Same region
    - You must have a dedicated subnet in the target vNet
    - Allow access to resources in:
      - target vNet
      - peered vNets
      - ExpressRoute connected networks
      - Across Service Endpoints
  - Other regions
    - You need a vNet gateway (point-to-site) provisioned in the target vNet
    - Provides access to resources in
      - target vNet
      - peered vNets
      - VPN connected networks
    - No access to resources across ExpressRoute or Service Endpoints
- Features:
  - Require a Standard, Premium, PremiumV2, PremiumV3, or Elastic Premium pricing plan.
  - Support TCP and UDP.
  - Work with Azure App Service apps and function apps, and Logic Apps Standard.

- Azure networking features:
  - NSG outbound rules apply on your integration subnet, inbound rules do not, because vNet integration do not provide inbound access to your app.
  - UDRs apply to outbound calls, **do not** affect replies to inbound app requests
  - By default, your app only routes RFC1918 traffic into your vNet, if you add application setting `WEBSITE_VNET_ROUTE_ALL=1` into your app, all outbound traffic is routed to the vNet
    - You could add a NAT gateway to the integration subnet for connection to the Internet
  - Outbound traffic is still sent from addresses listed in your app properties
  - After integration, your app uses the same DNS servers configured for your vNet. To work with private DNS zones, you need these app settings:
    - `WEBSITE_DNS_SERVER=168.63.129.16`
    - `WEBSITE_VNET_ROUTE_ALL=1`

- It's different to **Private site access**, which refers to making an app accessible only from a private network

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
