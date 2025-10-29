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
  - [Attributes](#attributes)
  - [Trace ingestion and retention](#trace-ingestion-and-retention)
  - [Ingestion](#ingestion)
    - [Head-based sampling](#head-based-sampling)
    - [Error and rare spans sampling](#error-and-rare-spans-sampling)
    - [Manual](#manual)
    - [Single span sampling rule](#single-span-sampling-rule)
    - [Other ingestion reasons](#other-ingestion-reasons)
    - [Span filtering](#span-filtering)
  - [Generating metrics](#generating-metrics)
  - [Retention](#retention)
  - [Trace metrics](#trace-metrics)
  - [Runtime metrics](#runtime-metrics)
    - [Node.js](#nodejs)
  - [Usage metrics](#usage-metrics)
  - [Continuous Profiler](#continuous-profiler)
  - [APM monitors](#apm-monitors)
- [Network Performance Monitoring (NPM)](#network-performance-monitoring-npm)
- [Integrations](#integrations)
  - [Installation](#installation)
- [Kubernetes](#kubernetes)
- [Tagging](#tagging)
  - [`docker-compose`](#docker-compose)
  - [Best practices](#best-practices)
- [Agent](#agent)
  - [Docker](#docker)
  - [Agent running as a container](#agent-running-as-a-container)
- [Agent/library Configuration](#agentlibrary-configuration)
  - [Remote configuration](#remote-configuration)
  - [Fleet Automation](#fleet-automation)
  - [Processes](#processes)
    - [Live Processes](#live-processes)
    - [Process checks](#process-checks)
- [Monitor](#monitor)
  - [Notifications](#notifications)
- [Universal Service Monitoring (USM)](#universal-service-monitoring-usm)
  - [`docker-compose`](#docker-compose-1)
  - [Service Catalog](#service-catalog)
- [Synthetic testing](#synthetic-testing)
- [Real User Monitoring (RUM)](#real-user-monitoring-rum)
  - [Collected event types](#collected-event-types)
  - [Data masking](#data-masking)
  - [Session replay](#session-replay)
  - [Correlate RUM with APM](#correlate-rum-with-apm)
  - [Notes](#notes)
- [Database Monitoring (DBM)](#database-monitoring-dbm)
  - [DBM features](#dbm-features)
  - [Diagnose DB performance issues](#diagnose-db-performance-issues)
  - [Example config for Oracle](#example-config-for-oracle)
- [Error Tracking](#error-tracking)
- [Keys](#keys)
- [DogStatsD](#dogstatsd)
- [Source code integration](#source-code-integration)
  - [Setup](#setup)
- [Audit Trail](#audit-trail)
- [Azure](#azure)
  - [Logging](#logging)
  - [Container Apps](#container-apps)
    - [Via sidecar container](#via-sidecar-container)
    - [Via `serverless-init`](#via-serverless-init)
- [Gotchas](#gotchas)


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

- **Trace**: tracks the time spent by an application processing a request and the status of this request. Each trace consists of one or more spans. Created from spans by Datadog.
- **Span**: represents a logical unit of work in a distributed system for a given time period. Multiple spans construct a trace.
  - **Trace root span**: The entry point of the entire trace, the service that generates this first span also creates the Trace ID
  - Span tags and attributes are similar but distinct concepts:
    - **Tags** provide context (about the host, container or service): `hostname`, `pod_name`, ...
    - **Attributes** are about the content of a span, eg. `http.url`, `http.status_code`, `error.message`, ..., use `@` prefix in queries, like `@http.status_code:500`

### Instrumentation

- You use language-specific Datadog libraries (`ddtrace`) in your application code.
- Traces are submitted to Datadog Agent first, then sent to Datadog.
  - By default, Agent collects traces using TCP port 8126.
- Instrumented application expect some environment variables, eg. `DATADOG_HOST` `DD_ENV`, `DD_VERSION`, and `DD_SERVICE`.
  - `DD_AGENT_HOST`: which service hosts the agent
  - `DD_LOGS_INJECTION`: injects `trace_id` and `span_id` into logs
    - In Node.js, could be set in code `const tracer = require('dd-trace').init({ logInjection: false });` and it takes precedence over the env variable
    - If nothing in code, the env variable is applied
    - **Automated injection** only works for certain logging libraries (eg. Winston, Bunyan, Pino, etc for NodeJS) and logs formatted as JSON, see https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/nodejs/
      - Not working for `console.log()`
      - Not working for `morgan` in NodeJS, you may make it work manually, see https://github.com/delfiatech/dd-nodejs-morgan
  - `DD_TRACE_SAMPLE_RATE`
  - `DD_PROFILING_ENABLED` whether enable continuous profiler (NOT supported by all languages)
  - `DD_SERVICE_MAPPING` rename service
- For Python app, run it with command `ddtrace-run`, like:
    ```sh
    DD_SERVICE="<SERVICE>" DD_ENV="<ENV>" DD_LOGS_INJECTION=true ddtrace-run python my_app.py
    ```

### Attributes

- See https://docs.datadoghq.com/standard-attributes/?product=apm
- The headers of requests/responses are NOT collected by default, you need to enable it with
  - `DD_TRACE_HEADER_TAGS=Brand-ID:http.brand_id,Color-ID:http.color_id` (with name remapping)
  - OR `DD_TRACE_HEADER_TAGS=Brand-ID,Color-ID` (keep in `http.request.headers.*` or `http.response.headers.*`)

### Trace ingestion and retention

![Trace ingestion and retention](./images/datadog_trace-pipeline.avif)

- **Ingestion**: data sent to Datadog, available for 15 mins live search
  - To each span ingested, there is attached a unique ingestion reason
- **Indexing/retention**: indexed for search, retained for 15 days
- Metrics generated are stored for 15 months
- Relevant built-in dashboards:
  - APM Traces Estimated Usage
  - APM Traces Ingestion Reasons Overview

### Ingestion

- Sampling rate could be controlled remotely for newer Agents with `DD_REMOTE_CONFIGURATION_ENABLED=true`
- Use "Ingestion Control" page to view and set sampling rate remotely
- For each service, the config mode could be:
  - Automatic (10 TPS per Agent)
  - Configured remotely (via Ingestion Control)
  - Configured locally (via `DD_TRACE_SAMPLING_RULES` targeting a service)
  - Adaptive (both Agent and Tracer versions are compatible, and onboarded)

#### Head-based sampling

![Head-based sampling](./images/datadog_head-based-sampling.avif)

- Decision made at the start of the root span
- The trace is guranteed to be kept or dropped as a whole
- Decision propagated to other services as part of their request context, for example an HTTP request header
- You can set sampling rates for head-based sampling in two places:
  - Agent (default)
    - `ingestion_reason: auto`
    - Default value is 10 traces per second
    - Could be customized in "Ingest Control" page, or env var `DD_APM_MAX_TPS`
    - The Agent tunes sampling by **sending sampling rates to trace libraries**
    - The rate is distributed **across all services** reporting to the Agent, if both service A nad B report to the same Agent, A might be instructed to keep 7 traces per second, B to keep 3
  - Tracing library
    - `ingestion_reason: rule`
    - User defined rule (eg. `DD_TRACE_SAMPLING_RULES`), could be at service or resource level
    - Overrides rate limit sent to the tracing library by the Agent
    - New rate limit default to 100 per second, per service instance (configured by `DD_TRACE_RATE_LIMIT`)

#### Error and rare spans sampling

- Additional sampling mechanisms to keep critical and diverse traces
- Capture **local** traces at the Agent level (no propagation to other services, so traces could be not complete)
- They are **IGNORED** when using custom library sampling rules for services
- Error sampler:
  - `ingestion_reason:error`
  - Not already caught by head-based sampling
  - Up to 10 traces per second per Agent (customizable with `DD_APM_ERROR_TPS`)
- Rare sampler:
  - `ingestion_reason:rare`
  - Based on combinations of `env`, `service`, `name`, `resource`, `error.type` and `http.status`
  - Up to 5 traces per second per Agent
  - Could be disabled in "Ingest Control" page

#### Manual

- `ingestion_reason: manual`
- In the code, you could **manually force keep or drop** a trace , but this trace could be incomplete, and could still be dropped at the Agent level based on rules

#### Single span sampling rule

- `ingestion_reason: single_span` (seems show up in Datadog as `ingestion_reason:rule` ?)
- When you want a specific span ingested for metrics, but don't want to ingest the whole traces
- Sampling rules could be based on resource names, service names, tags and operation names (based on the first span in a trace)
- Span kept by head-based sampling won't be affected
- Example:
  ```sh
  # service name
  DD_TRACE_SAMPLING_RULES='[{"service": "store-frontend-api", "sample_rate": 0.20}]'

  # resource name
  DD_TRACE_SAMPLING_RULES='[{"resource": "GET healthcheck", "sample_rate": 1.0, "max_per_second": 50}]'

  # tags
  DD_TRACE_SAMPLING_RULES='[{"tags": {"http.url": "http://.*/healthcheck$"}, "sample_rate": 0.5}]'
  ```

#### Other ingestion reasons

- `ingestion_reason:otel`: OpenTelemetry setup
- `ingestion_reason:rum`
  - For traces initiated by Real User Monitoring (RUM) sessions, default to 100%, could be controlled by `traceSampleRate` parameter
- `ingestion_reason:synthetics` or `ingestion_reason:synthetics-browser`
  - 100% by default
- Others:
  - `lambda` or `xray`: AWS Lambda or X-Ray
  - `appsec`: flagged by AAP as a threat
  - `data_jobs`: Datadog Java Tracer Spark integration or Databricks integration

#### Span filtering

If you don't want a span ingested, and don't want to see it reflected in trace metrics.

Could be done with either Trace Agent (in Datadog Agent) configuration or Tracer configuration
- Trace Agent
  - Based on tags or resources (support regex)
  - Env variables:
    - `DD_APM_FILTER_TAGS_REQUIRE="key1:value1 key2:value2"`
    - `DD_APM_FILTER_TAGS_REJECT="key1:value1 key2:value2"`
    - `DD_APM_IGNORE_RESOURCES="(GET|POST) /healthcheck,API::NotesController#index"`
  - Or do it in `datadog.yaml` file
    ```yaml
    apm_config:
      ignore_resources: ["(GET|POST) /healthcheck","API::NotesController#index"]
      filter_tags:
        require: ["db:sql", "db.instance:mysql"]
        reject: ["outcome:success", "key2:value2", "http.url:http://localhost:5050/healthcheck"]
    ```
- Tracer
  - Language specific code
  - Node.js example
    ```js
    const tracer = require('dd-trace').init();
    tracer.use('http', {
      // incoming http requests match on the path
      server: {
        blocklist: ['/healthcheck']
      },
      // outgoing http requests match on a full URL
      client: {
        blocklist: ['https://telemetry.example.org/api/v1/record']
      }
    })
    ```

### Generating metrics

- Happens before retention/indexing
- Based on 100% of ingested spans
  - You can base metrics on *all* application traffic, without ingesting 100% all traces. This is done by configuring **span sampling rules** at the trace library.
- Available for 15 months
- Billed as custom metrics

### Retention

- **The Intelligent Retention Filter**
  - Always on
  - Retains a subset of spans for every environment, service, operation, and resource for different latency distributions
  - A combination of diversity sampling and 1% flat sampling
    - Diversity-sampled spans are **biased** towards errors and high latency traces, you can choose to exclude them by adding `-retained_by:diversity_sampling` to a search query
    - For the reasons explained above, spans indexed by the intelligent retention filter are **excluded** from alert monitors that use APM Trace Analytics.
  - **Not** counted towards the usage of indexed spans, do not impact your bill
- **Default retention filters**:
  - Synthetics Default: `@_dd.origin:(synthetics OR synthetics-browser)`
  - Error Default: `status:error`
- **Custom filters**:
  - Based on span attribute or tag filters
  - Query could be targeting: Trace root spans, Service entry spans, or all spans
  - Then you define:
    - Span rate: percentage of matching spans to index
    - Trace rate: percentage of full traces associated with the indexed span
  - A span is processed by the first matching retention filter only, so filter order matters
- Depending on your filters:
  - some spans are indexed by itself, not in a full trace
  - some spans are indexed because it is in the same trace with an indexed span

### Trace metrics

- Metrics:
  - request counts
  - error counts
  - latency
- Available for dashboards and monitors
- Based on 100% of the application's traffic, regardless of ingestion sampling configs


### Runtime metrics

- About your application's memory usage, garbage collection, and parallelization
- Can be enabled with `DD_RUNTIME_METRICS_ENABLED=true` environment variable
- Send to `localhost:8125` by default

#### Node.js

- Not enabled by default for Node.js
- Can be enabled with `DD_RUNTIME_METRICS_ENABLED=true` or in code

    ```js
    require('dd-trace').init({
      // other tracer options...
      runtimeMetrics: true
    })
    ```
- Example metrics:
  - `runtime.node.cpu.total`
  - `runtime.node.mem.rss`
  - `runtime.node.process.uptime`
  - `runtime.node.event_loop.delay.avg`
  - `runtime.node.gc.pause.avg`

### Usage metrics

- Built-in metrics for number of ingested/indexed spans
- Metric names start with `datadog.estimated_usage.apm`
  - Metrics like `datadog.estimated_usage.apm.ingested_spans` is tagged with `ingestion_reason`, `service`, `env`
- You can create alert monitors on these metrics to avoid unexpected usages
- There are built-in APM dashboards

### Continuous Profiler

- Gives you insight into the system resource consumption (eg. CPU, memory and IO bottlenecks) of your applications beyond traces
- Supported by client libraries

### APM monitors

Three types:

- APM metrics
- Trace Analytics
  - Only for traces retained by custom retention filters, not the ones retained by Datadog's Intelligent Retention Filter (those are biased)
- Watchdog


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

- **Agent-based (AKA. checks)**
  - Use a Python class method called `check`, executed every 15 seconds
  - A check could collects multiple metrics, events, logs and service checks
    - eg. use `http_check` to collect metrics from an HTTP endpoint, it generates metrics like `network.http.can_connect`, `network.http.response_time`, etc
  - Some are considered core integrations, eg. disk, Docker, Nginx, MySQL, Redis, etc
  - You can define custom checks, see [here](https://docs.datadoghq.com/developers/custom_checks/write_agent_check/), you need to create a custom Python file `checks.d/my_custom_check.py`, and then `conf.d/my_custom_check.yaml` (could be in a sub-folder like `conf.d/my_custom_check/conf.yaml` as well)
  - Commands:
    ```sh
    # Show the checks
    sudo datadog-agent status

    # Run a specific check
    sudo datadog-agent check uptime
    ```
- **Authentication based (crawler)**
  - Either pull data from other systems, using other system's credentials, eg. AWS, Azure, GCP, etc
  - Or authorize other systems to push data to Datadog, using Datadog's API key
- **Library**
  - Often refereed to as trace libraries
  - Use Datadog's tracing API
  - Mostly for APM
  - You import packages to your code
  - Send data to the Agent, the Agent then sends it to Datadog (with related tags)
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


## Agent

- Could be installed on a host, or in a container
- Components:
  - Collector: running checks and collect metrics
  - Forwarder: sending payloads to Datadog
  - APM Agent: collect app traces
  - Process Agent: collect live process infomation
  - Dozens of Integrations (checks):
    - Python scripts that the Agent runs to collect metrics, events, and logs from the host and running services, such as: Nginx, Redis, PostgreSQL, etc
    - Some core system checks run by default: disk, cpu, memory, uptime etc
- Main config file in `datadog.yaml`
  - Enabled by default: system checks, accepting APM traces
  - Disabled by default: live processes, log collection
- Common commands
  ```sh
  # Show status
  sudo datadog-agent status

  # configs
  sudo datadog-agent config

  # list running checks
  sudo datadog-agent configcheck
  ```

### Docker

The Agent collects metrics, events and logs from containers by reading `docker.sock`, which is only accessible to users in the `docker` group.

```sh
# Add the dd-agent user to the docker group
usermod -a -G docker dd-agent
```

For the agent on a host to receive APM traces from containers, you need to set `apm_non_local_traffic: true`

### Agent running as a container

<img src="./images/datadog_agent-in-a-container.png" width="600" alt="Agent in a container" />

- Can monitor the host, container runtime, and other containers
- Monitor the host by mounting host resources as volumes within the Agent container
- Configuration on Agent container:
  - Environment variables: `DD_API_KEY`, `DD_ENV`, etc
    - Use this to configure which custom labels to collect as tags: `DD_CONTAINER_LABELS_AS_TAGS={"my.custom.label.team":"team"}`
- Configuration on workload containers:
  - Environment variables: typically used if the container has been instrumented with APM libraries, can be used to tag logs and metrics
    - You could set `DD_ENV` to override the one on the Agent container
    - `DD_AGENT_HOST` for APM library to send traces to the Agent
    - `DD_SERVICE` (overriding the container name), `DD_VERSION`, etc
  - **Labels**: for tagging logs and metrics, usually for containers NOT instrumented with APM libraries
    ```yaml
    labels:
      my.custom.label.team: 'discounts'
      com.datadoghq.tags.service: 'discounts'
      com.datadoghq.tags.version: '1.0.3'
      com.datadoghq.ad.logs: '[{"source": "python", "service": "discounts"}]' # apply to logs, help Datadog to process the logs, `service` tag is optional here, because already set by `com.datadoghq.tags.service`
    ```
    Could also have additional labels for specific integrations, eg. for the Agent to connect to a Postgres database:
    ```yaml
    com.datadoghq.ad.checks: '{"<INTEGRATION_NAME>": {"instances": [<INSTANCE_CONFIG>], "logs": [<LOGS_CONFIG>]}}'
    com.datadoghq.ad.init_configs: '[{}]'
    com.datadoghq.ad.instances: '[{"host":"%%host%%", "port":5432, "username":"datadog", "password":"datadog"}]'
    ```
    In newer Agent versions, it could try autodiscovery with some common services
- The Agent can collect logs from services that are writing to respective containers standard output

Example config for the Agent container:

```yaml
dd-agent:
    image: gcr.io/datadoghq/agent:7.56.0
    environment:
      - DD_API_KEY
      - DD_HOSTNAME
      - DD_ENV
      - DD_LOGS_ENABLED=true
      - DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true
      - DD_PROCESS_AGENT_ENABLED=true
      - DD_CONTAINER_LABELS_AS_TAGS={"my.custom.label.team":"team"}
      - DD_APM_NON_LOCAL_TRAFFIC=true
      - DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true
      - DD_SYSTEM_PROBE_NETWORK_ENABLED=true
      - DD_SYSTEM_PROBE_SERVICE_MONITORING_ENABLED=true
      - HOST_ROOT='/host/root'
    pid: "host"
    ports:
      - "8126:8126/tcp"
      - "8125:8125/udp"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /sys/kernel/debug:/sys/kernel/debug
      - /:/host/root:ro
      - /etc/passwd:/etc/passwd:ro
      - /etc/group:/etc/group:ro
      - /etc/os-release:/etc/os-release
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

Commands:

```sh
docker compose exec dd-agent agent status

docker compose exec dd-agent agent config
```


## Agent/library Configuration

By priority (high to low):

- Remote configuration
- Environment variables
- Local configuration (`datadog.yaml`)
  - `remote_config.enabled` controls whether an agent accepts Remote Configuration

### Remote configuration

- Remotely config Datadog components (such as Agents, tracing libraries, Observability Pipelines Workers) for select features
- Could be enabled at organization scope
  - Enabled by default in most cases, see [here](https://docs.datadoghq.com/agent/remote_config/?tab=configurationyamlfile#enabling-remote-configuration)
  - An API key could be enabled or disabled for remote configuration
- When enabled, Agents polls and automatically applies configuration updates from Datadog
  - Tracing libraries communicate with Agents to request and receive configuration updates
- Supported environments:
  - Agents on hosts
  - Serverless container cloud services: AWS Fargate
  - Not supported: Azure Container Apps, Azure Functions
- Supported features:
  - Fleet automation
  - APM
    - services's trace sampling rate, log injection enablement, HTTP header tags, etc
    - Agent trace sampling rate, etc
  - Dynamic instrumentation (metrics, logs and traces from live application without code change)
  - ASM (protect against OWASP, WAF attack patterns)
  - CSM (default agent rules, agentless scanning in AWS only ?)
  - Control observability pipeline workers (OPW)
  - Sensitive Data Scanner (SDS)
    - Redact sensitive info in your logs

### Fleet Automation

- View Agent configuration
  - Enabled by default in later versions
  - Set `inventories_configuration_enabled=true` for older versions
- View Agent integration configurations
  - Enabled by default in later versions
  - Set `inventories_checks_configuration_enabled=true` for older versions
- Remotely Upgrade/Downgrade and Configure Agents
  - Needs to enable "Remote Agent Management"
  - You need to set `DD_REMOTE_UPDATES=true` when installing the Agent
  - Upgrade is supported only for Agents on Hosts or in Kubernetes
- Send a flare
- Rotate API keys (which key is used by which Agents)
- Audit trail: config changes, API key updates, etc
  - 90 days if enabled in your org, otherwise 24 hours

### Processes

#### Live Processes

- Enable it in `datadog.yaml`
- Monitor all running processes
- Does not support Unix (IBM AIX)
- Show up in "Infrastructure -> Processes"

#### Process checks

- Enable in `conf.d/process.d`
- Specify which processes to monitor by PID file or command string matching
- Collects metrics like
  - `system.processes.number` number of processes
  - `system.processes.cpu.pct`
  - `system.processes.threads`
  - `system.processes.run_time.avg` (The average running time of all instances of this process)
- Don't show up in "Infrastructure -> Processes"


## Monitor

### Notifications

There's not a field dedicated for recipients, you need to specify it with `@`, `@slack` in the message

```yaml
The {{service.name}} service container {{color.name}} has high CPU usage!!

Contact: Email - @{{service.name}}@mycompany.com, @admin@mycompany.com
Slack - @slack-{{service.name}}
```

Conditional notifications:

```yaml
{{#is_alert}}
@pagerduty-incident-response
The store-frontend service is currently experiencing elevated latency which has exceeded {{threshold}}.

Some places to begin investigation are:
- ...
- ...
{{/is_alert}}

{{#is_warning}}
@slack-incident-response
@slack-frontend-team
The store-frontend service latency has surpassed its warning threshold of {{threshold}}.
{{/is_warning}}

{{#is_recovered}}
@slack-incident-response
@slack-frontend-team
The store-frontend service latency has returned to acceptable levels.
{{/is_recovered}}
```


## Universal Service Monitoring (USM)

Features:

- No instrumentation
- Relies on configured Agent and Unified Service Tagging
- Only supports HTTP/HTTPS

Prerequisites:

- If on Linux, your service must be running in a container.
- If on Windows and using IIS, your service must be running on a virtual machine.
- The Datadog Agent needs to be installed alongside your service
  - Could be installed on the hosts or as a container
  - No need for a tracing library
- The `env` tag for Unified Service Tagging must be applied to your deployment.

If `service` tag not found, Datadog uses container tags: `app`, `short_image`, `container_name`
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

Metrics:
- `universal.http.server.*`: inbound traffic to your service
- `universal.http.client.*`: outbound traffic to other destinations


## Synthetic testing

Associate testing results to APM:

- Not done by default
- You must specify the URLs for which Datadog should add the necessary HTTP headers


## Real User Monitoring (RUM)

- Works for web JS and mobile apps
- You need to instrument your app with RUM SDK (by `<script />` tag or NPM package)
- There is a setting to enable/disable RUM, but if disabled, no session is ingested, seems only data collected is view count ?
  - Error Tracking is enabled when you enable RUM
- Parameters:
  - `trackUserInteractions` enables the collection of user clicks in your application, which means sensitive and private data contained in your pages may be included to identify elements that a user interacted with
  - `enablePrivacyForActionName` masks all action names, you can use it in conjunction with the `mask` privacy setting. This operation automatically substitutes all non-overridden action names with the placeholder `Masked Element`

### Collected event types

<img src="./images/datadog_rum-event-types.png" width="400" alt="Collected event types" />

- Session:
  - Session id saved in a cookie, so a session could be continued after closing and reopening a browser tab
  - Reset after 15mins of inactivity
- View: create a new view each time when you load a new page, or route change an SPA
- Resource: images, JS, CSS, XHR, Fetch, etc
- Long Task: any task that blocks the main thread for more than 50ms
- Error
- Action: when `trackUserInteractions` is `true`
  - You could use `data-dd-action-name=<my-action>` on elements to customize action name
  - Use `addAction` to send custom actions

To add additional data to events at different levels:
- `setGlobalContextProperty()`
- `setViewContextProperty()`
- `event.context.<key> = <value>`

### Data masking

- `Sensitive Data Scanner` could be used for RUM events
  - You could add custom regex to mask URL paths
- RUM init parameters:
  - `enablePrivacyForActionName`
  - `defaultPrivacyLevel` for Session Replay masking
    - Three options: `mask-user-input`, `mask` (mask labels etc), and `allow`
  - `beforeSend` callback function to redact event properties like `view.url`, `action.target.name`, etc

### Session replay

- The RUM SDK records snapshots of the browser's DOM and CSS to build the animation
- There is a Session Replay sample rate
- You can modify the `defaultPrivacyLevel` to control what elements are masked
  - Some elements are ALWAYS masked, eg. `<input type="password">`, `<input type="email">`, `<input type="tel">`, etc

### Correlate RUM with APM

You need to add `allowedTracingUrls` to the RUM init parameters.

Then for those URLs, the RUM SDK will inject HTTP headers prefixed with `x-datadog-*` to XHR requests.

### Notes

- A URL path segment with any number `/hello-10.html` will be showing up as `/?` by default, you'll need to manually set the view name
  - This is not controlled by `defaultPrivacyLevel`, or `Sensitive Data Scanner `


## Database Monitoring (DBM)

- It has a small impact on the DB performance, you can tweak data collection frequency and query sampling rate
- For self-hosted databases, you can install the Datadog Agent on the database host, and enable the integration
- For cloud-managed databases, you need to intall the Agent on a separate host, and configure it to connect to each managed instance
  - Metrics such as CPU, memory, disk usage and related telemetry are collected directly from the cloud provider using Datadog integration with that provider
  ![DBM architecture](./images/datadog_database-monitoring-cloud-dbs.avif)
- DBM instrumentation is a superset of DB infrastructure integration
  - A lot of metrics could be collected by the infra integration
  - The infra integration needs a read-only account in the DB
  - To turn on DBM, usually you just need to set `dbm: true` in the integration config file
    - The `datadog` account in the DB may require additional permissions for DBM
    - DB engine may require additional configs
    - Each monitored database may need additional instrumentation (schema, user, function) as well
  - DBM could get more detailed info, such as query metrics, query samples, explain plans, wait events, blocking summaries, etc
  - After DBM is on, in the `status` command output, you should see "Database Monitoring ..." in the DB checks section

### DBM features

- Query metrics
  - Metrics for normalized queries (with parameters removed), across hosts
  - Saved for 3 monthes
  - Execution count, avg. rows, avg. duration, etc
  - Execution plan
- Query samples
  - Individual execution of a query
  - There are samples of explain plans as well

### Diagnose DB performance issues

- Investigate locks/blocking queries
- Investigate slow and frequent queries

### Example config for Oracle

Config file path: `/etc/datadog-agent/conf.d/oracle.d/conf.yaml`

With custom queries:

```yaml
init_config:
instances:
  - server: 'localhost:1521'
    service_name: "XE" # The Oracle CDB service name
    username: 'c##datadog'
    password: 'OraclePass'
    dbm: true
    tags:  # Optional
      - 'service:oracle-dbm-test'
      - 'env:dev'

    custom_queries:
      - metric_prefix: oracle
        query: SELECT 'foo', 11 FROM dual
        columns:
        - name: foo
          type: tag
        - name: gary.event.total
          type: gauge
        tags:
        - test:tag_value_1
        pdb: XEPDB1
      - metric_prefix: oracle
        query: select count(*) as audit_count from audit_actions
        columns:
        - name: audit_count
          type: gauge
        tags:
        - test:tag_value_2
        pdb: XEPDB1
```


## Error Tracking

- Automatically groups uncaught exceptions found in certain error events
- Sources: APM traces, RUM sessions, standalone frontend errors, and logs
- No additional cost for errors collected as part of APM traces and RUM sessions
- Filtering:
  - Error Tracking Rules: to include and exclude certain errors that are ingested and billed
  - Rate limiting: to safeguard against unexpected costs by allowing you to set a budget


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


## Source code integration

- Help you debug stack traces, slow profiles
- Quickly access the relevant lines of code in your repo
- Code snippets:
  - Support GitHub, GitLab
  - Not supported for ADO

### Setup

  - Set environment variables
      ```sh
      export DD_GIT_COMMIT_SHA="<commitSha>"
      export DD_GIT_REPOSITORY_URL="<git-provider.example/me/my-repo>"
      ```
  - Run `datadog-ci git-metadata upload` in your CI pipeline
    - This reports repo URL, commit SHA, and tracked file paths to Datadog
  - For GitHub, you could use a GitHub App


## Audit Trail

- Retention in Datadog up to 90 days
- Can be forwarded for archiving in Azure Storage, etc


## Azure

- Two integration methods
  - "Datadog - An Azure Native ISV Service" resource in Azure (seems only available to Datadog org in US3 region)
  - App registration
    - The app reg needs "Monitoring Reader" role over the monitored scope
    - Need Datadog API key and App key
- Configuration
  - Metrics
    - All metrics are collected by default, you could add filters to include/exclude VMs, ASPs, Container apps (eg. `datadog:monitored,env:production,!env:staging,instance-type:c1.*`)
    - Whether include custom metrics from App Insights (will be under namespace `application_insights.custom.<METRIC_NAME>`)
  - Logs
    - Whether include activity logs
    - Tags rules for limiting logs
  - Whether collect resource metadata and configurations
  - Whether enable Cloud security management on resource configurations

### Logging

To collect Azure platform logs (activity logs, resource diagnostics logs, AAD logs), you need to setup an Event Hub, and a Function App

- Event Hub
  - Diagnostic settings -> Event Hub -> trigger a Function App
- Storage accounts
  - For resources that can not stream to an Event Hub

You could set up everything with a template provided by Datadog, it deploys:
- Event hub
- Function app
  - A function with event hub trigger
  - Has env variables like `DD_API_KEY`, `DD_SITE`, `DD_TAGS`
- Storage account used by the function app
- Deployment script
  - Has a UAMI, with "Website Contributor" role on the RG
- Diagnostic settings for activity logs on the subscription
- No diagnostic settings on any resources, you need to set them up yourself

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
- You need to import the `ddtrace` library to your app
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
- You don't need to import the `dd-trace` library to your app
  - Correlating Node.js Logs and Traces
    - works if you are using a supported logging library (eg. Winston, Bunyan, Pino, etc) and logs formatted as JSON
    - not working for `console.log()`
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


## Gotchas

- `http.client_ip` is disabled by default, you need to enable it with :
  - `DD_TRACE_CLIENT_IP_ENABLED="true"`
  - To use a custom header, use `DD_TRACE_CLIENT_IP_HEADER="x-custom-ip-header"`