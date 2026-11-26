# Notes

**Why it is correct.** Built-in Reader via `subscriptionResourceId`. Name is `guid(resourceGroup().id, principalId, readerRoleId)` — scope, principal, role. `principalId` and `principalType` are the shipped parameters.

**Numbers / SKUs.** Reader definition `acdd72a7-3385-48ef-bd42-f606fba81ae7`. Assignment API `2022-04-01`.

**Alternatives.** Inlining `subscriptionResourceId(...)` in `name` and `roleDefinitionId` without a `var` compiles the same.

**The usual mistake.** `newGuid()` (a new name on every deploy, which fails updates) or a hard-coded GUID. Omitting `principalType` lets ARM infer it, but the tests require the property.
