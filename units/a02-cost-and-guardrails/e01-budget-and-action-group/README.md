# a02-e01-budget-and-action-group `[WRITE] [LAB]` (M)

## Goal

Write the course subscription budget and an email action group, then deploy and export them.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- Entry is `up.sub-scope.bicep` (`targetScope = 'subscription'`).
- Compiled template contains `Microsoft.Consumption/budgets@2024-08-01` named from `budgetName` (default `lagb-monthly`) and `Microsoft.Insights/actionGroups`.
- Five notifications: Actual 50/80/100 and Forecasted 80/100 (Azure's per-budget maximum is 5). Amount is the `amount` parameter (default 25, allowed 10–25 for the course).
- The action group is resource-group-scoped; deploy it with a module `scope: resourceGroup(guardrailsResourceGroup)`.
- Offline checks do not run `az`. Live deploy is `pwsh -File ../../../scripts/lab/lab-up.ps1 -Path .` after `.lab-env.json` exists (`budget.contactEmail` required).

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

## Lab

**Cost class:** free / negligible (Consumption budget + Monitor action group).

**Teardown:** `pwsh -File ../../../scripts/lab/lab-down.ps1 -Path . -IncludePersistent` (the guardrails group is `lifecycle=persistent` and is skipped without that switch).

**Export (live, after deploy):** `az deployment sub export --name lagb-a02-budget`.

This lab *creates* the budget that later `[LAB]`s require. A02 is exempt from the budget gate.

<details>
<summary>Hint</summary>

Write the budget and the action-group module below the marker. Five notifications: Actual 50/80/100 and Forecasted 80/100. The starter below the marker is empty on purpose.

</details>
