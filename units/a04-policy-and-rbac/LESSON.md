# A04: Azure Policy and role-based access

## Advance organizer

You have organized resources with groups, tags, and locks. This unit teaches governance enforcement: Azure Policy (built-in and custom definitions, Policy effects, assignments at resource-group and subscription scope) and role-based access control (built-in roles, role assignments at different scopes, scope inheritance). After this unit you can assign Policy definitions to enforce organizational standards, assign roles to grant access, and troubleshoot access assignments when a deployment is blocked.

You must already know: **A00** (Bicep language), **A01** (deployments and ARM), **A02** (cost control), and **A03** (resource organization).

After this unit you can:
- Assign a built-in Azure Policy definition at resource-group or subscription scope
- Write a custom Policy definition for a lab guardrail
- Assign a built-in role at resource-group, subscription, or management-group scope
- Explain Policy effects (Deny, Audit, Modify, DeployIfNotExists)
- Interpret an access assignment in the portal or CLI

## Foundations

### Azure Policy

**Azure Policy** evaluates resources against rules and enforces organizational standards. A **policy definition** is the rule (for example, "storage accounts must use HTTPS"). A **policy assignment** attaches the definition to a scope (subscription, resource group, or management group). Azure evaluates resources at that scope and applies the policy's **effect**.

Policy definitions are JSON documents. Azure provides hundreds of built-in definitions. You can also write custom definitions. The course uses built-in definitions for most governance work and writes one small custom definition for the lab SKU and region guard.

### Policy assignments

A policy assignment attaches a definition to a scope. You assign Policy at subscription, resource group, or management-group scope in Bicep. The `policyDefinitionId` is the full resource ID of the built-in or custom definition. Built-in definitions live at `/providers/Microsoft.Authorization/policyDefinitions/<guid>`. Custom definitions you deploy live at subscription or management-group scope.

Policy assignments inherit downward: a Policy assigned at subscription scope applies to every resource group and resource in the subscription. A Policy assigned at management-group scope applies to every subscription, resource group, and resource in that management group.

### Policy effects

A policy definition's `effect` controls what happens when a resource violates the rule. Common effects:

- **Deny**: blocks the resource creation or update. The request fails with a Policy violation error.
- **Audit**: logs the violation but allows the operation to proceed.
- **Append**: adds fields to the resource during creation or update.
- **AuditIfNotExists** and **DeployIfNotExists**: evaluate whether a related resource exists. AuditIfNotExists logs a violation if the related resource is missing. DeployIfNotExists creates the missing resource after the deployment succeeds.
- **Modify**: alters create or update requests (for example, "set the minimum TLS version to 1.2"). The assignment requires a managed identity (portal and ARM require `identity` and `location` on the assignment). The identity needs a role assignment covering the `roleDefinitionIds` the definition declares, or remediation fails.
- **DenyAction**: a control-plane effect that blocks DELETE operations only (returns HTTP 403). Evaluated last.
- **Manual**: marks resources for manual compliance review.
- **Disabled**: the Policy is assigned but not evaluated.

**Evaluation order**: Disabled, Append/Modify, Deny, Audit, Manual, AuditIfNotExists/DeployIfNotExists, then DenyAction last.

Deny and Audit are the most common. Deny blocks non-compliant resources at deployment. Audit allows them through but flags them. Modify and DeployIfNotExists assignments require a managed identity (`identity` and `location` on the assignment); the identity also needs role assignments covering the definition's `roleDefinitionIds`, or remediation fails. Existing non-compliant resources need a remediation task.

### Custom Policy definitions

A custom Policy definition is a JSON document with `policyRule`, `parameters`, and `metadata`. Deploy it at subscription scope:

```bicep
targetScope = 'subscription'

resource customPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'require-owner-tag'
  properties: {
    displayName: 'Require owner tag on resources'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          { field: 'tags[owner]', exists: false }
          { field: 'type', notIn: [
            'Microsoft.Insights/actionGroups'
            'Microsoft.Consumption/budgets'
            'Microsoft.OperationalInsights/workspaces'
          ] }
        ]
      }
      then: { effect: 'Deny' }
    }
  }
}
```

This definition uses `mode: 'Indexed'` and excludes global resources (action groups, budgets, workspaces) that do not have `tags` or `location` fields. It denies Indexed resources that do not have an `owner` tag. After deploying the definition, you assign it at the desired scope. Custom definitions are useful for organizational standards not covered by built-in policies.

