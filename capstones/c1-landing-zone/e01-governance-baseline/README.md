# c1-e01-governance-baseline `[WRITE] [LAB]` (L)

## Goal

Write a subscription-scope governance baseline: a guardrails resource group with course tags, a `CanNotDelete` lock on that group, an Allowed locations Policy assignment, a Reader role assignment, and the A02 budget pattern.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

Attempt after A04. Management groups and Entra identity are **documentation-only** in this README; do not create them here. Modules inside this exercise folder are allowed.

## Constraints

- `targetScope` is `subscription`.
- Guardrails resource group named from `rgName` (default `lagb-c1-e01-governance-baseline`), tagged with the course set (`course`, `unit`, `exercise`, `expires`, `owner`). `lab-up` overwrites `tags` with `New-LabTags` (including a fresh `expires`).
- `Microsoft.Authorization/locks` named `lagb-cannotdelete`, `level` `CanNotDelete`, `scope` the resource group (not the subscription).
- `Microsoft.Authorization/policyAssignments` named `lagb-allowed-locations` at **subscription** scope: built-in Allowed locations (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) via `subscriptionResourceId` or `tenantResourceId`. Do not copy the definition. Deny/audit only.
- `Microsoft.Authorization/roleAssignments`: built-in Reader (`acdd72a7-3385-48ef-bd42-f606fba81ae7` via `subscriptionResourceId`) at the resource group, `name = guid(<rg scope>, principalId, roleDefinitionId)`. `principalId` and `principalType` are parameters. Do not hard-code a GUID; do not use `newGuid()`.
- `Microsoft.Consumption/budgets@2024-08-01` named `budgetName` (default `lagb-c1-baseline`, **not** the A02 gate name `lagb-monthly`): Actual 50/80/100 and Forecasted 80/100.
- Location comes from the `location` parameter.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

## Lab

Optional and free. **Cost class:** $0 in East US (Policy, RBAC, locks, a resource group, and a Consumption budget do not meter compute).

**Teardown:** `pwsh -File ../../../scripts/lab/lab-down.ps1 -Path .`. `down.ps1` removes the lock **before** deleting the group, then removes the assignment, role assignment, budget, and group it created.

Live deploy is `pwsh -File ../../../scripts/lab/lab-up.ps1 -Path .` after `.lab-env.json` exists and the A02 budget is in place. `up.ps1` follows the A02 contract: LabGuard already refused a Deloitte/work tenant; it never runs `az login` or `az account set`; it honours `-WhatIf`; it throws on failure. For a live Reader assignment, replace the placeholder `principalId` up.ps1 passes with an object ID in your personal tenant.

## Documentation-only (not in the template)

- **Management groups:** A03; a personal tenant often cannot create them. No MG `[LAB]` (SPEC 13.3).
- **Identity:** Entra users, groups, and directory roles wait for A05 in the disposable test tenant. This capstone only assigns Azure RBAC to a `principalId` you pass in.

<details>
<summary>Hint</summary>

Subscription-scope file. Create the group, then `scope: rg` on the lock and the Reader assignment. The Allowed locations assignment stays at subscription scope (no `scope: rg`; `down.ps1` deletes it by name). Budget stays at subscription scope with five notifications. Modules in this folder are allowed.

</details>
