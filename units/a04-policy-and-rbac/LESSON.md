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

A policy assignment attaches a definition to a scope. You assign Policy at subscription, resource group, or management-group scope in Bicep:

```bicep
targetScope = 'subscription'

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
    displayName: 'Allowed locations'
    description: 'This policy restricts resource locations to East US and West US'
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

The `policyDefinitionId` is the full resource ID of the built-in or custom definition. Built-in definitions live at `/providers/Microsoft.Authorization/policyDefinitions/<guid>`. Custom definitions you deploy live at subscription or management-group scope and have resource IDs like `/subscriptions/<id>/providers/Microsoft.Authorization/policyDefinitions/<name>`.

Policy assignments inherit downward: a Policy assigned at subscription scope applies to every resource group and resource in the subscription. A Policy assigned at management-group scope applies to every subscription, resource group, and resource in that management group. This is the same inheritance model as locks and RBAC.

### Policy effects

A policy definition's `effect` controls what happens when a resource violates the rule. Common effects:

- **Deny**: blocks the resource creation or update. The request fails with a Policy violation error.
- **Audit**: logs the violation but allows the operation to proceed.
- **AuditIfNotExists** and **DeployIfNotExists**: evaluate whether a related resource exists. AuditIfNotExists logs a violation if the related resource is missing. DeployIfNotExists creates the missing resource after the deployment succeeds.
- **Modify**: alters create or update requests (for example, "set the minimum TLS version to 1.2"). The assignment requires a managed identity with a role assignment covering the `roleDefinitionIds` the definition declares.
- **Disabled**: the Policy is assigned but not evaluated.

Deny and Audit are the most common. Deny blocks non-compliant resources at deployment. Audit allows them through but flags them. Modify and DeployIfNotExists assignments require a managed identity and role assignments; existing non-compliant resources need a remediation task to apply the change.

### Custom Policy definitions

A custom Policy definition is a JSON document with `policyRule`, `parameters`, and `metadata`. Deploy it at subscription scope:

```bicep
targetScope = 'subscription'

resource customPolicy 'Microsoft.Authorization/policyDefinitions@2024-04-01' = {
  name: 'sku-region-guard'
  properties: {
    displayName: 'Lab SKU and region guard'
    policyType: 'Custom'
    mode: 'All'
    parameters: {
      allowedLocations: { type: 'Array' }
      allowedSkus: { type: 'Array' }
    }
    policyRule: {
      if: {
        anyOf: [
          {
            not: {
              field: 'location'
              in: '[parameters(\'allowedLocations\')]'
            }
          }
          {
            allOf: [
              { field: 'type', equals: 'Microsoft.Storage/storageAccounts' }
              {
                not: {
                  field: 'Microsoft.Storage/storageAccounts/sku.name'
                  in: '[parameters(\'allowedSkus\')]'
                }
              }
            ]
          }
        ]
      }
      then: { effect: 'Deny' }
    }
  }
}
```

This definition denies resources outside the allowed locations or storage accounts outside the allowed SKUs. After deploying the definition, you assign it with a policy assignment that passes parameter values. The course uses a custom definition for the lab SKU and region guard to prevent accidental deployments of costly SKUs.

### Role-based access control (RBAC)

**RBAC** grants users, groups, or service principals access to Azure resources. A **role assignment** attaches a **role definition** (a set of permissions) to a **principal** at a **scope** (subscription, resource group, or resource).

Azure provides built-in roles:

- **Owner**: full access, including managing RBAC assignments.
- **Contributor**: full resource access, but `NotActions` exclude `Microsoft.Authorization/*/Write` and `*/Delete` (among others), so it cannot manage RBAC.
- **Reader**: read-only access.
- **User Access Administrator**: manage role assignments only, no resource access.
- **Role Based Access Control Administrator**: create and delete role assignments at the assigned scope, plus read resources. Can be constrained with ABAC conditions to restrict which roles or principals it manages.
- Many resource-specific roles: **Storage Blob Data Contributor**, **Virtual Machine Contributor**, etc.

RBAC is **additive**: the principal's effective permissions are the union of all role assignments at all scopes. Azure also supports **deny assignments** (explicit denials that override allow), created by Azure features such as Deployment Stacks (deny settings) and managed applications, not directly by users.

### Role assignments

A role assignment attaches a role to a principal at a scope. You assign roles in Bicep:

```bicep
targetScope = 'resourceGroup'

