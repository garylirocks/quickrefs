# Azure architecture

- [Well Architected Framework](#well-architected-framework)
  - [Cost optimization](#cost-optimization)
  - [Operational excellence](#operational-excellence)
  - [Reliability](#reliability)
  - [Performance efficiency](#performance-efficiency)
  - [Security](#security)
- [Paired regions](#paired-regions)
  - [Regions with no pair](#regions-with-no-pair)
  - [Storage](#storage)
  - [Key Vault](#key-vault)
- [Cloud design principles](#cloud-design-principles)


## Well Architected Framework

Five pillars, use "CORPS" as a mnemonic

### Cost optimization

- Right size, sku
- Stop/deallocate/delete when not used
- VM: spot instance, resevered instance
- SQL DB: elastic pool, reserved capacity
- Autoscaling
- Policy
- Budget

### Operational excellence

- DevOps
  - IaC: declarative
  - Deployment: blue/green, canary, a/b testing
  - Testing: unit, smoke, integration, stress, security, fault injection (Chaos studio)
- Automation
  - Logic Apps
  - Azure Functions
  - Azure Automation
  - React to monitoring alerts
- Custom images
  - VM Image Builder (uses Packer under the hood)
  - Image gallery

### Reliability

- SLA
  - 99.99 ~ 1 min per week
  - 99.9 ~ 10 min per week
- Availability sets
- Availability zones
- Regions
- RPO: recovery point objective, how much can I lose
- RTO: recovery time objective
  - Backup
  - Replication
  - Active-active

### Performance efficiency

- Auto scale: VMSS, AKS, App service
- DB
- Storage
- Caching: Redis, CDN, Frontdoor
- Network: latency, egress

### Security

- Regulatory standard
- Zero Trust
- Defense in Depth
  - Data
  - App
  - Compute
  - Network
  - Perimeter
  - Policy: Conditional access, MFA, PIM
  - Physical security (Microsoft's responsibility)


## Paired regions

- Usually in the same geo-political boundary (100s of miles apart)
- Latency in 10s of ms, data sync is asynchronous
- Some services use paired regions for resiliency:
  - Storage: GRS
  - Key Vault: replication
  - Staged rollout, one region in a pair is prioritized
    - One region gets the update 24 hours earlier than the other
    - If you have a active-passive workload, the active instance needs to be in the first region, when there's an issue with an update, you could failover to the second region
- Cons:
  - Paired regions could have different features (eg. one doesn't support AZ)

### Regions with no pair

- Region pairs were introduced before AZs
- Some new regions support AZs, but have no region pair
  - Use ZRS, or Cross Region Disaster Recovery
- Some servies don't care about region pairs
  - Data services: eg. Cosmos DB, SQL could have replicas in any region
  - Global services: eg. AFD, Traffic manager, cross-region load balancer

### Storage

GRS has some limitations:
- All data are copied, no filtering
- Same access tier on the paired region, you can't use a cheaper tier
- Mostly used in DR scenario, although you could have RAGRS

Alternatively, we could use **[Object replication](./azure-storage.markdown#object-replication)**, it's more flexible
- Destination could be any region
- Destination could be a cheaper access tier
- Filter on data

*But it's slower, and only supports blobs, not ADLS Gen2, Files, etc*

### Key Vault

See [here](./azure-key-vault.markdown#replication-and-backup)

You should avoid using global secrets, keys.
- Create one per country
- Consider using managed identity, federated credentials, etc


## Cloud design principles

- Design for failure
  - Multiple instances/zones/regions
  - Intelligent code: retry, exponential backoff
  - Observability
- Elasticity and scale
  - Auto scale
  - Serverless
  - PaaS
- IaC and SDP (software deployment process)
  - Automated pipelines
  - Rolling update
- Governance
  - Policy
  - Tagging
  - Budgets for cost control
- Security
  - Zero trust, least privilege
  - Avoid secrets
  - Use passkeys
  - Encrypt everywhere
