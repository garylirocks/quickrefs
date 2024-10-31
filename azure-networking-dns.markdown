# Azure Networking - DNS

- [Overview](#overview)
- [DNS resolution within virtual networks](#dns-resolution-within-virtual-networks)
- [Azure-provided name resolution](#azure-provided-name-resolution)
- [Private DNS zones](#private-dns-zones)
- [Your own DNS server](#your-own-dns-server)
- [CLI](#cli)


## Overview

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

## DNS resolution within virtual networks

There are a few options:

- Azure DNS private zones
- Azure-provided name resolution
- Your own DNS server
- Azure DNS Private Resolver (*replaces setting up your own DNS servers*)

## Azure-provided name resolution

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
- The DNS zone is `.internal.cloudapp.net.`
- Any VM created in the vNet is registered
- The domain name is
  - Windows: computer name
  - Linux: hostname is the same as VM resource name by default ?
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

## Private DNS zones

You could link a Private DNS Zone to a vNet (not subnet), enable auto-registration, then hostname of any VMs in the vNet would be registered in this Private DNS Zone

- The vNet and the Private DNS Zone could be in different subscriptions, to create a vNet link, permissions required:
  - `Microsoft.Network/privateDnsZones/virtualNetworkLinks/write` on the Private DNS Zone
  - `Microsoft.Network/virtualNetworks/join/action` on the vNet
  - The builtin role `Private DNS Zone Contributor` has the required permissions
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

## CLI

```sh
az network private-dns zone list
    --output table

az network private-dns record-set list \
    -g <resource-group> \
    -z <zone-name> \
    --output table
```
