# Azure Cost Management

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