@description('Principal ID of the user, group, or service principal')
param principalId string

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: principalId
  }
}
```

The `roleDefinitionId` is the full resource ID of the built-in role definition. Built-in role definitions are subscription-level resources; their IDs are `/subscriptions/<id>/providers/Microsoft.Authorization/roleDefinitions/<guid>`. The role GUID is fixed for each built-in role (Reader is always `acdd72a7-3385-48ef-bd42-f606fba81ae7`). The `name` is a GUID; use `guid()` to generate a deterministic GUID from the scope, principal, and role to make the assignment idempotent.

Role assignments inherit downward: a role assignment at subscription scope grants access to every resource group and resource in the subscription. A role assignment at management-group scope grants access to every subscription in that management group. To grant access to a single resource, assign the role at that resource's scope (set `scope: <resource-symbolic-name>` on the role assignment).

### Interpreting access assignments

The portal (IAM blade) and CLI (`az role assignment list`) show effective role assignments. When a deployment fails with "insufficient permissions," check the role assignments at the resource, resource group, subscription, and management-group levels. RBAC is additive, so look for any assignment that grants the needed permission. If none exists, request the role from an Owner or User Access Administrator at the appropriate scope.

The CLI command `az role assignment list --assignee <principal-id>` shows all assignments for that principal. Add `--all` to include inherited assignments from groups. The output shows the role, scope, and principal. To interpret an access assignment, find the role definition GUID, then look up the role name and permissions in the official documentation or with `az role definition list --name <role-name>`.

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

Deploy this at subscription scope with `az deployment sub create --location eastus --template-file main.bicep`. After deployment, any attempt to create a resource in a region outside East US or West US fails with a Policy violation error. Existing resources outside those regions are flagged as non-compliant but are not deleted.

**The plausible wrong reading.** You might expect the Policy to delete existing resources that violate the rule. That is not true. Deny policies block new deployments and updates, but they do not delete existing resources. To remediate existing resources, delete them manually or use a remediation task (available for DeployIfNotExists and Modify, not Deny).

## Worked example: Assign Reader role at resource-group scope

A contractor needs read-only access to a development resource group. You will assign the Reader role at resource-group scope to the contractor's principal ID.

The Reader role GUID is `acdd72a7-3385-48ef-bd42-f606fba81ae7`. Here is the assignment:

```bicep
targetScope = 'resourceGroup'

