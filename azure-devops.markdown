# Azure DevOps

- [Overview](#overview)
- [organization-project-team structure](#organization-project-team-structure)
  - [How to structure a project](#how-to-structure-a-project)
  - [Processes](#processes)
  - [Work item](#work-item)
  - [Backlogs, Boards, Taskboards and Plans](#backlogs-boards-taskboards-and-plans)
  - [Teams vs. Groups](#teams-vs-groups)
  - [Scoped under team](#scoped-under-team)
  - [Boards-GitHub Connection](#boards-github-connection)
- [Pipelines](#pipelines)
  - [Overview](#overview-1)
  - [Multistage pipeline](#multistage-pipeline)
    - [Stage dependencies](#stage-dependencies)
  - [Variables](#variables)
    - [Scopes](#scopes)
    - [Naming](#naming)
    - [Syntax](#syntax)
    - [Environment variables](#environment-variables)
    - [Specify variables](#specify-variables)
    - [Secret variables](#secret-variables)
    - [Set variables and use output variables](#set-variables-and-use-output-variables)
  - [Predefined variables](#predefined-variables)
  - [Expressions](#expressions)
  - [Templates](#templates)
  - [Variable templates](#variable-templates)
  - [Use Key Vault secrets in pipelines](#use-key-vault-secrets-in-pipelines)
  - [Artifacts in Azure Pipelines](#artifacts-in-azure-pipelines)
    - [Publish](#publish)
    - [Download](#download)
  - [Resources](#resources)
  - [Checkout task](#checkout-task)
    - [Triggering](#triggering)
  - [Job authorization](#job-authorization)
    - [Job authorization scope](#job-authorization-scope)
    - [Built-in identities](#built-in-identities)
  - [Agent pools](#agent-pools)
  - [Deployment jobs](#deployment-jobs)
    - [Deployment strategies](#deployment-strategies)
  - [GitHub integration](#github-integration)
- [Artifacts](#artifacts)
- [Tests](#tests)
- [Deployment patterns](#deployment-patterns)
- [CLI](#cli)


## Overview

## organization-project-team structure

![Organization hierarchy overview](images/azure-devops_organization-project-overview.png)

  - Organization is also called project collection.
  - Project could be either private or public.
  - It is recommended to use just **a single project for an organization**, unless:
    - To support custom work tracking process for specific business units
    - To prohibit or manage access to the information contained within a project to select groups
    - To support entirely separate business units that have their own policies and administrators
  - Project can not be moved to another organization without losing history data
  - Each project has a default team (which is also a security group), you can add more teams.
  - Some project resources are scoped under a team, such as Notifications, Dashboards, Iteration and Area Paths

### How to structure a project

  - Create a GIT repo for each subproject or application
  - Define area paths to support different subprojects, products, features or teams
  - Define iteration paths (AKA sprints) that can be shared across teams
  - Add a team for people that develops a set of features for a product
  - Grant or restrict access to select features and functions using custom security groups


### Processes

You need to choose a workflow process when you create a project, it could be one of the default processes (Basic, Agile, Scrum, CMMI), or a custom one which inherits one of the defaults;

The processes mainly differ in the work item types (WITs)

- Basic

  ![Basic process work item types](images/azure-devops_work-item-types-basic.png)

  Issues and Tasks are used to track work, epics are used to group work under larger scenarios.

- Agile

  ![Agile process work item types](images/azure-devops_work-item-types-agile.png)

  Each team can configure how they manage Bugs, at the same level as User Stories or Tasks

- Scrum

  ![Scrum process work item types](images/azure-devops_work-item-types-scrum.png)

  Similar to Agile process, 'User Story' is called 'Product backlog item', 'Issue' is called 'Impediment'

Workflow states

| Basic              | Agile                                  | Scrum                                   | CMMI                               |
| ------------------ | -------------------------------------- | --------------------------------------- | ---------------------------------- |
| To Do, Doing, Done | New, Active, Resolved, Closed, Removed | New, Approved, Committed, Done, Removed | Proposed, Active, Resolved, Closed |


### Work item

- Use work items to track anything you need to track
- Work item types(WIT) available in a project are based on the process used when your project was created (Basic, Agile, Scrum or CMMI)

- WIT categories determine which types appear on backlogs and boards

  | Category    | Work item type                                                                      | Controls backlogs/boards                        |
  | ----------- | ----------------------------------------------------------------------------------- | ----------------------------------------------- |
  | Epic        | Epic                                                                                | Epic portfolio backlogs and boards              |
  | Feature     | Feature                                                                             | Feature portfolio backlogs and boards           |
  | Requirement | User Story (Agile), Issue (Basic), Product Backlog Item (Scrum), Requirement (CMMI) | Product backlogs and boards and Sprints backlog |
  | Task        | Task                                                                                | Sprints Taskboards                              |
  | Bug         | Bug                                                                                 | Dependent on how bugs are tracked               |

- You can add custom work item types
- You can add fields, change the workflow, add custom rules and add custom pages to the work item form
- Work items can link to each other, there are different link types, such as parent-child, predecessor-successor:

  ![work item link types](images/azure-devops_work-item-link-types.png)

### Backlogs, Boards, Taskboards and Plans

- Backlogs display items as a list and boards display them as cards
- Product backlog: quickly plan and prioritize work
- Use sprint backlogs and taskboards when you work in Scrum
- Use Kanban board to update work status
- Each backlog is associated with a board, changes to priority order you make in one are reflected in its corresponding board
- Plans allow you to review the deliverables for several teams across sprints and a calendar schedule
- Backlogs, boards and plans are configurable for each team

Three classes of backlogs
  - Portfolio: high level features, scenarios or epics
  - Product: user stories, deliverables, or work you plan to build or fix
  - Sprint: items in a scheduled sprint

Two types of boards
  - Kanban: track requirements, sprint-independent, monitor the flow through the cumulative flow chart
  - Taskboards: tasks defined for a sprint and you monitor the flow via the sprint burndown chart


### Teams vs. Groups

- Each team you create automatically creates a security group for that team, so you can manage permissions for a team;
- There are security groups at both organization and project level;
- Groups could be nested;
- All security groups are organizational level entities, even groups that only have permissions to a specific project;

**A permission caveat:** *If you were in multiple groups, they have different permissions, you may get permissions inherited from the less permissive group, in this case, you could remove yourself from that less permissive group*

### Scoped under team

- Backlog navigation levels
  - Epics
  - Issues
- Working days (for capacity and burndown report)
- Iteration Paths (Sprints)
- Area Paths

  You define area and iteration paths for a project, each team can choose one or more paths to specify which work items will appear on their backlogs and boards

Recommendations on how to configure project and teams:

- Determine the number and names of area paths that you want to categorize your work. At a minimum, add **one area path for each team you define**.
- Define the area paths in `Project configuration`
- Determine the number and names of teams
- Add teams
- Open the team configuration and assign the default and additional area paths to each team
- Assign the area path of work items to an area path you defined

    **It's not recommended to assign the same area path to multiple teams**

- Determine the length of the iteration

    **Recommended practice is to have all teams use the same sprint cadence**

- Determine if you want a flat structure or hierarchy of sprints and releases
- Define the iteration paths in `Project configuration`
- Assign the default and additional iteration paths to each team

![Iteration paths example](images/azure-devops_iteration-paths-example.png)

Iterations don't enforce any rules, at the end of an iteration, you can move any remaining active items to next iteration or back to the backlog

### Boards-GitHub Connection

After you add a connection to a GitHub repo in the settings, you could add a link up work items in Azure Boards with GitHub commits, issues, pull requests.

For example:

A commit message like `Fix #2, Fix AB#113` should
  - close Issue 2 in GitHub
  - add a link in Azure Boards work item #113 and update its state to be `Done`

## Pipelines

### Overview

Azure Pipelines can be defined in either a YAML file (recommended), or with the Classic Editor. Some features are only available with one method, not the other (see: https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops#feature-availability).

An example pipeline YAML file:

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
        variables:  # job level variables
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
    dependsOn: Build              # 1
    condition: |  # only when the pipeline running on 'release' branch
      and (
        succeeded(),
        eq(variables['Build.SourceBranchName'], variables['releaseBranchName'])
      )
    jobs:
      - deployment: Deploy  # a deployment job
        pool:
          vmImage: "ubuntu-18.04"
        environment: dev          # 2
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

- *#1* By default, a job is independent from other jobs. They could run in any order or in parallel, use `dependsOn` to make sure the correct execution order.
- *#2* An environment is created automatically if it does not exist, you can create one manually and add approvals and checks to it.

#### Stage dependencies

- By default, stages run in the order they are defined, each stage is implicitly depends on preceding stage
- You could remove this implicit dependency:
  ```yaml
  stages:
  - stage: FunctionalTest
    ...

  - stage: AcceptanceTest
    dependsOn: []    # this removes the implicit dependency and causes this to run in parallel
  ```
- Use `dependsOn`

  ```yaml
  stages:
  - stage: Test

  - stage: DeployUS1
    dependsOn: Test    # this stage runs after Test

  - stage: DeployUS2
    dependsOn: Test    # this stage runs in parallel with DeployUS1, after Test

  - stage: DeployEurope
    dependsOn:         # this stage runs after DeployUS1 and DeployUS2
    - DeployUS1
    - DeployUS2
  ```

- You could add add `condition` on a stage (the implicit one is that all the dependencies have completed and succeeded)

  ```yaml
  stages:
  - stage: A

  # stage B runs if A fails
  - stage: B
    condition: failed()

  # C runs if A succeeded and B skipped or succeeded
  - stage: C
    dependsOn:
    - A
    - B
    condition: |
      and
      (
        succeeded('A'),
        in(dependencies.B.result, 'Succeeded', 'Skipped')
      )
  ```

### Variables

#### Scopes

Variables can be defined at multiple levels, the most locally scoped one wins:

Job -> Stage -> Pipeline root -> Pipeline settings UI

#### Naming

Variable names **can't** be prefixed with `endpoint`, `input`, `secret` and `securefile`

#### Syntax

- Template expression `${{ variables.myVar }}`

  - processed at compile time, based only on the YAML file content
  - for reusing parts of YAML as templates
  - the same syntax as template parameters
  - can appear as either keys or values: `${{ variables.key }} : ${{ variables.value }}`
  - examples:

    ```yaml
    steps:
      - ${{ each item in parameters.my_list }}:
        - bash: "echo ${{ item }}"
        - bash: ...

    steps:
      - script: echo "start"
      - ${{ if eq(variables.foo, 'adaptum') }}:
        - script: echo "this is adaptum"
      - ${{ elseif eq(variables.foo, 'contoso') }}: # true
        - script: echo "this is contoso"
      - ${{ else }}:
        - script: echo "the value is not adaptum or contoso"
    ```

- Macro `$(myVar)`

  - processed during runtime, before a task runs
  - designed to interpolate variable values into task inputs and into other variables
  - can only be values, not keys
  - renders as '$(myVar)' if not found

    ```yaml
    variables:
      my.name: 'gary'

    steps:
      # macro syntax is the same for all three
      # the value is interpolated before passing to 'echo'
      # 'echo' only see the env variable
      - bash: |
          echo $(my.name)
          echo $MY_NAME
      - powershell: |
          echo $(my.name)
          echo $env:MY_NAME
      - script: echo $(my.name)
    ```

- Runtime expression `$[variables.myVar]`

  - runtime, designed for use with conditions and expressions
  - must take up the entire right side of a definition
  - eg. get variables outputted from a previous job

    ```yaml
    dependsOn: A
    variables:
      # map the output variable from A into this job
      varFromA: $[ dependencies.A.outputs['ProduceVar.MyVar'] ]
    ```

Example:

```yaml
variables:
  - name: one
    value: initialValue

steps:
  - script: |
      echo ${{ variables.one }}     # outputs initialValue
      echo $(one)
    displayName: First variable pass

  - bash: echo '##vso[task.setvariable variable=one]secondValue'
    displayName: Set new variable value

  - script: |
      echo ${{ variables.one }}     # outputs initialValue
      echo $(one)                   # outputs secondValue
    displayName: Second variable pass
```

| Syntax              | Example                | When is it processed?          | Where does it expand in a pipeline definition? | How does it render when not found? |
| ------------------- | ---------------------- | ------------------------------ | ---------------------------------------------- | ---------------------------------- |
| template expression | `${{ variables.var }}` | compile time                   | key or value (left or right side)              | empty string                       |
| macro               | `$(var)`               | runtime before a task executes | value (right side)                             | prints `$(var)`                    |
| runtime expression  | `$[variables.var]`     | runtime                        | value (right side)                             | empty string                       |

#### Environment variables

The above variable syntaxes are processed by the Pipeline engine, already interpolated before passing to a Bash script, which can access those variables through environment variables.

System and user-defined variables get injected as environment variables for your platform, the name become uppercase, periods turn into underscores:

| Variable  | Linux & Mac | Windows (batch) | Windows (PowerShell) |
| --------- | ----------- | --------------- | -------------------- |
| `any.var` | `$ANY_VAR`  | `%ANY_VAR%`     | `$env:ANY_VAR`       |

#### Specify variables

- Key-value pairs

  ```yaml
  variables:
    my.name: 'gary'
    foo: 'bar'
  ```

- List

  ```yaml
  variables:
    # a regular variable
    - name: myvariable
      value: myvalue

    # a variable group
    - group: myvariablegroup

    # a reference to a variable template
    - template: myvariabletemplate.yml
  ```

#### Secret variables

- Don't put secret in the YAML file directly
- Define it in the Pipeline settings UI or in a variable group (only accessible within the same project)
- Secret variables are encrypted at rest with a 2048-bit RSA key
- You could use the macro syntax `$(mySecretVar)` to include it as task input
- They are not automatically decrypted into environment variables for scripts though, you need to map it with `env`

```yaml
variables:
 global_secret: $(mySecret)
 global_nonsecret: $(nonSecretVariable)

steps:
  - bash: |
      echo "Using an input-macro directly works: $(mySecret)"
      echo "Using a mapped input-macro works: $(global_secret)"
      echo "Using the env var directly does not work: $MYSECRET"
      echo "Using a global secret var mapped in the pipeline does not work either: $GLOBAL_MYSECRET"
      echo "Using a global non-secret var mapped in the pipeline works: $GLOBAL_NONSECRET"
      echo "Using the mapped env var for this task works and is recommended: $MY_MAPPED_ENV_VAR"
    env:
      MY_MAPPED_ENV_VAR: $(mySecret) # the recommended way to map to an env variable
```

```
Using an input-macro directly works: ***
Using a mapped input-macro works: ***
Using the env var directly does not work:
Using a global secret var mapped in the pipeline does not work either:
Using a global non-secret var mapped in the pipeline works: Not a secret
Using the mapped env var for this task works and is recommended: ***
```

Macros like `$(mySecret)`, `$(global_secret)` work, they are interpreted by the Pipeline engine, but they are not available as `$MYSECRET` or `$GLOBAL_SECRET` env variables directly, you need to map it in `env` explicitly

#### Set variables and use output variables

- Same job

  - Use the **`##vso[task.setvariable ...]`** logging command to output a variable from a task
  - Then use macro syntax `$(var)` to use it in following tasks

  ```yaml
  steps:
  - bash: |
       echo "##vso[task.setvariable variable=MyVar]true"
  - script: echo $(MyVar) # this step uses the output variable
  ```

- A different job

  - You must have `isOutput=true` in the logging command
  - In following job, use the runtime expression syntax `$[ dependencies.PrevJob.outputs['Task.VarName'] ]` to map it to a variable in the job

  ```yaml
  jobs:
  - job: JobA
    steps:
    # assume that MyTask generates an output variable called "MyVar"
    # (you would learn that from the task's documentation)
    - bash: |
        echo "##vso[task.setvariable variable=MyVar;isOutput=true]true"
      name: ProduceVar  # because we're going to depend on it, we need to name the step
    - script: echo $(MyVar) # this step uses the output variable

  - job: JobB
    dependsOn: JobA
    variables:
      # map the output variable from A into this job
      varFromA: $[ dependencies.JobA.outputs['ProduceVar.MyVar'] ]
    steps:
    - script: echo $(varFromA) # this step uses the mapped-in variable
  ```

- A different stage

  - At the stage level, the format for referencing variables from a different stage is `dependencies.STAGE.outputs['JOB.TASK.VARIABLE']`
  - At the job level, the format for referencing variables from a different stage is `stageDependencies.STAGE.JOB.outputs['TASK.VARIABLE']`

  ```yaml
  stages:
  - stage: StageOne
    jobs:
    - job: JobA
      steps:
      - bash: |
          echo "##vso[task.setvariable variable=MyVar;isOutput=true]true"
        name: ProduceVar  # because we're going to depend on it, we need to name the step

  - stage: StageTwo
    dependsOn: StageOne
    condition: |
      and(
        succeeded(),
        eq(dependencies.StageOne.outputs['JobA.ProduceVar.MyVar'], 'true')
      )
    jobs:
    - job: JobB
      variables:
        # map the output variable from JobA into this job
        varFromA: $[ stageDependencies.StageOne.A.outputs['ProduceVar.MyVar'] ]
      steps:
      - script: echo $(varFromA) # this step uses the mapped-in variable
  ```

### Predefined variables

Can be used as env variables in scripts and as parameters in build task, see https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml

Examples:
- `System.DefaultWorkingDirectory`: The local path on the agent where your source code files are downloaded. eg. `c:\agent_work\1\s` on Windows, `/azp/agent/_work/1/s` on Linux
  - If only one repo is checked out, it's the same as `Build.SourcesDirectory`
  - When multiple repos are checked out, each repo is checkedout as a folder in this directory
- `Build.SourcesDirectory`: seems to be the same as `System.DefaultWorkingDirectory`
- `Pipeline.Workspace`: the local path on an agent where all folders for a build pipeline are created, same as `Agent.BuildDirectory`, eg. `/azp/agent/_work`, other folders are under it:
  - `$(Agent.TempDirectory)` -> `/azp/agent/_work/_temp/`

- `Build.ArtifactStagingDirectory`: The local path on the agent where any artifacts are copied to before being pushed to destination, same as `Build.StagingDirectory`, you need to copy your artifacts here before publishing. **NOT RECOMMENDED ANYMORE**, you could just publish directly from where your files are.
- `Build.SourceBranchName`: 'main', ...
- `Build.Reason`: 'Manual', 'Schedule', 'PullRequest', ...
- `Pipeline.Workspace`
- `System.AccessToken`, a special variable that carries the security token used by the running build, could be used as a PAT token or a `Bearer` token to call Azure Pipelines REST API
  - Could be used like:

    ```yaml
    steps:
      - bash: |
          echo This script could use $SYSTEM_ACCESSTOKEN
          git checkout "git::https://:${SYSTEM_ACCESSTOKEN}@dev.azure.com/myOrg/myProject/_git/my-repo"
        env:
          SYSTEM_ACCESSTOKEN: $(System.AccessToken)
      - powershell: |
          Write-Host "This is a script that could use $env:SYSTEM_ACCESSTOKEN"
          Write-Host "$env:SYSTEM_ACCESSTOKEN = $(System.AccessToken)"
        env:
          SYSTEM_ACCESSTOKEN: $(System.AccessToken)
    ```

Deployment job only:

- `Environment.Name`
- `Strategy.Name`: The name of the deployment strategy: `canary`, `runOnce`, or `rolling`.

### Expressions

see: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops

Expressions can be evaluated at either

- Compile time:
  - syntax: `${{ <expression> }}`
  - evaluated when the YAML file is compiled into a plan
  - can be used everywhere
  - have access to `parameters` and statically defined `variables`
- or Run time:
  - syntax: `$[ <expression> ]`
  - can be used in variables and conditions
  - have access to more `variables` but *no parameters*

Example:

```yaml
variables:
  staticVar: 'my value'                                             # static variable
  compileVar: ${{ variables.staticVar }}                            # compile time expression
  isMain: $[eq(variables['Build.SourceBranch'], 'refs/heads/main')] # runtime expression

steps:
  - script: |
      echo ${{variables.staticVar}} # outputs my value
      echo $(compileVar) # outputs my value
      echo $(isMain) # outputs True
```

Use in `condition`

```yaml
  - job: B1
    condition: ${{ containsValue(parameters.branchOptions, variables['Build.SourceBranch']) }}
    steps:
      - script: echo "Matching branch found"
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

### Variable templates

- Variables could be defined in a template file
- It could have parameters
- And you could load different templates based on parameters

```yaml
# experimental.yml
parameters:
- name: DIRECTORY
  type: string
  default: "."

variables:
- name: RELEASE_COMMAND
  value: grep version ${{ parameters.DIRECTORY }}/package.json
```

```yaml
# File: azure-pipelines.yml
parameters:
- name: isExperimental
  displayName: 'Use experimental build process?'
  type: boolean
  default: false

variables: # Global variables
- ${{ if eq(parameters.isExperimental, true) }}: # Load based on parameters
  - template: experimental.yml
    parameters:                                  # pass parameter to a template
      DIRECTORY: "beta"
- ${{ if not(eq(parameters.isExperimental, true)) }}:
  - template: stable.yml
    parameters:
      DIRECTORY: "stable"
```


### Use Key Vault secrets in pipelines

- Create a service principal for the pipeline, and configure proper access policy in Key Vault for it
- Use the `AzureKeyVault` task to get secrets
- Explicitly map secrets to env variables

```yaml
pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureKeyVault@1
  inputs:
    azureSubscription: 'repo-kv-demo'                    ## YOUR_SERVICE_CONNECTION_NAME
    KeyVaultName: 'kv-demo-repo'                         ## YOUR_KEY_VAULT_NAME
    SecretsFilter: 'secretDemo'                          ## YOUR_SECRET_NAME
    RunAsPreJob: false

- bash: |
    echo "Secret Found! $MY_MAPPED_ENV_VAR"
  env:
    MY_MAPPED_ENV_VAR: $(secretDemo)  ## secret available in this task now
```

### Artifacts in Azure Pipelines

There are artifacts produced and associated with a pipeline run, *not the same as Azure Artifacts*

#### Publish

```yaml
steps:
- task: PublishPipelineArtifact@1
  inputs:
    targetPath: $(System.DefaultWorkingDirectory)/bin/WebApp
    artifactName: WebApp
```

or shortcut

```yaml
steps:
- publish: $(System.DefaultWorkingDirectory)/bin/WebApp
  artifact: WebApp
```

Use `.artifactignore` to ignore files

```
# ignore everthing except .exe files

**/*
!*.exe
```

#### Download

```yaml
steps:
- task: DownloadPipelineArtifact@2
  inputs:
    artifact: WebApp
```

or shortcut

```yaml
steps:
- download: current   # download artifacts produced by the current pipeline run
  artifact: WebApp    # optional
  patterns: '**/*.js' # optional
```

- Files are downloaded into `$(Pipeline.Workspace)`
- `artifact` controls which artifact to download, if empty, download everything
- Use `patterns` to filter which files to download
- Artifacts are downloaded automatically in deployment jobs (a download task is auto injected), use the following step to stop it:

  ```yaml
  steps:
  - download: none
  ```

### Resources

- Protected

  These resources have security settings, you can make them accessible only to specific users and pipelines within the project, and you can run additional manual or auto checks every time a pipeline uses one of these resources

  - agent pools
  - variable groups (can only be used by pipelines in the same project)

    ```yaml
    # you need to delcare it like this in a pipeline job for access
    variables:
      - group: 'Release'
    ```

  - secure files
  - service connections (can be shared across projects)
  - environments
  - repositories

- Open

  - artifacts
  - pipelines
  - test plans
  - work items

### Checkout task

Scenarios:

- A `checkout: self` step is added automatically to a job if nothing specified
- Use `checkout: none` if you don't need to checkout the source code
- Or specify one or more `checkout: ` steps

For Git repos in the same ADO organization, you could checkout like:

```yaml
steps:
- checkout: self
- checkout: git://MyProject/MyRepo
- checkout: git://MyProject/MyRepo2@features/tools # checkout specified branch
```

For repos that require a service connection, you must declare them as repository resources:

```yaml
resources:
  repositories:
  - repository: MyGitHubRepo # The name used to reference this repository in the checkout step
    type: github
    endpoint: MyGitHubServiceConnection
    name: MyGitHubOrgOrUser/MyGitHubRepo

steps:
- checkout: self
- checkout: MyGitHubRepo
- script: dir $(Build.SourcesDirectory)
```

Default checkout path(s):

- Single repo: `$(Agent.BuildDirectory)/s`
- Multiple repos: `$(Agent.BuildDirectory)/s/repo1`, `$(Agent.BuildDirectory)/s/repo2`, ...

#### Triggering

You could trigger a pipeline run when an update is pushed to the `self` repo or to any of the repos declared as resources (only work for Git repos in same ADO organization). This could be useful:

- Trigger a run whenever a dependency repo updated
- Keep your YAML pipeline in a separate repo

Example:

```yaml
trigger:
- main
- feature

resources:
  repositories:
  - repository: A
    type: git
    name: MyProject/A
    ref: main
    trigger:
    - main

  - repository: B
    type: git
    name: MyProject/B
    ref: release
    trigger:
    - main
    - release
```

A run is triggered whenever:

- `main` or `feature` branch updates
- `main` branch updates in `MyProject/A`
- `main` or `release` branch updates in `MyProject/B`


### Job authorization

See: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops&tabs=yaml

At run-time, a job in a pipeline may access other resources in Azure DevOps:

- Check out code from a Git repo
- Add a tag to the repo
- Access a feed in Azure Artifacts
- Update a work item
- Upload logs, test results and other artifacts from the agent to the service

#### Job authorization scope

Azure Pipelines uses a dynamically generated **job access token**

- For a private project, the default scope is **organization**, this means a job could access all repos in an organization.
- You could limit the scope to "project" in Organization/Project pipeline settings
- You could further **Limit job authorization scope to referenced Azure DevOps repositories**, use a `checkout` step or `uses` statement:

  ```yaml
  steps:
  - checkout: git://MyProject/AnotherRepo # An ADO repo in the same organization
  - script: # Do something with that repo
  ```

  ```yaml
  # Or you can reference it with a uses statement in the job
  uses:
    repositories: # List of referenced repositories
    - AnotherRepo

  steps:
  - script: # Do something with that repo like clone it
  ```

#### Built-in identities

ADO uses built-in identities(users) to execute pipelines. For a project `MyProject` in org `MyOrg`, there is:

- A collection-scoped identity: `Project Collection Build Service (MyOrg)`
- A project-scoped identity: `MyProject Build Service (MyOrg)`

The collection-scoped one is used unless you limit the job access scope to "project" as described above.



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

### Deployment jobs

```yaml
jobs:
  - deployment: string   # name of the deployment job, A-Z, a-z, 0-9, and underscore. The word "deploy" is a keyword and is unsupported as the deployment name.
    displayName: string  # friendly name to display in the UI
    pool:                # see pool schema
      name: string       # Use only global level variables for defining a pool name. Stage/job level variables are not supported to define pool name.
      demands: string | [ string ]
    workspace:
      clean: outputs | resources | all # what to clean up before the job runs
    dependsOn: string
    condition: string
    continueOnError: boolean                # 'true' if future jobs should run even if this job fails; defaults to 'false'
    container: containerReference # container to run this job inside
    services: { string: string | container } # container resources to run as a service container
    timeoutInMinutes: nonEmptyString        # how long to run the job before automatically cancelling
    cancelTimeoutInMinutes: nonEmptyString  # how much time to give 'run always even if cancelled tasks' before killing them
    variables: # several syntaxes, see specific section
    environment: string  # target environment name and optionally a resource name to record the deployment history; format: <environment-name>.<resource-name>
    strategy:
      runOnce:    #rolling, canary are the other strategies that are supported
        deploy:
          steps: [ script | bash | pwsh | powershell | checkout | task | templateReference ]
```

A deployment job:

- Doesn't automatically clone the source repo, you can do it with `checkout: self`
- Automatically download build artifacts
- Allow you do define the deployment strategy
- Records history against the deployed-to environment

#### Deployment strategies

- `runOnce`

    each hook is executed once, then run either `on:failure` or `on:success`

  ```yaml
  strategy:
      runOnce:
        preDeploy:
          pool: [ server | pool ] # See pool schema.
          steps:
          - script: [ script | bash | pwsh | powershell | checkout | task | templateReference ]

        deploy:
          pool: [ server | pool ] # See pool schema.
          steps: ...

        routeTraffic:
          pool: [ server | pool ]
          steps: ...

        postRouteTraffic:
          pool: [ server | pool ]
          steps: ...

        on:
          failure:
            pool: [ server | pool ]
            steps: ...

          success:
            pool: [ server | pool ]
            steps: ...
  ```

- `rolling`

  ```yaml
  strategy:
    rolling:
      maxParallel: [ number or percentage as x% VMs]

      preDeploy:
        steps: ...

      deploy:
        steps: ...

      routeTraffic:
        steps: ...

      postRouteTraffic:
        steps: ...

      on:
        failure:
          steps: ...

        success:
          steps: ...
  ```

  - Currently only support deployment to VM resources
  - In each iteration, rolling out new version to a fixed set of VMs(rolling set)
  - Typically waits for deployment on each set of VMs to complete before proceeding, you could do a health check after each iteration
  - All lifecycle hook jobs are created to run on each VM

- `canary`

  An example, deploying to AKS, will first deploy to 10-percent pods, then 20 percent, while monitoring the health during `postRouteTraffic`

  ```yaml
  jobs:
  - deployment:
    environment: smarthotel-dev.bookings
    pool:
      name: smarthotel-devPool
    strategy:
      canary:
        increments: [10,20]
        preDeploy:
          steps:
          - script: initialize, cleanup....

        deploy:
          steps:
          - script: echo deploy updates...
              - task: KubernetesManifest@0
                inputs:
                  action: $(strategy.action)
                  namespace: 'default'
                  strategy: $(strategy.name)
                  percentage: $(strategy.increment)
                  manifests: 'manifest.yml'

        postRouteTraffic:
          pool: server
          steps:
          - script: echo monitor application health...
        on:
          failure:
            steps:
            - script: echo clean-up, rollback...
          success:
            steps:
          - script: echo checks passed, notify...
  ```

  - `preDeploy` run once, then iterates with `deploy`, `routeTraffic` and `postRouteTraffic` hooks, then exits with either the `success` or `failure` hook


### GitHub integration

Azure Pipelines has an OAuth App and a GitHub App

- the OAuth App allows it read your repo, update `azure-pipelines.yml` file directly from within Azure DevOps
- the GitHub App triggers the pipeline


## Artifacts

- Is in organization scope
- Supports storing NuGet, NPM, Maven, Python and Universal packages in a single feed

To publish an NPM package to a feed:

 - You must first provide a Contributor access to the `Project Collection Build Service` identity in the feed's settings

 - Use an `Npm` task

    ```yaml
    - task: Npm@1
      inputs:
        command: 'publish'
        publishRegistry: 'useFeed'
        publishFeed: '865b7c4e-795b-4149-8d51-fbdb16a6db21'
    ```


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

## CLI

```sh
# add extension
az extension add --name azure-devops

# set default organization and project
az devops configure --defaults organization=https://dev.azure.com/myorg/ project=MyProject

# list defaults
az devops configure -l

# list repos
az repos list -otable

# list PRs
az repos pr list -otable

# list pipelines
az pipelines list -otable
```
