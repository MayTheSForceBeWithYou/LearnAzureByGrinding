# a03-e04-lock-wrong-scope

## What was wrong
The lock compiled at **subscription** scope. `main.bicep` is `targetScope = 'subscription'`, and the `Microsoft.Authorization/locks` resource had no `scope` and was not in a resource-group module. Extension resources without a module attach to the deployment scope, so the lock protected the subscription rather than `lagb-a03-e04`.

## Mechanism
Locks are extension resources. In Bicep 0.49.2 you cannot write `scope: rg` on a lock in a subscription-scope file: `bicep build` fails with **BCP139** ("you must use modules to deploy resources to a different scope"). The fix is a resource-group-scope module (`lock.bicep`) deployed with `scope: rg`. `level` stays `CanNotDelete`; the lock name stays `lagb-cannotdelete`.

## Which tool showed it
The advertised defect is Pester: `the lock is scoped to the resource group, not the subscription` (`main.tests.ps1`). Compiling the naive `scope: rg` fix also fails `bicep build` with BCP139. Lint and PSRule on the shipped starter were clean; the starter defect is a Pester-only scope mistake. The compiling fix is a module.
