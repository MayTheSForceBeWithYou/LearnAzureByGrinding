# a04-e03-reader-role-assignment `[WRITE]` (S)

## Goal

Assign the built-in Reader role at resource-group scope to `principalId`.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled template contains `Microsoft.Authorization/roleAssignments`.
- `targetScope` is `resourceGroup`.
- `name` is `guid(resourceGroup().id, principalId, roleDefinitionId)` (the assignment scope, the principal, and the role). Do not hard-code a GUID and do not use `newGuid()`.
- `principalId` and `principalType` are parameters (already declared above the marker).
- Reader is `subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')`. Do not copy a role definition.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`name: guid(resourceGroup().id, principalId, readerRoleId)` with `readerRoleId` from `subscriptionResourceId` as above. Set `properties.principalType` from the parameter.

</details>
