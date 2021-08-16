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
  - [Multistage pipeline](#multistage-pipeline)
  - [Resources](#resources)
  - [Templates](#templates)
  - [Agent pools](#agent-pools)
- [Tests](#tests)
- [Deployment patterns](#deployment-patterns)


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
- Define hte iteration paths in `Project configuration`
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

### Resources

- Protected

  These resources have security settings, you can make them accessible only to specific users and pipelines within the project, and you can run additional manual or auto checks every time a pipeline uses one of these resources

  - agent pools
  - variable groups

    ```yaml
    # you need to delcare it like this in a pipeline job for access
    variables:
      - group: 'Release'
    ```

  - secure files
  - service connections
  - environments
  - repositories
    - access token given to an build agent for running jobs will only have access to repositories explicitly mentioned in the `resources` section of the pipeline

- Open

  - artifacts
  - pipelines
  - test plans
  - work items


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

