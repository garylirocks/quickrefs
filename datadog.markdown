# Datadog

- [Overview](#overview)
  - [Concepts](#concepts)
- [Keys](#keys)
- [Integrations](#integrations)
- [Agent/library Configuration](#agentlibrary-configuration)
  - [Remote configuration](#remote-configuration)
- [Tagging](#tagging)
- [Audit Trail](#audit-trail)


## Overview

### Concepts

- **Monitoring**: what happened in a system
- **Observability**: why it happened


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


## Tagging

Unified service tagging: `service`, `env`, `version`


## Audit Trail

- Retention in Datadog up to 90 days
- Can be forwarded for archiving in Azure Storage, etc