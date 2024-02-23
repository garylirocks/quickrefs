# Privileged Identity Management

- [Privileged Identity Management (PIM)](#privileged-identity-management-pim)
  - [API](#api)
    - [Activate Azure roles](#activate-azure-roles)
    - [Just-Enough-Access](#just-enough-access)
    - [Relationship between PIM entities and role assignment entities](#relationship-between-pim-entities-and-role-assignment-entities)
    - [Activate Entra roles](#activate-entra-roles)
    - [PIM policies (role settings)](#pim-policies-role-settings)
- [Entra roles](#entra-roles)
  - [Microsoft Graph](#microsoft-graph)
  - [`AzureADPreview` (deprecating)](#azureadpreview-deprecating)
- [Azure roles](#azure-roles)
  - [Get eligible assignments or active assignments](#get-eligible-assignments-or-active-assignments)
  - [Self-activate an eligible assignment](#self-activate-an-eligible-assignment)
  - [Azure role settings (PIM policies)](#azure-role-settings-pim-policies)


## Privileged Identity Management (PIM)

- P2 feature
  - If you have a P2 license plan and already use PIM, **all role management tasks are performed in the PIM experience**
- When you enable PIM, an enterprise app named "MS-PIM" is added to your tenant automatically
- Two types of role assignments:
  - Eligible role assignments
  - Active role assignments
- Both active and eligible assignments could be time-bound or permanent
- Roles:
  - Entra Role
    - Assignment scope could be `/` (tenant-wide) or `AppScopeId` (limit scope to an application only)
  - Azure resource Role
  - Entra privileged group membership
    - You could assign either members or owners the group
    - Useful to mssign multiple roles to the group, then a user just need one activation (for the group membership), instead of activating multiple roles one by one
- Most common use case: create "Eligible Assignment" of roles/memberships to some users/groups, who need to active them when needed

### API

See [API concepts in Privileged Identity management](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-apis)

Endpoints:

- Entra roles - using Microsoft Graph endpoint (`graph.windows.net`)
- Entra groups - using Microsoft Graph endpoint (`graph.windows.net`)
- Azure resources - using ARM endpoint (`management.azure.com`)

Objects:

- `*AssignmentSchedule` and `*EligibilitySchedule` objects show current assignments and assignments that will become active in the future.
- `*AssignmentScheduleInstance` and `*EligibilityScheduleInstance` objects show current assignments only.

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

#### Just-Enough-Access

If a user has an eligible role assignment at a resource (parent), they can choose to **activate the role at a child level scope** of the parent resource instead of the entire parent scope.

For example, if a user has "Contributor" eligible role at a subscription, they can activate the role at a resource group in the subscription.

#### Relationship between PIM entities and role assignment entities

The only link between the PIM entity and the role assignment entity for persistent (active) assignment for either Microsoft Entra roles or Azure roles is the `*AssignmentScheduleInstance`. There is a one-to-one mapping between the two entities. That mapping means `roleAssignment` and `*AssignmentScheduleInstance` would both include:

- Persistent (active) assignments made outside of PIM
- Persistent (active) assignments with a schedule made inside PIM
- Activated eligible assignments

PIM-specific properties (such as end time) will be available only through `*AssignmentScheduleInstance` object.

#### Activate Entra roles

See notes in [Microsoft Graph](./microsoft-graph.markdown) and [Azure PowerShell](./azure-powershell.markdown)

#### PIM policies (role settings)

To manage the PIM policies, use `*roleManagementPolicy` and `*roleManagementPolicyAssignment` entities:

- The `*roleManagementPolicy` resource includes rules that constitute PIM policy: approval requirements, maximum activation duration, notification settings, etc.
- The `*roleManagementPolicyAssignment` object attaches the policy to a specific role.
- For PIM for Microsoft Entra roles, PIM for Groups: `unifiedroleManagementPolicy`, `unifiedroleManagementPolicyAssignment`
- For PIM for Azure resources: API endpoint is like `https://management.azure.com/{scope}/providers/Microsoft.Authorization/roleManagementPolicies/{roleManagementPolicyName}`




## Entra roles

Programmatically, you can use either `Microsoft.Graph`(recommended) or `AzureADPreview` module to work with PIM for Entra roles.

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

- This uses `Az.Resources` module, which connects to `https://management.azure.com`, NOT the Microsoft Graph API
- If you use a service principal to assign PIM roles for Azure resources, the SP needs to have the "**User Access Administrator**" or "Owner" role over the Azure scope.

### Get eligible assignments or active assignments

```powershell
$scope='<full-resource-id>' // FULL id required
$principal='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# get eligible ones
# - shows inherited permissions from upper scopes
# - shows assignment in sub scopes,
#   - if the scope is a subscription, like `/subscriptions/xxxx`, it shows assignment on children resource groups
#   - but if the scope is a management group like `/providers/Microsoft.Management/managementGroups/xxx`, it doesn't show assignements in children subscriptions
Get-AzRoleEligibilitySchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,PrincipalType,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,Status `
| Format-Table

# Get active role assignments and who it's been eligible to (could be current user or a containing group):
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
