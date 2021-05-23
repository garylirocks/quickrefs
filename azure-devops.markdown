# Azure DevOps

- [Overview](#overview)
- [Pipelines](#pipelines)
  - [Templates](#templates)


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




