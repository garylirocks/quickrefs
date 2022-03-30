# Azure Networking

- [Overview](#overview)
- [Virtual networks](#virtual-networks)
  - [Subnets](#subnets)
  - [IP addresses](#ip-addresses)
  - [CLI](#cli)
- [Network security group (NSG)](#network-security-group-nsg)
  - [Azure platform considerations](#azure-platform-considerations)
  - [Virtual IP of the host node](#virtual-ip-of-the-host-node)
    - [`168.63.129.16`](#1686312916)
- [Network Peering](#network-peering)
  - [CLI](#cli-1)
- [VPN](#vpn)
  - [Site to site](#site-to-site)
  - [Point to site](#point-to-site)
- [ExpressRoute](#expressroute)
  - [Virtual WAN](#virtual-wan)
- [Routing](#routing)
  - [System routes](#system-routes)
  - [User-defined routes](#user-defined-routes)
  - [BGP](#bgp)
  - [Route selection and priority](#route-selection-and-priority)
  - [NVA](#nva)
- [Azure Firewall](#azure-firewall)
  - [Web Application Firewall (WAF)](#web-application-firewall-waf)
- [DDoS Protection](#ddos-protection)
- [Private Endpoints](#private-endpoints)
- [Service endpoints](#service-endpoints)
- [Azure Load Balancer](#azure-load-balancer)
  - [SKUs](#skus)
  - [Distribution modes](#distribution-modes)
- [Application Gateway](#application-gateway)
  - [How does routing works](#how-does-routing-works)
  - [AGW subnet and NSG](#agw-subnet-and-nsg)
- [Traffic Manager](#traffic-manager)
- [Front Door](#front-door)
- [CDN](#cdn)
  - [Standard rules engine notes](#standard-rules-engine-notes)
  - [Custom domain HTTPS](#custom-domain-https)
- [DNS](#dns)
  - [Private DNS zones](#private-dns-zones)
  - [CLI](#cli-2)
- [Networking architecutres](#networking-architecutres)
- [Hub-spoke architecture](#hub-spoke-architecture)

## Overview

- Logically isolated network
- Scoped to a single region
- Can be segmented into one or more *subnets*
- Can use a *VPN gateway* to connect to an on-premises network

## Virtual networks

![vnet](images/azure_virtual-networks.png)

The vNet can be
- cloud-only, or
- connected to on-prem network through site-2-site VPN, or ExpressRoute circuit

### Subnets

Each vNet is segmented into multiple subnets:

- Each subnet should have non-overlapping CIDR address space
- Some services require its own dedicated subnet, such as VPN gateway
- Routing:
  - By default, network traffic between subnets in a vNet is allowed, you can override this default routing
  - You could also route inter-subnet traffic through a network virtual appliance(NVA)
- You could enable **service endpoints** in subnets, this allows some public-facing Azure services(e.g. Azure storage account or Azure SQL database) to be accessible from these subnets and deny access from internet
- A subnet can have zero or one NSG, and an NSG could be associated to multiple subnets
- Each subnet has **5 reserved IP addresses**, so the maximum prefix in the subnet CIDR is /29 (e.g 10.0.1.0/29, 5 Azure reserved addresses + 3 available)
  - `x.x.x.0`: Network address
  - `x.x.x.1`: Reserved by Azure for the default gateway
  - `x.x.x.2`, `x.x.x.3`: Reserved by Azure to map the Azure DNS IPs to the VNet space
  - `x.x.x.255`: Network broadcast address

### IP addresses

Three ranges of non-routable IP addresses for internal networks:

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`

Private vs. Public IPs:

| Feature    | Private IP                                                                             | Public IP                                                                                                           |
| ---------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Resources  | <ul><li>VM NICs</li><li>internal load balancers</li><li>application gateways</li></ul> | <ul><li>VM NICs</li><li>internet-facing load balancers</li><li>application gateways</li> <li>VPN gateways</li></ul> |
| Assignment | Dynamic (DHCP lease) or Static (DHCP reservation)                                      | Dynamic or Static                                                                                                   |

Public IP SKUs

| Feature       | Basic SKU                                           | Standard SKU                                                                                                       |
| ------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| IP assignment | Static or dynamic                                   | Static                                                                                                             |
| Security      | Open by default, available for inbound only traffic | **Are secure by default and closed to inbound traffic**, you must enable inbound traffic by using NSG              |
| Resources     | all that can be assigned a public IP                | <ul><li>VM NICs</li><li>Standard public load balancers</li><li>application gateways</li><li>VPN gateways</li></ul> |
| Redundancy    | Not zone redundant                                  | Zone redundant, or assigned to be in a specific zone                                                               |

### CLI

```sh
# list vNets
az network vnet list --output table

# list subnets
az network vnet subnet list \
        --vnet-name my-vnet \
        --output table
```


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

Service tags represent a group of IP addresses, these could be used in an NSG rule:

  - VirtualNetwork
  - Internet
  - SQL
  - Storage
  - AzureLoadBalancer and
  - AzureTrafficManager
  - AppService

You could add VM NICs to an **App Security Group** (like a custom service tag), which could be used in an NSG rule to make management easier, you just add/remove VMs to/from the ASG, no need to manually add/remove IPs to the NSG rules

![App Security Group](images/azure_app-security-group-asg-nsg.svg)

### Azure platform considerations

Details: https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#azure-platform-considerations

- **Licensing (Key Management Service)**: Windows images running in a VM will send request to the Key Management Service host services. The request is made outbound through port 1688.
- **VMs in load-balanced pools**: Source port and address are from the originating computer, not the load balancer. The destination port and address are for the destination VM, not he load balancer
- **Azure service instances**: Instances of some Azure services could be or must be deployed in vnet subnets. You need to be aware of the port requirements for these services running in a subnet when applying NSGs.
- **Outbound email**: Depending on your subscription type, you may not be able to send email directly over TCP port 25. Use an authenticated SMTP relay service (typically over TCP port 587)


### Virtual IP of the host node

- Basic infrastructure services like DHCP, DNS, IMDS and health monitoring are provided through the virtualized host IP addresses **168.63.129.16** and **169.254.169.254** (*`169.254.0.0/16` are "link local" addresses. Routers are not allowed to forward packets sent from an IPv4 "link local" address, so they are always used by a directly connected device*)
- These IP addresses belong to Microsoft and are the ONLY virtualized IP addresses used in all regions
- Effective security rules and effective routes will not include these platform rules
- To override this basic infrastructure communication, you can create a security rule to deny traffic by using these service tags on your NSG rules: AzurePlatformDNS, AzurePlatformIMDS, AzurePlatformLKM

#### `168.63.129.16`
Typically, you should allow this IP in any local (in the VM) firewall policies (outbound direction). It's not subject to user defined routes.

- The VM Agent requires outbound communication over port 80/tcp and 32526/tcp with WireServer(168.63.129.16). This is not subject to the configured NSGs.
- 168.63.129.16 can provide DNS services to the VM when there's no custom DNS servers definition. By default this is not subject to NSGs unless specifically targeted using the "AzurePlatformDNS" service tag. You could also block 53/udp and 53/tcp in local firewall on the VM.
- Load balancer health probes originate from this IP. The default NSG config has a rule that allows this communication leveraging the "AzureLoadBalancer" service tag.


## Network Peering

Connect two virtual networks together, resources in one network can communicate with resources in another network.

![network peering](images/azure_network-peering.png)

- The networks can be in **different** subscriptions, AAD tenants, or regions
  - For different subscription scenarios, you must have the `Network Contributor` role in both subs to configure the peering
- Traffic between networks is **private**, on Microsoft backbone network
- Non-transitive, for example, with peering like this A <-> B <-> C, A can't communicate with C, you need to peer A <-> C

A typical use for peering is creating hub-spoke architecture:

![Azure gateway transit](images/azure_gateway-transit.png)

- A vNet only allows **one gateway**, when configuring peering, you could choose whether to use gateway in this vNet or the remote vNet
- In above diagram, to allow connection between vNet B and on-prem, you need configure **Allow Gateway Transit** in the hub vNet, and **Use Remote Gateway** in vNet B
- Spoke networks can **NOT** connect with each other by default through the hub network, you need to add peering between the spokes or consider using user defined routes (UDRs)
  - Peering enables the next hop in a UDR to be the IP address of an NVA (network virtual appliance) or VPN gateway. Then traffic between spoke networks can flow through the NVA or VPN gateway in the hub vNet.
- Azure Bastion in hub network can be used to access VMs in spoke network (networks must be in same tenant)

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

## VPN

Different types:

- **site to site**: your on-premise to vNet (needs a on-prem VPN device)
  ![Azure VPN site to site](images/azure_vpn-site-to-site.svg)
- **point to site**: your local machine to a vNet (doesn't require on-prem VPN device)
  ![Azure VPN point to site](images/azure_vpn-point-to-site.svg)
- **vNet to vNet**

VPN Gateway:

- Each vNet can have **only one** VPN gateway
- Underlyingly, a gateway actually is composed of **two or more VMs** that are deployed to a specific subnet you create
  - this gateway subnet must be named  **`GatewaySubnet`**
  - better use a CIDR block of /27 to allow enough IP addresses for future config requirements
  - never put other resources in this subnet
- These VMs contain routing tables and specific services, they are created automatically, you can't configure them directly
- VPN gateways can be deployed to multiple AZs for high availability

VPN gateway type

- **Route-based**: for most cases
- **Policy-based**: only for some S2S connections

### Site to site

![S2S gateway creation steps](images/azure_vpn-gateway-creation-steps.png)

*Last 3 steps are specific to S2S connections*

![VPN gateway resources](images/azure_vpn-gateway-resources.svg)

- Create local network gateway: this gateway refers to the on-prem location, you specify the IP or FQDN of the on-prem VPN device, and the CIDR of your on-prem network
- Configure on-prem VPN device: steps differ based on your device, you need a **shared key**(a ASCII string of up to 128 characters) and the public IP of the Azure VPN gateway
- Create the VPN connection: specify the VPN gateway, the local network gateway and the shared key (same as previous step)

For high availability, you could have either active-standby or active-active configurations:

![Active standby](images/azure_vpn-gateway-active-standby.png)
![Active active](images/azure_vpn-gateway-active-active.png)



### Point to site

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

- A direct, private connection(but NOT encrypted) to Microsoft services, including Azure, Microsoft 365, Dynamics 365
- Facilitated by a connectivity provider (e.g. AT&T, Verizon, Vodafone)
- Connect with one peering location, gain access to all regions within the same geopolitical region
- **ExpressRoute Global Reach** allows you to connect multiple ExpressRoute circuits
- DNS queries, certificate revocation list checking and Azure CDN requests are still sent over the public internet
- Up to 10 vNets can be linked to an ExpressRoute circuit

Three connectivity models

- CloudExchange co-location (layer 2 and 3)
- Point-to-point Ethernet connection (layer 2 and 3)
- Any-to-any(IPVPN) connection (Microsoft will behave just like another location on your private WAN)

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


### Virtual WAN

![Virtual WAN](images/azure_virtual-wan.png)

- Azure regions serve as hubs that you choose to connect your branches to
- Brings together many networking services: site-to-site VPN, point-to-site VPN, ExpressRoute into a single operational interface
- The cloud hosted 'hub' enables transitive connectivity between endpoints across different types of 'spokes'


## Routing

### System routes

![Azure system routes](images/azure_system-routes.png)

- By default, each subnet is associated with a route table, which contains system routes. These routes manage traffic within the same subnet, between subnets in the same vNet, from vNet to the Internet.
- Each subnet can only be associated with one route table, while a route table could be associated with multiple subnets.

These are the default system routes:

| Address prefix | Next hop type   |
| -------------- | --------------- |
| vNet addresses | Virtual network |
| 0.0.0.0/0      | Internet        |
| 10.0.0.0/8     | None            |
| 172.16.0.0/12  | None            |
| 192.168.0.0/16 | None            |
| 100.64.0.0/10  | None            |

- *`100.64.0.0/10` is shared address space for communications between a service provider and its subscribers when using a carrier-grade NAT (see https://en.wikipedia.org/wiki/Carrier-grade_NAT)*
- The `0.0.0.0/0` route is used if no other routes match, Azure routes traffic to the Internet, the exception is that traffic to the public IP addresses of Azure services remains on the Azure backbone network, not routed to the Internet.


Additional system routes will be created when you enable:

- vNet peering
- Service chaining (lets you override default peering routes with UDRs)
- vNet gateway
- vNet Service endpoint

### User-defined routes

![User defined routes](images/azure_user-defined-routes.png)

You could config user-defined routes (UDRs), by define the next hop in a route to be a virtual network gateway, virtual appliance, vNet or the Internet

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

![BGP](images/azure_bgp.svg)

### Route selection and priority

- If multiple routes are available for an IP address, the one with the longest prefix match is used. Eg. when sending message to `10.0.0.2`, route `10.0.0.0/24` is selected over route `10.0.0.0/16`
- You can't configure multiple UDRs with the same address prefix
- If multiple routes share the same prefix, route is selected based on this order of priority:
  - UDR
  - BGP routes
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
- Some NVAs require multiple network interfaces, one of which is dedicated to the management network for the appliance
- NVAs should be deployed in a highly available architecture
- You need to enable **IP forwarding** for an NVA, when traffic flows to the NVA but is meant for another target, the NVA will route the traffic to its correct destination

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

# enable IP forwarding within the VNA
ssh -t -o StrictHostKeyChecking=no azureuser@$NVAIP 'sudo sysctl -w net.ipv4.ip_forward=1; exit;'
```


## Azure Firewall

Firewall in a hub-spoke network:

![Azure Firewall](images/azure_firewall-overview.png)

More detailed:

![Azure Firewall architecture](images/azure_firewall-hub-spoke.png)

- Typically deployed on a **central vNet**, so you can centrally create, enforce, and log application and network connectivity policies **across subscriptions and virtual networks**
- Uses **one or multiple static public IP** addresses, so outside firewalls can identify traffic originating from your vNet
- Built-in high availability (no need to configure additional load balancers), and can span multiple availability zones
- Inbound and outbound filtering rules
- Inbound Destination Network Address Translation (DNAT)
- Is **stateful**, analyzes the complete context of a network connection, not just an individual packet
- You should use it along with NSG and WAF

By default, all traffic is blocked, you can configure:

- **NAT rules**:
  - translate fireware public IP and port to a private IP and port, could be helpful in publishing SSH, RDP, or non-HTTP/S applications to the Internet
  - **must be accompanied by a matching network rule**
- **Network rules**:
  - apply to **non-HTTP/S traffic** that flow through the firewall, including traffic from one subnet to another
  - inbound/outbound filtering rules by source, destination, port and protocol(TCP, UDP, ICMP or any), it can distinguish legitimate packets for different type of connections
- **Application rules**:
  - only allow **a list of specified FQDNs for outbound HTTP/S** and Azure SQL traffic
  - could use FQDN tags: Windows Update, Azure Backup, App Service Environment
- **Threat Intelligence**
  - alert/deny traffic from known malicious IP and domains

Network rules are processed before application rules

### Web Application Firewall (WAF)

- Centralized, inbound protection for your web applications agains common exploits and vulnerabilities
- Provided by Application Gateway, Front Door and CDN services

## DDoS Protection

![DDoS Protection](images/azure_ddos-protection.png)

- Basic: Free, part of your Azure subscription
- Standard: Protection policies are tuned through dedicated traffic monitoring and machine learning algorithms

## Private Endpoints

![Private endpoints for storage](images/azure_private-endpoints-for-storage.jpg)

* **Azure Private Endpoint**: a special network interface for an Azure service in your vNet, it gets an IP from the address range of the vNet
* Connection between the private endpoint and the storage service uses a **private link**, which traverses only Microsoft backbone network
  - A Private Link can connect to Azure PaaS services, customer-owned or Microsoft partner services.
  - A Private Link service receives connections from multiple private endpoints. A private endpoint connects to one Private Link service.
  - Private Link works across Azure AD tenants
  - No gateways, NAT devices, ExpressRoute or VPN connections, or public IP addresses are needed.
* Applications in the vNet can connect to the service over the private endpoint seamlessly, **using the same connection string and authorization mechanisms that they would use otherwise**;
* You **DON'T** need a firewall rule to allow traffic from a vNet that has a private endpoint, since the storage firewall only controls access through the public endpoint. Private endpoints instead rely on the consent flow for granting subnet access;
* You need a separate private endpoint for each storage service in a storage account that you need to access: Blobs, Files, Static Websites, ...;
* For RA-GRS accounts, you should create a separate private endpoint for the secondary instance;

DNS resolution:

Clients on a vNet using the private endpoint should use the same connection string (not using the *privatelink* URL), as clients connecting to the public endpoint. This requires DNS configuration.

Out of vNet:

```sh
# before private endpoint
garystoryagefoo.blob.core.windows.net. 78 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
blob.syd26prdstr02a.store.core.windows.net. 75 IN A 20.150.66.4

# after
garystoryagefoo.blob.core.windows.net. 120 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
garystoryagefoo.privatelink.blob.core.windows.net. 119 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
blob.syd26prdstr02a.store.core.windows.net. 119 IN A 20.150.66.4
```

In the vNet (private DNS auto configured):

```sh
# after
garystoryagefoo.blob.core.windows.net. 60 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
garystoryagefoo.privatelink.blob.core.windows.net. 9 IN A 10.0.0.5
```

CLI example:

```sh
# get the resource id of the storage account
id=$(az storage account show \
      -g default-rg \
      -n garystoryagefoo \
      --query '[id]' \
      -o tsv
    )

# disable private endpoint network policies for the subnet
az network vnet subnet update \
    --name default \
    --resource-group default-rg \
    --vnet-name default-vnet \
    --disable-private-endpoint-network-policies true

# create private endpoint in a vnet
az network private-endpoint create \
      --name myPrivateEndpoint \
      -g default-rg \
      --vnet-name default-vnet \
      --subnet default \
      --private-connection-resource-id $id \
      --group-id blob \
      --connection-name myConnection

# create a private dns zone
az network private-dns zone create \
    --name "privatelink.blob.core.windows.net"

# link the private dns to a vnet
az network private-dns link vnet create \
    --zone-name "privatelink.blob.core.windows.net" \
    --name MyDNSLink \
    --virtual-network default-vnet \
    --registration-enabled false

# register the private endpoint in the private dns
az network private-endpoint dns-zone-group create \
   --endpoint-name myPrivateEndpoint \
   --private-dns-zone "privatelink.blob.core.windows.net" \
   --name MyZoneGroup \
   --zone-name storage
```


## Service endpoints

![Service endpoints overview](images/azure_vnet_service_endpoints_overview.png)

- The purpose is to secure your network access to PaaS services (by default, all PaaS services have public IP addresses and are exposed to the internet), such as:

  - Azure Storage
  - Azure SQL Database
  - Azure Cosmos DB
  - Azure Key Vault
  - Azure Service Bus
  - Azure Data Lake

- A virtual network service endpoint provides the identity of your virtual network to an Azure service. You secure the access to an Azure service to your vNet by adding a virtual network rule. You could fully remove public Internet access to this service.

- After enabling a service endpoint, the source IP addresses switch from using public IPv4 addresses to using their private IPv4 address when communicating with the service from that subnet. This switch allows you to access the services without the need for reserved, public IP addresses used in Azure service IP firewalls.

- With service endpoints, DNS entries for Azure services don't change, continue to resolve to public IP addresses assigned to the Azure service. (**Different from private endpoints**)
  - When a service endpoint is created, **Azure actually creates routes in the route table to direct the traffic, keeping it within Microsoft network**. The route table would like:

    | SOURCE  | STATE  | ADDRESS PREFIXES        | NEXT HOP TYPE                 |
    | ------- | ------ | ----------------------- | ----------------------------- |
    | Default | Active | 10.1.1.0/24             | VNet                          |
    | Default | Active | 0.0.0.0./0              | Internet                      |
    | Default | Active | 10.0.0.0/8              | None                          |
    | Default | Active | 100.64.0.0./10          | None                          |
    | Default | Active | 192.168.0.0/16          | None                          |
    | Default | Active | 20.38.106.0/23, 10 more | VirtualNetworkServiceEndpoint |
    | Default | Active | 20.150.2.0/23, 9 more   | VirtualNetworkServiceEndpoint |

- If you use ExpressRoute for connectivity from on-prem to Azure, you need to add the two NAT IPs of the ExpressRoute to the service's IP firewall.

- Virtual networks and Azure service resources can be in the same or different subscriptions. Certain Azure Services (not all) such as Azure Storage and Azure Key Vault also support service endpoints across different Active Directory(AD) tenants i.e., the virtual network and Azure service resource can be in different Active Directory (AD) tenants.

CLI

```sh
# enable service endpoint in a subnet
az network vnet subnet update \
    --resource-group my-rg \
    --vnet-name my-vnet \
    --name my-subnet \
    --service-endpoints Microsoft.Storage

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

**Private endpoints** vs. **service endpoints**:

- Private Endpoints allows you to connect to a service via a private IP address in a vNet, easily extensible to on-prem network;
- A service endpoint remains a publicly routable IP address, scoped to subnets;

## Azure Load Balancer

- Can be used with incoming internet traffic, internal traffic, port forwarding for specific traffic, or outbound connectivity for VMs
- Public load balancers can only have public IPs, they seem to be **not in a vNet**
- Internal load balancers are **not in a paticular subnet**, they could have frontend IPs from multiple subnets in a vNet

Example multi-tier architecture with load balancers

![Azure Load Balancer](images/azure_load-balancer.png)

### SKUs

| SKU          | Basic                                     | Standard (extra features) |
| ------------ | ----------------------------------------- | ------------------------- |
| Health probe | TCP, HTTP                                 | HTTPS                     |
| Back-end     | single availability set or scale set      | availability zones        |
| Outbound     | source network address translation (SNAT) | outbound rules            |

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

- Is a load balancer for web apps, supports HTTP, HTTPS, HTTP/2 and WebSocket protocols
- Support redirection, rewrite HTTP headers and custom error pages
- Works at application layer (OSI layer 7)
- Uses Azure Load Balancer at TCP level (OSI layer 4)
- Could be internet-facing (public ip) or internal only (private ip)

Benefits over a simple LB:

- Cookie affinity
- SSL termination
- Web application firewall (WAF): detailed monitoring and logging to detect malicious attacks
- URL rule-based routes: based on hostname and paths, helpful when setting up a CDN
- Rewrite HTTP headers: such as scrubing server names

![Application Gateway](images/azure_application-gateway.png)

Components:

![Application Gateway components](images/azure_application-gateway-components.png)

- Front end: a public IP, a private IP, or both (*it is a load balancer, and AGW instances are in its backend pool, so we need to allow AzureLoadBalancer in the NSG*)
- Listeners
  - Defined by protocol, port, host and IP address
  - Two types:
    - Basic: each port can only have one basic listener
    - Multi-site: each port can have multiple multi-site lisenters, you specify one or more host names in each listener
  - Handle TLS/SSL certificates for HTTPS
  - A listener can have **only one** associated rule
- WAF:
  - checks each request for common threats: SQL-injection, XSS, command injection, HTTP request smuggling, crawlers, etc
  - based on OWASP rules, referred to as Core Rule Set(CRS)
  - you can opt to select only specific rules, or specify which elements to examine
- Backend pool: a backend pool can contain one or more IP/FQDN, VM, VMSS and App Services
- Rule: associates a listener with targets
  - Rule target types:
    - Backend pool: with HTTP settings
    - Redirection: to another listener or external site with a specified HTTP code
  - You could also have multiple targets based on path
- HTTP settings: backend port/protocol, cookie-based affinity, time-out value, path or hostname overriding, default or custom probe, etc
- Health probes
  - If not configured, a default probe is created, which waits for 30s before deciding whether a server is unavailable
  - The source IP address for health probes depends on the target
    - If the target is a public endpoint, then the source IP is the AGW's public IP
    - If the target is a private endpoint, then the source IP is from the AGW subnet's *private IP address space*

### How does routing works

1. If a request is valid and not blocked by WAF, the rule associated with the listener is evaluated, determining which backend pool to route the request to.
1. Use round-robin algorithm to select one healthy server from the backend pool.
1. Opens a new TCP session to the server based on HTTP settings.

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

### AGW subnet and NSG

See: https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure

An Application Gateway needs its own dedicated subnet:

- An AGW can have multiple instances, each has one private IP from the subnet
- Another private IP address needed if a private frontend IP is configured
- A subnet can host multiple AGWs
- You need to size this subnet appropriately based on the number of instances
  - V2 SKU can have max. 125 instances, /24 is recommended for the subnet

Suggested NSG for the subnet (See: https://aidanfinn.com/?p=21474):

| Source                | Dest           | Dest Port                                  | Protocol | Direction | Allow | Comment                                                             |
| --------------------- | -------------- | ------------------------------------------ | -------- | --------- | ----- | ------------------------------------------------------------------- |
| Internet or IP ranges | Any            | eg. 80, 443                                | TCP      | Inbound   | Allow | Allow Internet or specified client and ports                        |
| GatewayManager        | Any            | 65200-65535 (v2 SKU), 65503-65534 (v1 SKU) | TCP      | Inbound   | Allow | Azure infrastructure communication, protected by Azure certificates |
| AzureLoadBalancer     | Any            | *                                          | *        | Inbound   | Allow | Required                                                            |
| VirtualNetwork        | VirtualNetwork | *                                          | *        | Inbound   | Allow | AllowVirtualNetwork                                                 |
| Any                   | Internet       | *                                          | *        | Outbound  | Allow | A default outbound rule, required, don't override                   |
| Any                   | Any            | *                                          | *        | Inbound   | Deny  | Deny everything else, overridding default rules                     |



## Traffic Manager

Comparing to Load Balancer:

|                 | Use                                                                                     | Resiliency                                                                                                   |
| --------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Load Balancer   | makes your service **highly available** by distributing traffic within the same region  | monitor the health of VMs                                                                                    |
| Traffic Manager | works at the DNS level, directs the client to a preferred endpoint, **reduces latency** | monitors the health of endpoints, when one endpoint is unresponsive, directs traffic to the next closest one |

![Traffic Manager](images/azure_traffic-manager.png)

There are different routing methods (determines which endpoint is returned)

- **Priority routing**: choose an healthy one with the highest priority
- **Performance routing**: choose an endpoint with the lowest latency, traffic manager maintains an internet latency table by tracking the roundtrip time between IP address ranges and each Azure datacenter
- **Weighted routing**: pick a random endpoint based on the weights
- **Geographic routing**: choose a designated geo endpoint based on DNS query's source IP address
- **Subnet routing**: static mapping from DNS query's source IP ranges to endpoints
- **Multivalue routing**: return multiple healthy endpoints in a response, client can retry another one if an endpoint is unresponsive

## Front Door

![Front door](images/azure_front-door.png)

It's like the Application Gateway at a global scale, plus a CDN
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

Common X.509 certificate encoding formats and extensions:

- Base64 (ASCII)
  - PEM
    - .pem
    - .crt
    - .ca-bundle
  - PKCS#7
    - .p7b
    - .p7s
- Binary
  - DER
    - .der
    - .cer
  - PKCS#12
    - .pfx
    - .p12

`*.pem`, `*.crt`, `*.ca-bundle`, `*.cer`, `*.p7b`, `*.p7s` files contain one or more X.509 digital certificate files that use base64 (ASCII) encoding.

A `.pfx` file, also known as PKCS #12, is a single, password protected certificate archive that **contains the entire certificate chain plus the matching private key**. Essentially it is everything that any server will need to import a certificate and private key from a single file.

see:
- https://www.ssls.com/knowledgebase/what-are-certificate-formats-and-what-is-the-difference-between-them/
- https://blog.neilsabol.site/post/azure-cdn-custom-https-secret-contains-unsupported-content-type-x-pkcs12/

## DNS

Concepts:

- **DNS Zone** corresponds to a domain name, parent and children zones could be in different resource groups
- A **record set** is a collection of records in a zone that have the same name and type (e.g. multiple IP addresses for name 'www' and type 'A')

Features:

- Split-horizon DNS support: allows the same domain name to exist in both private and public zones, so you could have a private version of your services within your virtual network.

- Alias record sets: allows you to setup alias record to direct traffic to an Azure public IP address(load balancer), an Azure Traffic Manager profile, or an Azure CDN endpoint.
  - It's a dynamic link between a record and a resource, so when the resource's IP changes, it's automatically handled;
  - Supports these record types: A, AAAA, CNAME;

### Private DNS zones

You could link a Private DNS Zone to a vNet (not subnet), enable auto-registration, then hostname of any VMs in the vNet would be registered in this Private DNS Zone

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

### CLI

```sh
az network dns zone list \
    --output table

az network dns record-set list \
    -g <resource-group> \
    -z <zone-name> \
    --output table
```

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
