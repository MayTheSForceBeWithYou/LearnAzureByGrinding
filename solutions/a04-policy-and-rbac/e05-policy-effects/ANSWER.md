# a04-e05-policy-effects

The neighbour `main.bicep` assigns built-in Allowed locations (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) at resource-group scope with `listOfAllowedLocations = ['eastus']`. Do not treat that as a live capture; it is the shipped template. The three cases below differ only by effect.

## Evaluation order
On a create or update request Azure Policy applies effects in this order: **Disabled** (skip), then **Append** and **Modify** (they can change the request), then **Deny** (block if still non-compliant), then **Audit** (log, do not block). **AuditIfNotExists**, **DeployIfNotExists**, and **Manual** run after the resource exists. **DenyAction** applies to delete, not to this create.

## Deny
The new StorageV2 account with `location: westus` is **blocked**. ARM returns a Policy deny error; the account is not created. Deny does not change the request and does not move anything to `eastus`.

## Audit
The new westus account **is created**. Policy marks it non-compliant and emits an audit event. Audit never blocks a deployment.

## Modify
Modify runs *before* Deny. If the assignment is configured to set `location` to `eastus` and that alias is writable on create, the incoming request is rewritten and the account is created in `eastus`. Modify does not, by itself, block a request: if the location alias is not Modify-capable, the westus create succeeds and the account is non-compliant until remediated. Modify and `deployIfNotExists` assignments need a **managed identity**, a **location** for that identity, and a **role assignment** the identity can use. They are not a drop-in replacement for Deny.

## Existing non-compliant resources
Deny does **not** remove or relocate the storage account that was already in `westus`. It stays. Audit reports it non-compliant. Modify does not touch existing resources during evaluation; they stay westus until you run a **remediation task**. Storage account location is immutable after create, so a remediation task cannot move that existing account to `eastus`.

## Remediation identity
A Modify or DeployIfNotExists assignment must declare `identity` (system-assigned is the usual lab choice) and `location` on the assignment resource, and the identity must have the role the definition lists (`roleDefinitionIds` — Contributor for the built-in inherit-tag policies). The portal can create that role assignment for you; Bicep must include `identity` and `location` or the assignment will not deploy. Existing resources are remediated only by a remediation task that uses that identity — not by assigning the policy.
