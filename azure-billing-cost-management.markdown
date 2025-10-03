# Azure Cost Management

- [Overview](#overview)
- [Billing Account types (agreement types)](#billing-account-types-agreement-types)
  - [Microsoft Online Service Program](#microsoft-online-service-program)
  - [Enterprise Agreement (EA)](#enterprise-agreement-ea)
  - [Microsoft Partner Agreement](#microsoft-partner-agreement)
  - [MCA](#mca)
    - [Billing scopes](#billing-scopes)
    - [Billing tags](#billing-tags)
    - [Billing Roles](#billing-roles)
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
- [Azure Hybrid Benefit](#azure-hybrid-benefit)
- [Azure Plans/SKUs](#azure-plansskus)
  - [Microsoft Azure Plan](#microsoft-azure-plan)
  - [Visual Studio subscribers](#visual-studio-subscribers)
  - [Dev/Test pricing](#devtest-pricing)


## Overview

| Concepts        | Purpose                                             | Scopes                                | Teams            | Credits, taxes, etc |
| --------------- | --------------------------------------------------- | ------------------------------------- | ---------------- | ------------------- |
| Cost Management | To monitor, allocate, and optimize your Azure costs | Billing or Resource management scopes | Finance, DevOps  | Not included        |
| Billing         | To manage your accounts, invoices, and payments     | Billing scopes                        | Finance, leaders | Included            |


## Billing Account types (agreement types)

| Type                               | How                                                  | subscription limit                                       |
| ---------------------------------- | ---------------------------------------------------- | -------------------------------------------------------- |
| Microsoft Online Service Program   | Azure Free Account, pay-as-you-go                    | 5                                                        |
| Microsoft Customer Agreement (MCA) | Sign the agreement, or pay-as-you-go in some regions | 5                                                        |
| Microsoft Partner Agreement (MPA)  | Sign the agreement, or pay-as-you-go in some regions | N/A                                                      |
| Enterprise Agreement (EA)          | Enterprise Agreement                                 | unlimited EA accounts, 5000 subscriptions per EA account |

**A tenant could contain subscriptions of different agreement types**

### Microsoft Online Service Program

![Microsoft Online Service Program](images/azure_billing-mosp-hierarchy.png)

### Enterprise Agreement (EA)

![Enterprise Agreement](images/azure_billing-ea-hierarchy.png)

- Scopes
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}` for Billing Account
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}/departments/{departmentId}` for Department
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}/enrollmentAccounts/{enrollmentAccountId}` for EnrollmentAccount
- Invoices at billing account level
- Departments and enrollment accounts
  - Used to organize subscriptions
  - AREN'T represented winthin invoice PDF
  - Can be used in cost analysis
- The only Enterprise Agreement role with access to Azure subscriptions is the **account owner**, an account owner becomes subscription owner for all subscriptions provisioned under the account

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

- Scopes:
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}` for BillingProfile
  - `/providers/Microsoft.Billing/billingAccounts/{billingAccountId}/customers/{customerId}`
- To create a subscription manually
  - You need to do it in the CSP's Parter Center Portal
  - You need "Global Admin" and "Admin Agent" role in the CSP partner tenant (NOT the customer's tenant), this is managed in Parter Center (`partner.microsoft.com`)
  - See details https://learn.microsoft.com/en-us/partner-center/account-settings/permissions-overview

### MCA

![Microsoft Customer Agreement](images/azure_billing-mca-hierarchy.png)

#### Billing scopes

- Billing account
  - Properties: ID, name, status, Tax ID, Agreement type, Sold-to address, etc
  - "**Cost allocation**" is configured at this level
- Billing profile
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}/billingProfiles/{billingProfileId}`
  - Payment methods and Invoices are scoped at this level
  - Properties: ID, name, invoice email preference, enabled Azure plans, PO(Product Order) number, tags
  - Has settings controlling whether a user with access to an Azure subscription can:
    - View charges
    - Purchase Azure Reservation, Savings Plan, Marketplace products
    - Manage invoice section tags
- Invoice sections
  - `providers/Microsoft.Billing/billingAccounts/{billingAccountId}/invoiceSections/{invoiceSectionId}`
  - A billing profile has a default invoice section
  - You can create additional sections to track and allocate costs based on project, department, environments etc.
  - A subscription is always associated to an invoice section
- Subscription
  - Could have a "cost center" attached, which could be project, department, etc

#### Billing tags

- "Billing profile" and "invoice sections" can have tags, which are called billing tags
- You can use "Tag inheritance" feature to apply them (as well as subscription and resource group tags) to new usage data of resources

#### Billing Roles

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
  - `"type": "Microsoft.CostManagement/views"`
- You can subscribe to a view and get emails
  - `"type": "Microsoft.CostManagement/ScheduledActions"`
  - `"kind": "Email"`

Gotchas:
  - If you create a custom view in the Portal, it will have a unscoped resource ID like `/providers/Microsoft.CostManagement/views/costview-gary`, though the data could be scoped to a resource group
  - With Terraform,
    - it can only create a view within a subscription, with an ID like `/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.CostManagement/views/my-daily-cost-view`
    - [the resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_cost_management_view) seems not up to date with the API, it doesn't have an argument for `properties.dateRange`, which is required for the subscription email to work
    - we can use `azapi_update_resource` to update the required properties

### Tags in cost and usage data

Individual resources submit usage record to Cost Management, and tags are included.

Limitations:

- Tags must be applied directly to resources
  - Or you could enable tag inheritance (instead of using Azure Policy)
- Only support resources deployed to resource groups
- Some resources does not support tags, or might not include tags in usage data
- Newly added tags aren't applied to historical usage data

### Tag inheritance

![Tag inheritance](./images/azure_tags-inheritance.svg)

- Works for these billing account types:
  - Enterprise Agreement (EA)
  - Microsoft Customer Agreement (MCA)
  - Microsoft Partner Agreement (MPA) with Azure plan subscriptions
- For MCA, you could also enabled inheritance of billing tags at Billing Profile or Invoice Section level
- Tags are inherited to resource usage records, **NOT** resources themselves
- When enabled
  - Takes 8-24 hour to update usage records
  - The current tags are applied to all usage records of current month
- If the same tag is on both subscription and resource group levels, the subscription one takes precedence
- If a resource that doesn't emit usage at a subscription scope, they will not have the subscription tags applied
- These inherited tags could be used for filters in budgets

## Alerts

- **Budget alerts**
  - Available for every budget scope
  - Subscription and resource group scoped budgets also support action group
- **Anomaly alerts**
  - `"type": "Microsoft.CostManagement/ScheduledActions"`
  - `"kind": "InsightAlert"`
  - Only for subscription scope, maximum 5 in a subscription
  - Cost anomalies are evaluated for subscriptions daily and compare the day's total usage to a forecasted total based on the last 60 days to account for common patterns in your recent usage. For example, spikes every Monday. (using a deep learning algorithm called WaveNet, different from the Cost Management forecast)
  - The anomalies show in "Smart views" in cost analysis (*the insights light bulb icon*)
  - The anomalies are always evaluated, the alerts export it as emails
  - Requires `Microsoft.CostManagement/scheduledActions/write` permission to create one (the permission of the rule creator is evaluated at the time that the email is sent, so you may need a service principal to create the rule)
  - Could be created using API [CreateOrUpdateInsightAlertScheduledActionByScope](https://learn.microsoft.com/en-us/rest/api/cost-management/scheduled-actions/create-or-update-by-scope?view=rest-cost-management-2024-08-01&tabs=HTTP#createorupdateinsightalertscheduledactionbyscope)
- **Reservation utilization**
  - Scopes: MCA billing profile, MPA customer scope, EA billing account
- Scheduled emails for **saved cost views**
  - `"type": "Microsoft.CostManagement/ScheduledActions"`
  - `"kind": "Email"`
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


## Azure Hybrid Benefit

- For Windows Server
- For SQL Server
- For RHEL/Suse
  - Bring Your Own Subscription (BYOS): you need to enable this in RedHat portal first
  - Pay As You Go (PAYG): purchase your subscription through Azure
  - License could be converted from BYOS to PAYG, or vice versa, without downtime
  - Applies to VMs, VMSS, and custom images


## Azure Plans/SKUs

### Microsoft Azure Plan

- Standard pay-as-you-go rates
- Under the Microsoft Customer Agreement
- Sign up incentives:
  - $200 credit for first 30 days (convert to Pay-as-You-Go when it ends)
  - 12 month free services
- Some services have monthly free amount, eg.
  - ADO: unlimited private repos
  - Entra ID: 50,000 stored objects
  - Networking: 100 GB outbound data transfer
  - SQL database: 100,000 vCore seconds with 32GB of storage
  - ...

### Visual Studio subscribers

- Gets some credit per month, eg. Visual Studio Enterprise subscriptions gives you $150 credit per month
- Visual Studio subscription portal (`https://my.visualstudio.com`)
  - You can create a new Azure subscription to get the credit
    - Subscription name is "Visual Studio Enterprise Subscription – MPN"
    - Subscription is created under a new billing account of type "**Microsoft Online Services Program**"
    - The subscription has a spending limit per month, it will be disabled once it reaches its spending limit. You can remove the limit by adding a credit or debit card.
    - Remaining credit is shown on the subscription overview page, seems there's no dedicated page for it.
  - You can associate an alternate email to get the Azure credit, access ADO, sign-in to Visual Studio

### Dev/Test pricing

- Only available to active Visual Studio subscribers
  - This is in addition of the $150 per month credit
  - Need a Visual Studio subscription for each user who needs to access a Dev/Test subscription
- Significantly reduce costs of dev/test workloads
  - Windows VMs: Billed at CentOS/Ubuntu Linux VM rates
  - SQL database: Up to 55%
  - Logic Apps Enterprise Connector: 50% discount
  - ...
- Plans:
  | Visual Studio subscription | Azure Plan                                              |
  | -------------------------- | ------------------------------------------------------- |
  | Personal                   | Pay-As-You-Go Dev/Test                                  |
  | Organization (Azure EA)    | Enterprise Dev/Test (Create in Azure Enterprise Portal) |
  | Organization (Azure MCA)   | Azure Plan for Dev/Test                                 |
- Not available for MPA
- When using CLI, specify option `--workload "DevTest"` when creating a subscription
- These subscriptions do not have SLAs, except Azure DevOps and Azure Monitor