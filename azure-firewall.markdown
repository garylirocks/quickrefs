# Azure Firewall

- [Overview](#overview)
- [Azure Firewall Manager](#azure-firewall-manager)
- [Firewall policy](#firewall-policy)
  - [Rule types](#rule-types)
  - [Rule matching](#rule-matching)
- [TLS inspection](#tls-inspection)
- [Asymmetric routing](#asymmetric-routing)


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
- **Threat Intelligence**
  - Alert/deny traffic from known malicious IP and domains

DNS proxy:
- Azure Firewall could be used as a DNS proxy, this enables FQDN-based network rules
- Supports DNS request logging

Premium SKU only:
- TLS inspection
- IDPS: Intrusion Detection and Prevention System


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

Pricing:

- Azure Firewall policies could incur charges
- No charge if a policy is associated to a single firewall
- Otherwise, if a policy is associated to multiple firewalls, it's charged per region per month


## Firewall policy

- Created in Firewall Manager
- Not only security policies, can have **routing policies as well**.
  - User-defined routes aren't needed to route traffic through the firewall.
- Policy organization: Firewall Policy resource -> Rule Collection Group (could have multiple types) -> Rule Collection (single type) -> rule (single type)
- Rule types:
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

### Rule types

- **NAT rules**:
  - Translate firewall public IP/port to a private IP/port, could be helpful in publishing SSH, RDP, or non-HTTP/S applications to the Internet
  - DNAT rules are applied first. If a match is found, an **implicit corresponding network rule to allow the translated traffic is added**. You can override this behavior by explicitly adding a network rule collection with deny rules that match the translated traffic. **No application rules are applied for these connections**.
  - Work for private IP destinations as well (ie. spoke to spoke, on-prem to spoke)
  - In addition to DNAT, inbound connections via public IP are always SNATed to one of the firewall private IPs. (For HTTP/s traffic, Azure Front Door or Application Gateway in front of the firewall could preserve the original client IP in `X-Forwarded-For` header)
- **Network rules**:
  - Apply to TCP, UDP, ICMP or any IP protocol
  - Could inspect traffic from one subnet to another
  - Inbound/outbound filtering rules by source, destination, port and protocol, it can distinguish legitimate packets for different type of connections
  - **Service tags** are supported as destinations
  - Also support **FQDN-based limits** to more precisely control egress traffic that application rules don't handle, this feature requires that DNS proxy is enabled. A common use is limiting Network Time Protocol (NTP) traffic to known endpoints, such as `time.windows.com`
- **Application rules**:
  - Does **NOT** apply to inbound traffic (when traffic DNATed to a private IP)
    - If you want to filter inbound HTTP/S traffic, use WAF
  - Only works for HTTP/S and MSSQL protocols
    - For HTTP, matches the **"Host" header**
    - For HTTPS, matches according to **Server Name Indication**
    - Does not require TLS termination
  - FQDN could include wildcard
  - Could use **FQDN tags** (not service tags), which are comprised of a list of FQDNs
    - Windows Update
    - Azure Backup
    - App Service Environment
    - etc
  - Firewall needs to be **able to resolve the FQDN** to an IP address, otherwise you get a "Failed to resolve address" error, and the traffic is denied
    - In both HTTP and TLS inspected HTTPS cases, the firewall ignores the packet's destination IP address and uses the DNS resolved IP address from the "Host" header. (DNS resolution is done by Azure DNS or by a custom DNS if configured on the firewall)
    - Why does it need to resolve the FQDN ?
  - The firewall expects to get port number in the Host header, otherwise it assumes the standard port 80. If there's a port mismatch between the actual TCP port and the port in the host header, the traffic is dropped. 
  - Azure Firewall includes a built-in rule collection for **infrastructure FQDNs** that are allowed by default and evaluated after all custom application rules.
    - Compute access to storage Platform Image Repository (PIR)
    - Managed disks status storage access
    - Azure Diagnostics and Logging (MDS)

### Rule matching

- By default, all traffic is blocked
- Rule collection groups are processed in priority order (100 -> 65000)
- Rule collections are processed in priority order (100 -> 65000)
- Rule Collection Groups in the parent policy always takes precedence regardless of the priority of a child policy regardless of priority number
- DNAT rules are processed first, then network rules, then application rules
  - **Regardless** of Rule Collection Group or Rule Collection priority and policy inheritance
- The rules are **terminating**, so rule processing stops on a match
  - If a match is found in network rules, application rules are not processed
  - If no network and application rules match, the traffic is denied
- Threat Intelligence
  - If you enable threat intelligence-based filtering, those rules are **highest priority** and are always processed first (before network and application rules). Threat-intelligence filtering may deny traffic before any configured rules are processed.
- IDPS
  - *Alert* mode: IDPS engine works in **parallel** to the rules engine, and generates a log entry
  - *Alert and Deny* mode: IDPS engine works **after** rules engine (even the traffic is denied by rules ?)
    - IDPS blocks flow silently, no "RST" is sent on the TCP level


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


## Asymmetric routing

![Azure Firewall asymmetric routing](images/azure_networking-firewall-asymmetric_routing.png)

- Under the hood, Azure Firewall has a public ALB and a internal ALB
- You want traffic from spoke to a shared service in the CommonServices subnet in hub to be filtered by Firewall
- The UDR rule in red (hub vNet range as prefix) could cause asymmetric routing, inbound traffic goes via instance `.7`, but return traffic goes via instance `.6`
- If a spoke needs to reach a specific subnet in hub vNet, use the subnet's range as prefix (eg. `192.168.1.0/24`), instead of the whole hub vNet address space
