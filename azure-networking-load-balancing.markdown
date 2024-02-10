# Azure Networking - Load Balancing

- [Load balancing](#load-balancing)
- [Azure Load Balancer](#azure-load-balancer)
  - [SKUs](#skus)
  - [Distribution modes](#distribution-modes)
- [Application Gateway](#application-gateway)
  - [Overview](#overview)
  - [Components](#components)
  - [How does routing works](#how-does-routing-works)
  - [AGW subnet and NSG](#agw-subnet-and-nsg)
  - [CLI](#cli)
- [Traffic Manager](#traffic-manager)
  - [DNS resolution example](#dns-resolution-example)
  - [Traffic-routing methods](#traffic-routing-methods)
  - [Nested profiles](#nested-profiles)
- [Front Door](#front-door)
- [CDN](#cdn)
  - [Standard rules engine notes](#standard-rules-engine-notes)
  - [Custom domain HTTPS](#custom-domain-https)


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
