# Azure Networking

- [Overview](#overview)
- [Virtual networks](#virtual-networks)
  - [Subnets](#subnets)
    - [IP addressing](#ip-addressing)
    - [Design](#design)
    - [Delegation](#delegation)
  - [CLI](#cli)
- [IP](#ip)
  - [IP prefixes](#ip-prefixes)
  - [CLI](#cli-1)
- [NAT Gateway](#nat-gateway)
- [Network security group (NSG)](#network-security-group-nsg)
  - [Service Tag](#service-tag)
    - [`VirtualNetwork` tag](#virtualnetwork-tag)
  - [App Security Group](#app-security-group)
  - [Azure platform considerations](#azure-platform-considerations)
  - [Virtual IP of the host node](#virtual-ip-of-the-host-node)
    - [`168.63.129.16`](#1686312916)
- [Network Peering](#network-peering)
  - [CLI](#cli-2)
- [vNet Gateways](#vnet-gateways)
- [VPN](#vpn)
  - [VPN Gateway](#vpn-gateway)
  - [Site to site](#site-to-site)
  - [High availability](#high-availability)
  - [Point to site](#point-to-site)
    - [Native Azure certificate auth](#native-azure-certificate-auth)
- [ExpressRoute](#expressroute)
- [Routing](#routing)
  - [Default system routes](#default-system-routes)
  - [User-defined routes](#user-defined-routes)
  - [BGP](#bgp)
  - [Route selection and priority](#route-selection-and-priority)
  - [NVA](#nva)
  - [Autonomous systems](#autonomous-systems)
  - [Route Server](#route-server)
    - [Usage scenarios](#usage-scenarios)
    - [Commands](#commands)
  - [Forced tunneling](#forced-tunneling)
  - [Troubleshooting](#troubleshooting)
- [Service endpoints](#service-endpoints)
  - [Create](#create)
  - [Service endpoint policies](#service-endpoint-policies)
  - [Private endpoints vs. service endpoints](#private-endpoints-vs-service-endpoints)
- [Private Endpoints](#private-endpoints)
- [Deploy Azure service to vNets](#deploy-azure-service-to-vnets)
- [Load balancing](#load-balancing)
- [Azure Load Balancer](#azure-load-balancer)
  - [SKUs](#skus)
  - [Distribution modes](#distribution-modes)
- [Application Gateway](#application-gateway)
  - [Overview](#overview-1)
  - [Components](#components)
  - [How does routing works](#how-does-routing-works)
  - [AGW subnet and NSG](#agw-subnet-and-nsg)
  - [CLI](#cli-3)
- [Traffic Manager](#traffic-manager)
  - [DNS resolution example](#dns-resolution-example)
  - [Traffic-routing methods](#traffic-routing-methods)
  - [Nested profiles](#nested-profiles)
- [Front Door](#front-door)
- [CDN](#cdn)
  - [Standard rules engine notes](#standard-rules-engine-notes)
  - [Custom domain HTTPS](#custom-domain-https)
- [DNS](#dns)
  - [Overview](#overview-2)
  - [DNS resolution within virtual networks](#dns-resolution-within-virtual-networks)
  - [Azure-provided name resolution](#azure-provided-name-resolution)
  - [Private DNS zones](#private-dns-zones)
  - [Your own DNS server](#your-own-dns-server)
  - [CLI](#cli-4)
- [Azure Firewall](#azure-firewall)
  - [Asymmetric routing](#asymmetric-routing)
  - [Azure Firewall Manager](#azure-firewall-manager)
  - [Firewall policy](#firewall-policy)
- [Web Application Firewall (WAF)](#web-application-firewall-waf)
  - [WAF Config (legacy)](#waf-config-legacy)
  - [WAF policy on AGW](#waf-policy-on-agw)
    - [Custom rules](#custom-rules)
    - [Managed rules](#managed-rules)
- [DDoS Protection](#ddos-protection)
- [Azure Virtual Network Manager](#azure-virtual-network-manager)
- [Network Watcher](#network-watcher)
  - [Auto creation](#auto-creation)
- [Network design considerations](#network-design-considerations)
- [Networking architecutres](#networking-architecutres)
- [Hub-spoke architecture](#hub-spoke-architecture)
- [Firewall and Application Gateway integration patterns](#firewall-and-application-gateway-integration-patterns)

## Overview

- Logically isolated network
- Scoped to a single region
- Can be segmented into one or more *subnets*
- Can use VPN or ExpressRoute to connect to on-premises networks

## Virtual networks

![vnet](images/azure_virtual-networks.png)

A vNet can be cloud-only or connected to on-prem network through site-2-site VPN, or ExpressRoute

- Some resources are connected directly:
  - VM
  - VMSS
  - App Service Environment
  - AKS
- Use service endpoints to connect to other PaaS services: storage accounts, key vaults, SQL databases, etc
- Or use private endpoints to connect to PaaS or your own custom services.
- A vNet spans multiple availability zones, not limited to a single data center

### Subnets

#### IP addressing

- You should use address ranges defined by RFC 1918 (not routable on public networks):
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
- You cannot use these ranges:
  - 224.0.0.0/4 (Multicast)
  - 255.255.255.255/32 (Broadcast)
  - 127.0.0.0/8 (Loopback)
  - 169.254.0.0/16 (Link-local)
  - 168.63.129.16/32 (Internal DNS)
- Each subnet has **5 reserved IP addresses**, so the smallest supported IPv4 subnet is /29 (e.g 10.0.1.0/29, 5 Azure reserved addresses + 3 available)
  - `x.x.x.0`: Network address
  - `x.x.x.1`: Reserved by Azure for the default gateway
  - `x.x.x.2`, `x.x.x.3`: Reserved by Azure to map the Azure DNS IPs to the VNet space
  - `x.x.x.255`: Network broadcast address

#### Design

- Each subnet should have non-overlapping CIDR address space
- Some services require its own dedicated subnet, such as VPN gateway
- Routing:
  - By default, network traffic between subnets in a vNet is allowed, you can override this default routing
  - You could also route inter-subnet traffic through a network virtual appliance(NVA)
- You could enable **service endpoints** in subnets, this allows some public-facing Azure services(e.g. Azure storage account or Azure SQL database) to be accessible from these subnets and deny access from internet
- A subnet can have zero or one NSG, and an NSG could be associated to multiple subnets

#### Delegation

- You could delegate a specific subnet to an Azure PaaS service, such as VNet data gateway (`Microsoft.PowerPlatform/vnetaccesslinks`)
- The purpose usually is to allow a PaaS service to access/manage resources for the subnet, such as managing NSGs (`Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action`)
- You need `Microsoft.Network/virtualNetworks/subnets/join/action` permission to delegate a subnet (included in "Network Contributor" role)


### CLI

```sh
# list vNets
az network vnet list --output table

# list subnets
az network vnet subnet list \
        --vnet-name my-vnet \
        --output table
```

## IP

- Public IP addresses enable Internet resources to communicate with Azure resources and enable Azure resources to communicate outbound with Internet and public-facing Azure services.
- A public IP address in Azure is dedicated to a specific resource, until it's unassigned by a network engineer.
- A resource without a public IP assigned can communicate outbound through network address translation services, where Azure dynamically assigns an available IP address that isn't dedicated to the resource.

Private vs. Public IPs:

| Feature    | Private IP                                                                             | Public IP                                                                                                                                                                                                             |
| ---------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Resources  | <ul><li>VM NICs</li><li>internal load balancers</li><li>application gateways</li></ul> | <ul><li>VM NICs</li><li>VMSS</li><li>Public Load Balancers</li><li>vNet gateways(VPN/ER)</li><li>NAT gateways</li><li>application gateways</li><li>Azure Firewall</li><li>Bastion Host</li><li>Route Server</li></ul> |
| Assignment | Dynamic (DHCP lease) or Static (DHCP reservation)                                      | Dynamic or Static                                                                                                                                                                                                     |

Dynamic vs. Static IP assignment:

- Dynamic: IP is not allocated when you create the IP resource, only allocated when needed (eg. when you create or start a VM, released when you stop or delete a VM)
- Static: assigned immediately, only released when you delete the IP resource


Public IP SKUs

| Feature           | Basic SKU                                           | Standard SKU                                                                                                       |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| IP assignment     | Static or dynamic                                   | Static                                                                                                             |
| Security          | Open by default, available for inbound only traffic | **Are secure by default and closed to inbound traffic**, you must enable inbound traffic by using NSG              |
| Resources         | all that can be assigned a public IP                | <ul><li>VM NICs</li><li>Standard public load balancers</li><li>Application gateways</li><li>VPN gateways</li></ul> |
| Availability Zone | Not supported                                       | Zone redundant by default, or zonal                                                                                |

### IP prefixes

- You specify the name and prefix size
- After the public IP prefix is created, you can create public IP addresses
- You could also bring your own IP prefixes to Azure (BYOIP)

### CLI

```sh
# create a public IP with a DNS label
az network public-ip create \
  --resource-group myRG \
  --name garyPublicIP \
  --sku Standard \
  --dns-name garyip

# then `garyip.australiaeast.cloudapp.azure.com` resolves to this IP
```


## NAT Gateway

![NAT Gateway](images/azure_nat-gateway.png)

- Allows you to share public IPs among multiple internal resources
- You associated it to a subnet (a subnet can only have one NAT gateway)
- A zonal service, you need to choose an availability zone to deploy it
- An NAT gateway can be associated to multiple subnets (must be in the same vNet)
- Subnets with following resources are not compatible:
  - IPv6 address space
  - An existing NAT gateway
  - A vNet gateway
  - A Basic SKU public IP (attached to a NIC in the subnet)
  - A Basic SKU load balancer
- Can only use **Standard SKU** Public IPs or public IP prefixes
- After NAT is configured
  - NAT **takes precedence** over other outbound scenarios and replaces the default Internet destination of a subnet
  - All UDP and TCP outbound flows from any VM instance will use NAT for Internet connectivity (**takes precedence over other public IPs on its NIC**)
  - Does not support ICMP
  - No further configuration is necessary, and you don't need to create any UDR
- Allows flows from vNet to the Internet, return traffic is only allowed in response to an active flow
- Each public IP gives you ~64,000 SNAT ports
  - This is an option to help scale SNAT ports for Azure Firewall (which has max. 250 IPs, and 2496 SNAT ports per IP)
  - You can link a NAT gateway to the Azure Firewall subnet
  - Only works for Azure Firewall in a hub vnet of a hub-spoke topology, doesn't work for the secured hub scenario.
  - See: https://learn.microsoft.com/en-us/azure/firewall/integrate-with-nat-gateway
- You could configure the TCP idle timeout, default is 4 minutes
- Compatible with Standard SKU load balancer, Standard SKU public IP/prefix (those could still accept inbound connections)

  ![NAT compatibility](images/azure_networking-nat-flow-direction-inbound-outbound.png)

  *Traffic coming in from a load balancer will return vai it, not via the NAT Gateway*

## Network security group (NSG)

- Filters inbound and outbound traffic
- Can be associated to a **network interface** (per host rules), a **subnet** , or both
- Each subnet or NIC can have zero or one NSG
- An NSG is an independent resource, doesn't belong to a vNet, it can be associated **multiple times** to subnets in the same or different vNets (must be in the same region)
- Default rules cannot be modified but *can* be overridden
- Rules evaluation starts from the **lowest priority** rule, deny rules always stop the evaluation

![network security group](images/azure_network-security-group.png)

- To access a VM, traffic must be allowed on both subnet and NIC NSG rules
- For inbound traffic, subnet NSG rules are evaluated first, then NIC NSG rules, the other way around for outbound traffic

### Service Tag

Service tags represent a group of address prefixes, usually from a given Azure service
  - Microsoft maintains and automatically updates the prefixes
  - These tags could be used in NSG rules, UDR, Azure Firewall
  - Examples:
    - VirtualNetwork (*see below*)
    - Internet
    - AzureCloud (*> 4500 prefixes*)
    - Storage (*Azure Storage for the entire cloud*)
    - Storage.WestUS (*some tags could be regional*)
    - SQL
    - AzureLoadBalancer
    - AzureTrafficManager
    - AppService
    - Dynamics365ForMarketingEmail

Example:

![Service tags](images/azure_service-tags.png)

This NSG allows traffic to public IPs of Storage and Sql.EastUS, denies anything else to the Internet.

Notes:

- Underlying IP ranges corresponding to a service tag are cloud specific. So IP addresses encompassed in `Storage` in Azure Public Cloud are different from Azure USGov Cloud.
- When you enable a service endpoint in a subnet, Azure adds a route to the subnet, the address prefixes in the route are the same address prefixes of the corresponding service tag.

#### `VirtualNetwork` tag

This tag includes all the following address prefixes:

- virtual network address space
- peered virtual networks
- all connected on-premises address spaces
- virtual networks connected to a virtual network gateway
- the virtual IP address of the host (168.63.129.16 and 169.254.169.254)
- **address prefixes used in UDRs**
- might also contain default routes

When you have `0.0.0.0/0` in a UDR associated with the same subnet, `VirtualNetwork` denotes `0.0.0.0/0`. So the default `AllowVnetInBound` rule allows everything.

See details:
- https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview
- https://github.com/MicrosoftDocs/azure-docs/issues/22178
- https://journeyofthegeek.com/2022/06/22/virtualnetwork-service-tag-and-network-security-groups/


### App Security Group

You could add VM NICs to an **App Security Group** (like a custom service tag), which could be used in an NSG rule to make management easier, you just add/remove VMs to/from the ASG, no need to manually add/remove IPs to the NSG rules

![App Security Group](images/azure_app-security-group-asg-nsg.svg)

*Private endpoint could be added to an ASG as well*

### Azure platform considerations

Details: https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#azure-platform-considerations

- **Licensing (Key Management Service)**: Windows images running in a VM will send request to the Key Management Service host services. The request is made outbound through port 1688.
- **VMs in load-balanced pools**: Source port and address are from the originating computer, not the load balancer. The destination port and address are for the destination VM, not the load balancer
- **Azure service instances**: Instances of some Azure services could be or must be deployed in vnet subnets. You need to be aware of the port requirements for these services running in a subnet when applying NSGs.
- **Outbound email**: Depending on your subscription type, you may not be able to send email directly over TCP port 25. Use an authenticated SMTP relay service (typically over TCP port 587)


### Virtual IP of the host node

- Basic infrastructure services like DHCP, DNS, IMDS and health monitoring are provided through the virtualized host IP addresses **168.63.129.16** and **169.254.169.254** (*`169.254.0.0/16` are "link local" addresses. Routers are not allowed to forward packets sent from an IPv4 "link local" address, so they are always used by a directly connected device*)
- These IP addresses belong to Microsoft and are the ONLY virtualized IP addresses used in all regions
- **Effective security rules and effective routes WILL NOT include these platform rules**
- To override this basic infrastructure communication, you can create a security rule to deny traffic by using these service tags on your NSG rules: AzurePlatformDNS, AzurePlatformIMDS, AzurePlatformLKM

#### `168.63.129.16`

A virtual public IP address, used to facilitate a communication channel to Azure platform resources. Typically, you should allow this IP in any local (in the VM) firewall policies (outbound direction). It's not subject to user defined routes.

- The VM Agent requires outbound communication over port 80/tcp and 32526/tcp with WireServer(`168.63.129.16`). This is not subject to the configured NSGs.
- `168.63.129.16` can provide DNS services to the VM when there's no custom DNS servers definition. By default this is not subject to NSGs unless specifically targeted using the "AzurePlatformDNS" service tag. You could also block 53/udp and 53/tcp in local firewall on the VM.
- Load balancer health probes originate from this IP. The default NSG config has a rule that allows this communication leveraging the "AzureLoadBalancer" service tag.


## Network Peering

Connect two virtual networks together, resources in one network can communicate with resources in another network.

![network peering](images/azure_network-peering.png)

- The networks can be in **different** subscriptions, AAD tenants, or regions
- Traffic between networks is **private**, on Microsoft backbone network
- You need proper permission over both vNets to configure the peering (such as `Network Contributor` role)
- Global vNet peering has same settings as regional vnet peering
- Under the hood, routes of type `VNetPeering`/`VNetGlobalPeering` are added on both sides
- No downtime to resources
- Peerings on both side are created and removed at the same time
- Non-transitive, for example, with peering like this A <-> B <-> C, A can't communicate with C, you need to peer A <-> C

A typical use for peering is creating hub-spoke architecture:

![Azure gateway transit](images/azure_gateway-transit.png)

- In above diagram, to allow connection between vNet B and on-prem, you need configure **Allow Gateway Transit** in the hub vNet, and **Use Remote Gateway** in vNet B
  - In the background, this adds routes to vNet B's route table, VPN Gateway's IP would be the Next Hop if on-prem is the destination
- Spoke networks can **NOT** connect with each other by default through the hub network, you need to add peering between the spokes or consider using user defined routes (UDRs)
  - Peering enables the next hop in a UDR to be the IP address of an NVA (network virtual appliance) or VPN gateway. Then traffic between spoke networks can flow through the NVA or VPN gateway in the hub vNet.
- Azure Bastion in hub network can be used to access VMs in spoke network (networks must be in same tenant)

Peering on each side has these settings:

<img src="images/azure_vnet-peering-options.png" width="600" alt="vNet peering options" style="border: 1px solid grey" />

- **Traffic to remote virtual network**
  - If "Allow", remote vNet address space is included in the "VirtualNetwork" service tag (in all NSGs attached to subnets/NICs in this vNet), so the default `AllowVnetInBound` and `AllowVnetOutBound` would allow the traffic
  - If "Block", you could still add a custom NSG rule to allow traffic
- **Traffic forwarded from remote virtual network**
  - Whether allow forwarded traffic from remote vNet (not originating from inside remote vNet) into this vNet.
  - **This is not done via the "VirtualNetwork" service tag, if "Block", traffic will be blocked, even NSG rules allow it**
- **Virtual network gateway or Route Server**
  - A vNet only allows **one gateway**, you choose whether to use gateway in this vNet or the remote vNet
  - Under the hood, the chosen gateway's IP would be used as next hop IP in system defined routes for related address prefixes
  - It also controls which gateway would advertise (via BGP) this vNet's address range to on-prem

### CLI

```sh
az network vnet peering create \
    --resource-group my-rg \
    --name vnet1-to-vnet2 \
    --vnet-name vnet1 \
    --remote-vnet vnet2 \
    --allow-vnet-access

# create the reciprocal connection
az network vnet peering create \
    --resource-group my-rg \
    --name vnet1-to-vnet1 \
    --vnet-name vnet2 \
    --remote-vnet vnet1 \
    --allow-vnet-access

# list vnet peering
az network vnet peering list \
    --resource-group my-rg \
    --vnet-name vnet1 \
    --output table

# show effective route table of a vm in a peered vnet
# showing peering as the "Next Hop Type" for peered vnet addresses
az network nic show-effective-route-table \
    --resource-group my-rg \
    --name vm-in-vnet1 \
    --output table
# Source    State    Address Prefix    Next Hop Type      Next Hop IP
# --------  -------  ----------------  -----------------  -------------
# Default   Active   10.1.0.0/16       VnetLocal
# Default   Active   10.2.0.0/16       VNetPeering
# Default   Active   0.0.0.0/0         Internet
# Default   Active   10.0.0.0/8        None
# Default   Active   100.64.0.0/10     None
# Default   Active   192.168.0.0/16    None
# Default   Active   10.3.0.0/16       VNetGlobalPeering
```

## vNet Gateways

A vNet gateway serves two purposes: to exchange IP routes between the networks and to route network traffic.

There are two types of gateways: VPN and ExpressRoute

The configuration of the Azure public IP resource determines whether the gateway that you deploy is zone-redundant, or zonal.

- Public IP Standard SKU without specifying a zone
  - VPN gateway: the two instances will be deployed in any 2 out of these three zones
  - ExpressRoute gateway: there can be more than 2 instances, so it could span across all three zones
- Public IP Standard SKU specifying a zone (1, 2 or 3)
  - All gateway instances will be in the same zone as the public IP
- Public IP Basic SKU
  - A regional gateway without any zone-redundancy

## VPN

Different types:

- **Site to Site**: your on-premise to vNet
  - needs a on-prem VPN device
  - This could be over the Internet or a dedicated network, such as Azure ExpressRoute
  - Could be used to connect two vNets
  ![Azure VPN site to site](images/azure_vpn-site-to-site.svg)

- **Point to Site**: your local machine to a vNet (doesn't require on-prem VPN device)

### VPN Gateway

- Each vNet can have **only one** VPN gateway
- Each gateway supports a max. 30 S2S tunnels, use Virtual WAN if more are needed
- Within each gateway there are usually **two or more VMs** that are deployed to a gateway subnet
  - this gateway subnet must be named  **`GatewaySubnet`**
  - better use a CIDR block of /27 to allow enough IP addresses for future config requirements
  - never put other resources in this subnet
  - ExpressRoute and VPN could co-exist in a subnet, this configuration requires a larger subnet
- These VMs contain routing tables and specific services, they are created automatically, you can't configure them directly
- VPN gateways can be deployed to multiple AZs for high availability
- A VPN Gateway will have a public IP, and two private IPs (one is for BGP) ??

VPN types:

- **Route-based**: suitable for most cases, required by P2S
  - Use "routes" to direct traffic into their corresponding tunnel interfaces
  - The tunnel interfaces then encrypt/decrypt the packets in/out of the tunnels
- **Policy-based**: only for some S2S connections
  - Only allow 1 S2S tunnel
  - No support for P2S
  - No support for IKEv2

### Site to site

![S2S gateway creation steps](images/azure_vpn-gateway-creation-steps.png)

*Last 3 steps are specific to S2S connections*

![VPN gateway resources](images/azure_vpn-gateway-resources.svg)

- Create local network gateway
  - this gateway refers to the on-prem location,
  - you specify the IP or FQDN of the on-prem VPN device,
  - address space of your on-prem network, if you want to use this for a BGP-enabled connection, then the minimum prefix you need to declare is the host address of your BGP Peer IP address on your VPN device
  - vNet-to-vNet connection doesn't require local network gateways, you need to create a connection on either side to the VPN gateway on the other side

- Configure on-prem VPN device: steps differ based on your device, you need a **shared key**(a ASCII string of up to 128 characters) and the public IP of the Azure VPN gateway
- Create the VPN connection: specify the VPN gateway, the local network gateway and the shared key (same as previous step)

### High availability

A few options available:

- VPN Gateway redundancy (Active-standby)

  ![Active standby](images/azure_vpn-active-standby.png)

  - One VM is active, another standby
  - S2S or vNet-to-vNet connections fail over automatically, brief disruptions:
    - Planned maintennace: 10-15 seconds
    - Unplanned: 1-3 minutes
  - P2S: users need to reconnect

- Multiple on-premises VPN devices

  ![Multiple on-premises VPN devices](images/azure_vpn-multiple-onprem-vpns.png)

  - One local network gateway for each VPN device, one connection from VPN gateway to each local network gateway
  - BGP is required, each local network gateway must have a unique BGP peer IP
  - Use BGP to advertise the same on-prem network prefixes to your Azure VPN gateway, traffic will be forwarded through these tunnels simultaneously
  - You must use Equal-cost multi-path routing (ECMP)
  - Each connection is counted against the max. number of tunnels

- Active-active Azure VPN gateway

  ![Active-active Azure VPN gateway
](images/azure_vpn-active-active.png)

  - Each VM has a unique public IP address, each establish a tunnel to the on-prem VPN device
  - Both tunnels are part of the same connection
  - You on-prem VPN device needs to accept/establish the two S2S tunnels
  - Both tunnels are active. For a single TCP/UDP flow, Azure attempts to use the same tunnel when sending packets to your on-prem network. However, your on-prem network could use a different tunnel to send packets to Azure.
  - When disruption happens to one instance, IPsec tunnel from that instance to your on-prem VPN device will be disconnected. The corresponding routes on your VPN device should be removed automatically so traffic could be switched to the other active tunnel.

- Combination of both

  ![Combination of both](images/azure_vpn-dual-redundancy.png)

  - A full mesh with 4 IPsec tunnels
  - Require two local network gateways and two connections
  - BGP is required

- vNet to vNet

  ![vNet to vNet](images/azure_vpn-vnet-vnet.png)

  - Unlike the cross-premises scenario above, this needs only one connection for each gateway.
  - BGP is optional unless transit routing over the connection is required.

### Point to site

![Azure VPN point to site](images/azure_vpn-point-to-site.png)

Supported protocols:

- OpenVPN
  - SSL/TLS based, can penetrate firewalls, since most firewalls open TCP 443 outbound
  - Can be used to connect from Android, iOS, Windows, Linux, Mac
- SSTP
  - A proprietary TLS-based protocol
  - Only supported on Windows device
- IKEv2
  - A standards-based IPsec VPN solution
  - Mac only

Authentication methods:

- Native Azure certificate auth
  - Get a root certificate (self-signed or from a CA)
  - Upload root certificate to Azure
  - Each client need a certificate signed by the root certificate
  - When a client tries to establish a P2S VPN connection, the VPN gateway validates the client certificate
  - You also need to upload any revoked certs to Azure
- Native AAD auth
  - Only supports OpenVPN protocol and Windows 10 and Azure VPN client
- AD Domain Server
  - Requires a RADIUS server that integrates with the AD server
  - The RADIUS server could be on-prem or in a vNet, the VPN gateway must be able to connect to the RADIUS server, if the RADIUS server is on-prem, then a VPN S2S connection must be in place
    ![VPN P2S RADIUS server](images/azure_vpn-p2s-authenticate-with-ad.png)
  - The RADIUS server can also integrate with AD certificate service, allowing you do all certificate management in AD, you don't need to upload root certs and revoked certs to Azure

#### Native Azure certificate auth

Follow the doc (https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal)

The following covers how to generate CA/client certificates on Linux:

```sh
sudo apt install strongswan strongswan-pki libstrongswan-extra-plugins

# generate CA certificates
ipsec pki --gen --outform pem > caKey.pem
ipsec pki --self --in caKey.pem --dn "CN=VPN CA" --ca --outform pem > caCert.pem

# print certificate in base64 format (put this in Azure portal)
openssl x509 -in caCert.pem -outform der | base64 -w0 ; echo
```

Use following script to create client cert/key for multiple users

```sh
#!/bin/bash

USERS=$@

create_cert_key() {
  local PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)
  local U=$1

  echo "$PASSWORD" > "${U}_key_password"
  ipsec pki --gen --outform pem > "${U}_key.pem"
  ipsec pki --pub --in "${U}_key.pem" | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "CN=${U}" --san "${U}" --flag clientAuth --outform pem > "${U}_cert.pem"

  # create a p12 bundle (need to be installed on client machine to connect to VPN)
  openssl pkcs12 -in "${U}_cert.pem" -inkey "${U}_key.pem" -certfile caCert.pem -export -out "${U}.p12" -password "pass:${PASSWORD}"
}


for U in $USERS; do
  echo "creating cert for ${U}"
  create_cert_key "${U}"
  mkdir "$U"
  mv "${U}_key_password" "${U}_key.pem" "${U}_cert.pem" "${U}.p12" "${U}"
done
```

Then you download a VPNClient package from Azure portal, extract the file, it has clients/configs for Windows, OpenVPN, etc.

  - OpenVPN on Linux
    - make sure openvpn is installed
    ```sh
    sudo apt-get install openvpn network-manager-openvpn network-manager-openvpn-gnome
    ```
    - then create a OpenVPN connection by importing the OpenVPN config file from the package, set your cert file, key file, key password

  - Windows (IKEv2)

    - Open the `.p12` bundle to import client key (need to know the key password)
    - Run the Windows client provided by Azure to create a VPN connection


To revoke a client certificate, use the following scripts to get a client certificate's fingerprint:

```sh
a=$(openssl x509 -in my_cert.pem -fingerprint -noout)
a=${a#*=}       # remove everthing before '='
echo ${a//:}    # remove ':'
```

## ExpressRoute

![ExpressRoute overview](images/azure_expressroute.svg)
- A circuit represents a logical connection between your on-prem infrastructure and Microsoft cloud through a connectivity provider (e.g. AT&T, Verizon, Vodafone)
- A circuit does not map to any physical entities, it's uniquely identified by a standard GUID called a **service key**
- A direct, private connection(but NOT encrypted) to Microsoft services, including Azure, Microsoft 365, Dynamics 365
- A circuit is always active-active, two BGP sessions
- Ingress is not chared, egress is charged (could be metered or unlimited)
- Private peering:
  - For VMs (IaaS) and PaaS services deployed within a vNet
  - Connect your on-prem network to Azure vNets, lets you connect to VMs and cloud services directly on their private IP addresses
- Microsoft peering:
  - For Microsoft 365 and Azure PaaS services that are not deployed into a vNet
  - Microsoft 365 is designed to be used over the Internet, there is only some **very limited scenarios** in which you may want connect to it over an ER
  - Bidirectional connectivity between your WAN and Microsoft services
  - Route filter:
    - Why:  Connectivity to all Azure and Microsoft 365 services causes many prefixes to gets advertised through BGP. The large number of prefixes significantly increases the size of the route tables maintained by routers within your network.
    - How: You must associate a route filter to your ER circuit to enable route advertisement to your network.  A route filter lets you select the list of services that you plan to consume through Microsoft peering
    - A route filter can only have one rule of type "Allow", which has a list of BGP community values associated

- What are needed to establish a peering:

  - Requires a /29 address range, or two /30 ranges
    - One /30 range for primary link, another for secondary link
    - In each /30 range, you router gets one IP, MS uses another to setup BGP session
    - Could use a private IP range for private peering.
    - Must be a public IP ranges for Microsoft peering.

  - MS uses ASN 12076, and have 65515-65520 reserved for internal use
    - For Microsoft peering, you need a publicly registered ASN for your network
    - When an ER gateway is connected to two circuits, you could use either routing weight or AS prepending to set the preferred route

  - MS advertises routes tagged with appropriate community values
    - If you configure a custom BGP community value on your Azure vNet, you will see this custom value and a regional BGP value on the Azure routes advertised to your on-prem over ER
    - The regional BGP community values help you decide which routes take precedence when you have circuits in different regions
      - This value for Australia East is 12076:50015, Australia Southeast 12076:50016

- SKUs:
  - Local: only connect to local regions, egress traffic not charged
  - Standard: connect to regions in the same geopolitical boundary
  - Premium: global connectivity, more than 4k routes, connect to more than 10 vNets

- ER Direct: you buy a port from an MS edge router directly, up to 100Gbps, so your traffic does not go through a provider router

<img src="images/azure_expressroute-connectivity-models.png" width="600" alt="Connectivity models" />

Connectivity can be from:

- Virtual cross-connection via an Ethernet exchange (layer 2 and 3)
- Point-to-point Ethernet connection (layer 2 and 3)
- Any-to-any(IP VPN) network (Microsoft will behave just like another location on your private WAN)

![ExpressRoute connections](images/azure_expressroute-connections.drawio.svg)

- An ExpressRoute circuit located in one peering location could connect up to 10 vnets within the same geopolitical region
  - *ExpressRoute locations (peering locations) are co-location facilities where Microsoft Enterprise Edge (MSEE) devices are located, not the same as Azure regions*
- Each gateway could have connections to multiple ER circuits, you specify the routing weight of each connection
- **ExpressRoute Global Reach** allows you to connect multiple ExpressRoute circuits, which allows you to connect your multiple data centers in different geopolitical regions
  <img src="images/azure_expressroute-global-reach.png" width="400" alt="ExpressRoute global reach" />

  *Global Reach enables connectivity between 10.0.1.0/24 and 10.0.2.0/24*
- DNS queries, certificate revocation list checking and Azure CDN requests are still sent over the public internet

Design redundancy for an ExpressRoute deployment

- Configure ExpressRoute and S2S VPN coexisting connections (VPN could serve as a failover)
- Create a zone redundant vNet gateway in Azure Availability zones

A vNet can have both ExpressRoute and VPN gateways at the same time.

![Coexisting ExpressRoute and VPN gateway](images/azure_coexisting-connections.png)

Compare ExpressRoute to Site-to-Site VPN:

|                    | Site-to-site VPN                                                   | ExpressRoute                                                                                 |
| ------------------ | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| Services supported | Azure Iaas and PaaS (through private endpoint)                     | Azure IaaS and PaaS, Microsoft 365, Dynamics 365                                             |
| Bandwidth          | typically < 1Gbps                                                  | 50Mbps - 10Gbps (100Gbps with ExpressRoute Direct)                                           |
| Protocol           | SSTP or IPsec                                                      | Direct over VLAN or MPLS                                                                     |
| Routing            | Static or dynamic                                                  | Border Gateway Protocol (BGP)                                                                |
| Use cases          | <ul><li>Dev, test and lab</li><li>Small-scale production</li></ul> | <ul><li>Enterprise-class and mission-critical workloads</li><li>Big data solutions</li></ul> |


## Routing

### Default system routes

![Azure system routes](images/azure_system-routes.png)

- By default, each subnet is associated with a route table, which contains system routes. These routes manage traffic within the same subnet, between subnets in the same vNet, from vNet to the Internet.
- Each subnet can only be associated with one route table, while a route table could be associated with multiple subnets.

These are the default system routes:

| Address prefix     | Next hop type   |
| ------------------ | --------------- |
| vNet address range | Virtual network |
| 0.0.0.0/0          | Internet        |
| 10.0.0.0/8         | None            |
| 172.16.0.0/12      | None            |
| 192.168.0.0/16     | None            |
| 100.64.0.0/10      | None            |

- *`100.64.0.0/10` is shared address space for communications between a service provider and its subscribers when using a carrier-grade NAT (see https://en.wikipedia.org/wiki/Carrier-grade_NAT)*
- The `0.0.0.0/0` route is used if no other routes match, Azure routes traffic to the Internet, the **exception is that traffic to the public IP addresses of Azure services remains on the Azure backbone network**, not routed to the Internet.

Additional system routes will be created when you enable certain Azure capabilities:

- vNet peering (a route for each address range in the peered-to vnet's address space)
- vNet gateway (prefixes advertised from on-prem via BGP, or configured in the local network gateway)
- vNet Service endpoint (a route to the service's public IPs, only added to the subnets for which a service endpoint is enabled)

### User-defined routes

![User defined routes](images/azure_user-defined-routes.png)

You could config user-defined routes (UDRs), to override Azure's default system routes, or add more routes. For each route, the next hop could be
- **Virtual network appliance**
  - you need to specify an IP address of the NVA
  - the IP address could be:
    - Of a network interface attached to a VM, the NIC must have "Enable IP forwarding"
    - Of an internal load balancer, which connects to multiple NVAs for high availability
  - the IP must have direct connectivity
- Virtual network gateway (*can only be a VPN gateway, not ExpressRoute gateway*)
- Virtual network (*could be helpful if you want to keep traffic within a subnet remain within it, but direct everything else to an NVA*)
- Internet
- None

![Routing example](images/azure_routing-example.png)

In the above example,

- By default, traffic from public subnet goes to private subnet directly
- You define a route in the public subnet's route table, make any traffic from the public subnet to the private subnet go through the virtual appliance in the DMZ subnet.

```sh
# create a route table
az network route-table create \
        --resource-group my-rg \
        --name my-route-table \
        --disable-bgp-route-propagation false

# add a route, message to 10.0.1.0/24 goes through 10.0.2.4
az network route-table route create \
        --resource-group my-rg \
        --route-table-name my-route-table \
        --name productionsubnet \
        --address-prefix 10.0.1.0/24 \
        --next-hop-type VirtualAppliance \
        --next-hop-ip-address 10.0.2.4

# associate route table to the public subnet
az network vnet subnet update \
        --resource-group my-rg \
        --name publicsubnet \
        --vnet-name vnet \
        --route-table my-route-table
```

On a VM in the public subnet, run `traceroute private-vm --type=icmp`, result would be like:

```
traceroute to private.xxx.gx.internal.cloudapp.net (10.0.1.4), 64 hops max

1   10.0.2.4  0.710ms  0.410ms  0.536ms
2   10.0.1.4  0.966ms  0.981ms  1.268ms
```

### BGP

Border gateway protocol (BGP) is the standard routing protocol to exchange routing and information among two or more networks.

Usually used to advertise on-prem routes to Azure when you're connected through ExpressRoute or S2S VPN.

- ExpressRoute
  - You must use BGP to advertise on-prem routes to Azure
  - You can't create UDR to force traffic to an ExpressRoute gateway
  - You can use UDR to force traffic from an ExpressRoute gateway to an NVA (eg. You could add a UDR on `GatewaySubnet` to route traffic to a firewall)
- VPN
  - You can optionally use BGP
  - You could create UDR with a next hop type of *Virtual network gateway* (VPN gateway)

On a route table, you could define whether **virtual network gateway route propagation** should happen,
- If it's "Disabled", the on-prem routes (advertised via ER or VPN gateways) won't be propagated to NICs in the subnet.
- This shouldn't be disabled on the "GatewaySubnet".

![BGP](images/azure_bgp.svg)

### Route selection and priority

- If multiple routes are available for an IP address, the one with **the longest prefix match** is used. Eg. when sending message to `10.0.0.2`, route `10.0.0.0/24` is selected over route `10.0.0.0/16`
- You can't configure multiple UDRs with the same address prefix
- If multiple routes share the same prefix, route is selected based on this order of priority:
  - UDR
  - BGP routes (**So routes advertised by ExpressRoute gateway overrides vNetPeering ?**)
  - System routes

### NVA

![NVA](images/azure_nva.svg)

- NVAs are virtual machines that control the flow of network traffic by controlling routing
- You could use a **Windows/Linux VM** as an NVA, or choose NVAs from **providers in Azure Marketplace**, such as Check Point, Barracuda, Sophos, WatchGuard, and SonicWall
- Usually used to manage traffic flowing from a perimeter-network environment to other networks or subnets
- An NVA often includes various protection layers like:
  - a firewall
  - a WAN optimizer
  - application-delivery controllers
  - routers
  - load balancers
  - proxies
  - an SD-WAN edge
- Firewall could inspect all packets at OSI Layer 4 and possible Layer 7
- Some NVAs require **multiple network interfaces**, one of which is dedicated to the management network for the appliance
- You need to enable **IP forwarding** for an NVA, when traffic flows to the NVA but is meant for another target, the NVA will route the traffic to its correct destination
- NVAs should be deployed in a highly available architecture (eg. availability set in the diagram above)
- The `GatewaySubnet` ususally has UDR to route traffic to the NVA

Example: use a Linux VM as an NVA

```sh
# create a VM
az vm create \
    --resource-group my-rg \
    --name nva \
    --vnet-name vnet \
    --subnet dmzsubnet \
    --image UbuntuLTS \
    --admin-username azureuser \
    --admin-password <password>

# get NIC ID
NICID=$(az vm nic list \
    --resource-group my-rg \
    --vm-name nva \
    --query "[].{id:id}" --output tsv)

# get NIC name
NICNAME=$(az vm nic show \
    --resource-group my-rg \
    --vm-name nva \
    --nic $NICID \
    --query "{name:name}" --output tsv)

# enable IP forwarding on the NIC
az network nic update --name $NICNAME \
    --resource-group my-rg \
    --ip-forwarding true

# get NVA IP
NVAIP="$(az vm list-ip-addresses \
    --resource-group my-rg \
    --name nva \
    --query "[].virtualMachine.network.publicIpAddresses[*].ipAddress" \
    --output tsv)"

# enable IP forwarding within the NVA
ssh -t -o StrictHostKeyChecking=no azureuser@$NVAIP 'sudo sysctl -w net.ipv4.ip_forward=1; exit;'
```

### Autonomous systems

An Autonomous system (AS) is a large network or group of networks that uses a unique policy for routing. Each AS on the internet is registered and has its own pool of IP addresses. For example, an ISP's network, some university networks, some large companies, Azure network.

Each AS is registered under a specific name, called *ASN*. An ASN could be 16-bit (1 ~ 65534) or 32-bit (131072 ~ 4294967294)

Azure service has the AS number 65515.

Azure Route Server uses ASN to identify the peers with which it exchanges routing information.

### Route Server

When you add an ExpressRoute gateway, S2S VPN gateway, VNet peering, Service endpoints, private endpoints, the system routes in a vNet are updated automatically, but this does not happen for NVAs, you need to add them as UDRs manually.

Azure Route Server could help address this.

- Fully managed service that simplifies dynamic routing between your NVA and vNet (Software-defined network).
- It's not a router, it only exchanges routes, doesn't route/forward traffic or provide gateway functionalities.
- Supports connecting to SD-WAN when performing route exchange.
- You peer NVA with Route Server.
- Routes are exchanged using BGP protocol.
- Injects route to the route tables in the VNet (NICs in the VNet).
- NVAs could be in peered vNets.
- Branch-to-branch: whether routes should be exchanged between NVAs and ER gateways, this could effectively enable spoke-to-spoke traffic transit via a hub.

Requirements:

- Has to be in a dedicated subnet called "RouteServerSubnet", with at least a "/27" address space.
- It needs a public IP address to help ensure connectivity to the backend service that manages the Route Server configuration.

Drawbacks:

- Does not work with Azure Firewall, which does not talk BGP
- If you have a load balancer in front of multiple NVAs, route server can't propagate the load balancer IP as next hop

Behind the scenes:

- A VMSS with 2 VMs
- Each VM establish a BGP peer to an NVA

#### Usage scenarios

- With firewall and SD-WAN appliances, need to be configured as BGP peers

  ![Azure Route Server scenario NVAs](./images/azure_route-server-scenario-nvas.png)

- With network gateways, no need to configure peering, you should enable "Branch-to-branch" traffic

  ![Azure Route Server scenario expressroute and VPN gateways](./images/azure_route-server-scenario-expressroute-vpn-gateways.png)


#### Commands

```powershell
# get route learned from a peer
Get-AzRouteServerPeerLearnedRoute -RouteServerName TestARS -ResourceGroupName RG1 -PeerName NVA1 | Format-Table
```

  ![Azure Route Server learned routes](./images/azure_route-server-learned-routes.png)


### Forced tunneling

![Forced tunneling](images/azure_networking-forced-tunneling.png)

- Redirect all Internet-bound traffic back to your on-prem location via a S2S VPN tunnel for inspection and auditing.
- Can only be configured by Azure PowerShell, not in the Portal
- You to this by creating a route table, adding a UDR to the VPN Gateway
- The vNet must have a route-based VPN gateway, the on-prem VPN device must be configured using 0.0.0.0/0 as traffic selectors.

### Troubleshooting

To troubleshoot routing issues, you often need to check the effective routes of a network interface.
  - This requires `Microsoft.Network/networkInterfaces/effectiveRouteTable/action` permission.
  - You can only get this when the attached-to VM is running.

```sh
az network nic show-effective-route-table \
  --name nic-hub-workload \
  --resource-group rg-hub \
  -otable

# Source    State    Address Prefix    Next Hop Type      Next Hop IP
# --------  -------  ----------------  -----------------  -------------
# Default   Active   10.0.0.0/16       VnetLocal
# Default   Active   10.2.0.0/16       VNetPeering
# Default   Active   10.1.0.0/16       VNetPeering
# Default   Active   0.0.0.0/0         Internet
# Default   Active   10.0.0.0/8        None
# ...
# User      Active   10.1.1.0/24       VirtualAppliance   10.0.1.4
# Default   Invalid  10.1.1.4/32       InterfaceEndpoint
# Default   Invalid  10.1.1.5/32       InterfaceEndpoint
```


## Service endpoints

<img src="images/azure_vnet_service_endpoints_overview.png" width="600" alt="Service endpoints overview" />

- The purpose is to secure your network access to PaaS services (by default, all PaaS services have public IP addresses and are exposed to the internet), such as:

  - Azure Storage
  - Azure SQL Database
  - Azure Cosmos DB
  - Azure Key Vault
  - Azure Service Bus
  - Azure Data Lake

- A virtual network service endpoint provides the identity of your virtual network to an Azure service. You secure the access to an Azure service to your vNet by adding a virtual network rule. You could fully remove public Internet access to this service.

- After enabling a service endpoint, the source IP addresses switch from using public IPv4 addresses to using their private IPv4 address when communicating with the service from that subnet. This switch allows you to access the services without the need for reserved, public IP addresses used in Azure service IP firewalls.

- With service endpoints, DNS domain names for the PaaS services won't change, still resolves to public IP addresses. (**Different from private endpoints**)
  - When a service endpoint is created, **Azure actually creates routes in the route table to direct the traffic, keeping it within Microsoft network**. The route table would like:

    | SOURCE  | STATE  | ADDRESS PREFIXES        | NEXT HOP TYPE                     |
    | ------- | ------ | ----------------------- | --------------------------------- |
    | Default | Active | 10.1.1.0/24             | VNet                              |
    | Default | Active | 0.0.0.0./0              | Internet                          |
    | ...     | ...    | ...                     | ...                               |
    | Default | Active | 20.38.106.0/23, 10 more | **VirtualNetworkServiceEndpoint** |
    | Default | Active | 20.150.2.0/23, 9 more   | **VirtualNetworkServiceEndpoint** |

- Virtual networks and Azure service resources can be in the same or **different subscriptions**. Certain Azure Services (not all) such as Azure Storage and Azure Key Vault also support service endpoints across different Active Directory(AD) tenants.

- Service endpoint doesn't work with in on-prem scenarios, for on-prem clients, you need to
  - either setup ExpressRoute **public peering**
  - or add on-prem **NAT IPs** to the service's IP firewall

### Create

- On the service side, you need to add proper network rules

  ```sh
  # deny all network access
  az storage account update \
      --resource-group my-rg \
      --name my-storage-account \
      --default-action Deny

  # add network rule for the subnet
  az storage account network-rule add \
      --resource-group my-rg \
      --vnet-name my-vnet \
      --subnet my-subnet \
      --account-name my-storage-account
  ```

- On the vNet side, you need to:
    ```sh
    # enable service endpoint in a subnet
    az network vnet subnet update \
      --resource-group my-rg \
      --vnet-name my-vnet \
      --name my-subnet \
      --service-endpoints Microsoft.Storage

    # add NSG rule
    az network nsg rule create \
      --resource-group my-rg \
      --nsg-name nsg-demo-001 \
      --name Allow_Storage \
      --priority 120 \
      --direction Outbound \
      --source-address-prefixes "VirtualNetwork" \
      --source-port-ranges '*' \
      --destination-address-prefixes "Storage" \
      --destination-port-ranges '*' \
      --access Allow \
      --protocol '*' \
      --description "Allow access to Azure Storage"
    ```

### Service endpoint policies

![Service endpoint policies](images/azure_networking-vnet-service-endpoint-policies-overview.png)

- You could attach a policy to allow access only to
  - all storage accounts in a subscription
  - all storage accounts in a resource group
  - specified storage accounts
- Managed services other than Azure SQL Managed Instance are not currently supported with service endpoints.
- Managed Storage Accounts are not supported with service endpoint policies.

### Private endpoints vs. service endpoints

- Both solutions tackle the same issue: how to connect to a public PaaS service privately
- A service endpoint remains a publicly routable IP address, scoped to subnets, you need to do it in each subnet
- Private Endpoints allows you to connect to a service via a private IP address in a vNet, working for peered vNets and any connected on-prem network
- Private endpoint is the next evolution and usually preferrable


## Private Endpoints

See: [Azure networking - privatelink](./azure-networking-privatelink.markdown)


## Deploy Azure service to vNets

TODO


## Load balancing

HTTP(S) vs. Non-HTTP(S)

- **Non-HTTP(S)**: for non-web workloads
- **HTTP(S)**: Layer 7, SSL offload, WAF, path-based load balancing, session affinity

Global vs. regional:

- **Global**: distribute traffic across regional backends, clouds or hybrid on-prem services
- **Regional**: distribute traffic between VMs, containers, or clusters within a region in a vNet

| Service             | HTTP(S)/Non-HTTP(S) | Global/Regional | Features                                                            | Cons                                   |
| ------------------- | ------------------- | --------------- | ------------------------------------------------------------------- | -------------------------------------- |
| Load Balancer       | Non-HTTP(S)         | Regional        | Layer 4, TCP/UDP, zone-redundant                                    |                                        |
| Application Gateway | HTTP(S)             | Regional        | Layer 7, SSL offloading                                             |                                        |
| Front Door          | HTTP(S)             | Global          | Layer 7, SSL offloading, path-based routing, fast failover, caching |                                        |
| Traffic Manager     | Non-HTTP(S)         | Global          | DNS-based                                                           | can't failover as quickly as FrontDoor |

![Load balancing decision tree](images/azure_load-balancing-decision-tree.png)


## Azure Load Balancer

- Can be used with incoming internet traffic, internal traffic, port forwarding for specific traffic, or outbound connectivity for VMs
- Public load balancers
  - can only have public IPs
  - **not in a vNet**
  - provide outbound connections for VMs via NAT
- Internal load balancers
  - could have frontend IPs from **multiple subnets** in a vNet, but CAN'T be in multiple vNets

Example multi-tier architecture with load balancers

![Azure Load Balancer](images/azure_load-balancer.png)

### SKUs

| SKU                | Basic                                     | Standard (extra features)    |
| ------------------ | ----------------------------------------- | ---------------------------- |
| Health probe       | TCP, HTTP                                 | HTTPS                        |
| Back-end           | VMs in a single availability set or VMSS  | VMs or VMSS in a single vNet |
| Availability Zones | -                                         | Zone-redundant or zonal      |
| Secure by default  | Open by default, NSG optional             | Closed by default            |
| Outbound           | source network address translation (SNAT) | outbound rules               |

- Standard SKU is recommended
- VMs, availability sets, and VMSS can be connected to either Basic or Standart SKU LB, not both
- When public IPs are used, the SKU must match
- Availability zones
  - Zone-redundant (Need a zone redundant frontend IP)
    ![Zone redundant](images/azure_load-balancer-zone-redundant.png)
  - Zonal (Need zonal frontend IPs)
    ![Zonal](images/azure_load-balancer-zonal.png)


### Distribution modes

- The default is **Five-tuple hash** (Source IP, Source Port, Destination IP, Destination Port, Protocol)
  - Because source port changes for each session client might be redirected to a different VM for each session
- **Source IP affinity**, requests from a specific VM always go to the same VM
  - Could be three-tuple hash (Source IP, Destination IP, Protocol), or two-tuple hash (Source IP, Destination IP)
  - Could be used in cases like
    - Web app with in-memory sessions to store the logged in user's profile
    - Windows Remote Desktop Gateway
    - Media upload (In many implementations, there's a TCP connection, which remains open to monitor the progress, and a separate UDP session to upload the file)

## Application Gateway

### Overview

Features:

- Is a load balancer for web apps, supports HTTP, HTTPS, HTTP/2 and WebSocket protocols
- Works at application layer (OSI layer 7)
- Auto or manual scaling
- Support **redirection**: to another site, or from HTTP to HTTPS
- Rewrite HTTP headers
- Custom error pages
- Could be internet-facing (public ip) or internal only (private ip)

Benefits over a simple LB:

- Cookie affinity
- SSL termination
- Web application firewall (WAF): detailed monitoring and logging to detect malicious attacks
- URL rule-based routes: based on hostname and paths, helpful when setting up a CDN
- Rewrite HTTP headers: such as scrubing server names

### Components

![Application Gateway](images/azure_application-gateway.png)

![Application Gateway components](images/azure_application-gateway-components.png)

- **Frontend**
  - *It is actually a load balancer, and AGW instances are in its backend pool, so we need to allow AzureLoadBalancer in the NSG*
  - Could have a public IP, a private IP, or both
  - An AGW could have up to 125 instances
- **Listeners**
  - Defined by IP address (private or public), host name, port and protocol
  - Handle TLS/SSL certificates for HTTPS
  - Two types:
    - Basic: doesn't care host names, **each port can only have one basic listener**
    - Multi-site: you specify one or more host names, AGW matches incoming requests using **HTTP 1.1 `host` header**, each IP/port pair could have multiple multi-site listeners, and they are processed according to priority of associated routing rule ?
  - For v2 SKU, multi-site listeners are processed before basic listeners
  - A listener can have **only one** associated rule
  - You could redirect from one listener to another (eg. HTTP to HTTPS)
- **WAF**:
  - Checks each request for common threats: SQL-injection, XSS, command injection, HTTP request smuggling, crawlers, etc
  - Based on OWASP rules, referred to as Core Rule Set(CRS), you can opt to enable only specific rules
  - Could have exclusions
- **Backend pool**: a backend pool can contain one or more IP/FQDN, VM, VMSS and App Services
- **Rule**:
  - Maps one-to-one to a listener
  - Rule types:
    - **Basic**
    - **Path-based**: request is routed to the first-matching path, you should add a default one for any un-matched requests
  - Rule target types:
    - Backend pool: with HTTP settings
    - Redirection: to another listener or external site with a specified HTTP code, you can choose to include the original query string in redirection, but not the path in the original request
  - Each rule could have a rewrite rule set associated, it could rewrite:
    - Request headers
    - Response headers
    - URL components (path, query string)
- **Backend settings (aka. HTTP settings)**: backend port/protocol, cookie-based affinity, time-out value, path or hostname overriding, default or custom probe, etc
- **Health probes**
  - If not configured, a default probe is created, which waits for 30s before deciding whether a server is unavailable
  - If there are multiple listeners, each listener sends health probes independently
  - Each AGW instance sends health probes independently
  - The source IP address for health probes depends on the target
    - If the target is a public endpoint, then the source IP is the AGW's public IP
    - If the target is a private endpoint, then the source IP is from the AGW subnet's *private IP address space*

### How does routing works

1. If a request is valid and not blocked by WAF, the rule associated with the listener is evaluated, determining which backend pool to route the request to.
1. Use round-robin algorithm to select one healthy server from the backend pool.
1. Opens a new TCP session to the server based on HTTP settings. (If you want end-to-end TLS encryption, the traffic is **re-encrypted** when it travels from AGW to the back end)

If the target server is:
  - A private endpoint: AGW connects to it using its **instance private IP addresses**
  - A public endpoint: AGW uses its frontend public IP (one is assigned if public IP not exists)

AGW inserts six additional headers to all requests before it forwards the requests to the backend:

- `x-forwarded-for`: comma-separated list of IP:port
- `x-forwarded-port`: the listener port
- `x-forwarded-proto`: HTTP or HTTPS
- `x-original-host`
- `x-original-url`
- `x-appgw-trace-id`

Notes:

- AGW doesn't support port numbers in HTTP Host headers. As a result, the connection between AGW and the web server only supports TCP port 443, not non-standard ports.

- On using cert in a Key vault:

  If using Private Endpoints to access Key Vault, you **must link** the `privatelink.vaultcore.azure.net` private DNS zone, containing the corresponding record to the referenced Key Vault, to the virtual network containing Application Gateway. Custom DNS servers may continue to be used on the virtual network instead of the Azure DNS provided resolvers, however the private dns zone will need to remain linked to the virtual network as well.

### AGW subnet and NSG

See: https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure

An Application Gateway needs its own dedicated subnet:

- An AGW can have multiple instances, each has one private IP from the subnet
- Private front-end IP is taken from the subnet as well, eg. subnet range is `10.0.0.0/24`, `10.0.0.4` is the front-end IP, `10.0.0.5`, `10.0.0.6` are IPs of instances
- A subnet can host multiple AGWs
- You need to size this subnet appropriately based on the number of instances
  - V2 SKU can have max. 125 instances, /24 is recommended for the subnet

Suggested NSG for the subnet (See: https://aidanfinn.com/?p=21474):

| Source                | Dest           | Dest Port                                  | Protocol | Direction | Allow | Comment                                                                            |
| --------------------- | -------------- | ------------------------------------------ | -------- | --------- | ----- | ---------------------------------------------------------------------------------- |
| Internet or IP ranges | Any            | eg. 80, 443                                | TCP      | Inbound   | Allow | Allow Internet or specified client and ports                                       |
| GatewayManager        | Any            | 65200-65535 (v2 SKU), 65503-65534 (v1 SKU) | TCP      | Inbound   | Allow | Azure infrastructure communication, protected by Azure certificates                |
| AzureLoadBalancer     | Any            | *                                          | *        | Inbound   | Allow | Required                                                                           |
| VirtualNetwork        | VirtualNetwork | *                                          | *        | Inbound   | Allow | AllowVirtualNetwork                                                                |
| Any                   | Internet       | *                                          | *        | Outbound  | Allow | A default outbound rule, required (eg. connection back to clients), don't override |
| Any                   | Any            | *                                          | *        | Inbound   | Deny  | Deny everything else, overridding default rules                                    |

**V2 limitations**:

- Even all clients are on-prem or in Azure, conneting only to the private front-end IP of the AGW, it still needs a public IP for control plane management, `GatewayManager` always connects to this public IP, see: https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-private-deployment, and the default route to `0.0.0.0/0` can only go to `Internet` for this to work


### CLI

```sh
# create a public ip with DNS label
az network public-ip create \
  --resource-group myRG \
  --name appGatewayPublicIp \
  --sku Standard \
  --dns-name myapp${RANDOM}

# create an AGW with the public ip
az network application-gateway create \
  --resource-group myRG \
  --name myAppGateway \
  --sku WAF_v2 \
  --capacity 2 \
  --vnet-name myVnet \
  --subnet appGatewaySubnet \
  --public-ip-address appGatewayPublicIp \
  --http-settings-protocol Http \
  --http-settings-port 8080 \
  --private-ip-address 10.0.0.4 \
  --frontend-port 8080

# create a backend pool of VMs
az network application-gateway address-pool create \
  --gateway-name myAppGateway \
  --resource-group myRG \
  --name vmPool \
  --servers 10.0.1.4 10.0.1.5

# create a backend pool of app service
az network application-gateway address-pool create \
    --resource-group myRG \
    --gateway-name myAppGateway \
    --name appServicePool \
    --servers myapp.azurewebsites.net

# create a front-end port
az network application-gateway frontend-port create \
    --resource-group myRG \
    --gateway-name myAppGateway \
    --name port80 \
    --port 80

# create a listener
az network application-gateway http-listener create \
    --resource-group myRG \
    --name myListener \
    --frontend-port port80 \
    --frontend-ip appGatewayFrontendIP \
    --gateway-name myAppGateway

# health probe
az network application-gateway probe create ...
# add http settings
az network application-gateway http-settings create ...

# path-based routing
az network application-gateway url-path-map create ...
# add a rule to the map
az network application-gateway url-path-map rule create ...

# create a routing rule
az network application-gateway rule create \
    --resource-group myRG \
    --gateway-name myAppGateway \
    --name appServiceRule \
    --http-listener myListener \
    --rule-type PathBasedRouting \
    --address-pool appServicePool \
    --url-path-map urlPathMap
```


## Traffic Manager

- Works at the DNS level which is at the Application layer (Layer-7)
- Supports built-in endpoint monitoring and automatic endpoint failover
- Is not a gateway or proxy, it does not see the traffic between the client and the service
- Allows DNS record TTL as low as 0

Comparing to Load Balancer:

|                 | Use                                                                                     | Resiliency                                                                                                   |
| --------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Load Balancer   | makes your service **highly available** by distributing traffic within the same region  | monitor the health of VMs                                                                                    |
| Traffic Manager | works at the DNS level, directs the client to a preferred endpoint, **reduces latency** | monitors the health of endpoints, when one endpoint is unresponsive, directs traffic to the next closest one |

### DNS resolution example

![Traffic Manager name resolution example](images/azure_traffic-manager-dns-configuration.png)
![Client usage flow](images/azure_traffic-manager-client-usage-flow.png)

- Your public facing domain name `partners.contoso.com` CNAME to a Traffic Manager domain name `contoso.trafficmanager.net`
- According to the traffic-routing rule, Traffic Manager responds with another CNAME (not the final IP)
- Your DNS server resolves the CNAME (`contoso-eu.cloudapp.net` in above example) to an IP

### Traffic-routing methods

- **Priority routing**: choose an healthy one with the highest priority
  ![Traffic Manager priority routing](images/azure_traffic-manager-routing-method-priority.png)
- **Weighted routing**: pick a random endpoint, based on the weights, the endpoint with the highest weight gets most hits
- **Performance routing**
  ![Traffic Manager performance routing](images/azure_traffic-manager-routing-method-performance.png)
  - Traffic manager maintains an internet latency table by tracking the roundtrip time **between IP address ranges and each Azure datacenter, NOT latency to the actual endpoints !**
  - You need to specify the region for each endpoint
  - The one with lowest latency is chosen based on the query source IP and the region of the endpoints
- **Geographic routing**: choose a designated geo endpoint based on DNS query's source IP address
- **Subnet routing**: static mapping from DNS query's source IP ranges to endpoints
- **Multivalue routing**: when you have only IPv4/IPv6 addresses as endpoints, all healthy IPs are returned, client chooses one to connect

### Nested profiles

Within one Traffic Manager profile, you can use only one traffic-routing method.

You could have nested Traffic Manager profiles, to combine multiple routing methods to create sophisticated and flexible rules.

![Nested Traffic Manager profiles](images/azure_traffic-manager-nested-profiles.png)


## Front Door

![Front door](images/azure_front-door.png)
![Front door split TCP](images/azure_frontdoor-split-tcp.png)

It's like the Application Gateway at a global scale, plus a CDN
  - works at layer 7 using **anycast** protocol with **split TCP**
  - operates at the edge, not within a vNet
  - resilient to failures to an entire Azure region
  - can cache content
  - a backend can be within or outside Azure

Supports:
  - URL-path based routing
  - health probe: determines the **proximity** and health of each backend
  - cookie-based session affinity
  - SSL offloading
  - WAF
  - URL redirect/rewrite
  - Caching: like a CDN

```sh
az extension add --name front-door

az network front-door create \
  --resource-group myRG \
  --name gary-frontend \
  --accepted-protocols http https \
  --backend-address webapp1.azurewebsites.net webapp2.azurewebsites.net
```

## CDN

- Get content to users in their local region to **minimize latency**
- Can be hosted by Azure or other providers
- Standard Microsoft tier has less features than Akamai and Verizon CDNs
- Asset TTL is determined by the `Cache-Control` header from the origin server, if not set, Azure sets a default value. This can be changed by caching rules.
- In Standard Microsoft tier, you can't set specific caching rules for a file, if you do not want to cache a file, you should set the **`Cache-Control` to be `no-cache` in the origin server**
  - Since it's not cached by CDN, CDN won't compress it as well, so if you would like to serve a compressed version, you need to put the compressed file in the origin Blob storage, and set the `ContentEncoding: gzip` on it

    ```sh
    gzip /path/to/file
    mv /path/to/file.gz /path/to/file

    azcopy copy /path/to/file <Blob-storage-path> \
                --cache-control 'no-cache' \
                --content-encoding 'gzip'
    ```

### Standard rules engine notes

The rules engine rules are not so easy to debug, the rules takes quite a while to take effect, and the doc is not so detailed or seems to be wrong in some cases.

- https://docs.microsoft.com/en-us/azure/cdn/cdn-standard-rules-engine-match-conditions#url-file-name says multiple file names can be separated with a single space, but
  - If URL file name 'Contains' 'xxx yyy' => matches 'https://garytest.azureedge.net/xxx%20yyy' instead of 'https://garytest.azureedge.net/xxx'
- Some of the operators are numeric, like *Less than* or *Greater than*, example:
  - If URL file name 'Greater than' '6' => matches 'https://garytest.azureedge.net/verylongname'
  - If URL file extension 'Less than or equals' '0' => matches any url without a file extension, eg. 'https://garytest.azureedge.net/foo'
- The doc says *Equals* is a numeric operator, but:
  - If URL path 'Equals' '/abc' => matches 'https://garytest.azureedge.net/abc', does not work if you set a number
- URL path matches the whole path

### Custom domain HTTPS

Although Azure Vault supports both `.pem` and `.pfx` formats for certificates, when you load it to Azure CDN, only the `.pfx` format is supported (it includes the private key, which is needed in CDN), to convert a certificate from `.pem` to `.pfx`:

```sh
openssl pkcs12 -export -out server.pfx -inkey server.key -in server.crt -certfile root_or_intermediary_cert.crt
```

See:
- https://blog.neilsabol.site/post/azure-cdn-custom-https-secret-contains-unsupported-content-type-x-pkcs12/


## DNS

### Overview

Concepts:

- **DNS Zone** corresponds to a domain name, parent and children zones could be in different resource groups
- A **record set** is a collection of records in a zone that have the same name and type, e.g.
  - multiple IP addresses for name 'www' and type 'A'
  - "CNAME" record sets can only have one record at most

Features:

- Split-horizon DNS support: allows the same domain name to exist in both private and public zones, so you could have a private version of your services within your virtual network.

- Alias record sets: allows you to setup alias record to direct traffic to an Azure public IP address(load balancer), an Azure Traffic Manager profile, or an Azure CDN endpoint.
  - It's a dynamic link between a record and a resource, so when the resource's IP changes, it's automatically handled;
  - Supports these record types: A, AAAA, CNAME;

Missing features:

- No conditional forwarding and no query logging
  - You need to Bring-Your-Own DNS service, and conditionally forward queries to Azure DNS

### DNS resolution within virtual networks

There are a few options:

- Azure DNS private zones
- Azure-provided name resolution
- Your own DNS server
- Azure DNS Private Resolver (*replaces setting up your own DNS servers*)

### Azure-provided name resolution

Example (a VM `vm-demo-001` in a vNet)

```sh
hostname --fqdn
# vm-demo-001.bkz3n5lfd3kufhikua4wl40kwg.px.internal.cloudapp.net

hostname --all-fqdns
# vm-demo-001.internal.cloudapp.net

# get DNS Server name (not the local 127.0.0.1:53)
systemd-resolve --status
# ...
# DNS Servers: 168.63.129.16
# DNS Domain: bkz3n5lfd3kufhikua4wl40kwg.px.internal.cloudapp.net

# OR
resolvectl status eth0
# Link 2 (eth0)
#       Current Scopes: DNS
#   Current DNS Server: 168.63.129.16
#          DNS Servers: 168.63.129.16

nslookup -type=PTR 10.0.0.4
# Non-authoritative answer:
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.internal.cloudapp.net.

# after you link private DNS zone `example.private` to the vNet with auto-registration
nslookup -type=PTR 10.0.0.4
# Non-authoritative answer:
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.internal.cloudapp.net.
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.example.private.

# change hostname
hostnamectl set-hostname vm-demo-001.newdomain.com
```

- DNS IP is `168.63.129.16`, this is static, same in every vNet
- The IP is assigned to NICs for DNS by the default Azure DHCP assignment
- The domain name is `.internal.cloudapp.net.`
- Any VM created in the vNet is registered
- It's the Azure Resource name that is registered, not the name of the guest OS on the VM
  - *Tested in Ubuntu, if you update VM hostname, the DNS record updates automatically*
- DNS names can be assigned to both VMs and network interfaces
- PTR queries return FQDNs of form
  - `[vm].internal.cloudapp.net.`
  - `[vm].[privatednszonename].` (when private DNS zone linked to the vNet, and auto-registration enabled)
- See here for client side DNS caching(`dnsmasq`) and retry configs: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances#dns-client-configuration

Considerations:

- Scoped to vNet, a DNS name created in one vNet can't be resolved in another vNet
- You should use a unique name for each VM in a vNet to avoid conflicts
- WINS and NetBIOS are not supported, you cannot see your VMs in Windows Explorer

### Private DNS zones

You could link a Private DNS Zone to a vNet (not subnet), enable auto-registration, then hostname of any VMs in the vNet would be registered in this Private DNS Zone

- Note
  - They are global, could be accessed from any region, sny subscription, any tenant.
  - A zone can be linked to multiple vnets
  - A vnet can have **ONLY ONE** registration zone, but can have multiple resolution zones, even your vnet is configured with custom DNS servers, the auto-registration still happens

- Scoped to a single vNet

  ![Private DNS lookup](images/azure_private-dns-1.png)

  ```sh
  dig vm1
  # vm1.                    0       IN      A       10.0.0.4

  # reverse lookup (PTR)
  dig -x 10.0.0.4
  # 4.0.0.10.in-addr.arpa.  10      IN      PTR     vm1.internal.cloudapp.net.
  # 4.0.0.10.in-addr.arpa.  10      IN      PTR     vm1.gary.com.
  ```

- For multiple vNets

  ![Name resolution for multiple vNets](images/azure_private-dns-multiple-vnets.png)

  - Both vNets are linked to the private DNS zone
  - Auto registration enabled for vNet1, disabled for vNet2 (you could still add entries manually)
  - DNS queries resolve across vNets, reverse queries are scoped to the same vNet
  - To make reverse lookup work across multiple vNets, you can create a reverse lookup zone `in-addr.arpa`, link it to multiple vNets, and manage the records yourself

  On a VM in vNet2:

  ```sh
  # you could resolve vm1
  dig vm1.gary.com
  # vm1.gary.com.           10      IN      A       10.0.0.4

  # reverse query (PTR) works in the same vNet
  dig -x 10.1.0.4
  # 4.0.1.10.in-addr.arpa.  10      IN      PTR     vm2.internal.cloudapp.net.

  # reverse query doesn't work across vNets, getting 'NXDOMAIN' error
  dig -x 10.0.0.4
  # ;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 4990
  # ;4.0.0.10.in-addr.arpa.         IN      PTR
  ```

### Your own DNS server

- You could configure custom DNS servers at both vnet level and VM NIC level (takes precedence, if not specified, NIC inherits DNS settings from vnet)

- After custom DNS servers are configured, your VM won't get the `.internal.cloudapp.net` DNS suffix anymore, it gets a non-functioning placeholder `reddog.microsoft.com`

- If you change the custom DNS servers, you need to perform DHCP lease renewal on all affected VMs in the vNet, for Windows VMs, you could do it by `ipconfig /renew`

- You could configure your custom DNS to forward to Azure-provided DNS to resolve hostnames

- Or, you could use Dynamic DNS (DDNS) to register VM hostnames in your DNS server
  - Non-domain-joined Windows VMs attempt DDNS updates when they boot, or IP changes. DNS name is the hostname, you could set primary DNS suffix in the VM
  - Domain-joined Windows VMs register their IP using DDNS. The domain-join process sets the primary DNS suffix on the VMs.
  - Linux clients generally don't register themselves with the DNS server on startup, they assume the DHCP server does it. Azure's DHCP servers do not have the credentials to register records in your DNS server. You can use a tool called `nsupdate`


```sh
systemd-resolve --status
# Link 2 (eth0)
#       Current Scopes: DNS
#        LLMNR setting: yes
# MulticastDNS setting: no
#       DNSSEC setting: no
#     DNSSEC supported: no
#          DNS Servers: 172.16.0.10
#           DNS Domain: reddog.microsoft.com
```

Even with custom DNS configured, the VM host name is still **registered** to auto-registration-enabled private DNS zones:

```sh
nslookup -type=PTR 10.0.0.4 168.63.129.16
Server:         168.63.129.16
Address:        168.63.129.16#53

Non-authoritative answer:
4.0.0.10.in-addr.arpa   name = vm-demo-001.internal.cloudapp.net.
4.0.0.10.in-addr.arpa   name = vm-demo-001.example.private.
```

### CLI

```sh
az network private-dns zone list
    --output table

az network private-dns record-set list \
    -g <resource-group> \
    -z <zone-name> \
    --output table
```

## Azure Firewall

Firewall in a hub-spoke network:

![Azure Firewall](images/azure_firewall-overview.png)

More detailed:

![Azure Firewall architecture](images/azure_firewall-hub-spoke.png)

- Typically deployed on a **central vNet**, so you can centrally create, enforce, and log application and network connectivity policies **across subscriptions and virtual networks**
- Needs a dedicated subnet
- Uses **one or multiple static public IP** addresses, so outside firewalls can identify traffic originating from your vNet
- Built-in high availability (no need to configure additional load balancers), and can span multiple availability zones
- Inbound and outbound filtering rules
- Inbound Destination Network Address Translation (DNAT)
- Outbound SNAT support
- Is **stateful**, analyzes the complete context of a network connection, not just an individual packet
- Forced tunneling: route internet-bound traffic through an NVA
- You should use it along with NSG and WAF

By default, all traffic is blocked, you can configure:

- **DNAT rules**:
  - Translate firewall public IP/port to a private IP/port, could be helpful in publishing SSH, RDP, or non-HTTP/S applications to the Internet
  - **must be accompanied by a matching network rule**
  - Limitations:
    - Doesn't work for private IP destinations (ie. spoke to spoke, on-prem to spoke)
    - In addition to DNAT, inbound connections via public IP are always SNATed to one of the firewall private IPs. (For HTTP/s traffic, Azure Front Door or Application Gateway in front of the firewall could preserve the original client IP in `X-Forwarded-For` header)
- **Network rules**:
  - Apply to **non-HTTP/S traffic** that flow through the firewall, including traffic from one subnet to another
  - Inbound/outbound filtering rules by source, destination, port and protocol(TCP, UDP, ICMP or any), it can distinguish legitimate packets for different type of connections
  - Also support **FQDN-based limits** to more precisely control egress traffic that application rules don't handle, this feature requires that DNS proxy is enabled. A common use is limiting Network Time Protocol (NTP) traffic to known endpoints, such as `time.windows.com`
- **Application rules**:
  - Does not apply to inbound traffic
  - Only allow a list of specified FQDNs for outbound HTTP/S or Azure SQL traffic to a specified list of FQDN including wild card. Does not require TLS termination.
    - For HTTP, matches the **"Host" header**
    - For HTTPS, matches according to **Server Name Indication**
  - Could use FQDN tags: Windows Update, Azure Backup, App Service Environment
- **Threat Intelligence**
  - Alert/deny traffic from known malicious IP and domains

Network rules are processed before application rules

DNS proxy:
- Azure Firewall could be used as a DNS proxy, this enables FQDN-based network rules
- Supports DNS request logging

Premium SKU only:
- TLS inspection
- IDPS: Intrusion Detection and Prevention System

### Asymmetric routing

![Azure Firewall asymmetric routing](images/azure_networking-firewall-asymmetric_routing.png)

- Under the hood, Azure Firewall has a public ALB and a internal ALB
- You want traffic from spoke to a shared service in the CommonServices subnet in hub to be filtered by Firewall
- The UDR rule in red could cause asymmetric routing, inbound traffic goes via instance `.7`, but return traffic goes via instance `.6`
- The UDR rule in spoke should not include the Firewall subnet, set the prefix to `192.168.1.0/24`, instead of the whole hub address space

### Azure Firewall Manager

![Firewall manager overview](images/azure_firewall-manager.png)

In a large network deployment, you could have multiple firewall instances in hub vNets and secured virtual hubs, Azure Firewall Manager helps to manage rules across all the instances.

- A central view of security services (Azure Firewall, WAF, DDoS etc) in **multiple regions and subscriptions**
- Hierarchical policies:
  - Central IT author global policies
  - DevOps team could author local firewall rules for better agility
- For secured vHubs only:
  - Third-party security-as-a-service integration, they use Firewall Manager's API to set up security policies (currently supports zScaler, iBoss, Check Point)
  - Centralized route management: easily route traffic to your secured hub for filtering and logging without the need to manually setup UDR on spoke vNets

### Firewall policy

- Created in Firewall Manager
- Not only security policies, can have **routing policies as well**.
  - User-defined routes aren't needed to route traffic through the firewall.
- Policy organization: Firewall Policy resource -> Rule Collection Group -> Rule Collection -> rule, each collection contains rules of a single type:
  - DNAT rules
  - Network rules
  - Application rules
- Other settings:
  - Threat Intelligence
- Is global resource
  - Works across regions and subscriptions
  - Can be used by multiple Azure Firewall instances
- Could be inherited:
  - Allows DevOps to create local firewall policies on top of organization mandated base policy

![Firewall policies](images/azure_firewall-manager-policies.png)


## Web Application Firewall (WAF)

- Centralized, inbound protection for your web applications agains common exploits and vulnerabilities, like SQL injection, XSRF, etc
- Can also protect against L& DDos attaches, such as HTTP Floods
- Unlike WAF Config, a WAF policy resource can be shared across multiple instances of a service
- Can be deployed with **Application Gateway**, **Front Door** and **CDN** services, have different resource types:
  - AGW: `Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies`
  - Front Door: `Microsoft.Network/FrontDoorWebApplicationFirewallPolicies`
  - CDN: `Microsoft.Cdn/cdnWebApplicationFirewallPolicies`
- Two modes: Detection and prevention
- Can be managed Firewall Manager

### WAF Config (legacy)

- Not independent resources, `properties.webApplicationFirewallConfiguration` of an AGW
- Should be upgraded to a WAF policy
- When transition from WAF Config to WAF Policy, then the policy needs to be an exact copy of your config
  - Or you can enable "Force" mode (`properties.force_firewall_policy_association`), which will allow you to associate any WAF Policy, even if it doesn't match exactly

### WAF policy on AGW

- Can only be associated to AGW of **WAF_v2** SKU
- A policy includes settings for managed rules, custom rules, exclusions, file upload limit, etc
- A WAF policy can be associated to
  - AGW (global)
  - a listener (per-site)
  - a path-based rule (per-URI)
- A AGW can have only one WAF policy associated
- A WAF policy must be in the **same region and subscription** as the associated AGW
- You can config **log scrubbing rules** to mask sensitive data in WAF logs

#### Custom rules

- Processed before managed rules, **if a custom rule allows a request, NO managed rules will be processed**
- Two types:
  - Match
    - Conditions: IP address, Geo location, Request (method, URI, headers, cookies, body, query string, post args)
  - Rate limit:
    - All the MatchRule conditions can be used, so you can create rate limit rule just for a paticular URI, header, etc
    - Can be grouped by client address and geo location
    - Action can only be "Block" or "Log" (*"Allow" is not necessary*)
    - Using a sliding windows algorithm, traffic exceeding the limit is dropped in each window
- Once a rule is matched, the action will be applied, lower priorities rules will not be processed

#### Managed rules

- Hierarchy: Rule set -> rule group -> rule
- Rulesets:
  - OWASP CRS 3.x
    - Cross-site scripting
    - Java attacks
    - Local file inclusion
    - PHP injection attacks
    - Remote command execution
    - Remote file inclusion
    - Session fixation
    - SQL injection protection
    - Protocol attackers
  - DRS (Default Rule Set) 2.x: based on CRS, with additional Microsoft Threat Intelligence Collection rules
  - BotProtection Rule Set
- OWASP 3.x and DRS use **Anomaly Scoring mode**, each rule has a severity level and a corresponding anomaly score, when the total score is 5 or greater, the request is either blocked (in Prevention mode) or logged (in Detection mode)
- You can optionally enable bot protection rule set
  - Three bot categories: "Bad", "Good", "Unknown"
- Some managed rules can cause false positives and block real traffic, you can customize them by
  - Disable selected rule or rule groups
  - Change action to "Log"
  - Add exclusions based on request variables, exclusion could be applied globally or to a rule set, rule group or rule
- To trigger blocking by managed rules, you can use `curl -I "http://<IP-address>/?1=1"`, this triggers both IP as hostname and SQL injection rules


## DDoS Protection

![DDoS Protection](images/azure_ddos-protection.png)

- Basic: Free, part of your Azure subscription
- Standard:
  - Protection policies are tuned through dedicated traffic monitoring and machine learning algorithms
  - Policies are applied to public IP addresses associated to resources deployed in virtual networks, such as VMs, Azure Load Balancer, AGW and Azure Fabric instances
  - Does NOT apply to App Service Environments

Types of DDoS attack:

- Volumetric attacks
  - Flood the network layer with a substantial amount of seemingly legitimate traffic
  - UDP floods, amplification floods, spoofed-packet floods
- Protocol attacks:
  - exploits weakness in layer 3 and layer 4 protocol stack
  - SYN flood attacks, reflection attacks and other protocol attacks
- Application layer attacks
  - target web application packets
  - HTTP protocol violations, SQL injection, cross-site scripting
  - WAF should be used to provide defense against these attacks


## Azure Virtual Network Manager

- Scope: A manager instance could be created at a paticular scope: a management group or subscription, then you could target all vnets within the scope
  - So a vnet could be targeted by multiple manager instances
- Cost: you pay per subscription per AVNM instance, so if a subscription is included in two AVNM instances, you pay for it twice
- Entities: Network Groups, Configurations (Connectivity or Security Admin)

Connectivity:

- Allows you to deploy a topology(hub-spoke or mesh) to network groups, saving you time to create and manage the peerings one by one
- For the Hub-Spoke topology, every vnet in a network group is peered to the hub, you could also enable
  - Direct Connectivity: all vnets in the same region and network group can talk to each other directly (**This is NOT done by peerings, a route with "ConnectedGroup" type is added to the effective routes**)
  - Global Mesh: each vnet in the same network group can talk to all other vnets, regardless of regions
- For the mesh topology
  - Also uses the "ConnectedGroup" type route, not by peerings
  - By default it's mesh within regions, **across network groups**
  - You could turn on global mesh
- If you add/remove vnets in a group, connectivity gets updated automatically (seems done by Azure Policy ?)
- If the connectivity settings are updated, you need to redeploy

Security Admin rules:

- Similar to NSGs, but target at vnets level
- They are populated to all NICs within the vnets
- They are checked before NSGs
- Rules from manager instances with a higher scope level are checked first
- A rule has three possible actions: "Allow", "Deny", "Always allow", if it's "Always allow", rules from lower level manager instances and NSGs are ignored

![Security admin rules evaluation](./images/azure_networking-virtual-network-manager-security-admin-rules.png)


## Network Watcher

A combination of network monitoring and diagnostic tools.

- Monitoring
  - **Topology**: graphical display of a vnet, its subnets, associated NICs, NSGs, route tables, etc
    ![Network topology](images/azure_network-watcher-topology.png)
  - **Connection Monitor**: monitor connectivity and latency between a VM and another network resource
    - Azure VM: need to install Network Watcher extension
    - On-prem machines: Log Analytics agent
    - Connection monitor resource must be in the same region as the source endpoint
  - **Network Performance Monitor**: going to be replaced by *Connection Monitor*

- Diagnostic tools
  - **Effective security rules**: all effective NSG rules applied to a network interface
  - **Next hop**: for a given VM IP and dest IP, shows you the next hop, helps troubleshoot routing table issues
  - **Packet capture**: records all of the packets sent to and from a VM, depends on *Network Watcher Agent VM Extension* (automatically installed when you start a capture session)
  - **VPN troubleshoot**: troubleshoots virtual network gateways or connections
  - **IP flow verify**
  - **NSG diagnostics**
  - **Connection troubleshoot**: an amalgamation of 4 diagnostic tests: "Connectivity", "NSG diagnostic", "Next hop", "Port scanner", you could choose which ones to run

  Compare these three tools:

  |            | IP flow verify                                 | NSG diagnostics                                                                              | Connection troubleshoot                                            |
  | ---------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
  | Parameters | target VM NIC, packet details(5-tuple, in/out) | VM/NIC/VMSS/AGW, protocol, in/out, source IP/CIDR, dest IP, dest port                        | source(VM/VMSS/AGW/Bastion), dest(VM/FQDN/IP), TCP/ICMP, dest port |
  | What       | NSG rules for **one VM NIC**                   | NSGs on both NIC and subnet (*only on the VM/NIC you are checking, not the other end*)       | NSG, connectivity, next hop                                        |
  | How        | logical only                                   | logical only                                                                                 | real connection                                                    |
  | Result     | the denying rule                               | **rules applied in each NSG** and final allow/deny status                                    | latency and **every hop** in the route                             |
  | Note       | n/a                                            | source could be a CIDR, service tag or wildcard(\*), target IP and port could be wildcard(*) | like Connection Monitor, but only check the connection once        |

- Connection troubleshoot

  - This is the recommended way to test connectivity, as it covers other tools
  - In some cases, a successful connectivity test does not mean you could connect to the service:
    - eg. a connectivity test to `sql-temp-001.database.windows.net:1433` might be successful, but the SQL Server's firewall could block the actual connection

- Logging
  - NSG Flow Logs: log all traffic in your NSGs (a sub-resource under Network Watcher), does not support private endpoints, logs saved in a storage account
  - Traffic Analytics: ingest logs to Log Analytics, help query/visualize your NSG Flow Log data
    ![Traffic analytics data flow](images/azure_traffic-analytics.png)

### Auto creation

- A NetworkWatcher resource is created automatically when you create or update a virtual network, in the same region as the vNet, it is placed in a resource group called `NetworkWatcherRG`, there is a subscription feature called `Microsoft.Network/DisableNetworkWatcherAutocreation`
- When you use a NetworkWatcher feature on a VM without the `AzureNetworkWatcherExtension` extension, it's installed to the VM automatically
- There are also built-in policies regarding this, see [Azure Policy note](./azure-policy.markdown)


## Network design considerations

- Segmentation:

  Some resources need their own virtual network or subnet, eg. both Application Gateway and VPN Gateway need a dedicated subnet, multiple gateways can be hosted in the same subnet

- Security

  - Whenever possible, ONLY associate NSGs to subnets, NOT on a network interface
  - When VMs within a subnet need different security rules, use application security groups
  - Network security controls:
    - NS-1: Establish network security boundaries
      - vNets and subnets
    - NS-2: Secure cloud services with network controls
      - private link
      - vNet integration
    - NS-3: Deploy firewall at the edge of enterprise network
    - NS-4: Deploy intrusion detection/prevention systems
    - NS-5: Deploy DDoS protection
    - NS-6: Deploy web application firewall
      - at AGW, Front Door, CDN
      - built-in ruleset, such as OWASP Top 10
    - NS-7: Simplify network security configuration
      - Microsoft Defender for Cloud Network
      - Azure Firewall Manager: centralize firewall policy, NSG and route management
    - NS-8: Detect and disable insecure services and protocols
    - NS-9: Connect on-prem or cloud network privately
      - ExpressRoute, virtual WAN, VPN
    - NS-10: DNS security
      - Azure recursive DNS
      - Azure Private DNS
      - Azure Defender for DNS
      - Azure Defender for App Service to detect dangling DNS records

- IP addressing

  - vNet CIDR range can't be larger than /16
  - vNet address space shouldn't be overlapping with on-premises ranges

- Subnet

  - Azure retains 5 IP addresses from each subnet
  - The smallest subnet you can create is /29, with 3 usable addresses


## Networking architecutres

- Site-to-site VPN

  ![Reference architecture site-to-site VPN](images/azure_networking-reference-architecture-site-to-site-vpn.svg)

- ExpressRoute

  ![Reference architecture ExpressRoute](images/azure_networking-reference-architecture-expressroute.svg)

- ExpressRoute with VPN failover

  ![Reference architecture ExpressRoute with VPN failover](images/azure_networking-reference-architecture-expressroute-with-vpn-failover.svg)

- Hub-spoke

  ![Reference architecture Hub-spoke](images/azure_firewall-hub-spoke.png)


## Hub-spoke architecture

![Shared services in hub network](images/azure_networking-hub-shared-services.svg)

- Shared services in hub vnet: ExpressRoute Gateway, Management, DMZ, AD DS, etc
- Hub and each spoke could be in different subscriptions


## Firewall and Application Gateway integration patterns

See: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway

- In parallel

  ![Firewall and AGW parallel - ingress](images/azure_networking-firewall-agw-parallel-ingress.png)

  *HTTP/S traffic ingress via AGW*

  ![Firewall and AGW parallel - egress](images/azure_networking-firewall-agw-parallel-egress.png)

  *Traffic egress via Firewall*

  ![Firewall and AGW parallel - on-prem ingress](images/azure_networking-agw-firewall-onprem-clients.png)

  *Traffic ingress from on-prem*

  - For Non-HTTP(S) traffic, `GatewaySubnet` needs UDR to route it to the Firewall

- AGW before firewall

  ![AGW before firewall](images/azure_networking-agw-before-firewall.png)

  - Original client IP can be preserved in the `X-Forwarded-For` header added by AGW
  - Traffic can be encrypted end-to-end, Firewall can still inspect the en

- Firewall before AGW

  ![Firewall before AGW](images/azure_networking-firewall-before-agw.png)

  - Limited benefits, don't recommend
  - Application can't get original client IP, since Azure Firewall does DNAT and SNAT, unless you have Azure Front Door before the Firewall, which adds the `X-Forwarded-For` header
