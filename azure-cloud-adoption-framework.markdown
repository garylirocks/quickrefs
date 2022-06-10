# Cloud adoption framework

- [Conceptual architecture for Azure landing zones](#conceptual-architecture-for-azure-landing-zones)
- [Deploy with Terraform](#deploy-with-terraform)


## Conceptual architecture for Azure landing zones

![Reference architecture](images/azure_caf-reference-architecture-for-landing-zones.png)

- Sandboxes management group contains subscriptions for dev/testing with loose or no policies applied. **They should NOT have direct connectivity to the landing zone subscriptions.**


## Deploy with Terraform

![Terraform options](images/azure_caf-tf-module-compare.png)

There are two options:
- ALZ Terraform module, takes care:
  - Management hierarchy
  - Policies/role definition and assignment

- CAF Terraform landing zones:
  - A superset of the ALZ Terraform module, deploys workload resources as well
  - Consist of
    - multiple Terraform modules (including ALZ Terraform module),
    - a custom provider,
    - open-source automation for Terrafrom (Rover),
    - reference deployment templates
  - Configs written in YAML files, used to generate Terraform variable files
