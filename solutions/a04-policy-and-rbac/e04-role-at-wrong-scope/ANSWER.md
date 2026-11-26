# a04-e04-role-at-wrong-scope

## What was wrong
The Reader assignment had no resource-group module, so as an extension resource on a subscription-scope file it attached to the **subscription**. The name used `guid(subscription().id, principalId, readerRoleId)`, which matched that wrong scope. Reader id, `principalId`, and `principalType` were already correct.

## Mechanism
Role assignments are extension resources. At `targetScope = 'subscription'`, a role assignment in `main.bicep` is subscription-wide. Bicep 0.49.2 rejects `scope: rg` on that resource (**BCP139**); the compiling fix is a resource-group-scope module (`reader.bicep`) deployed with `scope: rg`. Inside the module the name is `guid(resourceGroup().id, principalId, roleDefinitionId)` — the assignment's actual scope, the principal, and the role.

## Which tool showed it
The advertised defect is Pester: `the assignment is at resource-group scope, not subscription` (`main.tests.ps1`). Compiling the naive `scope: rg` fix also fails `bicep build` with BCP139. Lint and PSRule on the shipped starter were clean.
