# Azure DevOps

- [Overview](#overview)
- [Pipelines](#pipelines)
  - [Multistage pipeline](#multistage-pipeline)
  - [Templates](#templates)
  - [Agent pools](#agent-pools)
- [Tests](#tests)
- [Deployment patterns](#deployment-patterns)


## Overview

## Pipelines

To integrate with GitHub: 

- Azure Pipelines has an OAuth App and a GitHub App
  - the OAuth App allows it read your repo, update `azure-pipelines.yml` file directly from within Azure
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
      - deployment: Deploy  # a deployment job
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

      - job: RunUITests
        dependsOn: Deploy # Depends on another job in the same stage
        displayName: 'Run UI tests'
        pool:
          vmImage: 'windows-2019'
        variables:
          - group: 'Release'
        ...

  - stage: "Staging"
    displayName: "Deploy to the staging environment"
    dependsOn: Test
    jobs:
      - deployment: Deploy
        environment: staging
        ...
```

- An environment is created automatically if it does not exist, you can create one manually and add approvals and checks to it;
- Jobs in a stage can run in any order or in parallel, use `dependsOn` to make them run in correct order
- Useful stage conditions:

  ```yaml
  dependsOn:    # depends on 2 stages
    - Stage1
    - Stage2
  condition: |  # Stage1 need to be successful, Stage2 could be skipped
    and
    (
      succeeded('Stage1'),
      in(dependencies.Stage2.result, 'Succeeded', 'Skipped')
    )
  ```


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


## Tests

- Functional tests
  - **Smoke testing**: most basic functionality, eg. `curl` to verify a web page returns 200
  - **Unit testing**: test individual function and method
  - **Integration testing**: multiple components work together, eg. add products to shoping car and then check out
  - **Regression testing**: make sure one component change doesn't affect other components, might involve just running unit tests and integration test for every change
  - **Sanity testing**: usually manually verify the software appears to be working before more thorough testing
  - **UI testing**: verify UI displays correctly and a sequence of interactions leads to expected result
  - **Usability testing**: usually manual, verify the software is intuitive
  - **User acceptance testing (UAT)**: typically done by real end users

- Nonfunctional tests

  - Performance testing
    - **Load testing**: performance at the upper limit of its SLA
    - **Stress testing**: under abnormally heavy loads, whether the application would fail gracefully
  - Security testing
    - **Penetration testing**: vulnerabilities
    - **Compliance testing**: eg. PCI, HIPPA

## Deployment patterns

Deployment pattern is an automated way to smoothly roll out new application features to users. It
  - helps you minimize downtime 
  - may enable you to roll out new features progressively
  - give you a chance to run tests that should happen in production

Common patterns:

- Blue-green deployment

  ![Deployment Pattern Blue-green](images/azure-devops_blue-green-deployment.png)

  - switch the router to release
  - easy to roll back

- Canary releases

  ![Deployment Pattern Canary](images/azure-devops_canary-deployment.png)

  - expose features to a small subset of user before make it available to everyone

- Feature toggles

  ![Deployment Pattern Feature toggles](images/azure-devops_feature-toggles.png)

- Dark launches

  ![Deployment Pattern Dark launches](images/azure-devops_dark-launches.png)

  - similar to canary release, but don't highlight new features

- A/B testing

  ![Deployment Pattern a-b testing](images/azure-devops_a-b-testing.png)

  - randomly show users two or more variations of a page, then use statistical analysis to decide which one performs better

- Progressive-exposure deployment

  ![Deployment Pattern progressive exposure](images/azure-devops_progressive-exposure-deployment.png)

