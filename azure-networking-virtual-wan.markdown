# Azure Networking - Virtual WAN

- [Overview](#overview)
- [Virtual Hub Routing](#virtual-hub-routing)
  - [Custom route tables](#custom-route-tables)
  - [Route maps](#route-maps)
  - [Routing Intent](#routing-intent)
  - [BGP peers](#bgp-peers)
  - [Routing scenarios](#routing-scenarios)
- [NVAs in a Virtual Hub](#nvas-in-a-virtual-hub)
- [SaaS solutions in a Virtual Hub](#saas-solutions-in-a-virtual-hub)
- [Virtual hub extension pattern](#virtual-hub-extension-pattern)
  - [Private DNS resolution](#private-dns-resolution)


## Overview

![Virtual WAN](images/azure_virtual-wan.png)

- Similar to the hub-spoke structure, virtual WAN replaces hub vNet as a managed service
- Organizations will generally only require one instance of a Virtual WAN
- Each Virtual WAN can have one or more hubs, all hubs are connected in a full mesh topology, allowing any-to-any transitive connectivity
- Brings together many networking services: site-to-site VPN, point-to-site VPN, ExpressRoute into a single operational interface
- **A virtual hub is a Microsoft-managed virtual network**
  - There can be only **ONE** hub per Azure region
  - Minimum address space is /24
  - Azure automatically creates subnets in the vNet for different gateways/services (ExpressRoute/VPN gateways, Firewall, routing, etc).
- Each secured virtual hub
  - Has associated security and routing policies configured by Azure Firewall Manager
  - At each hub, you could filter traffic between virtual networks(V2V), virtual netwoks and branch offices(B2V) and traffic to the Internet (B2I/V2I)
  - Provides automated routing, there's **no need to configure your own UDRs**


## Virtual Hub Routing

- A virtual hub has a router that manages all routing between gateways using BGP.
  - This router provides transit connectivity between virtual networks that connect to a virtual hub.
  - Ths router shows up as "Virtual network gateway" with a random public IP in effective routes of a connected VM.
- Four types of connections:
  - S2S VPN
  - P2S VPN
  - ExpressRoute
  - vNet
- Each virtual hub has its own
  - **Default route table**, static routes could be added, taking precedence over dynamic routes
  - **None route table**, propagating to this means no routes are required to be propagated from the connection
- For each connection:
  - By default, it associates and propagates to the Default route table
  - Can only associate to one route table, which controls where traffic from this connection will be routed to.
  - A connection could have static routes, and an option determines whether to propagate the default routes (eg. route traffic to a subnet via an NVA)
  - Can propagate routes to multiple route tables.
  - All branch connections (P2S VPN, S2S VPN, and ExpressRoute) are configured as a whole, they always associate and propagate to the same set of route tables.
  - Enabling routing intent disables routing configs on connections

![Virtual hub route propagation](images/azure_virtual-wan-routes-propagation.png)

### Custom route tables

You can create your own custom route tables

- You can add static routes to the custom route table, which will take precedence over propagated routes with same prefix
  - You control whether a vNet connection picks up those static routes via the "Propagate default route" option on the connection
- vNet connections can associate/propagate to any route tables
- Branches can
  - associate ONLY to the Default route table
  - propagate to any route tables
- Custom route tables can have labels, which are used to group route tables, a vNet connection can propagate to labels, as well as individual route tables

### Route maps

Function:

- Route aggregation, eg. summarize `172.16.0.0/24` and `172.16.1.0/24` to one route `172.16.0.0/16`
- Route filtering, drop some routes
- Modify BGP attributes such as AS-PATH and Communities

Structure:
- A Route-map is an ordered sequence of one or more rules
- A rule comprises of three parts: match conditions, actions, connections applied to

Apply to:
- Any branch or VNet connections
- Inbound, outbound or both directions

### Routing Intent

- Can be enabled in either of the following places:
  - Azure Firewall Manager -> vHub -> Security configuration -> Inter-hub (only works for Azure Firewall)
  - vHub -> Routing Intent (works for third-party firewalls as well)
- This summaries routes in the route tables to just following 4 prefixes, and next hop is the firewall:
  - 192.168.0.0/16
  - 172.16.0.0/12
  - 10.0.0.0/8
  - 0.0.0.0/0
- NICs on attached vNets get the RFC1918 summaries as well
- Branches still gets individual prefixes for each spoke
- You can view effective routes on the firewall, which shows the individual prefixes of the spokes
- Enabling routing intent disables routing config on connections, you don't need to config association/propagation, static routes, etc.
  - If the "Propagate default route" option is disabled on a VNet connection, then the `0.0.0.0/0` routing intent will not propagate to this connection

### BGP peers

- A vHub hosts BGP Endpoint service, it could peer to an NVA in a connected vNet, this allows your vHub to get all the routes from the NVA
- You need to configure:
  - ASN
  - Private IP address of the NVA
  - VNet connection
- If your NVA is already supported in a vHub, this is not necessary
- Usecase: your NVA is not supported to by deployed in the vHub yet, then you can deploy it to a connected VNet, and peer it to the vHub

### Routing scenarios

- Isolating vNets ([Video link](https://youtu.be/2g-_empU0GU?si=WZ0nU3iGwOnKL7Ya&t=895)):

  ![vWAN isolating vNets](images/azure_networking-vwan-routing-isolating-vnets.png)

  - All connections propagate to the default route table
  - Branches associate to the default route table, so it can reach to any spoke
  - Branches propagate to custom route table, vNets associate with it, so vNets can reach branches, but not among themselves

- To Internet via Azure Firewall:

  ![vWAN Internet via Azure Firewall](images/azure_networking-vwan-routing-internet-via-azure-firewall.png)

  - Public traffic (outbound to Internet) goes through Azure Firewall
    - You can configure this in Firewall Manager, which adds a static route to the Default route table
  - Private traffic go direct

- vNet to branch via NVA in a vNet ([Video link](https://youtu.be/2g-_empU0GU?si=jvFQRMECpU7yAi3i&t=845)):

  ![vWAN custom route table](images/azure_networking-vwan-routing-custom-route-table.png)

  - Requirement: Traffic from vNet1 and vNet2 to branches need to go through an NVA in vNet3
  - Both vNet1 and vNet2 propagate and associate to the custom route table
  - You add a static route in the custom route table to route traffic via the NVA in vNet3
    - Branch IP ranges as the destination
    - `vNet3 Connection` as the next hop type
    - NVA IP `10.3.0.5` as the next hop

- Tiered vNets via NVA or Azure Firewall:

  ![vWAN tiered vNets via NVA](images/azure_networking-vwan-routing-indirect-vnets.png)

  ![vWAN tiered vNets via Azure Firewall](images/azure_networking-vwan-routing-indirect-vnets-with-azure-firewall.png)

  *The NVA could be Azure Firewall, this was a workaround for inter-hub traffic filtering issue before the Routing Intent feature was introduced, see [Video link](https://youtu.be/YZ0EQDut6_8?si=VFc5N_qhlwNtd1Yq&t=273)*

  - Add UDRs for the indirect vNets, pointing to the NVA IP
  - Add static routes for indirect vNets to the Default route table, NVA IP as the next hop
  - Now indirect vNets can reach each other, eg. VNet2a <-> VNet4b


## NVAs in a Virtual Hub

- You can deploy NVAs from a third party to a virtual hub, such as
  - Barracuda CloudGen WAN
  - Cisco Cloud OnRamp for Multi-Cloud
  - VMware SD-WAN
- Each will have a public facing IP address

Deployment process:

![NVA deployment process](images/azure_virtual-wan-nva-high-level-process.png)

- Like all Managed Applications, there will be two Resource Groups created in your subscription:
  - **Managed Resource Group**: contains the NVA resource, you cannot change anything here, it's controlled by the publisher of the Managed Application
  - **Customer Resource Group**: contains an application placeholder, partners can use this resource group to expose whatever customer properties they choose
- Once deployed, any additional configuration must be performed via the **NVA partners portal or management application**.
- You do not need to create S2S/P2S connection resources to connect your branch site to the virtual hub. This is all managed via the NVA.
- You still need to create Hub-to-vNet connections to connect your virtual WAN hub to your vNets.
- No need to create UDRs, the NVA will handle all routing between the virtual hub and your branch sites.


## SaaS solutions in a Virtual Hub

Currently you can deploy Palo Alto NGFW in a vHub.

The rules could be managed by either:
  - Local rule stack
    - Managed in Azure
    - Includes IP prefixes, FQDNs, security services, certificates, rules etc
    - You could configure certificate to inspect egress SSL traffic
  - Panorama rule stack
    - Managed in Panorama portal


## Virtual hub extension pattern

In a traditional hub-spoke topology, you can deploy shared services to a hub vNet, like DNS resourese, Azure Bastion, Domain Controller VMs, custom NVA, etc. This is not possible in a virtual hub.

You can solve this issue by creating extension vNets

![Virtual hub extension pattern](images/azure_vwan-virtual-hub-extension-pattern.svg)

In the diagram above, there's

- An extension vNet hosting DNS private resolver
- An extension vNet hosting Azure bastion

### Private DNS resolution

![Topology for private endpoint and DNS resolution in Azure Virtual WAN](./images/azure_dns-private-endpoints-virtual-wan-baseline-architecture.svg)

The diagram above is a starting topology, there are

- Two secured virtual hubs
- DNS proxy enabled on Azure Firewall
- Each spoke vNet has its default DNS server configured to the private IP of the Azure Firewall in regional hub

Challenges:

- You can't link private DNS zone to a vHub, so Azure Firewall can't resolve private endpoint FQDNs

Solution:

![Single region extension vnet for private DNS resolution](images/azure_vwan-dns-private-endpoints-scenario-single-region.svg)

- Both workload vNet and DNS extension vNets are using Azure Firewall as DNS server
- Azure Firewall forwards DNS queries to the private IP of the inbound endpoint of the DNS Private Resolver (*this is configured in Azure Firewall policy*)
- Private DNS zones are linked to the extension vNet
- Following the single responsibility principle, the DNS extension vNetshould ONLY contain the resources required for DNS resolution
- You should have **one extension vNet per region**
