# Azure Monitor

- [Overview](#overview)
- [Azure Monitor](#azure-monitor-1)
  - [Azure metrics](#azure-metrics)
  - [Activity Log](#activity-log)
  - [Resource logs (Diagnostic logs)](#resource-logs-diagnostic-logs)
  - [VMs](#vms)
- [Log Analytics Agent](#log-analytics-agent)
  - [Difference between "Agent" and "Extensions"](#difference-between-agent-and-extensions)
- [Azure Monitor Agent](#azure-monitor-agent)
  - [Installation](#installation)
  - [Authentication](#authentication)
  - [AMA supports other services and features](#ama-supports-other-services-and-features)
- [Data Collection Rules (DCR)](#data-collection-rules-dcr)
- [Data collection endpoints](#data-collection-endpoints)
- [Alerts](#alerts)
  - [Overview](#overview-1)
  - [Signals](#signals)
  - [Notes](#notes)
- [Log Analytics Workspace](#log-analytics-workspace)
  - [Cost](#cost)
  - [Design considerations](#design-considerations)
    - [Criteria](#criteria)
    - [Common workspace deployment models](#common-workspace-deployment-models)
    - [Scale and ingestion volume](#scale-and-ingestion-volume)
  - [Storage](#storage)
  - [Access Control](#access-control)
    - [Access modes](#access-modes)
- [Kusto Query Language](#kusto-query-language)
- [Workbooks](#workbooks)
- [Insights](#insights)
  - [Azure Application Insights](#azure-application-insights)
  - [VM Insights](#vm-insights)
- [Azure Data Explorer](#azure-data-explorer)
- [Role and permissions](#role-and-permissions)

## Overview

![monitoring services](images/azure_monitoring-services.png)

Monitoring services in logical groups:

- Core monitoring

  Platform level, built-in to Azure, requires little to no configuration to set up.

  - Activity Log
  - Service Health
    - Identifies any issues with Azure services that might affect your application
    - Helps you plan for scheduled maintenance
  - Azure Monitor (metrics and diagnostics)
  - Advisor
    - Cost, Operational, Performance, Reliability, or Security issues
    - Updates twice a day

- Log Analytics

- Application Insights: APM
  - Identify performance issues, usage trends, and the overall availability of services

## Azure Monitor

![Azure Monitor Overview](images/azure_monitor.png)

Azure Monitor is based on a common mornitoring data platform that includes Logs and Metrics.

| Logs                           | Metrics                          |
| ------------------------------ | -------------------------------- |
| text (can have numeric fields) | numeric values                   |
| sporadic                       | at fixed interval                |
| record event                   | describe some aspect of a system |
| identify root causes           | performance, alerting            |
| Log Analytics workspace        | time-series database             |

- **Metrics**
- **Platform logs**
  - Azure AD logs
  - Activity logs (90 days by default)
  - Resource logs (aka. Diagnostic Logs)
- **Application logs**
- Usually for a resource:
  - *Metrics* and the *Activity logs* are collected and stored automatically, but can be routed to other locations by using a *diagnostic setting*.
  - *Resource Logs* are not collected and stored until you create a *diagnostic setting* and route them to one or more locations.
- Use *Data Collector API* to send data from your custom code

### Azure metrics

![Metric types](images/azure_metrics-types.png)

- **Resource and custom metrics** are stored in one **time-series database**
  - Usually displayed in the overview page of resources
  - Stored for **93 days**, in the Monitor Explorer, the maximum time windows is 30 days, but you can **pan the chart** to view data older than 30 days
  - Not in a log analytics workspace by default, but you can use diagnostic settings to send metrics to it
    - Not all metrics could be sent to a LA workspace
  - Platform metrics are usually collected at a one-minute frequency
  - No cost for Platform metrics, has cost for custom metrics
  - Custom metrics could be from:
    - Application Insights: server respons time, browser exceptions etc
    - VM agents: Windows diagnostic extension, Telegraf agent for Linux
    - API
- **Prometheus metrics** can be collected from AKS clusters
  - Stored in Azure Monitor workspace
  - Can be analyzed with PromQL and Grafana dashboards
  - Can set up Prometheus alert rules

### Activity Log

![Activity Log types](images/azure_activity-logs.png)

- Tracks any write operations taken on your resources, eg. VM startup, load balancer config change, etc
- Log data is retained for 90 days, although you can archive your data to a storage account, or send it to Log Analytics
  - Saved in `AzureActivity` table
  - No data ingestion or retention charges for activity log data stored in a Log Analytics workspace
- Subscription-level, when you open from a resource context, filters are scoped to current resource automatically
- Event Categories:
  - Administrative, eg. create a VM
  - Searvice Health
  - Resource Health
  - Alert
  - Autoscale
  - Recommendation
  - Security, alerts generated by Azure Defender for Servers
  - Policy, all effect action operations performed by Azure Policy

### Resource logs (Diagnostic logs)

- Not collected by default, you need *diagnostic setting* to collect them, can be sent to
    - Log Analytics workspace
    - Event Hub
    - Storage account
- When sending logs to Log Analytics Workspace, the table used depends what type of collection the resource is using:
  - **Azure diagnostics**: All data is written to `AzureDiagnostic` table
    - Legacy
    - Its schema is the superset of the schemas of all the different data types being collected
  - **Resource-specific**: individual tables for each category of the resource
    - Recommended, all service will be migrated to this mode
    - Better performance across ingestion latency and query times
    - You could grant RBAC access on a specific table
- Limitations
  - Most resource types have an `AllMetrics` category, which allows you to send metrics to a destination
    - Some metrics could not be exported this way, you need to use REST API

### VMs

![data sources in a VM](images/azure_monitor-compute.png)

For VMs, Azure collects some metrics(host-level) by default, such as CPU usage, OS disk usage, network traffic, boot success, to get a full set of metrics, you need to install certain agents:

- **Azure Monitor Agent**: see below
- **Log Analytics Agent**:
  - allows for the onboarding of *Azure Monitor VM Insights*, *Microsoft Defender for Cloud*, and *Microsoft Sentinel*
  - works with Azure Automation accounts to onboard Azure Update Management and Azure Automation State Configuration, Change Tracking and Inventory
- **Azure Diagnostics extension**: see table below
- **Dependency agent**: maps dependencies between VMs

## Log Analytics Agent

Comparison between Log Analytics Agent and Diagnostics Extension

|                            | Log Analytics Agent (aka. MMA/OMS)                                                                         | Diagnostics Extension                                                |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Where                      | Azure, other clouds, on-prem                                                                               | Azure VM only                                                        |
| Send data to               | Azure Monitor Logs                                                                                         | Azure Storage, Azure Event Hubs, Azure Monitor Metrics(Windows only) |
| How to configure in Portal | Azure Monitor -> Legacy agents management Logs                                                             | Resource -> Diagnostic settings                                      |
| Required by                | VM insights, Defender for Cloud, Azure Automation, Change Tracking, Update Management, solutions (retired) | n/a                                                                  |

- Log Analytics Agent is more powerful than Diagnostics Extension, they could be used together
- You configure **what data sources to collect in a workspace**, these configurations are pushed to all connected agents
  - You can't configure collection of **security events** from the workspace by using the Log Analytics agent. You must use Microsoft Defender for Cloud or Microsoft Sentinel to collect security events. The Azure Monitor agent can also be used to collect security events.
  - E.g. When you config Syslog in a workspace, the configs are pushed to each connected host by updating `/etc/rsyslog.d/95-omsagent.conf`, this config file controls what syslogs will be forwarded to the agent (listening on port 25224)

  ![Syslog forwarding](images/azure_monitor-linux-syslog-diagram.png)


### Difference between "Agent" and "Extensions"

- VM extensions requires Windows VM Agent (Windows VM Guest Agent) to be running
- For Log Analytics Agent, if you install it on-prem, you download the **Log Analytics Agent**, if you intall it to an Azure VM, you use **Log Analytics Agent VM extension**, extension version could be different from the agent version, see https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux?toc=%2Fazure%2Fazure-monitor%2Ftoc.json#agent-and-vm-extension-versio0


## Azure Monitor Agent

A new ETL-like data collection pipeline, replaces legacy monitoring agents:

- Log Analytics Agent
- Telegraf agent
- Diagnostics extension (not consolidated yet)

### Installation

- In the Portal, AMA extension is installed automatically when you create a DCR and associate it to a VM (could be VM, VMSS, Arc-enabled servers)
  - This also enable system-assigned managed identity for the VM automatically
  - If you want to use a user-assigned managed identity, see below
- Could be installed with CLI or Azure policy(for large scale deployment), this involves 3 steps:
  - Enable managed identity
    - Enable system-assigned managed identity for the VM
    - or add user-assigned managed identity to the VM (recommended for large scale deployment)
  - Install AMA agent (specify the UAMI for authentication if needed)

    ```sh
    az vm extension set \
        --name AzureMonitorLinuxAgent \
        --publisher Microsoft.Azure.Monitor \
        --ids <vm-resource-id> \
        --enable-auto-upgrade true \
        --settings '{"authentication":{"managedIdentity":{"identifier-name":"mi_res_id","identifier-value":"/subscriptions/<my-subscription-id>/resourceGroups/<my-resource-group>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<my-user-assigned-identity>"}}}'
    ```

  - Associate a DCR or DCE to the VM
- Installing, upgrading, or uninstalling doesn't require restart
- Manual install needed for Windows 10 and 11 devices

### Authentication

- If you use a user-assigned managed identity, config with the MI resource ID (`mi_res_id`) or the object/client ID `<guid-object-or-client-id>`

  ```json
  {
    "publisher": "Microsoft.Azure.Monitor",
    "type": "AzureMonitorLinuxAgent",
    "typeHandlerVersion": "1.2",
    "autoUpgradeMinorVersion": true,
    "enableAutomaticUpgrade": true,
    "settings": {
      "authentication": {
        "managedIdentity": {
          "identifier-name": "mi_res_id" or "object_id" or "client_id",
          "identifier-value": "<resource-id-of-uai>" or "<guid-object-or-client-id>"
        }
      }
    }
  }
  ```

- For Azure **Arc-enabled** servers, only system-assigned managed identity is supported, and it's **enabled automatically** as soon as you install the Azure Arc agent
- The managed-identity (SAMI or UAMI) **DOES NOT NEED any role** assigned to it

### AMA supports other services and features

| Servies/features                         | Other extensions installed                                                                  |
| ---------------------------------------- | ------------------------------------------------------------------------------------------- |
| VM insights                              | Dependency Agent extension                                                                  |
| Container insights                       | Containerized Azure Monitor agent                                                           |
| Defender for Cloud                       | Security Agent ext., SQL Advanced Threat Protection ext., SQL Vulnerability Assessment ext. |
| Microsoft Sentinel                       | Sentinel DNS ext. for DNS logs                                                              |
| Change Tracking and Inventory Management | Change Tracking ext.                                                                        |
| Network Watcher                          | NetworkWatcher ext.                                                                         |
| SQL Best Practices Assessment            | No additional ext. required                                                                 |
| AVD insights                             | No additional ext. required                                                                 |
| Stack HCI insights                       | No additional ext. required                                                                 |


## Data Collection Rules (DCR)

Platform type: Windows / Linux / All

Tables where data sent to:
- Performance - `Perf` table
- Windows event logs (including sysmon events) - `Event` table
- Syslog - `Syslog` table
- Text/Windows IIS logs - custom tables

Data structure

```json
"properties": {
  "dataSources": {
    "performanceCounters": [
      {
        "streams": [
          "Microsoft-Perf"
        ],
        "samplingFrequencyInSeconds": 60,
        "counterSpecifiers": [
          "\\Processor Information(_Total)\\% Processor Time",
          "\\..."
        ],
        "name": "perfCounterDataSource60"
      }
    ],
    "windowsEventLogs": [
      {
        "streams": [
          "Microsoft-Event"
        ],
        "xPathQueries": [
          "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]",
          "..."
        ],
        "name": "eventLogsDataSource"
      }
    ],
    "syslog": [
      {
        "streams": [
          "Microsoft-Syslog"
        ],
        "facilityNames": [
          "auth",
          "authpriv",
          "cron",
          "..."
        ],
        "logLevels": [
          "Info",
          "Notice",
          "Warning",
          "Error",
          "Critical",
          "Alert",
          "Emergency"
        ],
        "name": "sysLogsDataSource--1469397783"
      }
    ]
  },
  "destinations": {
    "logAnalytics": [
      {
        "workspaceResourceId": "xxxxxxxx",
        "name": "la-1234"
      }
    ]
  },
  "dataFlows": [
    {
      "streams": [
        "Microsoft-Perf"
      ],
      "destinations": [
        "la-1234"
      ]
    },
    {
      "streams": [
        "Microsoft-Event"
      ],
      "destinations": [
        "la-1234"
      ]
    },
    {
      "streams": [
        "Microsoft-Syslog"
      ],
      "destinations": [
        "la-1234"
      ]
    }
  ]
}
```

- `dataSources`: Performance / EventLogs / Syslog / CustomLogs
  - One type of data source could only be configured once, eg. only one "Syslog" entry is allowed in a DCR
  - One type of data source could be sent to multiple destinations
- `destinations`: only Log Analytics workspace is supported
- `dataFlows`: mapping between `streams` and `destinations`

Multi to multi:
- A resource could be associated with multiple DCR rules
- A DCR could be associated with multiple resources

How to create:
- Some DCRs will be created and managed by Azure Monitor to collect a specific set of data to **enable insights and visualizations**.
- You might also create your own DCRs to define the set of data required for other scenarios.

Resiliency:
  - Zone-redundant: The service is deployed to all three availability zones within the region.
  - Backed up to the paired-region within the same geography.

Data collection scenarios:

- Using AMA
  ![Using AMA](images/azure_monitor-data-collection-scenarios-agent.png)

- Using log ingestion API (a REST client sends data to a DCE, and specifying which DCR to use)
  - When using Custom Text or Custom JSON Logs as the data source, you can set a single line KQL to transform a record to multi columns in a table
  ![Using API](images/azure_monitor-data-collection-scenarios-api.png)

- Workspace transformation DCR
  - a special DCR
  - associated with a workspace and provide default transformation for supported tables
  - applied to any data sent to the table that doesn't use another DCR
  - could work with resource logs using a diagnostic setting, Log Analytics agent or Container insights
  ![Workspace transformation DCR](images/azure_monitor-data-collection-scenarios-workspace-transformation.png)


## Data collection endpoints

- It's optional for collecting Windows Event Logs, Linux Syslog or Performance Counters. REQUIRED for all other data sources.
- Also REQUIRED if:
  - AMA agent when network isolation is required
  - Log ingestion API

Components:

- Configuration access endpoint: the endpoints for AMA to fetch DCRs, eg. `<unique-dce-identifier>.<regionname>-1.handler.control.monitor.azure.com`
- Logs ingestion endpoint: `<unique-dce-identifier>.<regionname>-1.ingest.monitor.azure.com`
- Network access control list

Limitations:

- Only for machines in the same region
- Only support Log Analytics workspace as a destination
- Custom metrics collected by AMA aren't controlled by DCEs
- Can be accessed over a Private Link using the Azure Monitor Private Link Scope (AMPLS) it is added to.


## Alerts

### Overview

Make sure you understand the differences between:

- **Action groups**:
  - Configure notifications (Email, SMS, etc) and actions (runbook, webhook, etc)
  - Resource type: `Microsoft.Insights/actionGroups`
- **Alert rule**: the configuration of an alert
  - Generate new alerts based on conditions
  - Resource type differs depending on signal type:
    - Metric alerts: `Microsoft.Insights/metricAlerts`
    - Log query alerts: `microsoft.insights/scheduledqueryrules`
- **Alert processing rule**:
  - Previously know as 'action rule', resource type is still `Microsoft.AlertsManagement/actionRules`
  - Rule type:
    - **Suppression**:
      - Suppress alerts during planned maintenance (or outside of business hours), so you don't need to disable and enable your alert rules manually before and after the maintenance window
      - Only the action groups are suppressed, the alerts are still generated, and can be accessed in the Portal, via API, etc
      - Has higher priority, overrides "Apply action groups" rules
    - **Apply action groups**
      - Always use an action group for high severity alerts, saves you the trouble to config in multiple alert rules
      - Add action groups to alerts not fired by an alert rule: Azure Backup alert, VM Insights guest health alerts, Azure Stack Edge/Hub
  - Scope:
    - Can be at different levels: single resource, RG, subscription
    - A rule can have multiple scopes: two subs, one RG, etc
    - The rule applies to alerts fired on resources within that scope
  - Filtering:
    - Alert rule ID/name
    - Alert context
    - Alert description
    - Alert severity
    - Monitor condition: 'Fired' or 'Resolved'
    - Resource, resource group, resource type
    - Monitor service, could be "Platform", "Log Analytics", "Resource health", "Activity Log", etc
  - Have a one-time or recurring window
  - Doesn't work with **Azure Service Health** alerts

### Signals

Signal types:

- Metric
- **Log search**
  - Condition: result of a log query
- **Activity log**
  - Scope: all or selected resource types, at subscription or resource group level
  - Condition: create/update/delete a resource, other actions (eg. approve private endpoint connection)
- **Resource health**
  - Scope: all or selected resource types, at subscription or resource group level
  - Condition: resource status change (eg. from available to unavailable), and whether it's platform or user initiated
- **Service health**
  - Scope: Can be created only at subscription level. If you need to alert on more subscriptions, create a separate alert rule for each subscription. You'll only be notified on health events impacting the services used in your subscription.
  - Condition: service types, regions and event types (service issue, planned maintenance, etc).
- Advisor
- Smart detector: Application Insights

### Notes

- An alert rule can only be applied at **subscription level or below**, NOT at management group level
- An alert rule resource could only be in the **same subscription** as the resource it monitors
- A rule's **action group** could be in another subscription


## Log Analytics Workspace

![Log Analytics](images/azure_log-analytics.png)

- Azure Monitor stores log data in a Log Analytics workspace
- A Log Analytics workspace is the **equivalent of a database** inside Azure Data Explorer, data is organized into tables
- Not only Azure Monitor, some other services use Log Analytics workspaces to store and query logs as well:
  - Microsoft Defender for Cloud
  - Microsoft Sentinel
  - Azure Monitor Application Insights
- Cost is based on data ingestion and data retention

### Cost

If Microsoft Sentinel is enabled in a LAW:
- All data collected is subject to Sentinel charges, in addition to Log Analytics charges

Commitment tiers
- Works for a single workspace, so you might consider combine multiple workspaces to one to reduce costs
- If you daily ingest is > 100GB, you should use a dedicated cluster, then commitment tier could apply to multiple workspaces

### Design considerations

#### Criteria

- **Operational and security data**
  - Should you combine operational data from Azure Monitor in the same workspace as security data from Microsoft Sentinel ?
  - Cost implications:
    - When Microsoft Sentinel is enabled in a workspace, all data in that workspace is subject to **Microsoft Sentinel pricing** even if it's operational data collected by Azure Monitor, this usually ends up with higher cost
    - But if combining operational and security data helps you reach a commitment tier, then it will reduce cost
  - If you use both Microsoft Sentinel and Defender for Cloud, you should use same workspace for them to keep security data in one place
- **Azure regions**
  - Regulatory or compliance requirements
  - Cross-region egress charges
    - Usually minor relative to ingestion costs
    - Typically result from send data from a VM, resource logs from diagnostic settings doesn't incur this charge
- **Split billing**
  - You can use [log query to view billable data volume by Azure resource, RG or subscription](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/analyze-usage#data-volume-by-azure-resource-resource-group-or-subscription)
- **Data retention and archive**
  - Workspace has default data retention and archive settings, could also be configured per table
  - Use multiple workspace if you need different settings for data in the same table
- **Commitment tiers**: reduce ingestions cost
- **Data access control**: see [access control](#access-control)
- **Resilience**:
  - Ingest some data to multiple workspaces in different regions
  - Ancillary resources, like alerts and workbooks need to be created/enabled in the case of failover
- **Data ownership**: subsidiaries or affiliated companies
- **Azure tenants**: several data source can only send monitoring data to a workspace in the same tenant
- **Legacy agent limitations**
  - Azure Monitor Agent and the Log Analytics agent for Windows can connect to multiple workspaces. The Log Analytics agent for Linux can only connect to a single workspace.

#### Common workspace deployment models

- **Centralized** (*hub and spoke*)
  - All logs in one workspace
  - You need to maintain access control to different users
  - Easier to cross-correlate logs
  - Example: ![Centralized design](images/azure_log-analytics-workspace-centralized-design.png)
- **Decentralized**
  - Each team has their own workspace in their own resource group
  - Access control is consistent with resource access
  - Difficult to cross-correlate logs
- **Hybrid** not recommended, hard to maintain

You should create workspaces as less as possible for easier management, **reasons for multiple workspaces**:

- **Regulation**: specific regions for data sovereignty or compliance
- **Environment separation**: eg. shorter retention period for non-prod workspaces
- **Geography**:
  - Put workspace in the same region as workloads, so outages in one region won't affect another region
  - There are small charges for egress data transfer to another region, but usually not an issue

*Usually no need to split because of scale or multiple teams (unless they are completely self-managed without central IT team)*

#### Scale and ingestion volume

- Workspace are **NOT limited** in storage space, so no need to split workspaces due to scale.
- There is a default ingestion rate limit (6GB/minute) to protect from spikes and floods situations.
- If you need to ingest more than 4TB data per day, consider moving to *dedicated clusters*

### Storage

To better manage cost, there are different plans which could be configured for each table:

![Workplace data plan](images/azure_workspace-plan-overview.png)

- Analytics
  - Support all queries

- Basic
  - Cheaper
  - Can only search within the table, no joins
  - "Search jobs" bring the logs to analytics log tables
  - Fixed interactive period of 8 days

- Archive
  - After the interactive periods, both "Analytics" and "Basic" logs are archived
  - To query archived logs, you need to bring it back to Analytics log tables, by either
    - "Search jobs": data matching paticular criteria
    - or "Restore": data from a paticular time range
  - Up to 7 years

### Access Control

The data a user has access to is determined by a combination of factors that are listed in the following table.

| Factor                 | Description                                                                                                                                                                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Access mode            | How you access a workspace. Defines the scope of the data available and the access control mode that's applied.                                                                                                                                                              |
| Access control mode    | A workspace settings, two possible modes: 1. Use resource or workspace permissions (`properties.features.enableLogAccessUsingOnlyResourcePermissions = true` ) 2. Require workspace permissions (`properties.features.enableLogAccessUsingOnlyResourcePermissions = false` ) |
| Permissions            | Permissions applied to individual or groups of users for the workspace or resource. Defines what data the user will have access to.                                                                                                                                          |
| Table level Azure RBAC | *Optional* granular permissions that apply to *all users* regardless of their access mode or access control mode. Defines which data types a user can access.                                                                                                                |

#### Access modes

![Access modes](images/azure_monitor-log-analytics-rbac-model.png)

| Issue                | Workspace-context                                                                                                                                                   | Resource-context                                                                                                                                                              |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| How                  | When a workspace is the scope, eg. select **"Logs" in the "Monitor" page** in the Portal                                                                            | When you access the workspace for a paticular resource, resource group, or subscription, eg. select **"Logs" in a resource page** in the Portal                               |
| Intended for         | Central administration (Also currently required for users who need to access logs for resources outside of Azure)                                                   | Application teams. Administrators of Azure resources being monitored.                                                                                                         |
| Permissions required | [Permissions to the workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/manage-access)                                                             | **Read access** to the resource. Permission to the logs for the resource will be automatically assigned.                                                                      |
| Permissions scopes   | Workspace. Users with access to the workspace can query all logs in the workspace from tables that they have permissions to (allowed by optional table-level RBAC). | Azure resource. User can query logs for specific resources, resource groups, or subscription they have access to from any workspace but can't query logs for other resources. |


## Kusto Query Language

KQL was originally written for Azure Data Explorer. See a basic tutorial here: https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/tutorial

- Case sensitive - table names, column names, operators, functions, etc

Common table names:

![Common table names](images/azure_common-log-tables.png)


Example:

```
Events
| where StartTime >= datetime(2018-11-01) and StartTime < datetime(2018-12-01)
| where State == "FLORIDA"
| count
```

```
# The latest heartbeat for each computer, the '*' means all columns are kept
Heartbeat
| summarize arg_max(TimeGenerated, *) by ComputerIP
```

```
// Render a chart of average CPU usage in 5-minute interval for each computer

InsightsMetrics
| where TimeGenerated > ago(1h)
| where Origin == "vm.azm.ms"
| where Namespace == "Processor"
| where Name == "UtilizationPercentage"
| summarize avg(Val) by bin(TimeGenerated, 5m), Computer //split up by computer
| render timechart
```

![Query result chart example](images/azure_log-analytics-chart-example.png)

It's possible to [query data cross multiple Log Analytics workspaces](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/cross-workspace-query):

```
union
  Update,
  workspace("00000000-0000-0000-0000-000000000001").Update,
  workspace("00000000-0000-0000-0000-000000000002").Update
| where TimeGenerated >= ago(1h)
| where UpdateState == "Needed"
| summarize dcount(Computer) by Classification


# When you are in a resource-context, and you want to query another resource, use resource()
union
  (Heartbeat),
  (resource("/subscriptions/xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcesgroups/myresourcegroup).Heartbeat)
| summarize count() by _ResourceId, TenantId
```


## Workbooks

Allows you to connect to multiple data sources across Azure and combine them into unified interactive reports.


## Insights

- Provide a customized monitoring experience for particular applications and services.
- They collect and analyze both logs and metrics.

Provided insights:

- Application insights: monitor your live web apps on any platform
- Container insights: ACI, AKS
- Cosmos DB insights
- Networks insights: identify resource dependencies
- Resource Group insights
- Storage insights
- VM insights: health and performance of your VM and VMSS, monitor their processes and dependencies on other resources and external processes
- Key Vault insights
- Cache for Redis insights

### Azure Application Insights

- Is an APM (Application Performance Management) service, mostly captures two kinds of data: *events* and *metrics*
- Instrumentation methods:
  - **Runtime instrumentation**: can be enabled without making any changes to code (Windows IIS web app only, works best with ASP.NET)
  - **Build-time instrumentation**: by installing SDK to code, enables full functionality, supports custom events
  - **Client-side instrumentation**: JavaScript SDK, you can configure App Service to inject it automatically (Windows IIS web app only)


### VM Insights

When you enable VM insights, it

- Installs Azure Monitor Agent and Dependency Agent on your VM.
- Creates a data collection rule (DCR) that collects and sends a predefined set of client performance data to a Log Analytics workspace.
  - Because the DCR sends performance counters to Azure Monitor Logs, you DON'T use Metrics Explorer to view them
  - Instead, view the metrics with prebuilt VM insights workbooks
  - You need to create your own DCR to collect logs or other performance counters
- Present data in curated workbooks.

Provide

- Detailed performance metrics (view them in workbooks)
- A topology view showing dependencies like processes running, ports open, connection details, etc
- VMs, VMSS, VMs connected with Azure Arc, on-prem VMs
- Can monitor VMs **across multiple subscriptions** and resource groups

![VM Insights map](images/azure_vm-insights-map.png)


## Azure Data Explorer

- Unified big data analytics platform
- Greater flexibility for building quick and easy near-real-time analytics dashboards, granular RBAC, time series, pattern recognition and machine learning

Example design:

![Data Explorer](images/azure_data-explorer.png)


## Role and permissions

To add diagnostic settings and send logs to a workspace, the minimum permissions required are (see https://learn.microsoft.com/en-us/azure/azure-monitor/logs/manage-access?tabs=portal#custom-role-examples):

- On workspace
  - `Microsoft.OperationalInsights/workspaces/read`
  - `Microsoft.OperationalInsights/workspaces/sharedKeys/action`
- On resource
  - `Microsoft.Insights/logs/*/read`
  - `Microsoft.Insights/diagnosticSettings/write`


`Microsoft.OperationalInsights/workspaces/sharedKeys/action` is included in both

- **Log Analytics Contributor**
- **Monitoring Contributor**

the differences are

- "Log Analytics Contributor": can install VM extensions, can create solutions (`Microsoft.OperationsManagement/solutions/write`)
- "Monitoring Contributor": can manage action groups, DCR, metric alerts, scheduled query alerts, alert action rules, Private link scopes, etc
