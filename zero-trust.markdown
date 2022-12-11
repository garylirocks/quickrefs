# Zero Trust


## Principles

1. Verify Explicitly

    Users, devices, service principles, ...

2. Least Privilege

    Small chunks, Just In Time

3. Assume Breach


## Layers/entities

- Identity
- Endpoint
- Network
- Infrastructure
- Application
- Data
- SIEM


## Identity

- SSO
  - MFA
  - Passwordless
  - Disable legacy auth
- RBAC
  - PIM (Just In Time)
  - Control plane and data plane
- Conditional access
- Session control ?


## Endpoint

- Corporate, personal, IoT devices
- TPM (Trusted Platform Module), Secure trusted boot (ie. UEFI)
- Device cert (mutual TLS)
- Register -> Managed (ie. Intune) -> Compliant


## Network

- End-to-end encryption (TLS, IPSec)
- Layers/tiers
- Micro-segmentation (NSG, ASG, Azure Firewall, ...)


## Infrastructure

- Trusted
- JIT(Just-In-Time) RDP/SSH
- Signals


## Application

- Security policy at service
- Proxy/VDI
- Find shadow IT (balance between security and function)


## Data

- Data-driven protection: protection traveling with data

Discover
  - Inventory
  - Classify / Label (machine learning)

Encryption
  - at rest
  - end-to-end


## SIEM

Collecting, analysing signals from all sources
