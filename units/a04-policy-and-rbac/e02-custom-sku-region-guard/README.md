# a04-e02-custom-sku-region-guard `[WRITE] [LAB]` (M)

## Goal

Write a small custom Policy definition and assignment that guards lab SKUs and regions, then optionally deploy it at subscription scope.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- Entry is `main.bicep` (`targetScope = 'subscription'`).
- The compiled template contains `Microsoft.Authorization/policyDefinitions` and `Microsoft.Authorization/policyAssignments`.
- The definition is yours (a lab SKU/region guard). Do not paste a built-in `policyRule`.
- Effect is `deny` or `audit` only. Do not use `modify` or `deployIfNotExists` (those need a managed identity, `location`, and a remediation role).
- The assignment's `policyDefinitionId` is the custom definition, referenced with a resource id (the definition's `.id` or `subscriptionResourceId`), not a copied body.
- Name the definition and the assignment `lagb-sku-region-guard` (`down.ps1` deletes those names).

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

## Lab

**Cost class:** $0 in East US (Azure Policy is free; this lab creates no billable resources).

**Teardown:** `pwsh -File ../../../scripts/lab/lab-down.ps1 -Path .` (`down.ps1` removes the assignment, then the definition it created).

Live deploy is `pwsh -File ../../../scripts/lab/lab-up.ps1 -Path .` after `.lab-env.json` exists and the A02 budget is in place. `up.ps1` follows the A02 contract: LabGuard already checked the tenant; it never runs `az login` or `az account set`; it honours `-WhatIf`; it throws on failure.

<details>
<summary>Hint</summary>

Name both resources `lagb-sku-region-guard`. `then.effect` is `deny` or `audit`. The assignment's `policyDefinitionId` is `definition.id`.

</details>
