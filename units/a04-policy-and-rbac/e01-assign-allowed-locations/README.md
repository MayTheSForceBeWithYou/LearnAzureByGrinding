# a04-e01-assign-allowed-locations `[WRITE]` (S)

## Goal

Assign the built-in **Allowed locations** Policy at resource-group scope.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled template contains `Microsoft.Authorization/policyAssignments`.
- `targetScope` is `resourceGroup`.
- Reference the built-in definition with `subscriptionResourceId` or `tenantResourceId` for `Microsoft.Authorization/policyDefinitions` and definition id `e56962a6-4747-49cd-b67b-bf8b01975c4c`. Do not copy the definition's `policyRule`.
- Pass `listOfAllowedLocations` (the built-in parameter name). Include `eastus`.
- Effect is whatever the built-in definition uses; you are not writing a custom definition here.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`policyDefinitionId: subscriptionResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')`. Parameters go under `properties.parameters.listOfAllowedLocations.value`.

</details>
