# Azure Networking - Private Link

- [Private Endpoint Overview](#private-endpoint-overview)
- [Limitations](#limitations)
  - [NSG](#nsg)
  - [UDR](#udr)
- [Network architecture design with Azure Firewall](#network-architecture-design-with-azure-firewall)
- [DNS resolution](#dns-resolution)
  - [DNS integration at scale](#dns-integration-at-scale)
  - [Pitfall - Resolve PaaS endpoint in other tenants](#pitfall---resolve-paas-endpoint-in-other-tenants)
- [Multi-region scenarios](#multi-region-scenarios)
  - [Use of Azure Private Link / SDN](#use-of-azure-private-link--sdn)
  - [Inter-region failover](#inter-region-failover)
  - [Hybrid private link connectivity](#hybrid-private-link-connectivity)
- [CLI example](#cli-example)
- [Private Link](#private-link)
- [Quick Recipes](#quick-recipes)

## Private Endpoint Overview

<img src="images/azure_private-endpoints-for-storage.jpg" width="600" alt="Private endpoints for storage" />

In the above diagram:

* **Azure Private Endpoint**: a special network interface for an Azure service in your vNet, it gets an IP from the address range of a subnet
* Applications in the vNet can connect to the service over the private endpoint seamlessly, **using the same connection string and authorization mechanisms that they would use otherwise**;
* The Storage account **DOESN'T** need a network rule to allow traffic from the private endpoint, the network rules only control access through the public endpoint. Private endpoints instead rely on the consent flow for granting subnet access.

Notes

- A read-only network interface is created alongside a private endpoint
- Connections can only be initiated in one direction: from client to the endpoint
- **Outbound NSG rules do not affect PE connectivity, you could set a Deny-all outbound rule on the NSG, a PE could still connect to its service**
- For some service, you need separate private endpoints for each sub-resource, for a RA-GRS storage account, there are sub-resources like `blob`, `blob_secondary`, `file`, `file_secondary`, ...
- Private endpoints **DO NOT** restrict public network access to services, except **Azure App Service** and **Azure Functions**, they become inaccessible publicly when they are associated with a private endpoint. Other PaaS services may have additional access control. (*such as the `publicNetworkAccess` property, this property is not always visible in the Portal*)
- The connected private link resource could be in a different region
- To allow automatic approval for private endpoints, you need this permission on the private-link resource: `Microsoft.<Provider>/<resource_type>/privateEndpointConnectionsApproval/action`

## Limitations

See: https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview#limitations

Private endpoint is a special network interface, there are limitations:

### NSG

- Effective routes and security rules won't be displayed for the private endpoint NIC in the Azure portal, making debugging hard.
- **NSG flow logs** (Traffic Analytics as well) are not supported.
- NSG only apply when `PrivateEndpointNetworkPolicies` property on the containing subnet is "Enabled".
  - By default,
      - if creating a subnet in Portal, this property is `Disabled`
      - if creating with Terraform `azurerm` provider, this property is `Enabled`
  - With CLI or Terraform, you can only set it to be `Enabled` or `Disabled`
  - In the Portal, you could enable only NSG or UDR, then the value would be `NetworkSecurityGroupEnabled` or `RouteTableEnabled`
- Source port is interpreted as `*`
- Rules with multiple port ranges may not work as expected (see the doc)
- No need for outbound deny rules on a private endpoint, as it can't initiate traffic

### UDR

- When you add a private endpoint, Azure would add a route to ***all the route tables in the hosting and any peered vnets***, so all traffic to the private endpoint from these vnets goes directly, bypassing NVA:

    | Source  | State  | Address Prefixes | Next Hop Type     | Next Hop IP Addres |
    | ------- | ------ | ---------------- | ----------------- | ------------------ |
    | Default | Active | 10.1.1.4/32      | InterfaceEndpoint |                    |

  To overwrite this `/32` route, when `PrivateEndpointNetworkPolicies` property (of the hosting subnet, not client vnets)
    - is "Enabled", you could use a shorter prefix to overwrite it, so you won't running into the limit of 400 routes per table, in the following table, *a UDR with a shorter `/16` prefix overwrites a `/32` private endpoint route, this is an exception to the general precedence order*

      | Source  | State   | Address Prefixes | Next Hop Type     | Next Hop IP Addres |
      | ------- | ------- | ---------------- | ----------------- | ------------------ |
      | User    | Active  | **10.1.0.0/16**  | Virtual appliance | 10.0.1.4           | my-custom-route |
      | Default | Invalid | 10.1.1.4/32      | InterfaceEndpoint |                    |

    - is "Disabled", you need to add another route with the same `/32` prefix(on client subnet's UDR), you could easily hit the 400 routes per table limit if there are a lot of PEs

      | Source  | State   | Address Prefixes | Next Hop Type     | Next Hop IP Addres |
      | ------- | ------- | ---------------- | ----------------- | ------------------ |
      | User    | Active  | **10.1.1.4/32**  | Virtual appliance | 10.0.1.4           | my-custom-route |
      | Default | Invalid | 10.1.1.4/32      | InterfaceEndpoint |                    |

- Even `PrivateEndpointNetworkPolicies` is "Enabled", return traffic from PEs always go back to the source IP directly, **UDRs do not apply**, the return traffic could be asymmetric, bypassing NVA.
  - To mitigate this, use SNAT at the NVA, then the private endpoint see the NVA IP as source IP, this ensures symmetric routing
  - But there are exceptions (https://github.com/MicrosoftDocs/azure-docs/issues/69403), in the following cases, the return traffic does go through NVA, SNAT is not required:
    - Connecting to a storage PE (tested `blob`, not sure about other services)
    - Connecting via VPN
    - **Source and NVA are in different VNETs** (no matter whether source and PE are in the same VNET or not), this seems to be the best way to handle it, keeping NVA in the hub vnet, workload and PEs in spoke vnets

## Network architecture design with Azure Firewall

See: https://docs.microsoft.com/en-us/azure/private-link/inspect-traffic-with-azure-firewall

- Hub and spoke - Dedicated VNET for PEs

  ![Dedicated VNET for PEs](images/azure_private-endpoint-hub-and-spoke.png)

  *This was recommended to avoid the 400 route limit, but now if you enable `PrivateEndpointNetworkPolicies` on the PE subnet, you probably won't need to worry about this limit anymore. So this design is similar to the one below.*

- Hub and spoke - Shared

  ![Shared VNET for PEs](images/azure_private-endpoint-shared-spoke.png)

  *If you enable `PrivateEndpointNetworkPolicies` on the PE subnet, you don't need the overwrite with `/32` route anymore, you could overwrite with a shorter prefix , such as `/16`*


## DNS resolution

Microsoft documentation: https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration

**There are many pitfalls/challenges regarding private endpoint DNS resolution (and network routing), see:**
- https://github.com/dmauser/PrivateLink
- https://journeyofthegeek.com/2020/03/06/azure-private-link-and-dns-part-2/

Let's say you have a blob endpoint at `garystoryagefoo.blob.core.windows.net`, after you add a private endpoint, the FQDN would be a CNAME to `garystoryagefoo.privatelink.blob.core.windows.net.` (CNAME insertion only happens when the **PE is in "Approved", not if "Rejected"**)

- For external users, it should resolve to a public IP
- For internal users, it should resolve to a private IP (by Azure Private DNS Zone or your own DNS server)

Before private endpoint (Internal or external):

```sh
garystoryagefoo.blob.core.windows.net. 78 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
blob.syd26prdstr02a.store.core.windows.net. 75 IN A 20.150.66.4
```

After:

  - External:

    ```sh
    # after
    garystoryagefoo.blob.core.windows.net. 120 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
    garystoryagefoo.privatelink.blob.core.windows.net. 119 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
    blob.syd26prdstr02a.store.core.windows.net. 119 IN A 20.150.66.4
    ```

  - Internal (private DNS auto configured):

    ```sh
    # this is by Azure provided DNS (168.63.129.16)
    # if you have private DNS Zone "privatelink.blob.core.windows.net." linked to the same vnet, it would consult the zone
    garystoryagefoo.blob.core.windows.net. 60 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
    # this is the record in the private DNS Zone
    garystoryagefoo.privatelink.blob.core.windows.net. 9 IN A 10.0.0.5
    ```

On the client side, you must use the PasS service public FQDN, this is to ensure SNI (Service Name Indication) on TLS still works (see https://github.com/dmauser/PrivateLink/tree/master/DNS-Integration-Scenarios#74-server-name-indication-sni-on-tls-request-client-hello).

For example, when you access the data in the storage account from an Azure VM, **the Portal always loads data from `garystoryagefoo.blob.core.windows.net`, depending on your VM's DNS setting, it could be resolved to either a public IP or a private one**

For a web app, there will be two endpoints: `my-webapp.azurewebsites.net`, `my-webapp.scm.azurewebsites.net` pointing to the same IP, when enabling private endpoints, you only need one private DNS zone `privatelink.azurewebsites.net`, with two record sets in it like the following

```
my-webapp         10.0.0.4
my-webapp.scm     10.0.0.4
```

A few scenarios for DNS resolution:

- Single vNet without custom DNS server

  ![Private endpoint DNS in single vnet](images/azure_private-endpoint-single-vnet-azure-dns.png)

- Hub-spoke vnets without custom custom DNS server

  ![Private endpoint DNS in hub-spoke vnets](images/azure_private-endpoint-hub-and-spoke-azure-dns.png)

- Use a DNS forwarder

  ![Private endpoint DNS with a DNS forwarder](images/azure_private-endpoint-dns-forwarder.png)

  A Domain Controller integrated DNS Server as a DNS forwarder:

  ![Private endpoint DNS with DC integrated DNS](images/azure_dns-resolution.drawio.svg)

- Using Active Directory (see https://github.com/dmauser/PrivateLink/tree/master/DNS-Scenario-Using-AD)

  The key here is to setup **different AD DNS Application Partitions**, one for Azure, one for on-prem

  ![DC integrated DNS](images/azure_private-link-ad-scenario.png)

### DNS integration at scale

See: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale

With hub-spoke network architecture in an Enterprise landing zone scenario, you would like to
  - put all private DNS zones for private link endpoints in the connectivity subscription
  - allow each application team to create private endpoint, and have A records added to the central private DNS zones automatically (without help from the central IT team)

You could achieve this by using Azure Policy (assigned to landingzone subscriptions, not the connectivity subscription):
  - (Optional) `Deny` public endpoint for PaaS services
  - `Deny` creating of a private DNS zone with `privatelink` prefix
  - `DeployIfNotExists` policy to automatically create `privateDnsZoneGroups`, which associate private endpoints to private DNS zones in the connectivity subscription, the managed identity needs two permissions:
    - `Network Contributor` for the private endpoint to add `privateDnsZoneGroups` to the PE
    - `Private DNS Zone Contributor` for the private DNS zones to add 'A' records

### Pitfall - Resolve PaaS endpoint in other tenants

See: https://github.com/dmauser/PrivateLink/tree/master/Issue-Customer-Unable-to-Access-PaaS-AfterPrivateLink

There is a gotcha in all the above scenarios:

  - Company A access its KV `kv-a.vault.azure.net` through a private endpoint, it also access a KV in company B's tenant, `kv-b.vault.azure.net` through a public endpoint (resolves to a public IP).
  - Company B enables private endpoint for `kv-b.vault.azure.net`
  - Now company A can't resolve `kv-b.vault.azure.net`, since now it CNAME to `kv-b.privatelink.vaultcore.azure.net`, Azure provided DNS consults the linked private DNS zone, which doesn't have a record for `kv-b`

To remediate this, you could
  - (**recommended**) create a private endpoint in Company A's vnet to `kv-b.vault.azure.net` (need approval from Company B's side)
  - in your custom DNS server, conditionally forward `kv-b.vault.azure.net` to an Internet DNS resolver
  - (**not recommended**) on client VMs, use dnsmasq for Linux or NRPT (Name Resolution Policy Table) feature for Windows (see: https://github.com/dmauser/PrivateLink/tree/master/DNS-Client-Configuration-Options)


## Multi-region scenarios

See: https://github.com/adstuart/azure-privatelink-multiregion

When designing for multi-region deployment, BCDR scenarios, there are two options for private endpoint DNS zones, you could have:

1. Private DNS zone per region: a PaaS service could have a separate endpoint in each region, same FQDN with different IP in each zone
2. Shared private DNS zone: one zone, one IP, one active endpoint

Each option has its advantage and disadvantages.

### Use of Azure Private Link / SDN

![Private DNS zones inter region transit](./images/azure-private-dns-zone-multi-region-datapath.drawio.svg)

- **Zone per region**: Optimal, each region has its own private endpoint to the same PaaS services, ingress to private link close to source, inter-region routing transit handled by Azure. *(in the corresponding zone, they have same FQDN, but a different IP)*
- **Shared zone**: Non-optimal, inter-region data path relies on customer's inter-region routing solution *(only possible to have one endpoint, one record in the shared zone)*

###  Inter-region failover

![Private DNS zones inter region failover](./images/azure-private-dns-zone-multi-region-failover.drawio.svg)

*We use storage account as example above, because it's GRS, data is replicated to paired region automatically, after failover, the one in the failover region is effectively an LRS account*

- **Zone per region**: Optimal, no manual intervention needed (same as using the PaaS public endpoint)
- **Shared zone**: Upon failover, need user-intervention in the shared zone to point FQDN to IP of the private endpoint in the failover region

Actually, there are different scenarios for different PaaS services, if the PaaS service use the same FQDN for regional replicas, then you need user-intervention during failover if using a shared zone

| Service   | FQDN                                                                                                           | How to replicate                                           | Failover simulation ? |
| --------- | -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | --------------------- |
| Key Vault | Only one                                                                                                       | KeyVault data is automatically replicated to paired region | No                    |
| Storage   | Only one (a read-only secondary one for RA-GRS, RA-GZRS)                                                       | GRS, GZRS, RA-GRS, RA-GZRS                                 | Yes                   |
| Cosmos DB | `cosmon-demo.mongo.cosmos.azure.com` (global FQDN)<br/>-> `cosmon-demo.privatelink.`<br/>-> regional endpoints | Multi-region support                                       | Yes                   |

Some PaaS services have a global alias, and different FQDNs for regional replicas, you could add both to the shared zone, so you may not need any user-intervention during failover

For example, PaaS SQL instance in East US (`sql-demo-eus`) is replicated to West US as `sql-demo-wus`, you could add both to a shared private DNS zone `privatelink.database.windows.net`

They are in one failover group `fog-demo`, usually it points to `sql-demo-eus`, after failover, it points to `sql-demo-wus`

| Service               | FQDN                                                                                                                                         | How to replicate                                     | Failover simulation ? |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------- |
| SQL                   | `fog-demo.database.windows.net` (failover group) <br/>-> `sql-demo-eus`, `sql-demo-wus` (regional)<br/>-> privatelink FQDN                   | Failover group (one PaaS instance in each region)    | Yes                   |
| Event Hub/Service Bus | `evhns-alias-demo.servicebus.windows.net` (alias)<br/> -> `evhns-demo-eus`, `evhns-demo-wus` (regional)<br/> -> privatelink FQDN     </html> | Namespace pairing (one PaaS instance in each region) | Yes                   |

### Hybrid private link connectivity

See https://github.com/adstuart/azure-privatelink-multiregion#6-appendix-a---hybrid-forwarding-and-multi-region-private-link-considerations-when-accessing-from-on-premises

- **Zone per region**: could be a problem, depending on-prem DNS software used (BIND v9, Infoblox)
- **Shared zone**: no issues


## CLI example

```sh
# get the resource id of the storage account
id=$(az storage account show \
      -g default-rg \
      -n garystoryagefoo \
      --query '[id]' \
      -o tsv
    )

# the `PrivateEndpointNetworkPolicies` controls whether NSG and UDR are applied to private endpoints
# this step is not required, see notes above about NSG limitations
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

## Private Link

Connection between the private endpoint and the storage service uses a **private link**, which traverses only Microsoft backbone network

- A Private Link can connect to Azure PaaS services, Azure hosted customer-owned/partner services.
- A Private Link service receives connections from multiple private endpoints. A private endpoint connects to one Private Link service.
- Private Link works across Azure AD tenants
- No gateways, NAT devices, ExpressRoute or VPN connections, or public IP addresses are needed.
- **Azure App Service** and **Azure Functions** become inaccessible publicly when they are associated with a private endpoint, other Azure services require additional access controls.
- To make your service private to consumers in Azure, place your service behind a standard Azure Load Balancer, then you can create a Private Link Service referencing the load balancer.
  - Choose a subnet for NAT IP addresses
  - You need disable `privateLinkServiceNetworkPolicies` on this subnet, only applies to the NAT IP you chose, NSG still applies to other resources in the subnet

    ```sh
    az network vnet subnet update \
      --name default \
      --resource-group myResourceGroup \
      --vnet-name myVirtualNetwork \
      --disable-private-link-service-network-policies true
    ```

  - All consumer traffic will appear to originate from this pool of private IP addresses (192.168.0.5 in the diagram below) to the service provider.

  ![Private link service](images/azure_private-link-service.png)


## Quick Recipes

- List private endpoints with linked private DNS zones

  **NOTE**: A private endpoint could have an empty private DNS zone group, then the built-in private DNS zone group policies can't catch it, because it's compliant.

  The following script could help find endpoints that don't have a DNS zone group or have an empty one.

  ```sh
  #!/bin/env bash

  # get PE name and resource group in a file
  az network private-endpoint list --query "[].[name, resourceGroup]"  -otsv > "pe-name-rg-list.txt"

  readarray rows < pe-name-rg-list.txt

  for row in "${rows[@]}";do
    row_array=(${row})
    name=${row_array[0]}
    rg=${row_array[1]}

    # an endpoint can only have one DNS zone group
    DNS_ZONE_ID=$(az network private-endpoint dns-zone-group list --endpoint-name $name -g $rg --query "[0].privateDnsZoneConfigs[0].privateDnsZoneId" -otsv)

    echo ${name} - ${DNS_ZONE_ID}
  done
  ```

- Re-enable a private endpoint

  Seems like you cannot approve a "Rejected" private endpoint in the Portal, it could be done via CLI:

  ```sh
  az network private-endpoint-connection approve \
    -g rg-test \
    -n pe-test \
    --resource-name kv-test \
    --type Microsoft.Keyvault/vaults \
    --description "Re-enable the endpoint"
  ```
