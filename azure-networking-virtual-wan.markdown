# Azure Networking - Virtual WAN

- [Overview](#overview)
- [Virtual Hub Routing](#virtual-hub-routing)
  - [Branch to branch routing](#branch-to-branch-routing)
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
- Each **secured virtual hub**
  - Has associated security and routing policies configured by Azure Firewall Manager
  - At each hub, you could filter traffic between virtual networks(V2V), virtual netwoks and branch offices(B2V) and traffic to the Internet (B2I/V2I)
  - Provides automated routing, there's **no need to configure your own UDRs**


## Virtual Hub Routing

- A virtual hub has a router that manages all routing between gateways using BGP.
  - This router provides transit connectivity between virtual networks that connect to a virtual hub.
  - In a spoke vnet, a VM's effective routes are like (w/o routing intent):

    | Prefix        | Next Hop Type           | Next Hop IP                                 |
    | ------------- | ----------------------- | ------------------------------------------- |
    | vHub range    | VNet Peering            | --                                          |
    | spoke-b range | Virtual network gateway | random public IP (representing vHub router) |
    | onPrem range  | Virtual network gateway | a private IP (representing ER gateway)      |

- Four types of connections:
  - S2S VPN
  - P2S VPN
  - ExpressRoute
  - vNet

- Up to 1000 connections are supported per vHub, each connections consists of four links, each link supports two tunnels in active-active configuration.
- Routing preference, which determines if a range has been learnt from multiple origins, which one is preferred
  - ExpressRoute (default value)
  - VPN
  - AS Path (shortest AS Path first)

  ![Routing preference](images/azure_vwan-vhub-routing-preference.png)

  *In the above diagram, you want to set the preference on both vHubs to be **AS Path**, so the traffic would go from vHub to vHub, not be routed via the ER circuit, see https://youtu.be/D3-3BfWXzSo?si=541uRyNZ-ddwspPM*

- Each virtual hub has its own
  - **Default route table**, static routes could be added, taking precedence over dynamic routes
  - **None route table**, propagating to this means no routes are required to be propagated from the connection
- For each connection:
  - By default, it associates and propagates to the Default route table
  - Can only associate to one route table, which controls where traffic from this connection will be routed to.
  - Can propagate routes to multiple route tables.
  - A connection could have **static routes**, and whether they should be propagated
  - An option determines whether **default routes (`0.0.0.0/0`)** learnt by the vHub (by a Firewall in the hub) should be propagated to this connection
  - All branch connections (P2S VPN, S2S VPN, and ExpressRoute) are configured as a whole, they always associate and propagate to the same set of route tables.
  - Enabling routing intent (when a Firewall is deployed in the hub) disables routing configs on connections

![Virtual hub route propagation](images/azure_virtual-wan-routes-propagation.png)

### Branch to branch routing

- There's a setting to enable branch-to-branch routing in a vWAN
- For site-to-site VPN, the address spaces configured for VPN Sites determines the routing in the hub
  - Address spaces of a VPN site in one region will be propagated to hubs in other regions
  - If VPN sites in two regions have been configured with same address space, the traffic destined to it will be routed to the VPN gateway in the same hub, not hubs in other regions

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

Seems most useful when
  - you have an SD-WAN NVA
  - the NVA can't be deployed to a vHub, you need to put it in a spoke vNet
  - the NVA does not support route map itself

See an example here: https://youtu.be/5nHP3i5JG_8?si=ctJ99-HMVCMu6Ijp

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

Example:

- Using route map to fix asymmetric routing, see https://youtu.be/R5C8zJ7NEfk?si=w9H89XsypAL6HgI-

### Routing Intent

- Can be enabled in either of the following places:
  - Azure Firewall Manager -> vHub -> Security configuration (only works if Azure Firewall is deployed in vHub)
  - vHub -> Routing Intent (works for third-party firewalls as well)
- Enabling routing intent **disables routing config on connections**, you don't need to config association/propagation, static routes, etc.
  - For private traffic, it's always applied to all the VNets and branches
  - For public traffic, it could be applied selectively, if the "Propagate default route" option is disabled on a VNet connection, then the `0.0.0.0/0` routing intent will not propagate to this connection
- Under the hood, routing intent makes all vNet connection propagate to None route table, and associates to Default route table
- It summaries routes in the route tables to just these 4 prefixes, and next hop is the firewall:
  - 192.168.0.0/16
  - 172.16.0.0/12
  - 10.0.0.0/8
  - 0.0.0.0/0
- NICs on attached vNets get the RFC1918 summaries as well, with effective routes like:

  | Prefix         | Next Hop Type           | Next Hop IP                                                           |
  | -------------- | ----------------------- | --------------------------------------------------------------------- |
  | vHub range     | VNet Peering            | --                                                                    |
  | 192.168.0.0/16 | Virtual network gateway | private IP of Firewall                                                |
  | 172.16.0.0/12  | Virtual network gateway | private IP of Firewall                                                |
  | 10.0.0.0/8     | Virtual network gateway | private IP of Firewall                                                |
  | 0.0.0.0/0      | Virtual network gateway | private IP of Firewall (if routing intent enabled for public traffic) |
  | 0.0.0.0/0      | Internet                | N/A (if routing intent not enabled for public traffic)                |

- Branches still gets individual prefixes for each spoke
- You can view effective routes on the firewall, which shows the individual prefixes of the spokes

### BGP peers

- NVA or a BGP end point in a vNet connected to a vHub can directly peer with the vHub router, this allows your vHub to get all the routes from the NVA
  - The ASN of the NVA must be different from the vHub ASN
- Usecase:
  - If your NVA is already supported in a vHub, this is not necessary
  - If your NVA is not supported in the vHub yet, then you can deploy it to a connected vNet, and add the NVA as a BGP peer
- You need to configure:
  - ASN
  - Private IP address of the NVA
  - vNet connection
- In the routes the NVA advertises to the vHub, the next hop IP could be the NVA itself, or you can set it to the private IP of a load balancer
  ![BGP peering next hop IP](./images/azure_vwan-bgp-peer-next-hop-ip.png)

  *vNet-1 connected to vHub, and it has an NVA BGP peer*

  ![BGP peering effective routes](./images/azure_vwan-bgp-peer-next-hop-ip-effective-routes.png)

  *The BGP peer advertises two routes, one with the next hop IP to itself, another to the load balancer*

### Routing scenarios

See the [ExpressRoute note](./azure-networking.markdown#expressroute) for routing scenarios involving ER circuits

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
- Following the single responsibility principle, the DNS extension vNet should ONLY contain the resources required for DNS resolution
- You should have **one extension vNet per region**
