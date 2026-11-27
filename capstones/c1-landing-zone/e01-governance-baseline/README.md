# c1-e01-governance-baseline `[WRITE] [LAB]` (L)

## Goal

Write a subscription-scope governance baseline: a guardrails resource group with course tags, a `CanNotDelete` lock on that group, an Allowed locations Policy assignment, a Reader role assignment, and the A02 budget pattern.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

Attempt after A04. Management groups and Entra identity are **documentation-only** in this README; do not create them here. Modules inside this exercise folder are allowed.

## Constraints

- `targetScope` is `subscription`.
- Guardrails resource group named from `rgName` (default `lagb-c1-e01-governance-baseline`), tagged with the course set (`course`, `unit`, `exercise`, `expires`, `owner`). `lab-up` overwrites `tags` with `New-LabTags` (including a fresh `expires`).
- `Microsoft.Authorization/locks` named `lagb-cannotdelete`, `level` `CanNotDelete`, on the resource group (not the subscription). In this subscription-scope file you cannot put `scope: rg` on the lock (BCP139): deploy a resource-group-scoped module with `scope: rg`.
- `Microsoft.Authorization/policyAssignments` named `lagb-allowed-locations` at **subscription** scope: built-in Allowed locations (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) via `tenantResourceId` or the tenant-level `/providers/Microsoft.Authorization/policyDefinitions/<guid>` literal. Do not use `subscriptionResourceId` for a built-in Policy definition. Do not copy the definition. The built-in is Indexed and excludes `global`, so it will not deny the A02 action group or budget.
- `Microsoft.Authorization/roleAssignments`: built-in Reader (`acdd72a7-3385-48ef-bd42-f606fba81ae7` via `subscriptionResourceId`) at the resource group, also via a resource-group-scoped module (`scope: rg` on the module). `name = guid(resourceGroup().id, principalId, roleDefinitionId)`. `principalId` and `principalType` are parameters. Do not hard-code a GUID; do not use `newGuid()`.
- `Microsoft.Consumption/budgets@2024-08-01` named `budgetName` (default `lagb-c1-baseline`, **not** the A02 gate name `lagb-monthly`): Actual 50/80/100 and Forecasted 80/100.
- Location comes from the `location` parameter.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

## Lab

Optional and free. **Cost class:** $0 in East US (Policy, RBAC, locks, a resource group, and a Consumption budget do not meter compute).

**While this lab is up, Allowed locations is assigned at subscription scope for East US only.** Creating anything outside East US **anywhere in the subscription** is denied until `down.ps1` runs.

**Teardown:** `pwsh -File ../../../scripts/lab/lab-down.ps1 -Path .`. `down.ps1` removes the lock **before** deleting the group, then removes the assignment, role assignment, budget, and group it created.

Live deploy is `pwsh -File ../../../scripts/lab/lab-up.ps1 -Path .` after `.lab-env.json` exists and the A02 budget is in place. `up.ps1` follows the A02 contract: LabGuard already refused a Deloitte/work tenant; it never runs `az login` or `az account set`; it honours `-WhatIf`; it throws on failure. For a live Reader assignment, replace the placeholder `principalId` up.ps1 passes with an object ID in your personal tenant.

## Documentation-only (not in the template)

- **Management groups:** A03; a personal tenant often cannot create them. No MG `[LAB]` (SPEC 13.3).
- **Identity:** Entra users, groups, and directory roles wait for A05 in the disposable test tenant. This capstone only assigns Azure RBAC to a `principalId` you pass in.

<details>
<summary>Hint</summary>

Subscription-scope file. Create the group. Put the lock and the Reader assignment in resource-group-scoped modules and deploy those modules with `scope: rg` (do not put `scope: rg` on the lock or role assignment in this file — BCP139). The Allowed locations assignment stays at subscription scope (`tenantResourceId` for the built-in; `down.ps1` deletes it by name). Budget stays at subscription scope with five notifications. Modules in this folder are allowed.

</details>
