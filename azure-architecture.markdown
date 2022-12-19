# Azure architecture

## Well Architected Framework

Five pillars, use "CORPS" as a mnemonic

### Cost optimization

- Right size, sku
- Stop/deallocate/delete when not used
- VM: spot instance, resevered instance
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