### Role-based access control (RBAC)

**RBAC** grants users, groups, or service principals access to Azure resources. A **role assignment** attaches a **role definition** (a set of permissions) to a **principal** at a **scope** (subscription, resource group, or resource).

Azure provides built-in roles:

- **Owner**: full access, including managing RBAC assignments.
- **Contributor**: full resource access, but `NotActions` exclude `Microsoft.Authorization/*/Delete`, `Microsoft.Authorization/*/Write`, `Microsoft.Authorization/elevateAccess/Action`, Blueprint assignments write/delete, `Microsoft.Compute/galleries/share/action`, Purview consents write/delete, `Microsoft.Resources/deploymentStacks/manageDenySetting/action`, and Subscription cancel/enable, so it cannot manage RBAC, Policy, or locks.
- **Reader**: read-only access.
- **User Access Administrator**: `*/read`, `Microsoft.Authorization/*`, and `Microsoft.Support/*`. Can read all resources and manage all Authorization (role assignments, role definitions, Policy assignments, locks). Broad delegation scope.
- **Role Based Access Control Administrator**: `*/read`, `Microsoft.Authorization/roleAssignments/write`, `Microsoft.Authorization/roleAssignments/delete`, and `Microsoft.Support/*`. Can read all resources but only manage role assignments. Narrower delegation; supports ABAC conditions to constrain which roles or principals it assigns.
- Many resource-specific roles: **Storage Blob Data Contributor**, **Virtual Machine Contributor**, etc.

RBAC is **additive**: the principal's effective permissions are the union of all role assignments at all scopes. Azure also supports **deny assignments** (explicit denials that override allow), created by Azure features such as Deployment Stacks (deny settings) and managed applications, not directly by users.

### Role assignments

A role assignment attaches a role to a principal at a scope. You assign roles in Bicep:

```bicep
targetScope = 'subscription'

@description('Principal ID of the user, group, or service principal')
param principalId string

@description('Type of the principal')
param principalType string = 'User'

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: principalId
    principalType: principalType
  }
}
```

The `roleDefinitionId` is the full resource ID of the built-in role definition. Built-in role definitions are tenant-wide; their IDs at resource-group or subscription scope use `subscriptionResourceId('Microsoft.Authorization/roleDefinitions', <guid>)`. At management-group scope, use `tenantResourceId('Microsoft.Authorization/roleDefinitions', <guid>)`. The role GUID is fixed for each built-in role (Contributor is always `b24988ac-6180-42a0-ab88-20f7382dd24c`). The `name` is a GUID; use `guid()` to generate a deterministic GUID from the scope, principal, and role to make the assignment idempotent. Set `principalType` (User, Group, or ServicePrincipal) to avoid deployment delays.

Role assignments inherit downward: a role assignment at subscription scope grants access to every resource group and resource in the subscription. A role assignment at management-group scope grants access to every subscription in that management group. Role assignments at a resource or resource group scope apply to that resource and its child resources (such as blobServices and containers under a storage account).

### Interpreting access assignments

The portal (IAM blade) and CLI (`az role assignment list`) show effective role assignments. When a deployment fails with an `AuthorizationFailed` error, check the role assignments at the resource, resource group, subscription, and management-group levels. RBAC is additive, so look for any assignment that grants the needed permission. If none exists, request the role from an Owner or User Access Administrator at the appropriate scope.

The CLI command `az role assignment list --assignee <principal-id>` shows assignments for that principal at subscription scope by default. Add `--all` to include resource-group and resource scopes, `--include-inherited` to include parent scopes (subscription and management group), and `--include-groups` to include assignments inherited from groups the principal belongs to. The output shows the role, scope, and principal. To interpret an access assignment, find the role definition GUID, then look up the role name and permissions in the official documentation or with `az role definition list --name <role-name>`.

### Policy evaluation and timing

Azure evaluates Policy at deployment time and periodically against existing resources. When you assign a Deny Policy, existing resources that violate the Policy are flagged but not deleted. New deployments and updates are blocked. When you assign an Audit Policy, violations are logged in the Activity Log and Azure Policy compliance reports. Use the portal's Policy compliance view or `az policy state list` to see which resources are non-compliant.

