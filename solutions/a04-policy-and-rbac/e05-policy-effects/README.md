# a04-e05-policy-effects `[PREDICT]` (S)

## Goal

Predict Deny, Audit, and Modify outcomes for the deployment described below. `main.bicep` is a neighbour: a resource-group-scope assignment of the built-in Allowed locations definition (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) with `listOfAllowedLocations = ['eastus']`. Do not change it.

## Premise

You deploy a StorageV2 account whose `location` is `westus` into the assigned resource group. An existing storage account in that group is already in `westus` (created before the assignment). Consider three cases that differ only by effect: **Deny**, **Audit**, and **Modify** (Modify configured to set location to `eastus`).

Cover all of the following in `ANSWER.md`:

- Evaluation order of Policy effects (where Deny, Audit, and Modify sit relative to each other).
- What happens to **this** westus deployment under Deny, under Audit, and under Modify.
- Deny does **not** remove existing non-compliant resources.
- Modify and `deployIfNotExists` need a **managed identity**, a **location**, and a **role assignment** for remediation.
- Modify applies to **existing** resources only through a **remediation task**.

Required `ANSWER.md` headings (exact lines):

- `## Evaluation order`
- `## Deny`
- `## Audit`
- `## Modify`
- `## Existing non-compliant resources`
- `## Remediation identity`

Do not invent portal or CLI output. Do not change `main.bicep`.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
