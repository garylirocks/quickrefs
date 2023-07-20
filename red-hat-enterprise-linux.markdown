# Red Hat Enterprise Linux

## Subscriptions

- Subscriptions could be for RHEL OS or other Red Hat products
- A subscription is not tied to a paticular RHEL version, you could upgrade RHEL using the same subscription

To register your OS with Customer Portal Subscription Management service (or on-prem Subscription Asset Manager), run:

```sh
subscription-manager register

subscription-manager unregister
```

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
