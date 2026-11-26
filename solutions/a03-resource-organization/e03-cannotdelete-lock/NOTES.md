# Notes

**Why it is correct.** The group is already above the marker. Bicep 0.49.2 rejects `scope: rg` on a lock in a subscription-scope file (BCP139). The lock lives in `lock.bicep` (resource-group scope) and is deployed with `module … scope: rg`.

**Numbers / SKUs.** Lock API `Microsoft.Authorization/locks@2020-05-01`. Module name and lock name `lagb-cannotdelete`. Level `CanNotDelete`.

**Alternatives.** `ReadOnly` also compiles; the test requires `CanNotDelete`. A lock name can be any valid string.

**The usual mistake.** Putting `scope: rg` on the lock resource in `main.bicep` (BCP139). Omitting the module so the lock lands on the subscription. Deleting a locked group later requires removing the lock first.