**Policy cost:** Policy assignments, definitions, and evaluations are free for Azure resources (source: https://azure.microsoft.com/en-us/pricing/details/azure-policy/). Azure Arc-connected servers with machine configuration policies cost $6/server/month.

## Worked example: Assign a built-in Policy to restrict locations

You need to restrict all resource deployments in a subscription to East US and West US. You will assign the built-in "Allowed locations" Policy at subscription scope.

The built-in Policy definition is `e56962a6-4747-49cd-b67b-bf8b01975c4c`. Here is the assignment:

```bicep
targetScope = 'subscription'

resource allowedLocations 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations-eastus-westus'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
    displayName: 'Allowed locations: East US and West US'
    parameters: {
      listOfAllowedLocations: {
        value: [
          'eastus'
          'westus'
        ]
      }
    }
  }
}
```

Deploy this at subscription scope with `az deployment sub create --location eastus --template-file main.bicep`. After deployment, any attempt to create an Indexed resource (tracked resources with locations) in a region outside East US or West US fails with a Policy violation error. The built-in Allowed locations Policy does not cover resource groups (a separate built-in does), `global` resources, or types without a location property. Existing resources outside those regions are flagged as non-compliant but are not deleted.

**The plausible wrong reading.** You might expect the Policy to delete existing resources that violate the rule. That is not true. Deny policies block new deployments and updates, but they do not delete existing resources. To remediate existing resources, delete them manually or use a remediation task (available for DeployIfNotExists and Modify, not Deny).

## Worked example: Assign Contributor role at resource scope

A service principal deploys and manages a specific storage account but should not have access to other resources in the resource group. You will assign the Contributor role at the storage account's resource scope.

The Contributor role GUID is `b24988ac-6180-42a0-ab88-20f7382dd24c`. Here is the assignment in a resource-group-scoped file:

```bicep
targetScope = 'resourceGroup'

@description('Principal ID of the service principal')
param servicePrincipalId string

@description('Storage account name')
param storageAccountName string

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: guid(storage.id, servicePrincipalId, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

Deploy this at resource-group scope with `az deployment group create --resource-group my-rg --template-file main.bicep --parameters servicePrincipalId=<id> storageAccountName=<name>`. After deployment, the service principal can manage that storage account and its child resources (blobServices, containers) but cannot access other resources in the resource group.

**The plausible wrong reading.** You might expect Contributor at resource scope to also grant access to related resources in other resource groups. That is not true. The scope is the resource and its child resources. If the storage account has a private endpoint in another resource group, the Contributor assignment on the storage account does not grant access to that private endpoint.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Policy definition vs policy assignment | A policy definition is the rule (a JSON document). A policy assignment attaches the definition to a scope and passes parameter values. Without an assignment, the definition has no effect. |
| Deny vs Audit | Deny blocks non-compliant resources at deployment. Audit allows them through but logs the violation. |
| Modify vs DeployIfNotExists | Modify alters create/update requests. DeployIfNotExists creates a missing related resource after the deployment succeeds. Both assignments require a managed identity and role assignments. Existing non-compliant resources need remediation tasks. Deny and Audit do not. |
| Role definition vs role assignment | A role definition is a set of permissions. A role assignment attaches the role to a principal at a scope. Without an assignment, the definition has no effect. |
| Owner vs Contributor | Owner has full access including RBAC. Contributor's `NotActions` exclude `Microsoft.Authorization/*/Delete`, `Microsoft.Authorization/*/Write`, elevate access, Blueprint assignments, Compute galleries share, Purview consents, deployment stacks manage deny, and Subscription cancel/enable, so it cannot manage RBAC, Policy, or locks. |
| User Access Administrator vs Role Based Access Control Administrator | UAA has `*/read` and `Microsoft.Authorization/*` (all Authorization: role assignments, definitions, Policy, locks). RBAC Administrator has `*/read` and only `Microsoft.Authorization/roleAssignments/write` and `roleAssignments/delete` (narrower). Neither writes non-Authorization resources. RBAC Administrator supports ABAC conditions to constrain delegation; Microsoft recommends it over UAA. |
| Contributor vs Reader | Contributor has full resource access (create, update, delete). Reader is read-only. |
| RBAC is additive (except deny assignments) | The principal's effective permissions are the union of all role assignments at all scopes. Azure deny assignments (created by Deployment Stacks, managed applications, and other Azure features, not directly by users) override allow. |
| Scope inheritance | Policy assignments and role assignments inherit downward. A child scope cannot remove a parent assignment. Policy exemptions and `notScopes` do exclude child scopes from evaluation. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [What is Azure Policy?](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
- [Policy definition structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Understand Azure Policy effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Troubleshoot Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting)
- [Microsoft.Authorization/policyDefinitions](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/policydefinitions)
- [Microsoft.Authorization/policyAssignments](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments)
- [Microsoft.Authorization/roleAssignments](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments)
- [az policy](https://learn.microsoft.com/en-us/cli/azure/policy)
- [az role assignment](https://learn.microsoft.com/en-us/cli/azure/role/assignment)

## Check yourself

1. **You assign a Deny Policy at subscription scope that blocks storage accounts outside East US. A storage account in West US already exists. What happens to that account?**
2. **A Policy definition has the Audit effect. You deploy a resource that violates the Policy. Does the deployment succeed?**
3. **A user is assigned Reader at subscription scope and Contributor at resource-group scope for `dev-rg`. What access does the user have to `dev-rg`? What about other resource groups in the subscription?**
4. **You need to grant a service principal the ability to assign roles in a resource group, but you do not want it to create or modify resources. Which role do you assign?**
5. **Can you create a Policy assignment whose definition has the Modify effect without a managed identity? What if the managed identity exists but has no role assignments?**

<details>
<summary>Answers</summary>

1. Nothing. The account is flagged as non-compliant, but Deny policies do not delete existing resources. New storage accounts outside East US are blocked. To remediate the existing account, you must recreate the account in East US and copy the data (for example, with AzCopy).
2. Yes. Audit logs the violation but allows the operation to proceed. The resource is created and flagged as non-compliant. If the Policy had the Deny effect, the deployment would fail.
3. The user has Contributor access to `dev-rg` (full resource access, but cannot manage RBAC). The user has Reader access to other resource groups in the subscription. RBAC is additive: the effective permissions are the union of all assignments.
4. Role Based Access Control Administrator (recommended) or User Access Administrator. Both can read resources and manage role assignments, but neither writes non-Authorization resources. RBAC Administrator is narrower (only role assignments, not Policy or locks) and supports ABAC conditions. Owner has full resource access; Contributor can write resources but not manage RBAC.
5. No identity: assignment creation fails (portal and ARM require `identity` and `location` on the assignment). Identity exists but has no role assignments: the assignment is created, but remediation fails because the identity lacks permissions for the `roleDefinitionIds` the definition declares. Deny and Audit do not need a managed identity.

</details>

## Takeaways

- Policy definitions are rules; policy assignments attach definitions to scopes and pass parameters.
- Deny blocks non-compliant resources at deployment; Audit logs violations. Modify and DeployIfNotExists assignments require a managed identity (without it, creation fails); the identity also needs role assignments for the definition's `roleDefinitionIds` (without them, remediation fails). Existing non-compliant resources need remediation tasks.
- Policy assignments and role assignments inherit downward: assigned at subscription scope, they apply to every resource group and resource in the subscription.
- RBAC is additive: the principal's effective permissions are the union of all role assignments, except deny assignments (created by Deployment Stacks and other Azure features) override allow.
- Owner has full access including RBAC; Contributor's `NotActions` exclude Microsoft.Authorization write/delete, elevate access, Blueprint assignments, galleries share, Purview consents, deployment stacks deny, and Subscription actions; User Access Administrator has `*/read`, `Microsoft.Authorization/*`, and `Microsoft.Support/*`; Role Based Access Control Administrator has `*/read`, `Microsoft.Authorization/roleAssignments/write`, `Microsoft.Authorization/roleAssignments/delete`, and `Microsoft.Support/*` (narrower, supports ABAC conditions); Reader is read-only.
- Policy is free for Azure resources; Arc-connected servers with machine configuration cost $6/server/month.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-assign-allowed-locations | WRITE | S | Assign the built-in "Allowed locations" Policy at resource-group scope |
| 2 | e02-custom-sku-region-guard | WRITE, LAB | M | Custom Policy definition and assignment for lab SKU and region guard (Policy is free) |
| 3 | e03-reader-role-assignment | WRITE | S | Assign the Reader role at resource-group scope with a guid() name |
| 4 | e04-role-at-wrong-scope | BUG | S | Find and fix a role assignment at the wrong scope |
| 5 | e05-policy-effects | PREDICT | S | Predict Deny, Audit, and Modify outcomes from a scenario |
| 6 | e06-interpret-access-assignments | CLI | S | Interpret mocked `az role assignment list` output |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-policy-assignment | Assign a built-in Policy at subscription or resource-group scope |
| 2 | r02-role-assignment-name | Assign a role with a guid() name for idempotence |
