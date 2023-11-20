# Azure Cost Management

## Billing

Organized into three levels:

- Billing Account
  - Properties: ID, name, type, status, Tax ID, cost allocation, etc
  - Cost allocation allows to you to allocate cost of source (subscription/resource group/tag) to target subscription/resource group/tag
  - You can split the source cost - evenly, target's total/compute/storage/network cost, or custom
- Billing Profile
  - Properties: ID, name, invoice email preference, enabled Azure plans, PO(Product Order) number, tags
  - A subscription is billed to a billing profile
  - Has settings controlling whether a user with access to an Azure subscription can:
    - View charges
    - Purchase Azure Reservation, Savings Plan, Marketplace products
    - Manage invoice section tags
- Invoice sections
  - A billing profile has a default invoice section
  - You can create additional sections to track and allocate costs based on project, department, environments etc.
  - When you create a new subscription, it needs to be assigned to a invoice section

**Billing tags**:
- Billing profile and sections can have tags, which are called billing tags
- You can use "Tag inheritance" feature to apply them (as well as subscription and resource group tags) to new usage data of resources

**Billing Scopes**:

Billing + Cost Management related assets could be scoped to Billing Account/Profile, Invoice section, Management group, subscription, resource group

**Billing Roles**

See: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/understand-mca-roles

All three levels have roles like:
- Owner
- Contributor
- Reader

Other roles:
- Invoice manager (Billing Profile)
- Azure subscription creator (Invoice section)


## Budgets

- You could create budget in Azure.
- A budget is a tenant level resource, doesn't show up in any subscription.
- A budget could have alerts configured
  - Can be based on a pencentage of actual or predicted spending
  - Can notify specified email addresses or action groups

## Cost views

- There are preset cost views
- You can customize the views and save them
- You can subscribe to a view and get emails

Gotchas:
  - If you create a custom view in the Portal, it will have a unscoped resource ID like `/providers/Microsoft.CostManagement/views/costview-gary`, though the data could be scoped to a resource group
  - With Terraform,
    - it can only create a view within a subscription, with an ID like `/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.CostManagement/views/my-daily-cost-view`
    - [the resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_cost_management_view) seems not up to date with the API, it doesn't have an argument for `properties.dateRange`, which is required for the subscription email to work
    - we can use `azapi_update_resource` to update the required properties