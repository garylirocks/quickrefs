# Cloud adoption framework

- [Stages](#stages)
- [Motivations](#motivations)
- [Financial considerations](#financial-considerations)
- [Operating models](#operating-models)
- [Landing zones](#landing-zones)
- [Conceptual architecture](#conceptual-architecture)
  - [Policies](#policies)
  - [Monitoring basline](#monitoring-basline)
  - [Tools and resources](#tools-and-resources)
- [Deploy with Terraform](#deploy-with-terraform)
  - [ALZ Terraform module](#alz-terraform-module)
  - [CAF Terraform landing zones](#caf-terraform-landing-zones)


## Stages

Cloud Adoption Framework consists of tools, documentation, and proven practices. It has five stages:

1. Strategy
    1. Motivation
    1. Goals
    1. Financial considerations
    1. Technical considerations
2. Plan
    1. What digital estate to migrate
    1. Who needs to be involved
    1. Skills readiness
    1. A plan that brings together development, operations and business teams
3. Ready: create a landing zone
4. Adopt: migrate and innovate
5. Govern and manage your cloud environments


## Motivations

You could have multiple motivations.

Sometimes, you'd better commit to a single motivation category for a time-bound period. So you could avoid misalignment of the people, process and projects.


## Financial considerations

Cost-saving offers:

- Reserved Instances
- Hybrid Benefit: Use your on-prem Windows Server ans SQL Server licenses on Azure
- Spot VM: VMs for workloads that can be interrupted (eg. CI/CD, dev/test, visual rendering, etc)
- Enterprise Agreement
- Dev/Test pricing (requires active Visual Studio subscription)

Enforce tagging conventions with Azure Policy


## Operating models

Common IT operating models

<img src="images/azure_operating-models.png" width="600" alt="Operating models" />

- Decentralized

  <img src="images/azure_decentralized-operations.png" width="400" alt="Decentralized opetations" />

  - Organized around workloads, minimal dependency on centralized operations
  - Prioritize innovation over control

- Central

  <img src="images/azure_centralized-operations.png" width="400" alt="Central opetations" />

  - Most common model
  - Controlled production environment that's managed solely by centralized operations
  - Prioritize control and stability, often third-party compliance requirements drive environmental decisions

- Enterprise

  <img src="images/azure_enterprise-operations.png" width="400" alt="Enterprise opetations" />

  - For migrating entire datacenters or large portfolios
  - Large number of landing zones with foundational utilities centralized into a platform foundation
  - Balance the need for innovation in some landing zones and tight control in others
  - Build-and-operate for each workload team

- Distributed
  - Usually a result of acquisitions
  - Should consider transitioning to one of other models


## Landing zones

## Conceptual architecture

![Reference architecture](images/azure_caf-reference-architecture-for-landing-zones.png)

- Sandboxes management group contains subscriptions for dev/testing with loose or no policies applied. **They should NOT have direct connectivity to the landing zone subscriptions.**

### Policies

The reference landing zone implementation includes DINE and Modify policies, which help the landing zones and resources to be compliant, eg.

- Enable Microsoft Defender for Cloud, configure Defender exports to the central Log Analytics workspace(LAW) in the management subscription
- Enable Defender for Cloud for different resource types as per requirements
- Configure Azure Activity logs and diagnostic settings to be sent to the central LAW
- Deploy the required Azure Monitor agents for VM, VMSS, Arc connected servers, etc, sending logs to central LAW

### Monitoring basline

- Each subscription should have at least one action group, which should include an email notification channel
- You can use Azure Policy to create alert rules/alert processing rules/action groups at scale when the resources are deployed, see: https://azure.github.io/azure-monitor-baseline-alerts/welcome/

### Tools and resources

Most of them developed and maintained by Microsoft employees

- [AzAdvertizer](https://www.azadvertizer.net/), up-to-date info on different Azure Governance capabilities
  - Built-in/ALZ/Community Policies, initiatives
  - Security & regulatory compliance controls
  - Azure aliases
  - Built-in roles
  - Azure resource provider operations (used in role definition)
- [AzGovViz](https://github.com/JulianHayward/Azure-MG-Sub-Governance-Reporting), visualize Azure Governance hierarchy
- [Enterprise-Scale - Reference Implementation](https://github.com/Azure/Enterprise-Scale)
  - Can be deployed with Portal, ARM, Bicep and Terraform Modules
  - It has custom policy definitions (the `ALZ` type in AzAdvertizer)
  - Those policies are assigned to multiple levels [within the hierarchy](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies#what-policy-definitions-are-assigned-within-the-azure-landing-zones-custom--built-in)
- [Enterprise Policy-as-Code (aka EPAC)](https://github.com/Azure/enterprise-azure-policy-as-code), for deploy Azure policies at scale, using PowerShell scripts, easy to integrate with CI/CD pipelines
  - It has a script to pull policies from [ALZ repo](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies)


## Deploy with Terraform

![Terraform options](images/azure_caf-tf-module-compare.png)

There are two options:
- ALZ Terraform module
- CAF Terraform landing zones

### ALZ Terraform module

- Management hierarchy
- Policies/policy sets definition and assignment
- Creating proper role assignment for the managed identity of policy assignment !
- Resources in platform landing zones (Connectivity/Management/Identity)

Limitations:

- Doesn't create network peering from spoke to hub
- `Modify` and `DeployIfNotExists` assignments modify resources, may conflicts with Terraform configs for workload resources.

**Archetype** is a package of Azure Policy(policies/policy sets/policy assignments) and IAM(role definitions) resources, which could be associated to a management group.

- There are built-in archetypes in the module
- You could define your own custom archetypes, such as in `/lib`, then use argument `library_path = "${path.root}/lib"`
- All the definitions are defined in ARM templates (JSON or YAML)

Example archetype definition

```json
{
    "my_archetype_id": {
        "policy_assignments": [
          "Policy-Assignment-Name-1",
          "Policy-Assignment-Name-2"
        ],
        "policy_definitions": [
          // We recommend only creating Policy Definitions at the root_id scope
          "Policy-Definition-Name-1",
          "Policy-Definition-Name-2"
        ],
        "policy_set_definitions": [
          // We recommend only creating Policy Set Definitions at the root_id scope
          "Policy-Set-Definition-Name-1",
          "Policy-Set-Definition-Name-2"
        ],
        "role_definitions": [
          // We recommend only creating Role Definitions at the root_id scope
          "Role-Definition-Name-1"
        ],
        "archetype_config": {
            "parameters": {
              // Map of parameters, grouped by Policy Assignment
              // Key should match the "name" field from Policy Assignment
              "Policy-Assignment-Name-1": {
                "parameterName1": "myStringValue",
                "parameterName2": 100,
                "parameterName3": true,
                "parameterName4": [
                  "myListValue1",
                  "myListValue2",
                  "myListValue3"
                ],
                "parameterName5": {
                  "myObjectKey1": "myObjectValue1",
                  "myObjectKey2": "myObjectValue2"
                }
              }
            },
            "access_control": {
              // Map of Role Assignments to create, grouped by Role Definition name
              // Key should match the "name" of the Role Definition to assign
              // Value should be a list of strings, specifying the Object Id(s) (from Azure AD) of all identities to assign to the role
              "Reader": [
                "00000000-0000-0000-0000-000000000000",
                "11111111-1111-1111-1111-111111111111",
                "22222222-2222-2222-2222-222222222222"
              ],
              "Role-Definition-Name-1": [
                "33333333-3333-3333-3333-333333333333"
              ]
            }
        }
    }
}
```

Associate an archetype with a management group

```
custom_landing_zones = {
  my-landing-zone-id = {
    display_name               = "Example Landing Zone"
    parent_management_group_id = "tf-landing-zones"
    subscription_ids           = []
    archetype_config = {
      archetype_id = "default_empty"
      parameters   = {}
      access_control = {}
    }
  }
}
```

- *`parameters`, `access_control` are merged into the archetype definition.*
- *Use the built-in `default_empty` archetype if you need a management group without any custom policies/roles/etc.*


### CAF Terraform landing zones

- A superset of the ALZ Terraform module, deploys workload resources as well
- Consist of
  - multiple Terraform modules (including ALZ Terraform module),
  - a custom provider,
  - open-source automation for Terrafrom (Rover),
  - reference deployment templates
- Configs written in YAML files, used to generate Terraform variable files
