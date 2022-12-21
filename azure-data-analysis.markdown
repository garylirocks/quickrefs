# Azure data analysis

- [Overview](#overview)
- [Databricks](#databricks)
- [On-prem data gateways](#on-prem-data-gateways)
  - [Auth](#auth)
  - [Networking](#networking)
  - [Installation](#installation)
- [Virtual network data gateways](#virtual-network-data-gateways)
  - [Create](#create)


## Overview

//TODO

## Databricks

- Run big data pipelines using both batch and real-time data
  - Batch data from Data Factory
  - Real-time data from Event Hub, IoT hub
- Train machine-learning models
- Uses Spark

## On-prem data gateways

Quick and secure data transfer between on-prem data and Microsoft cloud services, seems mainly intended for **Power BI**, could also be used by Azure Logic Apps, Power Apps, Power Automate, Azure Analysis Services

Data gateway is different to Data Management Gateway (Self-hosted integration runtime) used by Azure Machine Learning Studio and Data Factory

Two types:
- Standard: multiple users to connect to multiple on-prem data sources
- Personal mode: Power BI only, one user only

Condiderations:
- There are limits on read/write payload size, GET URL length

![Data gateway architecture](./images/azure_on-prem-data-gateway-how-it-works.png)

### Auth

- Data source credentials are encrypted and stored in the gateway cloud service, decrypted by the on-prem gateway.
- When using OAuth2 credentials, the gateway currently doesn't support refreshing tokens automatically when access tokens expire (one hour after the refresh started). This limitation for long running refreshes exists for VNET gateways and on-premises data gateways.

### Networking

See: https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-communication

- There is **NO inbound connections to the gateway**
- The gateway uses **outbound connections to Azure Relay** (IPs and FQDNs)
  - You need to configure your on-prem firewall to unblock Azure Datacenter IP list
- By default, the gateway communicates with Azure Relay using direct TCP, but you can force HTTPS communication
- Even with ExpressRoute, you still need a gateway to connect to on-prem data sources

### Installation

- Can't be on a domain controller
- The standard gateway need to be installed on a machine:
  - domain joined
  - always turned on
  - wired rather than wireless
- You can't have more than one gateways running in the same mode on the same computer
- You can install multiple gateways (on different machines) to setup a cluster
- During installation, you need to **sign in** to your organization account, this registers the gateway to the cloud services, then you manage gateways from within the associated services
- For Logic Apps, after the gateway is installed on-prem, you need to add a corresponding resource in Azure as well.


## Virtual network data gateways

![vNet data gateway](images/azure_vnet-data-gateway-overview.png)

Helps connect to your Azure data services within a VNet without the need of an on-prem data gateway.

![vNet data gateway architecture](images/azure_vnet-data-gateway-architecture.png)

- A subnet is delegated to the data gateway service
- At step 2, the Power Platform VNet injects a container running the VNet data gateway in to the subnet
- The gateway *obeys NSG and NAT rules*
- The gateway *doesn't* require any Service Endpoint or open ports back to Power BI, it uses the SWIFT tunnel, which is a feature existing on the infrastructure VM

### Create

- Register `Microsoft.PowerPlatform` as a resource provider
- Associate the subnet to Microsoft Power Platform
  - Don't use subnet name "gatewaysubnet", it's reserved for Azure Gateway Subnet
  - The IP range could not overlap with `10.0.1.0/24`
- Create a VNet data gateway in Power Platform admin center
  - You can see the delegated subnet there
  - You can create multiple gateways (max. 3) for HA and load balancing


VNet gateways are in the same region as the VNet, the metadata (name, details, encrypted credentials) are in your tenant's default region.