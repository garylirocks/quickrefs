# Active Directory

## Overview

- There are objects, like users, groups, machines
- Objects are placed in OUs (Organization Units), forming a hierarchy
- Group policy can be linked to OU
- Each object has a distinguished name like `CN=Gary Li,OU=IT,DC=example,DC=com`
- Data are saved using X.500 schema

- Access
  - LDAP protocol

- Domain Controllers
  - Each DC has a full copy of the domain data
  - Start a domain by install "AD DS" and "DNS Server" roles on a Windows Server, then promote it to be a domain controller
  - Other DCs can join an existing domain, then the domain data is replicated to it
  - Most DCs are read-write
    - A DC could be read-only as well, it may only have a subset of the data
  - A Domain Controller can also be of type "Global Catalog", caching data from other domains in the same forest

- Authentication
  - Kerberos (preferred)
  - LDAP
  - NTLM

- The domain name is the DNS domain name, such as `example.com`
  - The default NetBIOS name is the first 15 characters of the first section of the domain name, in this case `EXAMPLE`

- Sites and Subnets
  - You can have subnets like
    - "CN=10.0.0.0/16,CN=Subnets,CN=Sites,CN=Configuration,DC=example,DC=com"
    - "CN=10.1.0.0/16,CN=Subnets,CN=Sites,CN=Configuration,DC=example,DC=com"
  - You can have sites like
    - "CN=NewYork,CN=Sites,CN=Configuration,DC=example,DC=com"
    - "CN=Azure,CN=Sites,CN=Configuration,DC=example,DC=com"
  - A site can link to a subnet
  - You can have DCs in an Azure vNet, define them as a site
  - Then based on the IP of each machine, AD knows which site each machine belongs to

- Trees and forests
  - A single domain is also a tree and a forest, you can expand it with more domains
  - `example.com` could have children domains `us.example.com` and `uk.example.com`, they form a tree, and have transitive trust between them
  - `foo.com` can join the forest, and have a forest root trust to `example.com`
  - "Schemas" and "Configurations" are replicated forest wide

## DNS

- Often installed on Domain Controllers
- Allows dynamic update of records
- There are "SRV" records for locating services (domain names and ports)

### Replication

- The server level forwarders config is not replicated, it's a server-specific setting.
  - Seems when you add a new DC, it would get this config from an existing DC, it's only one-off
- All DNS zones are replicated, you could configure the replication scope

  ```powershell
  # replicate to domain or forest
  Add-DnsServerConditionalForwarderZone `
    -ComputerName my-dc-001 `
    -Name gary.example.com `
    -ReplicationScope [Domain|Forest] `
    -MasterServers 8.8.8.8

  # replicate to a custom directory partition
  Add-DnsServerConditionalForwarderZone `
    -ComputerName my-dc-001 `
    -Name gary.example.com `
    -ReplicationScope Custom `
    -DirectoryPartitionName partition1.gary.example.com `
    -MasterServers 8.8.8.8
  ```
