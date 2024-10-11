# Azure Firewall

- [Overview](#overview)
- [Asymmetric routing](#asymmetric-routing)
- [Azure Firewall Manager](#azure-firewall-manager)
- [Firewall policy](#firewall-policy)
- [TLS inspection](#tls-inspection)


## Overview

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

- **NAT rules**:
  - Translate firewall public IP/port to a private IP/port, could be helpful in publishing SSH, RDP, or non-HTTP/S applications to the Internet
  - DNAT rules are applied first. If a match is found, an **implicit corresponding network rule to allow the translated traffic is added**. You can override this behavior by explicitly adding a network rule collection with deny rules that match the translated traffic. No application rules are applied for these connections.
  - Limitations:
    - Doesn't work for private IP destinations (ie. spoke to spoke, on-prem to spoke)
  - In addition to DNAT, inbound connections via public IP are always SNATed to one of the firewall private IPs. (For HTTP/s traffic, Azure Front Door or Application Gateway in front of the firewall could preserve the original client IP in `X-Forwarded-For` header)
- **Network rules**:
  - Apply to **non-HTTP/S traffic** that flow through the firewall, including traffic from one subnet to another
  - Inbound/outbound filtering rules by source, destination, port and protocol(TCP, UDP, ICMP or any), it can distinguish legitimate packets for different type of connections
  - **Service tags** are supported as destinations
  - Also support **FQDN-based limits** to more precisely control egress traffic that application rules don't handle, this feature requires that DNS proxy is enabled. A common use is limiting Network Time Protocol (NTP) traffic to known endpoints, such as `time.windows.com`
- **Application rules**:
  - Does not apply to inbound traffic
  - Only allow a list of specified FQDNs for outbound HTTP/S or Azure SQL traffic to a specified list of FQDN including wild card. Does not require TLS termination.
    - For HTTP, matches the **"Host" header**
    - For HTTPS, matches according to **Server Name Indication**
  - Could use **FQDN tags** (not service tags), which are comprised of a list of FQDNs
    - Windows Update
    - Azure Backup
    - App Service Environment
    - etc
  - Azure Firewall includes a built-in rule collection for infrastructure FQDNs that are allowed by default.
    - Compute access to storage Platform Image Repository (PIR)
    - Managed disks status storage access
    - Azure Diagnostics and Logging (MDS)

- **Threat Intelligence**
  - Alert/deny traffic from known malicious IP and domains

Rule matching:
- Network rules are processed before application rules
- Rules are terminating, if a match is found in network rules, application rules are not processed
- If no rules match, the traffic is denied

DNS proxy:
- Azure Firewall could be used as a DNS proxy, this enables FQDN-based network rules
- Supports DNS request logging

Premium SKU only:
- TLS inspection
- IDPS: Intrusion Detection and Prevention System


## Asymmetric routing

![Azure Firewall asymmetric routing](images/azure_networking-firewall-asymmetric_routing.png)

- Under the hood, Azure Firewall has a public ALB and a internal ALB
- You want traffic from spoke to a shared service in the CommonServices subnet in hub to be filtered by Firewall
- The UDR rule in red could cause asymmetric routing, inbound traffic goes via instance `.7`, but return traffic goes via instance `.6`
- The UDR rule in spoke should not include the Firewall subnet, set the prefix to `192.168.1.0/24`, instead of the whole hub address space


## Azure Firewall Manager

![Firewall manager overview](images/azure_firewall-manager.png)

In a large network deployment, you could have multiple firewall instances in hub vNets and secured virtual hubs, Azure Firewall Manager helps to manage rules across all the instances.

- A central view of security services (Azure Firewall, WAF, DDoS etc) in **multiple regions and subscriptions**
- Hierarchical policies:
  - Central IT author global policies
  - DevOps team could author local firewall rules for better agility
- For secured vHubs only:
  - Third-party security-as-a-service integration, they use Firewall Manager's API to set up security policies (currently supports zScaler, iBoss, Check Point)
  - Centralized route management: easily route traffic to your secured hub for filtering and logging without the need to manually setup UDR on spoke vNets


## Firewall policy

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


## TLS inspection

Without TLS inspection

![Without TLS](./images/azure_firewall-without-tls-inspection.png)

With TLS inspection

![Without TLS](./images/azure_firewall-with-tls-inspection.png)

- The certificate presented to the client is generated on-the-fly
- Supports:
  - Outbound TLS inspection
  - East-West (Azure from/to on-prem)
- No support for Inbound TLS inspection (you can do this with WAF on AGW)