@description('Principal ID of the contractor user or service principal')
param contractorPrincipalId string

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource readerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, contractorPrincipalId, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: contractorPrincipalId
  }
}
```

Deploy this at resource-group scope with `az deployment group create --resource-group dev-rg --template-file main.bicep --parameters contractorPrincipalId=<id>`. After deployment, the contractor can read resources in `dev-rg` but cannot modify them or access other resource groups (unless they have other role assignments).

**The plausible wrong reading.** You might expect Reader to include some write permissions (starting or stopping a VM). That is not true. Reader is strictly read-only. To start or stop a VM, the principal needs Contributor or Virtual Machine Contributor.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Policy definition vs policy assignment | A policy definition is the rule (a JSON document). A policy assignment attaches the definition to a scope and passes parameter values. Without an assignment, the definition has no effect. |
| Deny vs Audit | Deny blocks non-compliant resources at deployment. Audit allows them through but logs the violation. |
| Modify vs DeployIfNotExists | Modify alters create/update requests. DeployIfNotExists creates a missing related resource after the deployment succeeds. Both assignments require a managed identity and role assignments. Existing non-compliant resources need remediation tasks. Deny and Audit do not. |
| Role definition vs role assignment | A role definition is a set of permissions. A role assignment attaches the role to a principal at a scope. Without an assignment, the definition has no effect. |
| Owner vs Contributor | Owner has full access including RBAC management. Contributor's `NotActions` exclude `Microsoft.Authorization/*/Write` and `*/Delete`, so it cannot manage RBAC. |
| User Access Administrator vs Role Based Access Control Administrator | User Access Administrator manages role assignments only. Role Based Access Control Administrator manages role assignments and can read resources. Both lack resource write access. Use ABAC conditions on the latter to constrain which roles or principals it manages. |
| Contributor vs Reader | Contributor has full resource access (create, update, delete). Reader is read-only. |
| RBAC is additive (except deny assignments) | The principal's effective permissions are the union of all role assignments at all scopes. Azure deny assignments (created by Deployment Stacks, managed applications, and other Azure features, not directly by users) override allow. |
| Scope inheritance | Policy assignments and role assignments inherit downward. A child scope cannot remove a parent assignment. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [What is Azure Policy?](https://learn.microsoft.com/en-us/azure/governance/policy/overview) — Policy concepts
- [Policy definition structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure) — JSON schema, parameters, policyRule
- [Understand Azure Policy effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects) — Deny, Audit, Modify, DeployIfNotExists
- [Create a custom policy definition](https://learn.microsoft.com/en-us/azure/governance/policy/tutorials/create-custom-policy-definition) — custom Policy
- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview) — RBAC concepts and built-in roles
- [Azure built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) — full list with GUIDs
- [Understand scope for Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/scope-overview) — subscription, resource-group, resource scope
- [Troubleshoot Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/troubleshooting) — diagnose permissions issues
- [Microsoft.Authorization/policyDefinitions](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/policydefinitions) — Bicep/ARM Policy definitions
- [Microsoft.Authorization/policyAssignments](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments) — Bicep/ARM Policy assignments
- [Microsoft.Authorization/roleAssignments](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments) — Bicep/ARM role assignments
- [az policy](https://learn.microsoft.com/en-us/cli/azure/policy) — CLI commands for Policy
- [az role assignment](https://learn.microsoft.com/en-us/cli/azure/role/assignment) — CLI commands for role assignments

## Check yourself

<details>
<summary>Answers</summary>

1. **You assign a Deny Policy at subscription scope that blocks storage accounts outside East US. A storage account in West US already exists. What happens to that account?**  
   Nothing. The account is flagged as non-compliant, but Deny policies do not delete existing resources. New storage accounts outside East US are blocked. To remediate the existing account, you must delete it manually or move it to East US (if the resource type supports moves).

2. **A Policy definition has the Audit effect. You deploy a resource that violates the Policy. Does the deployment succeed?**  
   Yes. Audit logs the violation but allows the operation to proceed. The resource is created and flagged as non-compliant. If the Policy had the Deny effect, the deployment would fail.

3. **A user is assigned Reader at subscription scope and Contributor at resource-group scope for `dev-rg`. What access does the user have to `dev-rg`? What about other resource groups in the subscription?**  
   The user has Contributor access to `dev-rg` (full resource access, but cannot manage RBAC). The user has Reader access to other resource groups in the subscription. RBAC is additive: the effective permissions are the union of all assignments.

4. **You need to grant a service principal the ability to assign roles in a resource group, but you do not want it to create or modify resources. Which role do you assign?**  
   User Access Administrator or Role Based Access Control Administrator. Both manage role assignments but cannot create or modify resources. Owner can do both; Contributor can create resources but not manage RBAC.

5. **Can you create a Policy assignment whose definition has the Modify effect without configuring a managed identity and role assignments on the assignment?**  
   No. The assignment creation fails (portal and ARM require `identity` and `location`). Modify and DeployIfNotExists assignments write on behalf of the caller, so they must have a managed identity with role assignments covering the `roleDefinitionIds` the definition declares. Deny and Audit assignments do not need a managed identity.

</details>

## Takeaways

- Policy definitions are rules; policy assignments attach definitions to scopes and pass parameters.
- Deny blocks non-compliant resources at deployment; Audit logs violations. Modify and DeployIfNotExists assignments require a managed identity with role assignments; existing non-compliant resources need remediation tasks.
- Policy assignments and role assignments inherit downward: assigned at subscription scope, they apply to every resource group and resource in the subscription.
- RBAC is additive: the principal's effective permissions are the union of all role assignments, except deny assignments (created by Deployment Stacks and other Azure features) override allow.
- Owner has full access including RBAC; Contributor's `NotActions` exclude RBAC management; User Access Administrator and Role Based Access Control Administrator manage role assignments but cannot write resources; Reader is read-only.
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
