# GitHub

- [GitHub Flow](#github-flow)
- [Apps vs. OAuth Apps](#apps-vs-oauth-apps)
- [GitHub Enterprise](#github-enterprise)
- [Branch protection](#branch-protection)
- [Rulesets](#rulesets)
- [Status checks](#status-checks)
- [Workflows](#workflows)
  - [Workflow file](#workflow-file)
  - [Action definition](#action-definition)
  - [Contexts](#contexts)
  - [`env` variables](#env-variables)
  - [`vars` and `secrets`](#vars-and-secrets)
  - [`github` context](#github-context)
  - [Expressions](#expressions)
    - [Comparisons](#comparisons)
    - [Functions](#functions)
    - [Status check functions](#status-check-functions)
    - [Object filters](#object-filters)
  - [Conditional](#conditional)
  - [Compute contexts](#compute-contexts)
  - [Environments](#environments)
  - [Workflow commands](#workflow-commands)
    - [Set environment variables](#set-environment-variables)
    - [Set output](#set-output)
    - [Add a system path](#add-a-system-path)
    - [Add a job summary](#add-a-job-summary)
    - [Set messages](#set-messages)
    - [Mask a value](#mask-a-value)
    - [Stop and resume workflow commands processing](#stop-and-resume-workflow-commands-processing)
- [Common workflow tasks](#common-workflow-tasks)
  - [Artifacts](#artifacts)
  - [GitHub Script](#github-script)
  - [Azure login](#azure-login)
- [Reuse workflows](#reuse-workflows)
  - [Access](#access)
  - [Limitations](#limitations)
  - [Example](#example)
  - [Calling a reusable workflow](#calling-a-reusable-workflow)
  - [Use workflow output](#use-workflow-output)

## GitHub Flow

[Understanding the GitHub flow · GitHub Guides](https://guides.github.com/introduction/flow/)

![GitHub Flow](./images/github_github-flow.png)

Comparing with the Git Flow, GitHub Flow is more lightweight, and more suitable for CI/CD.

One Rule: **Anything in the `main` branch is always deployable**

1. Create a branch from `main`.
2. Add commits.
3. Open a pull request.
    - The purpose is to initiate discussion
    - You can open a pull request at **any point**, not necessarily when you are ready for review, you could use it to share screenshots/ideas, ask for help/advice
4. Make changes on your branch as needed, your pull request will update automatically.
5. Deploy
    - Once your PR has been reviewed and passed tests, you can deploy it to production, if it causes issues, roll it back by deploying the existing main branch
    - There are different deployment strategies, for some, it's better to deploy to a specifically provisioned testing environment, for others, it's better to deploy directly to production
6. Merge the pull request
    - Pull requests preserve a record of historical changes to your code
    - By using some phrases like `Closes #32` in your PR text, issue 32 will be closed automatically when you merge your PR


## Apps vs. OAuth Apps

 - Apps act as themselves, they are mostly bots, helping you automate some tasks, such as requesting more info for an issue if there's no description.

 - OAuth Apps act as the user who authorized them.


## GitHub Enterprise

![GitHub Enterprise](./images/github_enterprise-organization-hierarchy.jpg)

- Enterprise can contain multiple organizations
- An organization contains teams, repos
- A repo could be
  - Public: to the internet
  - Private: only visible to specified users
  - Internal: visible to any enterprise user


## Branch protection

You could create branch protection rules to protect a branch:

- Require a pull requests
  - Require approvals
- Require status checks
  - You can use **a job in a workflow as a check**
- Require conversation resolution
- Require deployments to succeed
  - Environments must be successfully deployed to


## Rulesets

Control how people could interact with branches and tags in a repo. Rules could be similar to branch/tag protection rules.

Rulesets advantages over branch/tag protection rules:

- Multiple rulesets can apply at the same time
  - Rules are aggregated
  - Also layer with branch/tag protection rules
- Rulesets can be disabled
- Anyone with read access to a repo can view active rulesets

With GitHub Enterprise:

- Rulesets at organization level
- Rules to control metadata, such as commit message and author's email address
- Use "Evaluate" status to test a ruleset before activating it


## Status checks

Two types:

- Statuses
  - Usually used by external services (CI/CD, security etc.) to mark commits with a state (`pending`, `success`, `error`, `failure`)
  - A status could have fields `state`, `description`, `target_url`, `context`, an example:
    ```json
    {
      "state": "success",
      "target_url": "https://example.com/build/status",
      "description": "The build succeeded!",
      "context": "continuous-integration/jenkins"
    }
    ```
  - A commit could have multiple statuses, the combined state of a commit would be:
    - `failure` if any of the contexts report as `error` or `failure`
    - `pending` if there are no statuses or a context is `pending`
    - `success` if the latest status for all contexts is `success`

- Checks
  - Comparing to statuses, checks provide *line annotations*, more *detailed messaging*, and are only available for use with *GitHub Apps*
  - Checks tab in a pull request only shows checks, not statuses
  - Checks can be skipped or requested with a commit mesage like

    ```sh
    $ git commit -m "Update README
    >
    >
    skip-checks: true"
    ```
    Or
    ```sh
    $ git commit -m "Update README
    >
    >
    request-checks: true"
    ```


## Workflows

![Workflow components](./images/github_actions-workflow-components.png)

Three levels:

- Workflow
- Job
- Action

  Actions can be defined in the same repo, in another repo, or in a published Docker image.

  Each action has its own purpose, defined with a YAML file.  There are two types:

  - Container actions
  - JavaScript actions

### Workflow file

- Workflow files should be in `.github/workflows/`
  - To promote consistency, an organization can have workflow templates in a `.github` repo, any repo in the org has access to it
- A workflow must have at least one job
- A job is run by a runner, which can be GitHub-hosted or self-hosted, and the job can run on a machine or a container

```yaml
name: A workflow for my Hello World file
on: push                              # trigger
jobs:
    build:                            # job id
      name: Hello world action        # (optional) give it a readable name
      runs-on: ubuntu-latest          # GitHub-hosted runner
      steps:
          - uses: actions/checkout@v1 # first step: action defined in another repo
          - uses: ./action-a          # another step: action defined in same repo
            with:
                MY_NAME: "Mona"       # input required by the action
```

Triggers:

```yaml
on: push

# or an array
on: [push, pull_request]

# or a map
on:
  # Trigger the workflow on push or pull request,
  # but only for the master branch
  push:
    branches:
      - master
  pull_request:
    branches:
      - master
  # Also trigger on page_build, as well as release created events
  page_build:
  release:
    types: # This configuration does not affect the page_build event above
      - created

# or by a schedule
on:
  schedule:
    - cron:  '0 3 * * SUN'

# or by manual or REST API
on:
  workflow_dispatch:
    inputs:
      logLevel:
        description: 'Log level'
        required: true
        default: 'warning'
      tags:
        description: 'Test scenario tags'

# or by webhook events
# and you can specify the activity types with `types`
on:
  check_run:
    types: [rerequested, requested_action]
```

You can skip a `on: push` or `on: pull_request` workflow by

- Adding `[skip ci]` to the commit message.
- Or ending the commit message with two empty lines followed by either:

  - `skip-checks:true`
  - `skip-checks: true`

  like:

  ```sh
  $ git commit -m "Update README
  >
  >
  skip-checks: true"
  ```

### Action definition

Action types:

- Docker container (Linux only)
- JavaScript
- Composite Actions (multiple steps in one action)

```yaml
name: "Hello Actions"
description: "Greet someone"
author: "octocat@github.com"

inputs:
    MY_NAME:                  # a variable that needs be set in workflow
      description: "Who to greet"
      required: true
      default: "World"

runs:
    using: "docker"
    image: "Dockerfile"       # path to docker image file

branding:                     # metadata for GitHub Marketplace
    icon: "mic"
    color: "purple"
```

A composite action

```yaml
name: 'Hello World'
description: 'Greet someone'
inputs:
  who-to-greet:  # id of input
    description: 'Who to greet'
    required: true
    default: 'World'
outputs:
  random-number:
    description: "Random number"
    value: ${{ steps.random-number-generator.outputs.random-number }}
runs:
  using: "composite"
  steps:
    - run: echo Hello ${{ inputs.who-to-greet }}.
      shell: bash
    - id: random-number-generator
      run: echo "random-number=$(echo $RANDOM)" >> $GITHUB_OUTPUT
      shell: bash
    - run: echo "${{ github.action_path }}" >> $GITHUB_PATH
      shell: bash
    - run: goodbye.sh
      shell: bash
```

### Contexts

| Context    | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `github`   | About the workflow run                                                              |
| `env`      | Variables set in a workflow, job or step, similar to `variables` in ADO             |
| `inputs`   | Inputs of a reusable or manually triggered workflow, similar to `parameters` in ADO |
| `vars`     | Variables set at org, repo, or environment level                                    |
| `secrets`  | Secrets set at org, repo, or environment level                                      |
| `job`      | Current running job                                                                 |
| `jobs`     | Reusable workflows only, contains outputs of jobs from the reusable workflow        |
| `steps`    | Info about the steps that have been run in the current job                          |
| `runner`   | Info about the current runner                                                       |
| `strategy` | Info about the matrix execution strategy                                            |
| `matrix`   | Matrix properties defined in the workflow that apply to the current job             |
| `needs`    | Outputs of all jobs that are defined as a dependency of current job                 |

- `github` context is available globally, other contexts are only available for some keys, see https://docs.github.com/en/actions/learn-github-actions/contexts#context-availability

### `env` variables

```yaml
env:
  workflowVar: Hello ${{ vars.PET }}

jobs:
  job1:
    runs-on: ubuntu-latest
    env:
      jobVar: A job var
    steps:
    - name: Print
      env:
        stepVar: A step var
      run: |
        echo $workflowVar
        echo $jobVar
        echo $stepVar
```

- Could have `env` on workflow, job and step level
- Could use variable substitution in `env` values
- Can be used in any key in a workflow step except for `id` and `uses`

### `vars` and `secrets`

```yaml
- name: Print a variable
  run: echo "name: " ${{ vars.name }}
- name: Use a secret - Azure login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

- `secrets.GITHUB_TOKEN` is automatically created for each workflow run, the default access level could be `permissive` or `restrictive`, see https://docs.github.com/en/enterprise-cloud@latest/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token
  - You can use `permissions:` key to customize the permissions for entire workflow or individual jobs, this overwrites the default permissions
  - You can see the permissions in "Set up job" section in the workflow run log

### `github` context

- `github.ref_name`: the short form branch or tag name, like `main`, `dev`, `v1.0`, `<pull_request_number>/merge`
- `github.base_ref`: only available for `pull_request` and `pull_request_target` events, the base branch name, eg. `main`


### Expressions

- Syntax: `${{ <expression> }}`

- In `if` conditional, no need to use `${{ }}` syntax

  ```yaml
  steps:
    - uses: actions/hello-world-javascript-action@e76147da8e5c81eaf017dede5645551d4b94427b
      if: <expression>
  ```

- Setting an env variable

  ```yaml
  env:
    MY_ENV_VAR: ${{ <expression> }}
  ```

- If-else

  ```yaml
  env:
    MY_ENV_VAR: ${{ github.ref == 'refs/heads/main' && 'value_for_main_branch' || 'value_for_other_branches' }}
  ```

#### Comparisons

- String comparisons are case insensitive
- If types don't match, values are cast to a number before comparison

#### Functions

- `contains( search, item )`: cast values to a string, case insensitive
  - Example: `contains(fromJSON('["push", "pull_request"]'), github.event_name)`
- `startsWith( searchString, searchValue )`
- `endsWith( searchString, searchValue )`
- `format( string, replaceValue0, replaceValue1, ..., replaceValueN)`
  - Example: `format('Hello {0} {1} {2}', 'Mona', 'the', 'Octocat')`
- `join( array, optionalSeparator )`
- `hashFiles(path)`, returns a single SHA-256 hash for multiple files
  - Example: `hashFiles('**/package-lock.json', '**/Gemfile.lock')`
- `toJSON(value)`
- `fromJSON(value)`
  - Convert environment variables from string to other types
    ```yaml
    name: print
    on: push
    env:
      continue: true
      time: 3
    jobs:
      job1:
        runs-on: ubuntu-latest
        steps:
          - continue-on-error: ${{ fromJSON(env.continue) }}
            timeout-minutes: ${{ fromJSON(env.time) }}
            run: echo ...
    ```
  - Returning a JSON object
    ```yaml
    name: build
    on: push
    jobs:
      job1:
        runs-on: ubuntu-latest
        outputs:
          matrix: ${{ steps.set-matrix.outputs.matrix }}
        steps:
          - id: set-matrix
            run: echo "matrix={\"include\":[{\"project\":\"foo\",\"config\":\"Debug\"},{\"project\":\"bar\",\"config\":\"Release\"}]}" >> $GITHUB_OUTPUT
      job2:
        needs: job1
        runs-on: ubuntu-latest
        strategy:
          matrix: ${{ fromJSON(needs.job1.outputs.matrix) }}
        steps:
          - run: build
    ```

#### Status check functions

- `success()`, none of the previous steps failed or cancelled
- `always()`
- `cancelled()`, if the worklow was cancelled
- `failure()`, any previous step fails, or any ancestor job fails

  ```yaml
  steps:
    ...
    - name: Failing step
      id: demo
      run: exit 1

    - name: The demo step has failed
      id: step2
      if: failure()
      run: echo "The demo step has failed"

    - name: Check conditions only
      id: step3
      if: steps.demo.conclusion == 'failure'
      run: echo "Check conditions only"

    - name: Check conditions and status
      id: step4
      if: failure() && steps.demo.conclusion == 'failure'
      run: echo "Check conditions and status"
  ```
  - `step3` is skipped, `step4` will run, because *only checking `.conclusion` is not enough, you need to check `failure()` as well, otherwise `success()` is implied*

#### Object filters

- On an array:
  ```json
  [
    { "name": "apple", "quantity": 1 },
    { "name": "orange", "quantity": 2 },
    { "name": "pear", "quantity": 1 }
  ]
  ```
  The filter `fruits.*.name` returns the array `[ "apple", "orange", "pear" ]`

- On an object
  ```json
  {
    "scallions": {
      "colors": ["green", "white", "red"],
      "ediblePortions": ["roots", "stalks"],
    },
    "beets": {
      "colors": ["purple", "red", "gold", "white", "pink"],
      "ediblePortions": ["roots", "stems", "leaves"],
    },
    "artichokes": {
      "colors": ["green", "purple", "red", "black"],
      "ediblePortions": ["hearts", "stems", "leaves"],
    },
  }
  ```

  The filter `vegetables.*.ediblePortions` could evaluate to (output order not garanteed):
  ```
  [
    ["roots", "stalks"],
    ["hearts", "stems", "leaves"],
    ["roots", "stems", "leaves"],
  ]
  ```



### Conditional

- Both jobs and steps can have `if` conditions
- The conditional is evaluated as expression automatically, DON'T use `${{ }}` syntax

```yaml
name: CI
on: push
jobs:
  prod-check:
    if: github.ref == 'refs/heads/main' # job condition
    runs-on: ubuntu-latest
    steps:
      ...
```

```yaml
name: CI
on: pull_request
jobs:
  job1:
    if: contains(github.event.pull_request.labels.*.name, 'peacock')
    # get an array of label names like ["bug", "stage", "peacock"] of the pull request that triggered this job
    runs-on: ubuntu-latest
    steps:
      - name: Frist step
      - name: Another step
        if: contains(github.event.issue.labels.*.name, 'bug') # step condition
        run: |
          echo "A bug report"
      ...
```

### Compute contexts

Multiple compute contexts for a job:

```yaml
test:
  runs-on: ubuntu-latest
  strategy:                                       # run in multiple OSes and Node version
    matrix:
      os: [ubuntu-lastest, windows-2016]
      node-version: [8.x, 10.x]
  steps:
    - uses: actions/checkout@v1
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}
    - name: npm install, and test
      run: |
        npm install
        npm test
      env:
        CI: true
```

### Environments

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    environment:
        name: dev
    steps:
    - name: check out repo
      uses: actions/checkout@v2
    - name: azure login
      uses: azure/login@v1
      with:
        creds: ${{secrets.AZURE_CREDENTIALS}}
```

- Specify the `dev` environment
- Each environment could have its own `AZURE_CREDENTIALS` secret

### Workflow commands

Workflow commands allow actions to communicate with the runner machine to set environment variables, output values, add debug messages, etc

There are two ways:

- Write to a file
- Use the `echo` command in a specific format
  - `echo "::workflow-command parameter1={data},parameter2={data}::{command value}"`

#### Set environment variables

- Output a line to the `$GITHUB_ENV` file `echo "{env_var}={value}" >> "$GITHUB_ENV"`
- Then you can use it in following steps: `$env_var`

```yaml
steps:
  - name: Set the value
    id: step_one
    run: |
      echo "action_state=yellow" >> "$GITHUB_ENV"
  - name: Use the value
    id: step_two
    run: |
      printf '%s\n' "$action_state" # This will output 'yellow'
```

#### Set output

```yaml
steps:
  - name: Set output
    id: step1
    run: echo "MY_COLOR=green" >> "$GITHUB_OUTPUT"

  - name: Use output of previous step
    env:
      MY_COLOR: ${{ steps.step1.outputs.MY_COLOR }}
    run: echo "The selected color is $MY_COLOR"
```

#### Add a system path

`echo "$HOME/.local/bin" >> $GITHUB_PATH`

#### Add a job summary

- Allow you to add info to the job summary page, so you don't need to go to the logs page
- You add to `$GITHUB_STEP_SUMMARY` in each step, they summaries for all step in a job will be grouped together
- Supports [GitHub flavored Markdown](https://github.github.com/gfm/)

```yaml
steps:
  - id: step1
    run: |
      echo "## step1" >> $GITHUB_STEP_SUMMARY
      echo "Fruit produced" >> $GITHUB_STEP_SUMMARY
      echo "" >> $GITHUB_STEP_SUMMARY # this is a blank line
      echo "- Apple" >> $GITHUB_STEP_SUMMARY
      echo "- Banana" >> $GITHUB_STEP_SUMMARY

  - id: step2
    run: |
      echo "## step2" >> $GITHUB_STEP_SUMMARY
      echo "Well done :rocket:" >> $GITHUB_STEP_SUMMARY
```

#### Set messages

- The messages show up in a "Annotations" pane in the summary page, similar to job summary pane
- The grouped log lines only show in logs page

```yaml
steps:
  # set messages
  - name: Set debug/notice/warning/error messages
    run: |
        echo "::debug::Set the Octocat variable"
        echo "::notice file=app.js,line=1,col=5,endColumn=7::Missing semicolon"
        echo "::warning file=app.js,line=1,col=5,endColumn=7::Missing semicolon"
        echo "::error file=app.js,line=1,col=5,endColumn=7::Missing semicolon"

  # group log lines
  - name: Group log lines
    run: |
        echo "::group::My title"
        echo "Inside group"
        echo "::endgroup::"
```

#### Mask a value

The value will be masked in all following steps

```yaml
jobs:
  generate-a-secret-output:
    runs-on: ubuntu-latest
    steps:
      - id: sets-a-secret
        name: Generate, mask, and output a secret
        run: |
          the_secret=$((RANDOM))
          echo "::add-mask::$the_secret"
          echo "secret-number=$the_secret" >> "$GITHUB_OUTPUT"

      - name: Use that secret output (protected by a mask)
        run: |
          echo "the secret number is ${{ steps.sets-a-secret.outputs.secret-number }}"
```

#### Stop and resume workflow commands processing

- Stop with `stop-commands::<marker>`
- Then resume with `::<marker>::`

```yaml
jobs:
  workflow-command-job:
    runs-on: ubuntu-latest
    steps:
      - name: Disable workflow commands
        run: |
          echo '::warning:: This is a warning message, to demonstrate that commands are being processed.'
          stopMarker=$(uuidgen)
          echo "::stop-commands::$stopMarker"
          echo '::warning:: This will NOT be rendered as a warning, because stop-commands has been invoked.'
          echo "::$stopMarker::"
          echo '::warning:: This is a warning again, because stop-commands has been turned off.'
```


## Common workflow tasks

### Artifacts

Artifact storage (upload artifacts generated by `build` job and download in `test` job):
  - Jobs run in parallel, unless configured otherwise
  - Use `needs` to configure dependencies

```yaml
build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: npm install and build webpack
        run: |
          npm install
          npm run build
      - uses: actions/upload-artifact@master
        with:
          name: webpack artifacts
          path: public/

test:
    needs: build                                # this job depends on another job
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - uses: actions/download-artifact@master
        with:
          name: webpack artifacts
          path: public
```

### GitHub Script

It is a special action (`actions/github-script`) that allows using `octokit/rest.js` directly in a workflow file.

- `octokit`: official collection of GitHub API clients
- `rest.js`: included in octokit, JavaScript client for GitHub rest API

GitHub Script provides these variables:

- `github`: rest.js client
- `context`: workflow context object

Example:

```yaml
# add a comment to newly opened issues
name: Learning GitHub Script

on:
  issues:
    types: [opened]

jobs:
  comment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/github-script@v6
        with:
          github-token: ${{secrets.GITHUB_TOKEN}}
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: "🎉 You've created this issue comment using GitHub Script!!!"
            })
```

### Azure login


## Reuse workflows

Like actions, you can reuse a workflow definition in another workflow.

### Access

What reusable workflows can be accessed by your workflow:

- In the same repo
- In a public repo, and your enterprise allows you to use.
- In an internal/private repo, and the settings for that repo allow it to be accessed.

### Limitations

- Can be nested up to **four levels**, including the top caller
- A maximum of **20** reusable workflows, including nested ones
- `env` variables in caller workflow level are NOT propagated to the called
- `env` variables in called workflow level are NOT propagated to the caller
- Reuse workflows can only be called directly within a job, not a step, so you cannot use `GITHUB_ENV` to pass values to or from it
- **`env`, `secrets` contexts can NOT be used** in `jobs.<job_id>.with.<with_id>`, so you cannot pass them to a reusable workflow as inputs
- **`vars` context CAN be used** in a called workflow directly without passing anything from the caller workflow

### Example

```yaml
name: Reusable workflow example

on:
  workflow_call:
    inputs:
      config-path:
        required: true
        type: string
    secrets:
      token:
        required: true

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/labeler@v4
      with:
        repo-token: ${{ secrets.token }}
        configuration-path: ${{ inputs.config-path }}
```

- Reusable workflow's syntax is similar to a normal workflow file
- You put it in `.github/workflows/`
- Use `workflow_call` as the trigger
- Use `inputs`, `secrets` to define parameters

### Calling a reusable workflow

```yaml
jobs:
  # no ref, use current commit
  # relative path from the repo root
  call-workflow-in-same-repo:
    uses: ./.github/workflows/workflow-2.yml

  # specify a ref
  call-workflow-in-same-repo-with-ref:
    uses: octo-org/this-repo/.github/workflows/workflow-1.yml@172239021f7ba04fe7327647b213799853a9eb89

  # from another repo
  call-workflow-in-another-repo:
    uses: octo-org/another-repo/.github/workflows/workflow.yml@v1

  # with a matrix strategy
  call-with-matrix:
    strategy:
      matrix:
        target: [dev, stage, prod]
    uses: octocat/octo-repo/.github/workflows/deployment.yml@main
    with:
      target: ${{ matrix.target }}

  # passing inputs and secrets
  call-workflow-passing-data:
    uses: octo-org/example-repo/.github/workflows/reusable-workflow.yml@main
    with:
      config-path: .github/labeler.yml
    secrets:
      envPAT: ${{ secrets.envPAT }}

  # Use `secrets: inherit` to pass all secrets implicitly
  call-workflow-implicitly-passing-secrets:
    uses: octo-org/example-repo/.github/workflows/reusable-workflow.yml@main
    secrets: inherit

  # Set the `GITHUB_TOKEN` permission in the called workflow
  call-workflow-setting-permissions:
    permissions:
      contents: read
      pull-requests: write
    uses: octo-org/example-repo/.github/workflows/workflow-B.yml@main
    with:
      config-path: .github/labeler.yml
    secrets:
      token: ${{ secrets.GITHUB_TOKEN }}
```

### Use workflow output

```yaml
name: Reusable workflow

on:
  workflow_call:
    # Map the workflow outputs to job outputs
    outputs:
      firstword:
        description: "The first output string"
        value: ${{ jobs.example_job.outputs.output1 }}
      secondword:
        description: "The second output string"
        value: ${{ jobs.example_job.outputs.output2 }}

jobs:
  example_job:
    name: Generate output
    runs-on: ubuntu-latest
    # Map the job outputs to step outputs
    outputs:
      output1: ${{ steps.step1.outputs.firstword }}
      output2: ${{ steps.step2.outputs.secondword }}
    steps:
      - id: step1
        # set step output
        run: echo "firstword=hello" >> $GITHUB_OUTPUT
      - id: step2
        run: echo "secondword=world" >> $GITHUB_OUTPUT
```

Then use workflow output in the caller workflow:

```yaml
name: Call a reusable workflow and use its outputs

on:
  workflow_dispatch:

jobs:
  job1:
    uses: octo-org/example-repo/.github/workflows/called-workflow.yml@v1

  job2:
    runs-on: ubuntu-latest
    needs: job1
    steps:
      - run: echo ${{ needs.job1.outputs.firstword }} ${{ needs.job1.outputs.secondword }}
```
