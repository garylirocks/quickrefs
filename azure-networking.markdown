# Azure Networking

- [Overview](#overview)
- [Virtual networks](#virtual-networks)
  - [Subnets](#subnets)
  - [IP addresses](#ip-addresses)
- [Network security group (NSG)](#network-security-group-nsg)
- [Network Peering](#network-peering)
- [VPN](#vpn)
  - [Site to site](#site-to-site)
  - [Point to site](#point-to-site)
- [ExpressRoute](#expressroute)
  - [Virtual WAN](#virtual-wan)
- [Routing](#routing)
- [Azure Firewall](#azure-firewall)
  - [Web Application Firewall (WAF)](#web-application-firewall-waf)
- [DDoS Protection](#ddos-protection)
- [Private Endpoints](#private-endpoints)
- [Service endpoints](#service-endpoints)
- [Azure Load Balancer](#azure-load-balancer)
- [Application Gateway](#application-gateway)
- [Traffic Manager](#traffic-manager)
- [Front Door](#front-door)
- [CDN](#cdn)
  - [Standard rules engine notes](#standard-rules-engine-notes)
  - [Custom domain HTTPS](#custom-domain-https)
- [DNS](#dns)
  - [Private DNS zones](#private-dns-zones)

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
- Each subnet has **5 reserved IP addresses**, so the maximum prefix in the subnet CIDR is 29 (e.g 10.0.1.0/29, 3 + 5 Azure reserved addresses)
  - `x.x.x.0`: Network address
  - `x.x.x.1`: Reserved by Azure for the default gateway
  - `x.x.x.2`, `x.x.x.3`: Reserved by Azure to map the Azure DNS IPs to the VNet space
  - `x.x.x.255`: Network broadcast address

### IP addresses

| Feature   | Private IP                                                                             | Public IP                                                                                                           |
| --------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Resources | <ul><li>VM NICs</li><li>internal load balancers</li><li>application gateways</li></ul> | <ul><li>VM NICs</li><li>internet-facing load balancers</li><li>application gateways</li> <li>VPN gateways</li></ul> |

Public IP SKUs

| Feature       | Basic SKU                                                                                                          | Standard SKU                                                     |
| ------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| IP assignment | Static or dynamic                                                                                                  | Static                                                           |
| Security      | Open by default                                                                                                    | **Are secure by default and closed to inbound traffic**          |
| Resources     | <ul><li>VM NICs</li><li>internet-facing load balancers</li><li>application gateways</li><li>VPN gateways</li></ul> | <ul><li>VM NICs</li><li>public standard load balancers</li></ul> |
| Redundancy    | Not zone redundant                                                                                                 | Zone redundant by default                                        |

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


## Network Peering

Connect two virtual networks together, resources in one network can communicate with resources in another network.

![network peering](images/azure_network-peering.png)

- The networks can be in **different** subscriptions, AAD tenants, or regions
- Traffic between networks is **private**, on Microsoft backbone network

A typical use for peering is creating hub-spoke architecture:

![Azure gateway transit](images/azure_gateway-transit.png)

- A VPN gateway in one network allows you access to its peered networks
- A vNet only allows one gateway, when configuring peering, you could choose whether to use gateway in this vNet or the remote vNet
- Azure Bastion in hub network can be used to access VMs in spoke network (networks must be in same tenant)
- Spoke networks can **NOT** connect with each other by default through the hub network, you need to add peering between the spokes or consider using user defined routes (UDRs)
  - Peering enables the next hop in a UDR to be the IP address of an NVA (network virtual appliance) or VPN gateway. Then traffic between spoke networks can flow through the NVA or VPN gateway in the hub vNet.



## VPN

Different types:

- **site to site**: your on-premise to vNet (needs a on-prem VPN device)
  ![Azure VPN site to site](images/azure_vpn-site-2-site.png)
- **point to site**: your local machine to a vNet
  ![Azure VPN point to site](images/azure_vpn-point-to-site.png)
- **vNet to vNet**

VPN Gateway:

- Each vNet can have **only one** VPN gateway
- Underlyingly, a gateway actually is composed of **two or more VMs** that are deployed to a specific subnet you create
  - this gateway subnet must be named  **`GatewaySubnet`**
  - better use a CIDR block of /28 or /27 to allow enough IP addresses for future config requirements
  - never put other resources in this subnet
- These VMs contain routing tables and specific services, they are created automatically, you can't configure them directly
- VPN gateways can be deployed to multiple AZs for high availability

VPN gateway type

- **Route-based**: for most cases
- **Policy-based**: only for some S2S connections

### Site to site

![S2S gateway creation steps](images/azure_vpn-gateway-creation-steps.png)

*Last 3 steps are specific to S2S connections*

- Create local network gateway: this gateway refers to the on-prem location, you specify the IP or FQDN of the on-prem VPN device, and the CIDR of your on-prem network
- Configure on-prem VPN device: steps differ based on your device, you need a **shared key** and the public IP of the Azure VPN gateway
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

![ExpressRoute overview](images/azure_expressroute.png)

- A direct, private connection to Microsoft services, including Azure, Microsoft 365, CRM
- Facilitated by a connectivity provider
- Connect with one peering location, gain access to all regions within the same geopolitical region

![Coexisting ExpressRoute and VPN gateway](images/azure_coexisting-connections.png)

A vNet can have both ExpressRoute and VPN gateways at the same time.

### Virtual WAN

![Virtual WAN](images/azure_virtual-wan.png)

- Azure regions serve as hubs that you choose to connect your branches to
- Brings together many networking services: site-to-site VPN, point-to-site VPN, ExpressRoute into a single operational interface
- The cloud hosted 'hub' enables transitive connectivity between endpoints across different types of 'spokes'


## Routing

![Azure system routes](images/azure_system-routes.png)

- By default, each subnet is associated with a route table, which contains system routes. These routes manage traffic within the same subnet, between subnets in the same vNet, from vNet to the Internet.
- Each subnet can only be associated with one route table, while a route table could be associated with multiple subnets.

![User defined routes](images/azure_user-defined-routes.png)

- You could config user-defined routes (UDRs), by define the next hop in a route to be a virtual network gateway, virtual appliance, vNet or the Internet

![Routing example](images/azure_routing-example.png)

In the above example,

- By default, traffic from public subnet goes to private subnet directly
- You define a route in the public subnet's route table, make any traffic from the public subnet to the private subnet go through the virtual appliance in the DMZ subnet.


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

![Private endpoints for storage](images/azure_private-endpoints-for-stroage.jpg)

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

- A virtual network service endpoint provides the identity of your virtual network to an Azure service. You secure the access to an Azure service to your vNet by adding a virtual network rule. You could fully remove public Internet access to this service.

- After enabling a service endpoint, the source IP addresses switch from using public IPv4 addresses to using their private IPv4 address when communicating with the service from that subnet. This switch allows you to access the services without the need for reserved, public IP addresses used in Azure service IP firewalls.

- With service endpoints, DNS entries for Azure services don't change, continue to resolve to public IP addresses assigned to the Azure service. (**Different from private endpoints**)
  - **When a service endpoint is created, Azure actually creates routes in the route table to direct the traffic, keeping it within Microsoft network**.

- Virtual networks and Azure service resources can be in the same or different subscriptions. Certain Azure Services (not all) such as Azure Storage and Azure Key Vault also support service endpoints across different Active Directory(AD) tenants i.e., the virtual network and Azure service resource can be in different Active Directory (AD) tenants.

**Private endpoints** vs. **service endpoints**:

- Private Endpoints allows you to connect to a service via a private IP address in a vNet, easily extensible to on-prem network;
- A service endpoint remains a publicly routable IP address, scoped to subnets;

## Azure Load Balancer

- Can be used with incoming internet traffic, internal traffic, port forwarding for specific traffic, or outbound connectivity for VMs

Example multi-tier architecture with load balancers

![Azure Load Balancer](images/azure_load-balancer.png)

## Application Gateway

- Is a load balancer for web apps
- Uses Azure Load Balancer at TCP level
- Understands HTTP, applies routing at application layer (L7)

Benefits over a simple LB

- Cookie affinity
- SSL termination
- Web application firewall (WAF): detailed monitoring and logging to detect malicious attacks
- URL rule-based routes: based on URL patterns, source IP and port, helpful when setting up a CDN
- Rewrite HTTP headers: such as scrubing server names

![Application Gateway](images/azure_aplication-gateway.png)

## Traffic Manager

Comparing to Load Balancer:

|                 | Use                                                                                     | Resiliency                                                                                                   |
| --------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Load Balancer   | makes your service **highly available** by distributing traffic within the same region  | monitor the health of VMs                                                                                    |
| Traffic Manager | works at the DNS level, directs the client to a preferred endpoint, **reduces latency** | monitors the health of endpoints, when one endpoint is unresponsive, directs traffic to the next closest one |

![Traffic Manager](images/azure_traffic-manager.png)

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
    gzip /paht/to/file
    mv /paht/to/file.gz /paht/to/file

    azcopy copy /paht/to/file <Blob-storage-path> \
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