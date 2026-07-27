# Azure Virtual Desktop

## Features

- Multi-session Windows 10
- Support Remote Desktop Services (RDS) environments


## Concepts

- **Host pool**
  - A collection of VMs, as session hosts
  - Number of session hosts in a host pool can be scaled up or down
  - Two types: Personal or Pooled
- **Application group**
  - A logical grouping of applications that are available on session hosts
  - Must be put in a host pool, and a workspace
  - Two types: RemoteApp or Desktop
  - Assigned to users or groups
- **Workspace**
  - A logical grouping of application groups
  - Controls network access (public, or private endpoint)
- **Scaling plan**
  - Allows you to define schedules and automatically scale session hosts in a host pool based on workload and the schedules defined in the scaling plan
- **Custom image template**
  - Used when adding session hosts
  - Easily add common customizations or custom scripts
  - Used Azure Image Builder and tailored for Azure Virtual Desktop


## Networking

- AVDs run in your virtual network
- **Doesn't require any inbound access** to your virtual network
- A set of outbound network connections are required


## Management

- Deployment
  - Standard
  - Host pool configuration: ONLY for polled host pools, NOT personal host pools
- Update
  - If using "Host pool configuration", you could automate the update of session hosts in a host pool
    - New hosts created using the new configuration
    - Initial update targeting one host
    - If successful, update the rest of the hosts in batches
  - For standard host pool, you need to update the host pool manually
    - By adding new hosts with new image, then removing the old hosts ?