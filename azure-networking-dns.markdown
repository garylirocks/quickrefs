# Azure Networking - DNS

- [Azure DNS (public DNS)](#azure-dns-public-dns)
- [DNS resolution within virtual networks](#dns-resolution-within-virtual-networks)
- [Azure-provided name resolution](#azure-provided-name-resolution)
- [Private DNS zones](#private-dns-zones)
  - [CLI](#cli)
- [Your own DNS server](#your-own-dns-server)
- [DNS Private Resolver](#dns-private-resolver)
  - [Inbound endpoint](#inbound-endpoint)
  - [Outbound endpoint](#outbound-endpoint)
  - [DNS forwarding rulesets](#dns-forwarding-rulesets)
  - [Architecture](#architecture)
- [Security](#security)
  - [DNS security policy](#dns-security-policy)


## Azure DNS (public DNS)

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
- DNSSEC (in preview)

Missing features:

- No conditional forwarding and no query logging
  - You need to Bring-Your-Own DNS service, and conditionally forward queries to Azure DNS

## DNS resolution within virtual networks

There are a few options:

- Azure DNS private zones
- Azure-provided name resolution
- Your own DNS server
- Azure DNS Private Resolver (*replaces setting up your own DNS servers*)

## Azure-provided name resolution

Example (a VM `vm-demo-001` in a vNet)

View/update hostname

```sh
hostname --fqdn
# vm-demo-001.bkz3n5lfd3kufhikua4wl40kwg.px.internal.cloudapp.net

hostname --all-fqdns
# vm-demo-001.internal.cloudapp.net

# change hostname
hostnamectl set-hostname vm-demo-001.newdomain.com
```

View DNS setting

```sh
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
```

Reverse lookup

```sh
nslookup -type=PTR 10.0.0.4
# Non-authoritative answer:
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.internal.cloudapp.net.

# after you link private DNS zone `example.private` to the vNet with auto-registration
nslookup -type=PTR 10.0.0.4
# Non-authoritative answer:
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.internal.cloudapp.net.
# 4.0.0.10.in-addr.arpa   name = vm-demo-001.example.private.
```

- DNS IP is `168.63.129.16`, this is static, same in every vNet
- The IP is assigned to NICs for DNS by the default Azure DHCP assignment
  - If you update the DNS server setting of a vNet, you need to restart a VM for the change to take effect on the VM
- The DNS zone is `.internal.cloudapp.net.`
- Any VM created in the vNet is registered
- The domain name is
  - Windows: computer name
  - Linux: hostname is the same as VM resource name by default ?
  - *Tested in Ubuntu, if you update VM hostname, the DNS record updates automatically*
- PTR queries return FQDNs of form
  - `[vm-name].internal.cloudapp.net.`
  - `[vm-name].[privatednszonename].` (when private DNS zone linked to the vNet, and auto-registration enabled)
- See here for client side DNS caching(`dnsmasq`) and retry configs: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances#dns-client-configuration

Considerations:

- Scoped to vNet, a DNS name created in one vNet can't be resolved in another vNet
- You should use a unique name for each VM in a vNet to avoid conflicts
- WINS and NetBIOS are not supported, you cannot see your VMs in Windows Explorer

## Private DNS zones

A private zone could be linked to one or more vNet (not subnet)

- The vNet and the Private DNS Zone could be in different subscriptions, to create a vNet link, permissions required:
  - `Microsoft.Network/privateDnsZones/virtualNetworkLinks/write` on the Private DNS Zone
  - `Microsoft.Network/virtualNetworks/join/action` on the vNet
  - The builtin role `Private DNS Zone Contributor` has the required permissions
- Auto-registration
  - Hostname of any VMs in the vNet would be registered in this Private DNS Zone
  - A vNet could be linked to multiple private zones, but **ONLY ONE** could have auto-registration enabled, even your vNet is configured with custom DNS servers, the auto-registration still happens
- Fallback to internet (preview)
  - It's a setting in vNet link `"resolutionPolicy": "NxDomainRedirect"`
  - When `NXDOMAIN` is returned from a private DNS zone, Azure redirects the query to public DNS resolver
  - Only available for Private DNS zones associated to Private Link resources (`privatelink.*` domains)
  - This helps when you access a private-link enabled PaaS resource in another tenant
    - Your DNS query would resolve to the public IP address of the resource
- Note
  - A private zone is global, could be accessed from any region, any subscription, any tenant.

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

### CLI

```sh
az network private-dns zone list
    --output table

az network private-dns record-set list \
    -g <resource-group> \
    -z <zone-name> \
    --output table
```


## Your own DNS server

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


## DNS Private Resolver

![Overview](./images/azure_dns-private-resolver.png)

A private resolver is deployed into a vNet, it needs a subnet for inbound endpoint, another for outbound endpoint.

### Inbound endpoint

- Provisioned with a private IP
- On-prem DNS servers need a forwarding rule pointing to this IP
- Other vNets can have a DNS forwarding ruleset associated, to forward some queries to this IP

### Outbound endpoint

- NOT provisioned with an IP
- Can be linked to DNS forwarding rulesets

### DNS forwarding rulesets

- A ruleset can have up to 1000 DNS forwarding rules
- A ruleset can be linked to multiple vNets in the same region
  - vNet could be in another subscription
  - CAN'T be in another region
- A ruleset must be associated with **at least one** outbound endpoint
- A single ruleset can be associated with up to 2 outbound endpoints belonging to the same DNS Private Resolver instance
  - CAN'T be associated to multiple private resolver instances

Rules example:

| Rule name    | Domain name        | Destination IP:Port       | Rule state |
| ------------ | ------------------ | ------------------------- | ---------- |
| Contoso      | contoso.com.       | 10.11.0.4:53,10.11.0.5:53 | Enabled    |
| AzurePrivate | azure.contoso.com. | 10.10.0.4:53              | Enabled    |
| Wildcard     | .                  | 10.11.0.4:53,10.11.0.5:53 | Enabled    |

- Rules are prioritized by longest suffix match
- Destination IP
  - Could have multiple destinations IPs, only the first one is used, unless it's unresponsive
  - Can't use the Azure DNS IP address of `168.63.129.16` as the destination IP
- Could have a wildcard `.`, matching any domain names
  - Azure services domains (eg. `windows.net`, `azure.com`, `azure.net`, `windowsazure.us`) are excluded
- If any destination in a rule is an inbound endpoint, this ruleset should not be linked to the vNet containing the inbound endpoint, doing this will lead to a **resolution loop**

### Architecture

![Centralized DNS architecture](./images/azure_dns-private-resolver-centralized-architecture.png)

- Private DNS zones linked to hub vNet
- DNS private resolver in hub vNet
  - Outbound endpoint and DNS forwarding ruleset is *optional*, only required if you need to resolve on-prem DNS names
- To resolve on-prem DNS names
  - Add a rule to the ruleset, eg. `onprem.local. 192.168.10.10`
  - The ruleset needs to be linked to **both the outbound endpoint and the hub vNet**
- Spoke vNet uses inbound endpoint IP as DNS server
  - So for a VM in spoke vNet to resolve an on-prem DNS name, the query goes like this: `spoke vm -> inbound endpoint in hub vNet -> (matching the rule) -> outbound endpoint -> on-prem DNS server`
- Hub vNet uses Azure provided DNS
  - So for a VM in hub vNet to resolve an on-prem DNS name, the query goes like this: `hub vm -> Azure-provided DNS in hub vNet -> (matching the rule) -> outbound endpoint -> on-prem DNS server`


## Security

### DNS security policy

- **DNS traffic rules**:
  - Processed in order of priority
  - A rule can have multiple DNS domain lists
  - Actions: Allow, Block and Alert
- **Virtual network links**
  - A policy can only be linked to vNets in the same region
  - policy:VNet relationship is **1:N**
- **DNS domain lists**
  - A list could be used in multiple DNS traffic rules in different security policies
  - Wildcard domains are allowed