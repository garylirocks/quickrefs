# Datadog

- [Overview](#overview)
  - [Concepts](#concepts)
- [Logs](#logs)
  - [Example queries](#example-queries)
  - [Tags and attributes](#tags-and-attributes)
  - [Indexing](#indexing)
  - [Facet](#facet)
  - [Views](#views)
  - [Log processing rules (pipelines)](#log-processing-rules-pipelines)
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
- [Monitor](#monitor)
  - [Notifications](#notifications)
- [Universal Service Monitoring (USM)](#universal-service-monitoring-usm)
  - [`docker-compose`](#docker-compose-1)
  - [Service Catalog](#service-catalog)
- [Keys](#keys)
- [Audit Trail](#audit-trail)


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

### Tags and attributes

- Tags are assigned at host or container level
- Attributes are extracted from logs

### Indexing

- Ingested logs:
  - Watchdog(automated) Insights, Error Tracking, generating metrics, and Cloud SIEM detection rules
- Indexed logs:
  - Can be used in monitors, dashboards, notebooks

### Facet

- Automatically created from common tags and log attributes
- A facet could be a **measure**, which is numerical and continuous, could be filtered by a range
  - eg. `@network.bytes_written:[512 TO 1024]`
- You can create custom facet from log tags or attributes

### Views

- Queries could be saved into views
- There are also predefined views, eg. Postgres, NGINX, Redis, ...

### Log processing rules (pipelines)


## Metrics

Can be collected by:

- DD Agent
- Integrations
- Generated with Datadog (eg. form logs)
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

### SLI & SLO

Service Level Indicators (SLI): metrics to measure some aspect of the level of service

Service Level Objectives (SLO): SLIs monitored overtime, eg.
- 99% of requests being successful over the past 7 days
- less than 1 second latency 99% of the time over the past 30 days

You can create an SLO based on a monitor, then you can create a monitor on an SLO to get alerts.


## Application Performance Monitoring (APM)

- **Trace**: tracks the time spent by an application processing a request and the status of this request. Each trace consists of one or more spans.
- **Span**: represents a logical unit of work in a distributed system for a given time period. Multiple spans construct a trace.

### Instrumentation

- You use language-specific Datadog libraries (`ddtrace`) in your application code.
- By default, Agent collects traces using TCP port 8126.
- Instrumented application expect some environment variables, eg. `DATADOG_HOST` `DD_ENV`, `DD_VERSION`, and `DD_SERVICE`.
  - `DD_AGENT_HOST`: which service hosts the agent
  - `DD_LOGS_INJECTION`: injects tracing data into the log lines and formats the output as JSON
  - `DD_TRACE_SAMPLE_RATE`
  - `DD_PROFILING_ENABLED` whether enable continuous profiler
  - `DD_SERVICE_MAPPING` rename service


### Continuous Profiler

- Find CPU, memory and IO bottlenecks
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
  - `check` methos executes every 15 seconds
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

- `trace_id` can be injected as tags in logs, for correlation


## Agent/library Configuration

By priority:

- Remote configuration (could be disabled on each individual agent ?)
- Environment variables
- Local configuration

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

You can manage metadata of a service either:
- Manually: using the web UI
- Automatically: Github or Terraform


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


## Audit Trail

- Retention in Datadog up to 90 days
- Can be forwarded for archiving in Azure Storage, etc