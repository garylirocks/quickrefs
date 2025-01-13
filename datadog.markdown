# Datadog

- [Overview](#overview)
  - [Concepts](#concepts)
- [Integrations](#integrations)
- [Tagging](#tagging)


## Overview

### Concepts

- **API key**: Datadog Agent requires an API key to submit metrics and events to Datadog
  - Scoped to organization (remains active even when the user created the token is disabled)
- **Application keys**: in conjunction with your organization's API key, give users access to Datadog's programmatic API.
  - Associated with the user account that created them
  - By default have the permissions and scopes of the user who created them
  - You could specify the authorization scopes, only allow least permissions necessary
  - Permissions required to create or edit application keys:
    - `user_app_keys` permission to scope their own application keys
    - `org_app_keys_write` permission to scope application keys owned by any user in their organization
    - `service_account_write` permission to scope application keys for service accounts
  - If a user's role or permissions change, authorization scopes specified for their application keys remain unchanged
- **Client token**: end user facing applications (browser, mobile, TV) use client tokens to send data to Datadog
  - Scoped to organization


## Integrations

Three types:

- **Agent-based**, use a Python class method called `check`
- **Authentication (crawler)**, based integrations are set up **in Datadog** where you provide credentials for obtaining metrics from APIs of other systems, such as Slack, AWS, Azure, and PagerDuty.
- **Library** integrations, use the Datadog API to allow you to monitor applications based on the language they are written in, like Node.js or Python.


## Tagging

Unified service tagging: `service`, `env`, `version`
