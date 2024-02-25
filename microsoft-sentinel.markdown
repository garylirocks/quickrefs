# Microsoft Sentinel

- [Overview](#overview)
- [Pricing](#pricing)
- [Content hub](#content-hub)
- [Data connections](#data-connections)
- [Incidents](#incidents)
  - [Analytic rules](#analytic-rules)
- [Workbooks](#workbooks)
- [Playbooks](#playbooks)
- [Notebooks](#notebooks)
- [Workspace manager](#workspace-manager)
- [Settings](#settings)


## Overview

Microsoft Sentinel is a security information event management (**SIEM**) and security orchestration automated response (**SOAR**) solution.

It natively incorporates Azure services as foundational components:
- Log Analytics provides data collection and storage capabilities
- Logic Apps enables the automation and orchestration of workflows


## Pricing

- You create Microsoft Sentinel by enabling Sentinel on an existing LA Workspace
- After you enable Sentinel on an LA workspace, the workspace uses Sentinel pricing tier
  - An LAW pay-as-you-go might cost US$3.5 per GB
  - After becoming a Sentinel workspace, the cost goes up to US$6.5 per GB


## Content hub

- Solutions or standalone content
- Provided by Microsoft, partner or community
- Data connectors are often part of a solution
- A solution is a package of contents, content type could be:
  - Analytics rule
  - Data connector
  - Hunting query
  - Parser
  - Playbook
  - Watchlist
  - Workbook
- You can connect to a GitHub repo which contains Sentinel contents, when the repos is updated, a pipeline can publish them to Sentinel automatically


## Data connections

- Service to service integration (covers most Microsoft and Azure services)
  - AWS - CloudTrail
  - Azure activity
  - Entra logs
  - Microsoft 365
  - ...
- External solutions via API
- External solutions via an agent
  - Seems the agent could be
    - Azure Monitor Agent (AMA)
    - Microsoft Sentinel agent, based on the Log Analytics agent, converts CEF (Common Event Format) formatted logs into a format that can be ingested by Log Analytics.
  - Depending on the device type, the agent is installed either directly on the device, or on a dedicated Linux-based log forwarder
  - Syslog daemon collect local events, forwards the events locally to the agent, then the agent streams the events to LA workspace
  - CEF logs appear in "CommonSecurityLog" table
  - Custom logs could be collected using Log Analytics custom log collection agent

![Syslog data flow](images/microsoft_sentinel-syslog-data-flow.png)
*Use a dedicated server for the agent*


## Incidents

Incidents are groups of related alerts that indicate an actionable possible threat you can investigate and resolve.

- **Analytics rules** are used to correlate alerts into incidents

### Analytic rules

- **Entity mapping**: map query results fields to Sentinel-recognized entities
  - Enriches output
  - The criteria by which you can group alerts together into incidents
- **Alert details**: allows you to use query result fields in the alert's properties. eg. put the attacker's account name in alert title
- **Ingestion delay**: To account for latency that may occur between an event's generation at the source and its ingestion into Microsoft Sentinel, and to ensure complete coverage without data duplication, Microsoft Sentinel runs scheduled analytics rules on a **five-minute delay from their scheduled time**.
- **Alert grouping**: Alerts can be grouped into an incident by matching entities
  - Up to 150 alerts can be grouped into a single incident.
- **Automated response**
  - Triggers: alert generated, incident created, incident updated


## Workbooks

- Each data source comes with workbook templates
- Intended for Security operations center (SOC) engineers and analysts of all tiers to visualize data
- Best for
  - high-level views of Microsoft Sentinel data
- **CAN'T** integrate with external data


## Playbooks

- Workflows in Azure Logic Apps
- Triggered by automation rules
- You need to configure permissions, so the playbooks could be triggered by Sentinel
- Best for
  - Automate repeatable tasks (eg. open a ticket in ServiceNow when a paticular alert is generated)
- NOT for
  - ad-hoc or complex task chains
  - or documenting and sharing evidence


## Notebooks

- Jupyter notebooks in Azure Machine Learning workspaces
- Higher learning curve and coding knowledge
- Extend the scope of what you can do in Sentinel:
  - Rich Python libraries for manipulating and visualizing data
  - Data sources outside of Azure
- Best for:
  - Ad-hoc procedural controls
  - Machine learning and custom analysis
  - More complex chains of repeatable tasks
  - Documenting and sharing analysis evidence


## Workspace manager

- A Microsoft Sentinel features
- Enables users to centrally manage multiple Microsoft Sentinel workspaces within one or more Azure tenants
- The Central workspace (with Workspace manager enabled) can consolidate content items to be published at scale to Member workspaces
- Need **Microsoft Sentinel Contributor** role assignment


## Settings

- User and Entity Behavior Analytics (UEBA)
  - Data sources could be on-prem AD and Entra ID
- Anomalies
  - UEBA needs to be enabled
  - Uses Machine Learning models to detect anomalies
  - Stored in the "Anomalies" table
- Central workspace
  - Whether to make this a central workspace
- Playbook permissions
  - Give Sentinel automation rules permission to run Logic App playbooks
- Whether allow Microsoft to access your data for model optimization
- Health monitoring (or diagnostic settings)
