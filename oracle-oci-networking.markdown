# OCI Networking

- [Concepts](#concepts)


## Concepts

| OCI                           | Azure            | Note                                                                |
| ----------------------------- | ---------------- | ------------------------------------------------------------------- |
| VCN                           | vNet             |                                                                     |
| DRG (Dynamic routing gateway) | ER Gateway       |                                                                     |
| FastConnect circuit           | ER circuit       |                                                                     |
| Local Peering Gateway         | Network Peering  |                                                                     |
| Service Gateway               | Service Endpoint | Service Gateway can be set in route table, enabling transit routing |


## Transit routing for private access to Oracle Services

See https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/Network/Tasks/transitroutingoracleservices.htm#Transit_Routing_Private_Access_to_Oracle_Services

Service Gateway is similar to Service Endpoints in Azure, it enables compute instances in a VCN to access Oracle SaaS Services without exposing the VCN to the public internet.

The difference is:
- In Azure, this adds routes to the vNet route table, only works for the vNet, there's no transit routing, so it does not work for other vNets or on-prem networks
- In OCI, you can set the Service Gateway in a route table, enabling transit routing

There are two ways:

- Directly through gateways
- Through a private IP in the VCN

### Directly through gateways

![Transit routing](images/oci_networking-transit-routing-to-oracle-services.svg)

You need to associate two route tables:

1. VCN route table for the DRG attachment

    | Destination CIDR               | Route Target    |
    | ------------------------------ | --------------- |
    | All OSN services in the region | Service Gateway |

1. VCN route table for the service gateway

    | Destination CIDR             | Route Target |
    | ---------------------------- | ------------ |
    | 172.16.0.0/12 (on-prem CIDR) | DRG          |

### Through a private IP in the VCN

![Transit routing through private IP](images/oci_networking-transit-routing-to-oracle-services-through-private-ip.svg)

- The instance has two VNICs, one in each subnet
- Need 4 route tables to route the traffic

### Gotchas

- A DRG attachment or service gateway can exist without a route table associated with it.
  - However, after you associate a route table with a DRG attachment or service gateway, there must always be a route table associated with it.
  - But, you can associate a different route table. You can also edit the table's rules, or delete some or ALL rules.
