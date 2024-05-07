# Privileged Identity Management

- [Overview](#overview)
- [Assignee](#assignee)
- [API](#api)
    - [Activate Azure roles](#activate-azure-roles)
  - [Just-Enough-Access](#just-enough-access)
  - [Relationship between PIM entities and role assignment entities](#relationship-between-pim-entities-and-role-assignment-entities)
  - [PIM policies (role settings)](#pim-policies-role-settings)
- [Entra roles](#entra-roles)
  - [Overview](#overview-1)
  - [Microsoft Graph](#microsoft-graph)
  - [`AzureADPreview` (deprecating)](#azureadpreview-deprecating)
- [Azure roles](#azure-roles)
  - [Overview](#overview-2)
  - [Get eligible assignments or active assignments](#get-eligible-assignments-or-active-assignments)
  - [In the Portal](#in-the-portal)
  - [By script](#by-script)
  - [Self-activate an eligible assignment](#self-activate-an-eligible-assignment)
  - [Azure role settings (PIM policies)](#azure-role-settings-pim-policies)
- [PIM for Groups](#pim-for-groups)


## Overview

- P2 feature
  - If you have a P2 license plan and already use PIM, **all role management tasks are performed in the PIM experience**
- When you enable PIM, an enterprise app named "**MS-PIM**" is added to your tenant automatically
- Two types of role assignments:
  - Eligible role assignments
  - Active role assignments
- Both active and eligible assignments could be **time-bound** or **permanent**
- Could be used with:
  - **Entra roles**
    - Depending on the role, assignment scope type could be
      - Directory
      - Group
      - User
      - Service principal
      - Device
      - Application
  - **Azure roles**
  - **PIM for Entra Groups**
- Role assignments could be extended or renewed
- Most common use case: create "Eligible Assignment" of roles/memberships to some users/groups, who need to active them when needed


## Assignee

- Users: works for all three
- Groups:
  - Entra roles: must be a cloud group that's marked as assignable to a role
  - Azure roles: can be any Microsoft Entra security group
  - PIM for Groups: don't recommend nesting a group to another with PIM for Groups
- Service principals: works for all three, but only for active assignments, NOT eligible assignments


## API

See [API concepts in Privileged Identity management](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-apis)

Endpoints:

- Entra roles - using Microsoft Graph endpoint (`graph.windows.net`)
- Entra groups - using Microsoft Graph endpoint (`graph.windows.net`)
- Azure roles - using ARM endpoint (`management.azure.com`)

Objects:

- `*AssignmentSchedule` and `*EligibilitySchedule` objects show both current and future assignments (active or eligible)
- `*AssignmentScheduleInstance` and `*EligibilityScheduleInstance` objects show current assignments only

#### Activate Azure roles

See [Manage active access to Azure resources through Azure Privileged Identity Management (PIM) using REST API - Azure](https://learn.microsoft.com/en-us/rest/api/authorization/privileged-role-assignment-rest-sample)

To activate an eligible assignment, you call `Create*AssignmentScheduleRequest`
- The `*EligibilityScheduleInstance` continues to exist
- New `*AssignmentSchedule` and a `*AssignmentScheduleInstance` object will be created for that activated duration.

A PUT request to `roleAssignmentScheduleRequests` is used for the following operations, the `RequestType` in the payload is different:

| Operation                      | `RequestType`    |
| ------------------------------ | ---------------- |
| Grant active assignment        | "AdminAssign"    |
| Remove active assignment       | "AdminRemove"    |
| Activate eligible assignment   | "SelfActivate"   |
| Deactivate eligible assignment | "SelfDeactivate" |

### Just-Enough-Access

If a user has an eligible role assignment at a resource (parent), they can choose to **activate the role at a child level scope** of the parent resource instead of the entire parent scope.

For example, if a user has "Contributor" eligible role at a subscription, they can activate the role at a resource group in the subscription.

### Relationship between PIM entities and role assignment entities

The only link between the PIM entity and the role assignment entity for persistent (active) assignment for either Microsoft Entra roles or Azure roles is the `*AssignmentScheduleInstance`. There is a one-to-one mapping between the two entities. That mapping means `roleAssignment` and `*AssignmentScheduleInstance` would both include:

- Persistent (active) assignments made outside of PIM
- Persistent (active) assignments with a schedule made inside PIM
- Activated eligible assignments

PIM-specific properties (such as end time) will be available only through `*AssignmentScheduleInstance` object.

### PIM policies (role settings)

To manage the PIM policies, use `*roleManagementPolicy` and `*roleManagementPolicyAssignment` entities:

- The `*roleManagementPolicy` resource includes rules that constitute PIM policy: approval requirements, maximum activation duration, notification settings, etc.
- The `*roleManagementPolicyAssignment` object attaches the policy to a specific role.
- For PIM for Entra roles, PIM for Groups: `unifiedroleManagementPolicy`, `unifiedroleManagementPolicyAssignment`
- For PIM for Azure roles: API endpoint is like `https://management.azure.com/{scope}/providers/Microsoft.Authorization/roleManagementPolicies/{roleManagementPolicyName}`


## Entra roles

### Overview

- Should be setup for privileged Entra roles: like Global Administrator
- Permissions to create an assignment: Privileged Role Administrator or Global Administrator
- Programmatically, you can use either `Microsoft.Graph`(recommended) or `AzureADPreview` module to work with PIM for Entra roles.

### Microsoft Graph

You need to specify the correct scope when `Connect-MgGraph`, since the Microsoft Graph API is protected, this would require admin or user consent granted to the client app (Microsoft Graph PowerShell)

See this page for all related permissions: https://learn.microsoft.com/en-us/graph/permissions-reference#role-management-permissions, be mindful about `*.All` and `*.Directory` permissions

- `RoleManagement.Read.All` this is for all supported RBAC providers (Cloud PC, device management/Intune, AAD directory, AAD entitlement management, Exchange Online), see [here](https://learn.microsoft.com/en-us/graph/api/resources/rolemanagement?view=graph-rest-beta&preserve-view=true)
- `RoleManagement.Read.Directory`: just for AAD role management

Login and get my principal ID

```powershell
Connect-MgGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory,RoleManagement.Read.Directory"

$myUpn=(Get-MgContext).Account
$myPrincipalId=(Get-MgUser -Filter "UserPrincipalName eq '$myUpn'").Id
```

Self activate an eligible assignment

```powershell
$params = @{
  "PrincipalId" = $myPrincipalId
  "RoleDefinitionId" = (Get-MgDirectoryRole -Filter "DisplayName eq 'Application Administrator'").RoleTemplateId
  "Justification" = "Activate assignment"
  "DirectoryScopeId" = "/"
  "Action" = "SelfActivate"
  "ScheduleInfo" = @{
    "StartDateTime" = Get-Date
    "Expiration" = @{
      "Type" = "AfterDuration"
      "Duration" = "PT1H"
    }
  }
}

New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest `
  -BodyParameter $params |
  Format-List Id, Status, Action, AppScopeId, DirectoryScopeId, RoleDefinitionID, IsValidationOnly, Justification, PrincipalId, CompletedDateTime, CreatedDateTime, TargetScheduleID
```

List active assignments

```powershell
# show active assignments
Get-MgRoleManagementDirectoryRoleAssignmentSchedule -Filter "principalId eq '$myPrincipalId'" `
  | Select DirectoryScopeId,
            AssignmentType,
            @{
              name='Role';
              expression={
                (Get-MgDirectoryRole -Filter "RoleTemplateId eq '$($_.RoleDefinitionId)'").DisplayName
              }
            }
```

### `AzureADPreview` (deprecating)

`AzureADPreview` only works in Windows PowerShell, *NOT PowerShell Core*, there are two sets of cmdlets:
  - `*-AzureAD*` connects to Azure AD graph endpoint `https://graph.windows.net`
  - `*-AzureADMS*` connects to Microsoft Graph endpoint `https://graph.microsoft.com`

<div style="background: #efd9fd; padding: 1em">
  <em>NOTE: </em><br />
  If the activation requires either <br />
    <ol>
      <li>ticket system/ticket number</li>
      <li>MFA</li>
    </ol>
  Then you need to do it in the Portal
</div>

- Prepare

  ```powershell
  # need this module
  Install-Module AzureADPreview

  # !! This does not work in PowerShell Core (v7)
  # See https://github.com/PowerShell/PowerShell/issues/10473
  Connect-AzureAD

  # find all related commands
  Get-Command  -Module AzureADPreview -Noun *privileged* -verb 'get'

  # CommandType     Name                                               Version    Source
  # -----------     ----                                               -------    ------
  # Cmdlet          Get-AzureADMSPrivilegedResource                    2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleAssignment              2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleAssignmentRequest       2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleDefinition              2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleSetting                 2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADPrivilegedRole                          2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADPrivilegedRoleAssignment                2.0.2.149  AzureADPreview
  ```

- Get definitions

  ```powershell
  $tenantId = (Get-AzContext).Tenant.Id
  $uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

  # get all AAD roles
  Get-AzureADMSPrivilegedRoleDefinition `
    -ProviderId aadRoles `
    -ResourceId $tenantId

  # get role assignments for the specified user
  Get-AzureADMSPrivilegedRoleAssignment `
    -ProviderId "aadRoles" `
    -ResourceId $tenantId `
    -Filter "subjectId eq '$uid'"
  ```

- Activate a role assignment

  ```powershell
  $durationInHours = 2
  $roleDefName = "Application Administrator"
  $reason = "Business Justification for the role assignment"
  $tenantId = (Get-AzContext).Tenant.Id
  $uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

  $start = Get-Date
  $end = $start.AddHours($durationInHours)
  $roleDefId = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Filter "DisplayName eq '$roleDefName'").Id

  $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
  $schedule.Type = "Once"
  $schedule.StartDateTime = $start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $schedule.endDateTime = $end.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

  Open-AzureADMSPrivilegedRoleAssignmentRequest `
    -ProviderId 'aadRoles' `
    -Type 'UserAdd' `
    -AssignmentState 'Active' `
    -ResourceId $tenantId `
    -RoleDefinitionId $roleDefId `
    -SubjectId $uid `
    -Schedule $schedule `
    -Reason $reason
  ```


## Azure roles

### Overview

- Should be set up for
  - "Owner" and "User Access Administrator" roles for all resources
  - Other roles for critical resources
- This uses `Az.Resources` module, which connects to `https://management.azure.com`, NOT the Microsoft Graph API
- If you use a service principal to assign PIM roles for Azure resources, the SP needs to have the "**User Access Administrator**" or "Owner" role over the Azure scope.

### Get eligible assignments or active assignments

### In the Portal

See https://stackoverflow.com/questions/73779593/how-to-get-pim-role-assignments-for-children-resources-of-a-subscription-via-pow

If you choose a subscription scope, then in the "Assignments" menu, you can export all PIM role assignments at the subscription level, and all children RGs and resources within it. (including eligible and active assignments)

For management groups, you can only export assignments at the MG level, **NOT** any children scopes.

### By script

```powershell
$scope='<full-resource-id>' // FULL id required
$principal='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# get eligible ones
# - shows inherited permissions from upper scopes
# - shows assignment in sub scopes,
#   - if the scope is a subscription, like `/subscriptions/xxxx`, it shows assignment on children RGs and resources within it
#   - but if the scope is a management group like `/providers/Microsoft.Management/managementGroups/xxx`, it doesn't show assignments in children subscriptions
Get-AzRoleEligibilitySchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,PrincipalType,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,Status `
| Format-Table

# Get active role assignments and who it's been eligible to (could be current user or a containing group):
# - if the scope is a subscription, like `/subscriptions/xxxx`, it shows assignment on children RGs and resources within it
Get-AzRoleAssignmentSchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,AssignmentType,@{
    n='PIMRoleAssignedTo';
    e={(Get-AzRoleEligibilitySchedule -Scope $_.ScopeId -Name ($_.LinkedRoleEligibilityScheduleId -Split '/' | Select -Last 1)).PrincipalDisplayName}
}`
| Format-Table
```

Usable filters:

- `-Filter "principalId eq $principal"`
  - works for active assignments
  - **DOES NOT** work for a user if the eligible role assignments are on a group, not directly on the user
- `-Filter "asTarget()"` limit to current user/service principal, works even if the eligible assignment is via a group
- `-Filter "atScope()"` limit to specified scope, including inherited roles from ancestor scopes, excluding subscopes
- `-Filter "asTarget() and atScope()"` combined

### Self-activate an eligible assignment

<div style="background: #efd9fd; padding: 1em">
  <em>NOTE: </em><br />
    <ol>
      <li>You can specify ticket system/ticket number</li>
      <li>Scope could be
        <ul>
          <li>management group ("/providers/Microsoft.Management/managementGroups/mg-foo")</li>
          <li>subscription ("/subscriptions/xxxx-xxxx-xxxx-xxxx")</li>
          <li>resource group ("/subscriptions/xxxx-xxxx-xxxx-xxxx/resourceGroups/rg-foo")</li>
        </ul>
      </li>
      <li>Seems there is no easy way to "Deactivate" an assignment via script</li>
    </ol>
</div>

```powershell
$durationInHours = 1
$roleName = "Contributor"
$justification = "Discovery"
$ticketNumber = 'FOO-123'

$guid = (New-Guid).guid
$uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id
$startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$roleId = (Get-AzRoleDefinition -Name $roleName).Id
$subscriptionId = ((Get-AzContext).Subscription).Id

$scope = "/subscriptions/${subscriptionId}"
$fullRoleDefId = "$scope/providers/Microsoft.Authorization/roleDefinitions/${roleId}"

New-AzRoleAssignmentScheduleRequest `
  -RequestType SelfActivate `
  -PrincipalId $uid `
  -Name $guid `
  -Scope $scope `
  -RoleDefinitionId $fullRoleDefId `
  -ScheduleInfoStartDateTime $startTime `
  -ExpirationDuration "PT${durationInHours}H" `
  -ExpirationType AfterDuration `
  -Justification $justification `
  -TicketNumber $ticketNumber `
  -TicketSystem JIRA
```

### Azure role settings (PIM policies)

- Also called PIM policies
- Is defined **per role** and **per resource**
  - All assignments for the same role on the same resource get the same role settings
  - **Not inherited**, eg. role settings on subscriptions are not inherited at resource group or resource level
- Resource type `/providers/Microsoft.Authorization/roleManagementPolicies`, its structure is like:

  ```json
  {
    "name": "xxxxx",
    "id": "xxxxx",
    "type": "Microsoft.Authorization/roleManagementPolicies"
    "properties": {
      "scope": "<scope-id>",
      "isOrganizationDefault": false,
      "lastModifiedDateTime": "<date-time>",
      "lastModifiedBy": {
        "displayName": "<principal-name>"
      },
      "policyProperties": {
        "scope": {
          "id": "<scope-id>",
          "displayName": "<scope-name>",
          "type": "subscription"
        }
      },
      "rules": [
        //...
      ],
      "effectiveRules": [
        //...
      ]
    }
  }
  ```

- Role settings assignment has resource type `/providers/Microsoft.Authorization/roleManagementPolicyAssignments`, its structure is like

  ```json
  {
    "name": "xxxxx",
    "id": "xxxxx",
    "type": "Microsoft.Authorization/RoleManagementPolicyAssignment"
    "properties": {
      "scope": "<scope-id>",
      "roleDefinitionId": "<role-def-id>",
      "policyId": "<role-management-policy-id>",
      "policyAssignmentProperties": {
        "scope": {
          "id": "<scope-id>",
          "displayName": "<scope-name>",
          "type": "subscription"
        },
        "roleDefinition": {
          "id": "<role-def-id>",
          "displayName": "<role-def-name>",
          "type": "BuiltInRole"
        },
        "policy": {
          "id": "<role-management-policy-id>",
          "lastModifiedBy": {
            "displayName": "<principal-name>"
          },
          "lastModifiedDateTime": "<date-time>"
        }
      },
      "effectiveRules": [
        //...
      ],
    }
  }
  ```


## PIM for Groups

- Member or owner role to a Entra security group
- Also allows you to set up PIM for other Microsoft services like Intune, Azure Key Vaults, etc
- Scenario: assign multiple Entra/Azure roles to the group, then a user just need one activation (for the group membership), instead of activating multiple roles one by one
- If the group is configured for app provisioning, activation of group membership triggers provisioning of group membership (and the user account, if it wasn’t provisioned) to the application using the System for Cross-Domain Identity Management (SCIM) protocol
- You can set role policy (for either member or owner) to require approval on activate, and select users or groups as approvers

![PIM for groups](images/entra_pim-for-groups.png)
