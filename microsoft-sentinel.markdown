# Microsoft Sentinel

- [Overview](#overview)
- [Data connections](#data-connections)
- [Incidents](#incidents)
- [Workbooks](#workbooks)
- [Playbooks](#playbooks)
- [Notebooks](#notebooks)


## Overview

Microsoft Sentinel is a security information event management (**SIEM**) and security orchestration automated response (**SOAR**) solution.

It natively incorporates Azure services as foundational components:
- Log Analytics provides data collection and storage capabilities
- Logic Apps enables the automation and orchestration of workflows


## Data connections

- Service to service integration (covers most Microsoft and Azure services)
  - AWS - CloudTrail
  - Azure activity
  - Entra logs
  - Microsoft 365
  - ...
- External solutions via API
- External solutions via an agent
  - Microsoft Sentinel agent, based on the Log Analytics agent, converts CEF (Common Event Format) formatted logs into a format that can be ingested by Log Analytics.
  - The agent is installed either directly on the appliance, or on a dedicated Linux server.
  - Real-time log streaming using the Syslog protocol

![Syslog data flow](images/microsoft_sentinel-syslog-data-flow.png)
*Use a dedicated server for the agent*


## Incidents

Incidents are groups of related alerts that indicate an actionable possible threat you can investigate and resolve.

- Analytics rules are used to correlate alerts into incidents


## Workbooks

- Each data source comes with workbook templates
- Intended for Security operations center (SOC) engineers and analysts of all tiers to visualize data
- Best for
  - high-level views of Microsoft Sentinel data
- **CAN'T** integrate with external data


## Playbooks

- Workflows in Azure Logic Apps
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