# Zero Trust

## Principles

1. Verify Explicitly

    Users, devices, service principles, ...

2. Least Privilege

    Small chunks, Just In Time

3. Assume Breach


## Identity

- SSO
  - MFA
  - Passwordless
  - Disable legacy auth
- RBAC
  - PIM (Just In Time)
  - Control plane and data plane

## Endpoint

- Corporate, personal, IoT devices
- TPM (Trusted Platform Module), Secure trusted boot (ie. UEFI)
- Device cert (mutual TLS)
- Register -> Managed (ie. Intune) -> Compliant

## Network

- End-to-end encryption (TLS, IPSec)
- Layers/tiers
- Micro-segmentation (NSG, ASG, Azure Firewall, ...)

## SIEM

Collecting, analysing signals