# Notes

**Why it is correct.** `module reader 'reader.bicep' = { scope: rg, … }` with `name: guid(resourceGroup().id, principalId, readerRoleId)` inside the module. Reader id and principal params were already right.

**Numbers / SKUs.** Reader `acdd72a7-3385-48ef-bd42-f606fba81ae7` via `subscriptionResourceId`.

**Alternatives.** None that compile on Bicep 0.49.2: `scope: rg` on the role assignment in `main.bicep` is BCP139.

**The usual mistake.** Adding `scope: rg` on the assignment in the subscription file (does not compile), or leaving `guid(subscription().id, …)` after moving the assignment into the group.
