# Datadog

- [Overview](#overview)
  - [Concepts](#concepts)
- [Logs](#logs)
  - [Example queries](#example-queries)
  - [Views](#views)
  - [Facet](#facet)
- [Keys](#keys)
- [Integrations](#integrations)
- [Agent/library Configuration](#agentlibrary-configuration)
  - [Remote configuration](#remote-configuration)
- [Universal Service Monitoring (USM)](#universal-service-monitoring-usm)
  - [`docker-compose`](#docker-compose)
  - [Service Catalog](#service-catalog)
- [Audit Trail](#audit-trail)


## Overview

### Concepts

- **Monitoring**: what happened in a system
- **Observability**: why it happened


## Logs

### Example queries

- `service:nginx`
- `@filename:banner.php` (`@` indicates an attribute of a log entry)
- `"total amount"` - search text in the log message

### Views

- Queries could be saved into views
- There are also predefined views, eg. Postgres, NGINX, Redis, ...

### Facet

- Common tags and log attributes are created as facets automatically
- You can create custom facet from log attributes


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


## Integrations

Three types:

- **Agent-based**, use a Python class method called `check`
- **Authentication (crawler)**, based integrations are set up **in Datadog** where you provide credentials for obtaining metrics from APIs of other systems, such as Slack, AWS, Azure, and PagerDuty.
- **Library** integrations, use the Datadog API to allow you to monitor applications based on the language they are written in, like Node.js or Python.


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


## Audit Trail

- Retention in Datadog up to 90 days
- Can be forwarded for archiving in Azure Storage, etc