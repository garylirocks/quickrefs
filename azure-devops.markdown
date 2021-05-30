# Azure DevOps

- [Overview](#overview)
- [Pipelines](#pipelines)
  - [Multistage pipeline](#multistage-pipeline)
  - [Environments](#environments)
  - [Templates](#templates)
  - [Agent pools](#agent-pools)


## Overview

## Pipelines

To integrate with GitHub: 

- Azure Pipelines has an OAuth App and a GitHub App
  - the OAuth App allows it read your repo, update your code on behalf of you from within Azure
  - the GitHub App triggers the pipeline

- The YAML file `azure-pipelines.yml` in your repo defines the trigger, the build agent, and the pipeline steps.

```yaml
## A sample azure-pipelines.yml file

trigger:
  - "*"

# specify the build agent
pool:
  vmImage: "ubuntu-18.04"
  demands:
    - npm

# define custom variables
variables:
  myVariable: "foo"

steps:
  # built-in task
  - task: Npm@1
    displayName: "Run npm install"
    inputs:
      verbose: false

  # custom script task
  - script: 'echo "$(Build.DefinitionName), $(myVariable)" > buildinfo.txt'
    displayName: "Write build info"
    workingDirectory: src

  - ...
```

### Multistage pipeline

![Multistage pipeline](./images/azure-devops_pipeline-stages.png)

In this demo pipeline, there are four stages:

1. `Build` runs on every push, producing a `.zip` artifact
2. `Dev` only runs on `release` branch
3. `Test` runs on a cron schedule
4. `Staging` requires an approval

```yaml
trigger:
  - "*"

variables:        # global variables
  foo: "bar"

schedules:        # run on a cron schedule for 'release' branch
  - cron: '0 3 * * *'
    displayName: Deploy every day at 3 A.M.
    branches:
      include:
        - release
    always: false # only when the 'release' branch contains changes from the prior scheduled run

stages:
  - stage: "Build"
    displayName: "Build the web application"
    jobs:
      - job: "Build"
        displayName: "Build job"
        pool:
          vmImage: "ubuntu-18.04"
          demands:
            - npm

        variables:  # stage level variables
          foo2: "bar2"
          foo3: "bar3"

        steps:
          - task: Npm@1
            displayName: "Run npm install"
            inputs:
              verbose: false

          ...

          - publish: "$(Build.ArtifactStagingDirectory)"
            artifact: drop

  - stage: "Dev"
    displayName: "Deploy the web application"
    dependsOn: Build  # depends on previous stage
    condition: |  # only when the pipeline running on 'release' branch
      and (
        succeeded(),
        eq(variables['Build.SourceBranchName'], variables['releaseBranchName'])
      )
    jobs:
      - deployment: Deploy  # a shortcut for a job named 'Deploy' ?
        pool:
          vmImage: "ubuntu-18.04"
        environment: dev    # an environment is created automatically if it doesn't exist
        variables:
          - group: Release  #NOTE: make a variables group available to a job
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current   # download artifact from previous stage
                  artifact: drop

                - task: AzureWebApp@1
                  displayName: "Azure App Service Deploy: website"
                  inputs:
                    azureSubscription: "ServiceConnection 1"  # service connection name
                    appName: "$(WebAppName)"
                    package: "$(Pipeline.Workspace)/drop/$(buildConfiguration)/*.zip"

  - stage: "Test"
    displayName: "Deploy to the test environment"
    dependsOn: Dev
    condition: eq(variables['Build.Reason'], 'Schedule')  # only if the pipeline is triggered by a schedule
    jobs:
      - deployment: Deploy
        environment: test
        ...

  - stage: "Staging"
    displayName: "Deploy to the staging environment"
    dependsOn: Test
    jobs:
      - deployment: Deploy
        environment: staging
        ...
```

### Environments

Environment can have releasing criteria: approvals and checks


### Templates

For some common tasks, you could extract them into templates, then use them in each pipeline:

```yaml
parameters:
  buildConfiguration: 'Release'

steps:
  - task: DotNetCoreCLI@2
    displayName: 'Build the project - ${{ parameters.buildConfiguration }}'
    inputs:
      command: 'build'
      arguments: '--no-restore --configuration ${{ parameters.buildConfiguration }}'
      projects: '**/*.csproj'

  - task: DotNetCoreCLI@2
    displayName: 'Publish the project - ${{ parameters.buildConfiguration }}'
    inputs:
      command: 'publish'
      projects: '**/*.csproj'
      publishWebProjects: false
      arguments: '--no-build --configuration ${{ parameters.buildConfiguration }} --output $(Build.ArtifactStagingDirectory)/${{ parameters.buildConfiguration }}'
      zipAfterPublish: true
```

- Define variables in the `parameters` section
- Read a variable using syntax like `${{ parameter.foo }}`

To call the template from the pipeline:

```yaml
steps:
  ...

  # in case your template file is in the same repo at `templates/build.yml`
  # this section actually includes two steps
  - template: templates/build.yml
    parameters:
      buildConfiguration: 'Debug'

  - template: templates/build.yml
    parameters:
      buildConfiguration: 'Release'
```

### Agent pools

Build agent can be organized into pools, either Microsoft hosted or self-hosted.

Use self-hosted agent:
  - Install needed build tools, such as Node, NPM, Make, .NET, etc, each agent's capabilities are registered in a pool, Azure Piplines select the right one for a build job (which specifies capability requirement using the `demands` section)
    ```yaml
    pool:
      name: 'MyAgentPool'   # specify a self-hosted pool
      demands:
        - npm               # capability requirement for an agent
    ```
  - Generate a PAT (Personal Access Token) to register your hosted agent in a pool
  - You need to install the agent software on your machine, and start a daemon service to connect to the pool