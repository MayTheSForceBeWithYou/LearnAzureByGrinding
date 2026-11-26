# Notes

**Why it is correct.** Same motion as e03: Reader by built-in id, deterministic `guid(resourceGroup().id, principalId, roleDefinitionId)`, `principalType` set.

**Numbers / SKUs.** Reader `acdd72a7-3385-48ef-bd42-f606fba81ae7`.

**Alternatives.** A `var` for the role id, as here, or the helper inlined twice.

**The usual mistake.** `guid(subscription().id, …)` on a resource-group-scope file, or `newGuid()`.
