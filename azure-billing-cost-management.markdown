# Azure Cost Management

- [Overview](#overview)
- [Billing Account types (Agreement types)](#billing-account-types-agreement-types)
- [Enterprise Agreement (EA)](#enterprise-agreement-ea)
- [MCA](#mca)
  - [Billing scopes](#billing-scopes)
- [Budgets](#budgets)
- [Cost management](#cost-management)
  - [Cost views](#cost-views)
  - [Tags in cost and usage data](#tags-in-cost-and-usage-data)
  - [Tag inheritance](#tag-inheritance)
- [Alerts](#alerts)
- [Cost allocation](#cost-allocation)
- [Reservations](#reservations)


## Overview

| Concepts        | Purpose                                             | Scopes                                | Teams            | Credits, taxes, etc |
| --------------- | --------------------------------------------------- | ------------------------------------- | ---------------- | ------------------- |
| Cost Management | To monitor, allocate, and optimize your Azure costs | Billing or Resource management scopes | Finance, DevOps  | Not included        |
| Billing         | To manage your accounts, invoices, and payments     | Billing scopes                        | Finance, leaders | Included            |


## Billing Account types (Agreement types)

| Type                             | How                                                  | subscription limit                                       |
| -------------------------------- | ---------------------------------------------------- | -------------------------------------------------------- |
| Microsoft Online Service Program | Azure Free Account, pay-as-you-go                    | 5                                                        |
| Enterprise Agreement             | Enterprise Agreement                                 | unlimited EA accounts, 5000 subscriptions per EA account |
| Microsoft Customer Agreement     | Sign the agreement, or pay-as-you-go in some regions | 5                                                        |
| Microsoft Partner Agreement      | Sign the agreement, or pay-as-you-go in some regions | N/A                                                      |

**Microsoft Online Service Program**

![Microsoft Online Service Program](images/azure_billing-mosp-hierarchy.png)

**Microsoft Partner Agreement**
![Microsoft Partner Agreement](images/azure_billing-mpa-hierarchy.png)


## Enterprise Agreement (EA)

![Enterprise Agreement](images/azure_billing-ea-hierarchy.png)

- Invoices created at billing account level
- Departments and enrollment accounts
  - Used to organize subscriptions
  - AREN'T represented winthin invoice PDF
  - Can be used in cost analysis
- The only Enterprise Agreement role with access to Azure subscriptions is the **account owner** because this permission was granted when the subscription was created.
- Each account owner is a subscription owner for all subscriptions provisioned under the account

Best practices:

- Assign a budget for each department and account, establish an alert associated with budget

Automation:

You can assign roles to a service principal to automate tasks, such as subscription creation. See: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/assign-roles-azure-service-principals

To create a subscription via code, the service principal needs to have "**subscription creator**" role

```terraform
data "azurerm_billing_enrollment_account_scope" "example" {
  billing_account_name    = "1234567890"
  enrollment_account_name = "0123456"
}

resource "azurerm_subscription" "example" {
  subscription_name = "My Example EA Subscription"
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.example.id
}
```



## MCA

### Billing scopes

![Microsoft Customer Agreement](images/azure_billing-mca-hierarchy.png)

- Billing Account
  - Properties: ID, name, status, Tax ID, cost allocation, etc
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
  - A subscription is always associated to an invoice section

**Billing tags**

- Billing profile and invoice sections can have tags, which are called billing tags
- You can use "Tag inheritance" feature to apply them (as well as subscription and resource group tags) to new usage data of resources

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

- A budget is a tenant level resource, doesn't show up in any subscription.
- A budget could have alerts configured
  - Can be based on a pencentage of actual or predicted spending
  - Can notify specified email addresses or action groups


## Cost management

### Cost views

- Views can be scoped to either:
  - A billing scope
  - A resource management scope (MG, sub, RG)
- There are preset cost views
- You can customize the views and save them
- You can subscribe to a view and get emails

Gotchas:
  - If you create a custom view in the Portal, it will have a unscoped resource ID like `/providers/Microsoft.CostManagement/views/costview-gary`, though the data could be scoped to a resource group
  - With Terraform,
    - it can only create a view within a subscription, with an ID like `/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.CostManagement/views/my-daily-cost-view`
    - [the resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_cost_management_view) seems not up to date with the API, it doesn't have an argument for `properties.dateRange`, which is required for the subscription email to work
    - we can use `azapi_update_resource` to update the required properties

### Tags in cost and usage data

- Tags must be applied directly ro resources
  - Or you could enable tag inheritance (instead of using Azure Policy)
- Some resources does not support tags

### Tag inheritance

- Tags are inherited to resource usage records, NOT resources

  ![Tag inheritance](./images/azure_tags-inheritance.svg)

- Works for these billing account types:
  - Enterprise Agreement (EA)
  - Microsoft Customer Agreement (MCA)
  - Microsoft Partner Agreement (MPA) with Azure plan subscriptions

- If the same tag is on both subscription and resource group levels, the subscription one takes precedence.

- When enabled, the resource usage records are updated for the current month.

- If a resource that doesn't emit usage at a subscription scope, they will not have the subscription tags applied.


## Alerts

- **Budget alerts**
  - Available for every Cost management scope
  - Subscription and resource group budgets can be configured to notify an action group
- **Anomaly alerts**
  - Only for subscription scope
- Scheduled emails for **saved cost views**
- EA commitment balance alerts
- Invoice alerts


## Cost allocation

Cost allocation allows to you to allocate cost of source (subscription/resource group/tag) to target subscription/resource group/tag

- Cost allocation does NOT affect billing invoice
- All chargeback processes happen outside of Azure
- Reallocated costs appear in cost analysis
- Cost can be splitted - evenly, based on target's total/compute/storage/network cost, or custom


## Reservations

- Works for many Azure services:
  - VM
  - Blob storage (ony storage, not transactions)
  - SQL database (vCore)
  - App Service
  - Red Hat plans
  - ...
- Reserve to 1 year or 3 years
- Could be paid monthly or annually
- Applies to your billing immediately