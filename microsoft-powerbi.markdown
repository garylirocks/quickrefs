# Microsoft Power BI

- [Overview](#overview)
- [Desktop App](#desktop-app)
  - [On-prem Data Gateway](#on-prem-data-gateway)


## Overview

## Desktop App

- The desktop app is used to create reports and data visualizations on the local machine
- You need to publish reports to the Power BI Service to share them with others
  - And to schedule data refreshes
- Data source connection
  - A local machine might connect to a local database directly
  - But the Power BI Service needs to connect to the database via a *on-prem data gateway*
  - Once a report is published, you need to map the data source to a gateway connection in the Power BI Service

### On-prem Data Gateway

- Installed on a server that can access on-prem data sources
  - Could be an Azure VM
- The gateway needs to be shared to you, before you can use it in the Power BI Service
