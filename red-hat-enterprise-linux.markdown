# Red Hat Enterprise Linux

- [Subscriptions](#subscriptions)
- [Package management](#package-management)
  - [Repos](#repos)
- [RHEL System Roles](#rhel-system-roles)
  - [Use rhc to register or unregister a system](#use-rhc-to-register-or-unregister-a-system)
- [Satellite](#satellite)


## Subscriptions

- Subscriptions could be for RHEL OS or other Red Hat products
- A subscription is not tied to a paticular RHEL version, you could upgrade RHEL using the same subscription

To register your OS with Customer Portal Subscription Management service (or on-prem Subscription Asset Manager), run:

```sh
subscription-manager register

subscription-manager unregister
```

*If RedHat Insights is enabled, during registration, insights data will be collected and sent to RedHat.*

Simple Content Access (SCA) is intended to simplify entitlement tooling.

```sh
subscription-manager register --username <$INSERT_USERNAME_HERE>

# OR (if using activation keys)
subscription-manager register --org <$INSERT_ORG_ID_HERE> \
  --activationkey <$INSERT_ACTIVATION_KEY_HERE>

# then, (if necessary) enable additional repos
subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
```


## Package management

DNF is the next major version of YUM

You can install a plugin with `dnf install 'dnf-command(versionlock)'`

### Repos

```sh
# show available repos
subscription-manager repos
```


## RHEL System Roles

Install

```
dnf install rhel-system-roles ansible-core
```

### Use rhc to register or unregister a system

```yaml
---
- name: Register to Satellite
  hosts: localhost
  vars_files:
    - secrets.yml   # contains activationKey
  vars:
    rhc_auth:
      activation_keys:
        keys:
          - "{{ activationKey }}"
    rhc_organization: GaryOrg
    rhc_server:
      hostname: my-satellite.com
      port: 443
      prefix: /rhsm
      insecure: true
    rhc_baseurl: http://example.com/pulp/content
    rhc_insights:  # disable Red Hat Insights
      state: absent
      autoupdate: false
      remediation: absent
  roles:
    - role: rhel-system-roles.rhc
```

To unregister

```yaml
---
- name: Unregister the system
  hosts: localhost
  vars:
    rhc_state: absent
  roles:
    - role: rhel-system-roles.rhc
```


## Satellite

Functions:

- Subscription management
- Provisioning
- Configuration management
- Patch management

Infrastructure:

- Satellite Server
  - Multi tenant, there could be multiple organizations
    - Each org could have multiple locations
  - On-prem repository management
  - RBAC
  - GUI, API, CLI
  - Advanced subscription management
  - Connected to RedHat Insights (predictive analytics)
- Satellite Capsule Server
  - Mirrors content from Satellite Server
  - No UI
  - Deployed to different geo locations, enabling scaling of your Satellite environment
  - Provides local content, provisioning, and integration services
  - Discovery of new physical & virtual machines

Other concepts:

- **Errata**: patches, could be security, bugfix, enhancement
- Content -> **product**: collection of repositories, you need to specify sync plan
- **Repositories**: you need to specify the upstream URL, GPG key, OS version, architecture, repo type, etc
- **Content View**:
  - Single Content View: a group of repositories (could be from multiple products)
  - Composite Content View: consists of multiple single content views
  - Filters: to include/exclude specific contents
  - Publish new version: creates a version and put it in the "Library" lifecycle environment
  - Promote: promote a version to other lifecycle environments
- **Activation Key**:
  - a key to register a system to Satellite
  - associates a system with a specific organization, location, and lifecycle environment
  - can override which repositories are enabled or disabled
