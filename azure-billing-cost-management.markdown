# Azure Cost Management

- [Overview](#overview)
- [Billing Account types (agreement types)](#billing-account-types-agreement-types)
  - [Microsoft Online Service Program](#microsoft-online-service-program)
  - [Enterprise Agreement (EA)](#enterprise-agreement-ea)
  - [Microsoft Partner Agreement](#microsoft-partner-agreement)
  - [MCA](#mca)
    - [Billing scopes](#billing-scopes)
- [Subscription vending](#subscription-vending)
  - [CLI command](#cli-command)
  - [Terraform `azurerm_subscription`](#terraform-azurerm_subscription)
  - [Other considerations](#other-considerations)
- [Budgets](#budgets)
- [Cost management](#cost-management)
  - [Cost views](#cost-views)
  - [Tags in cost and usage data](#tags-in-cost-and-usage-data)
  - [Tag inheritance](#tag-inheritance)
- [Alerts](#alerts)
- [Cost allocation](#cost-allocation)
- [Reservations](#reservations)
- [Savings plans](#savings-plans)
- [Azure Plans/SKUs](#azure-plansskus)
  - [Microsoft Azure Plan](#microsoft-azure-plan)
  - [Enterprise Dev/Test](#enterprise-devtest)
  - [Pay-As-You-Go Dev/Test](#pay-as-you-go-devtest)


## Overview

| Concepts        | Purpose                                             | Scopes                                | Teams            | Credits, taxes, etc |
| --------------- | --------------------------------------------------- | ------------------------------------- | ---------------- | ------------------- |
| Cost Management | To monitor, allocate, and optimize your Azure costs | Billing or Resource management scopes | Finance, DevOps  | Not included        |
| Billing         | To manage your accounts, invoices, and payments     | Billing scopes                        | Finance, leaders | Included            |


## Billing Account types (agreement types)

| Type                               | How                                                  | subscription limit                                       |
| ---------------------------------- | ---------------------------------------------------- | -------------------------------------------------------- |
| Microsoft Online Service Program   | Azure Free Account, pay-as-you-go                    | 5                                                        |
| Enterprise Agreement (EA)          | Enterprise Agreement                                 | unlimited EA accounts, 5000 subscriptions per EA account |
| Microsoft Customer Agreement (MCA) | Sign the agreement, or pay-as-you-go in some regions | 5                                                        |
| Microsoft Partner Agreement (MPA)  | Sign the agreement, or pay-as-you-go in some regions | N/A                                                      |

**A tenant could contain subscriptions of different agreement types**

### Microsoft Online Service Program

![Microsoft Online Service Program](images/azure_billing-mosp-hierarchy.png)

### Enterprise Agreement (EA)

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

To create a subscription via code, the service principal needs to have "**SubscriptionCreator**" role

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

### Microsoft Partner Agreement

![Microsoft Partner Agreement](images/azure_billing-mpa-hierarchy.png)

- Customer scope id example: `/providers/Microsoft.Billing/billingAccounts/99a13315-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx_xxxx-xx-xx/customers/7d15644f-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- To create a subscription manually
  - You need to do it in the CSP's Parter Center Portal
  - You need "Global Admin" and "Admin Agent" role in the CSP partner tenant (NOT the customer's tenant), this is managed in Parter Center (`partner.microsoft.com`)
  - See details https://learn.microsoft.com/en-us/partner-center/account-settings/permissions-overview

### MCA

![Microsoft Customer Agreement](images/azure_billing-mca-hierarchy.png)

#### Billing scopes

- Billing Account
  - Properties: ID, name, status, Tax ID, Agreement type, Sold-to address, etc
  - "**Cost allocation**" is configured at this level
- Billing Profile
  - Payment methods and Invoices are scoped at this level
  - Properties: ID, name, invoice email preference, enabled Azure plans, PO(Product Order) number, tags
  - Has settings controlling whether a user with access to an Azure subscription can:
    - View charges
    - Purchase Azure Reservation, Savings Plan, Marketplace products
    - Manage invoice section tags
- Invoice sections
  - Resource id format `/providers/Microsoft.Billing/billingAccounts/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx_xxxx-xx-xx/billingProfiles/xxxx-xxxx-xxx-xxx/invoiceSections/xxxx-xxxx-xxx-xxx`
  - A billing profile has a default invoice section
  - You can create additional sections to track and allocate costs based on project, department, environments etc.
  - A subscription is always associated to an invoice section
- Subscription
  - Could have a "cost center" attached, which could be project, department, etc

**Billing tags**

- "Billing profile" and "invoice sections" can have tags, which are called billing tags
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

*You could add external emails(not in your tenant) to a role*


## Subscription vending

![Vending process](./images/azure_subscription-vending-process.png)

| Type | Req. Roles                                                                                                                                        | Note                                            |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| MCA  | - Owner/Contributor role on a Billing Profile/Billing Account/Invoice Section<br /> - or "Azure subscription creator" role on an invoice section; |                                                 |
| MPA  | "Global Admin" or "Admin Agent" role in your organization's cloud solution provider account                                                       | Associate `resellerID` if there is one          |
| EA   | - "Enterprise Administrator" or "Owner" role on an Enrollment Account<br />- "SubscriptionCreator" role for a service principal                   | You can assign roles in Azure Enterprise Portal |

### CLI command

```sh
# `--name` is the alias name, required
# `--display-name` is optional
az account alias create --name "<alias-name>" \
  --display-name "<optional>" \
  --billing-scope "/providers/Microsoft.Billing/billingAccounts/99a13315-xxxx-xxxx-xxxx-xxxxxxxxxxxx:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx_xxxx-xx-xx/customers/2281f543-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  --workload "<DevTest|Production>" \
  --reseller-id "xxxxxx"
```

### Terraform `azurerm_subscription`

Could be used to create subscriptions or just aliases.
  - If `subscription_id` is applied, it creates an alias for it
  - If not `subscription_id`, but `billing_scope_id` is provided, it tries to create a new subscription in the scope
    - an alias is created at the same time

The aliases resource type is an extension resource (which means you can apply it to another resource)

  - You could manage it with `az account alias` commands
  - Subscription id is like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, while a full alias id is like `/providers/Microsoft.Subscription/aliases/test-alias`
  - A subscription could have multiple aliases

```terraform
resource "azurerm_subscription" "test" {
  alias = "my-alias"
  subscription_name = "sub-test"
  subscription_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tags = {
    foo = "bar"
  }
}
```

### Other considerations

- Designate a subscription owner, could be a user or an app
- Create a budget, and sending alerts
- Create Entra groups
  - recommended to use "PIM for groups" for write access
- Create workload identities
  - recommended to use **managed identities** to avoid managing secrets


## Budgets

- Scopes could be:
  - Billing hierarchy: billing account, billing profile, invoice section
  - Resource hierarchy: management group, subscription, resource group
    - For a subscription, the full resource ID is like `/subscriptions/<sub-id>/providers/Microsoft.Consumption/budgets/test-budget`
- You could specify emails to receive notifications
- If the cost exceeds the budget, it sends notifications (or triggers action groups), but Azure does not stop/remove the service automatically
- A budget could have an amount, and multiple thresholds
  - Each threshhold is based on a pencentage of actual or forcasted spending
  - Each can have an action group (**only for subscription/RG scopes**, not other scopes)


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
  - Available for every budget scope
  - Subscription and resource group scoped budgets also support action group
- **Anomaly alerts**
  - Only for subscription scope
- **Reservation utilization**
  - Scopes: MCA billing profile, MPA customer scope, EA billing account
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


## Savings plans

- Only for compute resources (NOT to OS, storage, software, or networking)
- Hourly commitment (min. $0.001)
- Term length: 1 or 3 years (whether auto-renew)
- Billing frequency: Monthly or All upfront (the whole term)
- Billing subscription: The subscription that the plan will be attributed to
- Resource scope:
  - The billing subscription
  - A specific RG in the sub
  - A management group of the subscription (any ancestor MG for the sub)
  - Any subscription in the same billing profile
- Automatically apply to matching resources (no need to create any associations)
- **Cannot** be cancelled


## Azure Plans/SKUs

### Microsoft Azure Plan

- Standard pay-as-you-go rates
- Under the Microsoft Customer Agreement
- When you sign up, you may receive some credits to use in the first 30 days, then you need to upgrade to the pay-as-you-go pricing

### Enterprise Dev/Test

- Lower rates on Windows VM, SQL, App Service, Logic Apps
- Need a Visual Studio subscription for each member who needs to access an Enterprise Dev/Test subscription
- Not available for MPA
- Specify the workload is "DevTest" when creating a subscription

### Pay-As-You-Go Dev/Test
