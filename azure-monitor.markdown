# Azure Monitor

- [Overview](#overview)
- [Azure Monitor](#azure-monitor-1)
  - [VMs](#vms)
- [Log Analytics Agent](#log-analytics-agent)
  - [Difference between "Agent" and "Extensions"](#difference-between-agent-and-extensions)
- [Azure Monitor Agent](#azure-monitor-agent)
  - [AMA supports other services and features](#ama-supports-other-services-and-features)
- [Data Collection Rules (DCR)](#data-collection-rules-dcr)
- [Data collection endpoints](#data-collection-endpoints)
- [Defender for Cloud](#defender-for-cloud)
- [Alerting](#alerting)
- [Activity Log](#activity-log)
- [Log Analytics](#log-analytics)
  - [Design considerations](#design-considerations)
  - [Storage](#storage)
  - [Access Control](#access-control)
    - [Access modes](#access-modes)
- [Kusto Query Language](#kusto-query-language)
- [Workbooks](#workbooks)
- [Insights](#insights)
  - [Azure Application Insights](#azure-application-insights)
  - [VM Insights](#vm-insights)
- [Azure Data Explorer](#azure-data-explorer)

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
    - Potential performance, cost, high availability or security issues

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

- What can be collected:
  - **Metrics**: usually displayed in the overview page of resources
  - **Platform logs**
    - Resource logs (formerly known as diagnostic logs)
    - Activity logs
    - Azure AD logs
  - **Application logs**
- Usually for a resource:
  - *Metrics* and the *Activity logs* are collected and stored automatically, but can be routed to other locations by using a *diagnostic setting*.
  - *Resource Logs* are not collected and stored until you create a *diagnostic setting* and route them to one or more locations.
- Use *Data Collector API* to send data from your custom code

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

|                            | Log Analytics Agent (aka. MMA/OMS)                 | Diagnostics Extension                                                |
| -------------------------- | -------------------------------------------------- | -------------------------------------------------------------------- |
| Where                      | Azure, other clouds, on-prem                       | Azure VM only                                                        |
| Send data to               | Azure Monitor Logs                                 | Azure Storage, Azure Event Hubs, Azure Monitor Metrics(Windows only) |
| How to configure in Portal | Azure Monitor -> Legacy agents management Logs     | Resource -> Diagnostic settings                                      |
| Required by                | VM insights, Defender for Cloud, retired solutions | n/a                                                                  |

- Log Analytics Agent is more powerful than Diagnostics Extension, they could be used together
- You configure **what data sources to collect in a workspace**, these configurations are pushed to all connected agents
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

To collect data:

- Install the agent (Azure, Azure Arc, desktops)
- Define a data collection rule and associate resources to it
  - Performance - `Perf` table
  - Windows event logs (including sysmon events) - `Event` table
  - Syslog - `Syslog` table
  - Text/Windows IIS logs - custom tables

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

Data structure

- `kind`: Windows or Linux or Custom
- `dataSources`: Performance / EventLogs / Syslog / CustomLogs
- `destinations`: Log Analytics
- `dataFlows`: including `streams` and `destinations`

Multi to multi:
  - A resource could be associated with multiple rules
  - A rule could be associated with multiple resources

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
  ![Using API](images/azure_monitor-data-collection-scenarios-api.png)

- Workspace transformation DCR
  - a special DCR
  - associated with a workspace and provide default transformation for supported tables
  - applied to any data sent to the table that doesn't use another DCR
  - could work with resource logs using a diagnostic setting, Log Analytics agent or Container insights
  ![Workspace transformation DCR](images/azure_monitor-data-collection-scenarios-workspace-transformation.png)


## Data collection endpoints

Required by:

- AMA agent when network isolation is required
- Log ingestion API

Components:

- Configuration access endpoint: the endpoints for AMA to fetch DCRs, eg. `<unique-dce-identifier>.<regionname>-1.handler.control`
- Logs ingestion endpoint: `<unique-dce-identifier>.<regionname>-1.ingest`
- Network access control list

Limitations:

- Only for machines in the same region
- Only support Log Analytics workspace as a destination
- Custom metrics collected by AMA aren't controlled by DCEs
- Can't be configured over private links, seems can be included in a Azure Monitor Private Link Scope (AMPLS) ?


## Defender for Cloud

- Formerly called Azure Security Center
- Free features are automatically enabled for your subscriptions when you visit "Defender for Cloud" in the Portal
- You could turn on "Enhanced security features" (Defender plan by resource type)
- Some plans could be enabled at either subscription level or resource level
  - Defender for Storage account
  - Defender for SQL
- Collects data from resources such as VMs by using the Log Analytics Agent, and puts it into a workspace;
  - Log Analytics Agent can be provisioned automatically


## Alerting

- Metric alerts
- Log alerts
- Activity Log alerts (resource creation, deletion, etc)


## Activity Log

![Activity Log types](images/azure_activity-logs.png)

- Tracks any write operations taken on your resources, eg. VM startup, load balancer config change, etc
- Log data is retained for 90 days, although you can archive your data to a storage account, or send it to Log Analytics
- Event Categories:
  - Administrative, eg. create a VM
  - Searvice Health
  - Resource Health
  - Alert
  - Autoscale
  - Recommendation
  - Security, alerts generated by Azure Defender for Servers
  - Policy, all effect action operations performed by Azure Policy


## Log Analytics

![Log Analytics](images/azure_log-analytics.png)

- Azure Monitor stores log data in a Log Analytics workspace
- A Log Analytics workspace is the **equivalent of a database** inside Azure Data Explorer, data is organized into tables
- Data collected can be retained for a maximum of two years
- These services all use Log Analytics workspaces to store and query logs:
  - Microsoft Defender for Cloud
  - Microsoft Sentinel
  - Azure Monitor Application Insights

### Design considerations

Common workspace deployment models:

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

You many need multiple workspaces because:

- Store log data in specific regions for data sovereignty or compliance
- Put workspace in the same region as resources to avoid outbound data transfer charges
- Multiple departments or business groups

Scale and ingestion volume:

- Workspace are **NOT limited** in storage space, so no need to split workspaces due to scale.
- There is a default ingestion rate limit (6GB/minute) to protect from spikes and floods situations.
- If you need to ingest more than 4TB data per day, consider moving to *dedicated clusters*

### Storage

To better manage cost, there are different plans which could be configured for each table:

- Analytics
  - Support all queries

- Basic
  - Cheaper
  - Can only search within the table, no joins
  - Search jobs bring the logs to analytics log tables
  - Fixed interactive period of 8 days

- Archive
  - After the interactive periods, both "Analytics" and "Basic" logs are archived
  - To query archived logs, you need to bring it back to Analytics log tables, by either "Search jobs" or "Restore"
  - Up to 7 years

### Access Control

The data a user has access to is determined by a combination of factors that are listed in the following table.

| Factor                 | Description                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Access mode            | How you access a workspace. Defines the scope of the data available and the access control mode that's applied.                                                                                |
| Access control mode    | Setting on the workspace that defines whether permissions are applied at the workspace or resource level. Two modes: 1. Use resource or workspace permissions 2. Require workspace permissions |
| Permissions            | Permissions applied to individual or groups of users for the workspace or resource. Defines what data the user will have access to.                                                            |
| Table level Azure RBAC | *Optional* granular permissions that apply to *all users* regardless of their access mode or access control mode. Defines which data types a user can access.                                  |

#### Access modes

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

Provide

- Detailed performance metrics
- A topology view showing dependencies like processes running, ports open, connection details, etc
- VMs, VMSS, VMs connected with Azure Arc, on-prem VMs
- Can monitor VMs **across multiple subscriptions** and resource groups

![VM Insights map](images/azure_vm-insights-map.png)


## Azure Data Explorer

- Unified big data analytics platform
- Greater flexibility for building quick and easy near-real-time analytics dashboards, granular RBAC, time series, pattern recognition and machine learning

Example design:

![Data Explorer](images/azure_data-explorer.png)
