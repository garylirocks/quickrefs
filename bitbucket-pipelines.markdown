# Bitbucket Pipelines

- [General](#general)
- [Demo config](#demo-config)

## General

add a `bitbucket-pipelines.yml` file in your root directory to config how pipelines run

- You can configure multiple pipelines, they can be triggered by any push, on specific branch or tag, or manually;
- Each pipeline has multiple steps, each step launches a new container, it can all use the same image, or specific images;
- Files generated in a step can be kept for later steps;

## Demo config

```yaml
image: atlassian/default-image:2 # specify a global image, can be overriden by each step

pipelines:
  default: # runs on every push, unless another branch/tag pipeline matches
    - step:
        name: Build and test
        image: node:8.5.0
        caches:
          - node
        script:
          - npm install
          - npm test
          - npm run build
        artifacts: # artifacts are kept for later steps
          - dist/**
          - reports/*.txt
    - step:
        name: Integration test
        image: node:8.5.0
        caches:
          - node
        services:
          - postgres
        script:
          - npm run integration-test
    - step:
        name: Deploy to beanstalk
        image: python:3.5.1
        trigger: manual # trigger this step manually
        script:
          - python deploy-to-beanstalk.py
  tags:
    release-*: # matchs any 'release-*' tag
      - step:
          # ...
          script:
            - echo "Only triggered with 'release-*' tag"
  custom: # manually triggered pipelines
    deployment-to-prod:
      - step:
          #...
          deployment: production # enable deployment tracking
          script:
            - echo "Manual triggers for deployment"

definitions: # defines other containers
  services:
    postgres:
      image: postgres:9.6.4
```

- `custom` pipelines and steps with `trigger: manual` are triggered manually;
- `deployment` can be `test`, `staging`, `production`;
