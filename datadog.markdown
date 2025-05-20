# Datadog

- [Overview](#overview)
  - [Concepts](#concepts)
- [Logs](#logs)
  - [Example queries](#example-queries)
  - [Configs](#configs)
  - [Tags and attributes](#tags-and-attributes)
  - [Facet](#facet)
  - [Views](#views)
  - [Log pathway](#log-pathway)
  - [Log processing rules (Pipelines)](#log-processing-rules-pipelines)
  - [Indexing](#indexing)
- [Metrics](#metrics)
  - [Metric types](#metric-types)
  - [SLI \& SLO](#sli--slo)
- [Application Performance Monitoring (APM)](#application-performance-monitoring-apm)
  - [Instrumentation](#instrumentation)
  - [Continuous Profiler](#continuous-profiler)
- [Network Performance Monitoring (NPM)](#network-performance-monitoring-npm)
- [Integrations](#integrations)
  - [Installation](#installation)
- [Kubernetes](#kubernetes)
- [Tagging](#tagging)
  - [`docker-compose`](#docker-compose)
  - [Best practices](#best-practices)
- [Agent/library Configuration](#agentlibrary-configuration)
  - [Remote configuration](#remote-configuration)
  - [Processes](#processes)
- [Monitor](#monitor)
  - [Notifications](#notifications)
- [Universal Service Monitoring (USM)](#universal-service-monitoring-usm)
  - [`docker-compose`](#docker-compose-1)
  - [Service Catalog](#service-catalog)
- [Synthetic testing](#synthetic-testing)
- [Real User Monitoring (RUM)](#real-user-monitoring-rum)
- [Keys](#keys)
- [DogStatsD](#dogstatsd)
- [Audit Trail](#audit-trail)
- [Azure](#azure)
  - [Container Apps](#container-apps)
    - [Via sidecar container](#via-sidecar-container)
    - [Via `serverless-init`](#via-serverless-init)


## Overview

### Concepts

- **Monitoring**: what happened in a system
- **Observability**: why it happened


## Logs

### Example queries

| Search term | Format                                     | Example              |
| ----------- | ------------------------------------------ | -------------------- |
| tag         | key:value                                  | `service:frontend`   |
| attribute   | @key:value                                 | `@http.method:POST`  |
| single term | word                                       | `Response`           |
| sequence    | group of words surrounded by double quotes | `"Response fetched"` |
| wildcard    | tag or attribute name and value            | `*:prod*`            |
| wildcard    | log message                                | `prod*`              |

### Configs

`docker-composer.yml` config for the Agent service

```yaml
services:
  agent:
    image: "datadog/agent:7.31.1"
    environment:
      - DD_API_KEY
      - DD_APM_ENABLED=true
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_DOCKER_LABELS_AS_TAGS={"my.custom.label.team":"team"}
      - DD_TAGS='env:intro-to-logs'
      - DD_HOSTNAME=intro-logs-host
    ports:
      - "8126:8126"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
    labels:
      com.datadoghq.ad.logs: '[{"source": "agent", "service": "agent"}]'
```

### Tags and attributes

- Tags are assigned at host or container level
  - `source` tag is for the integration name, corresponding to Log Processing Pipeline
- Attributes are extracted from logs
  - By a log processing pipeline, either a built-in Integration Pipeline, or a custom one

### Facet

- Automatically created from common tags and log attributes
- A facet could be a **measure**, which is numerical and continuous, could be filtered by a range
  - eg. `@network.bytes_written:[512 TO 1024]`
- You can create custom facet from log tags or attributes

### Views

- Queries could be saved into views
- There are also predefined views, eg. Postgres, NGINX, Redis, ...

### Log pathway

![Log processing pathway](./images/datadog_log-pathway-condensed.png)

### Log processing rules (Pipelines)

- Each pipeline includes a list of sequential Processors
  - Each pipeline has a query filter (eg. `source:nginx`), only matching logs are processed by the pipeline
  - Pipelines could be nested up to one level
- Pipelines extract attributes from each log message
- There are out-of-the-box integration pipelines for common services
- JSON format logs are pre-processed before pipelines
- Processors
  - Grok
    - Regex matching
    - A pipeline can have multiple Grok parsers
    - One Grok parser can have multiple parsing rules
    - Subsequent Grok parser can be used on an attribute extracted by preceding parsers
- Standard Attribute
  - Processed after all the pipelines
  - Instead of adding a remapper to each pipeline, you can use this to remap a common attribute from any source

### Indexing

- Ingested logs:
  - Watchdog(automated) Insights, Error Tracking, generating metrics, and Cloud SIEM detection rules
- Indexed logs:
  - Can be used in monitors, dashboards, notebooks


## Metrics

Can be collected by:

- DD Agent
- Integrations
- Generated within Datadog (eg. form logs)
- Custom metrics
  - Agent
  - DogStatsD
  - HTTP API

### Metric types

- Count (times in an interval)
- Rate (frequency)
- Gauge (last value in an interval)
- Histogram (five values: mean, count, median, 95th percentile, and maximum)
- Distribution (summarize values across all the hosts)
  - Enhanced query functionality and configuration options

RED metrics: Rate, Errors, Duration

### SLI & SLO

Service Level Indicators (SLI): metrics to measure some aspect of the level of service

Service Level Objectives (SLO): SLIs monitored overtime, eg.
- 99% of requests being successful over the past 7 days
- less than 1 second latency 99% of the time over the past 30 days

You can create an SLO based on a monitor, then you can create a monitor on an SLO to get alerts.


## Application Performance Monitoring (APM)

- **Trace**: tracks the time spent by an application processing a request and the status of this request. Each trace consists of one or more spans.
- **Span**: represents a logical unit of work in a distributed system for a given time period. Multiple spans construct a trace.
  - **Trace root span**: The entry point of the entire trace, the service that generates this first span also creates the Trace ID

### Instrumentation

- You use language-specific Datadog libraries (`ddtrace`) in your application code.
- Traces are submitted to Datadog Agent first, then sent to Datadog.
- By default, Agent collects traces using TCP port 8126.
- Instrumented application expect some environment variables, eg. `DATADOG_HOST` `DD_ENV`, `DD_VERSION`, and `DD_SERVICE`.
  - `DD_AGENT_HOST`: which service hosts the agent
  - `DD_LOGS_INJECTION`: injects `trace_id` and `span_id` into logs
    - In Node.js, could be set in code `const tracer = require('dd-trace').init({ logInjection: false });` and it takes precedence over the env variable
    - If nothing in code, the env variable is applied
  - `DD_TRACE_SAMPLE_RATE`
  - `DD_PROFILING_ENABLED` whether enable continuous profiler
  - `DD_SERVICE_MAPPING` rename service
- For Python app, run it with command `ddtrace-run`, like:

    ```sh
    DD_SERVICE="<SERVICE>" DD_ENV="<ENV>" DD_LOGS_INJECTION=true ddtrace-run python my_app.py
    ```

### Continuous Profiler

- Gives you insight into the system resource consumption (eg. CPU, memory and IO bottlenecks) of your applications beyond traces
- Supported by client libraries


## Network Performance Monitoring (NPM)

- Built on eBPF (detailed visibility into network flows at the Linux kernel level)
- Powerful and efficient with extremely low overhead
- Can monitor DNS traffic and DNS servers

To enable with containerized agent:

```yaml
    environment:
      - DD_SYSTEM_PROBE_NETWORK_ENABLED=true
      - ...
    volumes:
      - /sys/kernel/debug/:/sys/kernel/debug
      - ...
    cap_add:
      - SYS_ADMIN
      - SYS_RESOURCE
      - SYS_PTRACE
      - NET_ADMIN
      - NET_BROADCAST
      - NET_RAW
      - IPC_LOCK
      - CHOWN
    security_opt:
      - apparmor:unconfined
```


## Integrations

Three types:

- **Agent-based (system checks)**, use a Python class method called `check`
  - `check` method executes every 15 seconds
  - A check could collects multiple metrics, events, logs and service checks
  - Show the checks `docker compose exec datadog agent status`
  - Run a specific check `docker compose exec datadog agent check disk`
- **Authentication based (crawler)**
  - Either pull data from other systems, using other system's credentials
  - Or authorize other systems to push data to Datadog, using Datadog's API key
- **Library** integrations, use the Datadog API to allow you to monitor applications based on the language they are written in, like Node.js or Python.
  - Imported as packages to your code
  - Use Datadog's tracing API
  - Collect performance, profiling, and debugging metrics from your application at runtime

### Installation

When an integration is installed, it may also install OOTB dashboards, log processing pipelines, etc


## Kubernetes

The Datadog Agent is run as a DaemonSet to ensure the Agent is deployed on all nodes in the cluster.

Agent config:

```yaml
apiVersion: datadoghq.com/v2alpha1
kind: DatadogAgent
metadata:
  name: datadog-agent
  namespace: default
spec:
  global:
    clusterName: tagging-use-cases-k8s
    credentials:
      apiSecret:
        secretName: datadog-secret
        keyName: api-key
      appSecret:
        secretName: datadog-secret
        keyName: api-key
    podLabelsAsTags:
      "*": kube_pod_%%label%%
```

Configure `podLabelsAsTags:` to extract pod labels as tags


Pod config:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod61
  labels:
    component: backend
  annotations:
    ad.datadoghq.com/tags: '{"env": "production", "service": "user-service", "office": "lax", "team": "community", "role": "backend", "color": "red"}'
...
```

Pod `labels` and `annotations` will be extracted as tags


## Tagging

Tags could be key-value pairs (eg. `env:prod`), or simple value tags (eg. `file-server`)

Reserved tag key:

- `host`: correlation between metrics, traces, processes, and logs
- `device`
- `source`
- `env`
- `service`
- `version`
- `team`

Unified Service Tagging: `service`, `env`, `version`

### `docker-compose`

- To map a custom container label to a tag, use this environment variable on the agent container: `DD_CONTAINER_LABELS_AS_TAGS={"my.custom.label.color":"color"}`

### Best practices

- `trace_id`, `span_id` can be injected as tags in logs, for correlation


## Agent/library Configuration

By priority (high to low):

- Remote configuration
- Environment variables
- Local configuration (`remote_config.enabled` setting controls whether an agent accepts Remote Configuration)

### Remote configuration

- Works for agents or tracing libraries
- Enables them to pull configurations from Datadog
- Could be enabled at organization scope
- Supported features:
  - APM (config, sampling rate)
  - ASM (protect against OWASP, WAF attack patterns)
  - CSM (default agent rules, agentless scanning in AWS only ?)
  - Dynamic instrumentation (metrics, logs and traces from live application without code change)
  - Fleet automation
  - Control observability pipeline workers

### Processes

By default, the agent do not collect process-level metrics, you need to enable it with `process.d/conf.yaml`

It could collect metrics like:
- `system.processes.cpu.pct`
- `system.processes.ioread_bytes`
- `system.processes.threads`
- `system.processes.run_time.avg` (The average running time of all instances of this process)


## Monitor

### Notifications

There's not a field dedicated for recipients, you need to specify it with `@`, `@slack` in the message

```
The {{service.name}} service container {{color.name}} has high CPU usage!!

Contact: Email - @{{service.name}}@mycompany.com, @admin@mycompany.com
Slack - @slack-{{service.name}}
```


## Universal Service Monitoring (USM)

Enabling USM requires the following:

- If on Linux, your service must be running in a container.
- If on Windows and using IIS, your service must be running on a virtual machine.
- The Datadog Agent needs to be installed alongside your service.
- The `env` tag for Unified Service Tagging must be applied to your deployment.

Commonly used container tags: `app`, `short_image`, `container_name`
- `short_name` tag is used to discover common services, eg. `short_name:nginx` will identify `nginx` service

### `docker-compose`

- You need a few settings for the agent container to turn on USM
- Use `labels` like `com.datadoghq.tags.*` in other containers for tagging

### Service Catalog

For a service to show up, it needs to have unified service tags: `service`, `env`, `version`

Some services (eg. databases) showing up in the Catalog, but do not communicate with the Datadog Agent directly, their traces get captured by other services.

You can manage metadata of a service either:
- Manually: using the web UI
- Automatically: Github or Terraform


## Synthetic testing

Associate testing results to APM:

- Not done by default
- You must specify the URLs for which Datadog should add the necessary HTTP headers


## Real User Monitoring (RUM)

- Works for web JS and mobile apps
- You need to instrument your app with RUM SDK (by `<script />` tag or NPM package)



## Keys

|                          | API keys | App Keys | Client tokens                                      |
| ------------------------ | -------- | -------- | -------------------------------------------------- |
| Scope                    | org      | user     | org                                                |
| Disabled with user ?     | No       | Yes      | No                                                 |  |
| Auth scopes customizable | No       | Yes      | No                                                 |  |
| Usage                    | DD Agent | DD API   | End user facing applications (browser, mobile, TV) |

- **API keys**
  - Datadog Agent requires an API key to submit metrics and events to Datadog
- **Application keys**
  - In conjunction with your organization's API key, give users access to Datadog's programmatic API.
  - By default have the permissions and scopes of the user who created them
  - Permissions required to create or edit application keys:
    - `user_app_keys` permission to scope their own application keys
    - `org_app_keys_write` permission to scope application keys owned by any user in their organization
    - `service_account_write` permission to scope application keys for service accounts
  - If a user's role or permissions change, authorization scopes specified for their application keys remain unchanged


## DogStatsD

- DogStatsD consists of a server, which is bundled with the Datadog Agent
  - Could be installed as a standalone package as well
- and a client library, which is available in multiple languages.
- The DogStatsD server is enabled by default over UDP port 8125 for Agent v6+. You can set a custom port for the server if necessary.

- DogStatsD accepts custom metrics, events, and service checks over UDP and periodically aggregates and forwards them to Datadog.

- Because it uses UDP, your application can send metrics to DogStatsD and resume its work without waiting for a response. If DogStatsD ever becomes unavailable, your application doesn’t experience an interruption.

- As it receives data, DogStatsD aggregates multiple data points for each unique metric into a single data point over a period of time called the flush interval. DogStatsD uses a flush interval of **10 seconds**.



## Audit Trail

- Retention in Datadog up to 90 days
- Can be forwarded for archiving in Azure Storage, etc


## Azure

- Two integration methods
  - "Datadog - An Azure Native ISV Service"resource in Azure
  - App registration
    - The app reg needs "Monitoring Reader" role over the monitored scope
    - Need Datadog API key and App key
- Configuration
  - All metrics are collected by default, you could add filters to include/exclude VMs, ASPs, Container apps (eg. `datadog:monitored,env:production,!env:staging,instance-type:c1.*`)
  - Whether include custom metrics from App Insights (will be under namespace `application_insights.custom.<METRIC_NAME>`)
  - Whether collect resource metadata and configurations
  - Whether enable Cloud security management on resource configurations

### Container Apps

- Tracing: instrument your code with `dd-trace-*` library
- Metrics:
  - Standard metrics by the overall Azure integration
  - Custom metrics by the tracer
- Logs:
  - Azure Integration
  - Agent for direct log collection

#### Via sidecar container

- Uses file tailing to collect logs
  - The volume is mounted to both the app container and the sidecar
  - The volume could be ephemeral
- Env variables can't be shared, must be set on both containers
  - You could use references to secrets set on the ACA resource
  - Common env variables:
    - `DD_SERVICE`
    - `DD_ENV`
    - `DD_VERSION`
- Additional env variables for the app container:
  - `DD_LOGS_INJECTION` *must be on the app container, could be overwritten by setting in the app code*
  - could be on app container, not sure if they work on the sidecar
    - `DD_LOGS_ENABLED`
    - `DD_TRACE_SAMPLE_RATE`
- Additional env variables for the sidecar container:
    - `DD_AZURE_SUBSCRIPTION_ID`
    - `DD_AZURE_RESOURCE_GROUP`
    - `DD_API_KEY`
    - `DD_SERVERLESS_LOG_PATH`
    - `DD_SOURCE` *must be set on the sidecar, won't work on the app container, will be `containerapp` if not set*

#### Via `serverless-init`

- Use `serverless-init` to wrap your process
  - Starts a DogStatsD listener for metrics
  - And a Trace Agent listener for traces
  - Collects logs by wrapping the stdout/stderr streams of your process
  - Launches your command as a subprocess
- Logs collected by Azure integration, alternatively, set `DD_LOGS_ENABLED=true` environment variable to capture logs through the serverless instrumentation directly
- This integration depends on your runtime having a full SSL implementation. If you are using a slim image for Node, you may need to add the following command to your Dockerfile to include certificates.

  `RUN apt-get update && apt-get install -y ca-certificates`

- `Dockerfile` example:
  ```dockerfile
  COPY --from=datadog/serverless-init:1 /datadog-init /app/datadog-init
  RUN npm install --prefix /dd_tracer/node dd-trace  --save
  ENV DD_SERVICE=datadog-demo-run-nodejs
  ENV DD_ENV=datadog-demo
  ENV DD_VERSION=1
  ENTRYPOINT ["/app/datadog-init"]
  CMD ["/nodejs/bin/node", "/path/to/your/app.js"]
  ```
