# Microsoft Entra

- [Overview](#overview)
- [Data Protection](#data-protection)
- [Permissions management (CloudKnox)](#permissions-management-cloudknox)
- [Global Secure Access](#global-secure-access)
  - [Global settings](#global-settings)
  - [Client app](#client-app)
  - [Traffic forwarding](#traffic-forwarding)
  - [Private network connector](#private-network-connector)
  - [Applications (private)](#applications-private)
  - [Internet access](#internet-access)


## Overview


## Data Protection

- Data is stored in one of four geographies: US, Europe, Asia Pacific, Australia
  - One is chosen based on the country you selected for your tenant
- Each geography contains 4 regions
- Each region hosts multiple "cells"
  - Each cell is replicated to 4 regions in the geo
  - Each cell serves multiple tenants
  - Each cell has multiple partitions
  - A tenant's objects are spread across multiple partitions in a cell


## Permissions management (CloudKnox)

- Microsoft Entra Permissions Management (formerly known as CloudKnox) is a cloud infrastructure entitlement management (CIEM) solution.
- Detects, automatically right-sizes, and continuously monitors unused and excessive permissions.
- Enables Zero Trust security through least privilege access in Microsoft Azure, AWS, and GCP.
- At very granular permission level
- Ad-hoc, on-demand elevation
- Separate license based on resources scanned


## Global Secure Access

### Global settings

- Tenant Restrictions: whether user can use accounts in another tenant
- Adaptive Access: provides network location info to Conditional Access
  - Shows as "**All Compliant Network locations**" in the "Network" condition

### Client app

- Tunnels network traffic from a device to the Global Secure Access
- Supports Windows, Android, iOS, MacOS
- It's also packed in Defender for Endpoint, so if you have this, no need to install the client separately

### Traffic forwarding

- Profiles to assign to GSA clients or remote networks
- Three types of profiles:
  - Microsoft traffic
  - Private access
  - Internet access
- Each profile could have:
  - Traffic policies
  - Linked Conditional Access policies
  - User and group assignments
  - Remote network assignments

### Private network connector

- Installed on-premise
- Connects to Azure
- Organized in groups
- In Azure, you can install it from Marketplace
  - You need to specify VM size, public IP, vNet, etc

### Applications (private)

- You define the CIDR ranges, protocol and ports
- You define which connector group to use
- Applications here could be used as targets in Conditional Access policies
- You can enable Private DNS for certain domain names
  - Which sends the DNS query traffic to the specified private connector group

### Internet access

- Can do TLS inspection