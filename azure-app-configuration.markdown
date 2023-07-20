# Azure App Configuration

- [Overview](#overview)
- [Data structure](#data-structure)
- [Feature management](#feature-management)
- [Events](#events)


## Overview

Central management and distribution of configuration for different environments and geographies

Features:

- Keeps change history for key-values for a period (7 days for Free tier, 30 days for Standard tier)
- Soft-delete for the whole store
- Private endpoint
- Supports availability zones and geo-replication


## Data structure

A key-value pair is has a data structure like:

```
[
  {
    "key": "AppName:Service1:ApiEndpoint",
    "label": "dev",
    "value": "my-value",
    "content_type": "",
    "tags": {}
  }
]
```

- Keys are usually formatted in a hierarchical fashion, using delimiters like `/` or `:`
- 10KB limit on the combined size of key, value and optional attributes.
- `label` attribute could be
  - environments: `dev`, `prod`, etc
  - versions, Git commit IDs


## Feature management

A feature flag is a special type of key-value, the value could only be true or false

```json
{
  "id": "GaryApp/feature2",
  "description": "A testing feature flag",
  "enabled": true,
  "conditions": {
    "client_filters": [
      {
        "name": "Microsoft.TimeWindow",
        "parameters": {
          "Start": "Mon, 31 Jul 2023 12:00:00 GMT",
          "End": "Fri, 04 Aug 2023 12:00:00 GMT"
        }
      }
    ]
  }
}
```

- Feature flags are under a fixed namespace `.appconfig.featureflag/`, the full key for the flag above is  `.appconfig.featureflag/GaryApp/feature2`
- A flag could have filters, like
  - time window filter
  - targeting filter (based on user or group)
  - or custom filter


## Events

App config publishes events to Data Grid, can be used to trigger other workflows.

Two event types:

- `Microsoft.AppConfiguration.KeyValueModified`
- `Microsoft.AppConfiguration.KeyValueDeleted`

An example event:

```json
[{
  "id": "84e17ea4-66db-4b54-8050-df8f7763f87b",
  "topic": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/testrg/providers/microsoft.appconfiguration/configurationstores/contoso",
  "subject": "https://contoso.azconfig.io/kv/Foo?label=FizzBuzz",
  "data": {
    "key": "Foo",
    "label": "FizzBuzz",
    "etag": "FnUExLaj2moIi4tJX9AXn9sakm0"
  },
  "eventType": "Microsoft.AppConfiguration.KeyValueModified",
  "eventTime": "2019-05-31T20:05:03Z",
  "dataVersion": "1",
  "metadataVersion": "1"
}]
```