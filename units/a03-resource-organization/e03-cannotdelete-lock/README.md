# a03-e03-cannotdelete-lock `[WRITE]` (S)

## Goal

Add a `CanNotDelete` lock on the resource group already declared above the marker.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled template contains `Microsoft.Authorization/locks`.
- `properties.level` is `CanNotDelete` (not `ReadOnly`).
- The lock must apply to the resource group `rg`, not the subscription.
- In a `targetScope = 'subscription'` file you cannot put `scope: rg` on the lock resource (BCP139). Write a resource-group-scoped module and deploy it with `scope: rg` (see [scope for extension resources](https://learn.microsoft.com/azure/azure-resource-manager/bicep/scope-extension-resources)).
- A lock name may be any valid string; `lagb-cannotdelete` is fine.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

Add `lock.bicep` with `targetScope = 'resourceGroup'` and the `Microsoft.Authorization/locks` resource. From `main.bicep`, `module lockMod 'lock.bicep' = { name: 'lagb-lock'; scope: rg }`. Putting `scope: rg` on the lock in this file is BCP139.

</details>
