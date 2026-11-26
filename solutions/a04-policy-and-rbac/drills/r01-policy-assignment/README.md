# a04-r01-policy-assignment `[DRILL]` (S)

## Skill

Assign the built-in Allowed locations Policy at resource-group scope by referencing the definition id, not by copying it.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. Definition id `e56962a6-4747-49cd-b67b-bf8b01975c4c` through `tenantResourceId` or the tenant-level `/providers/Microsoft.Authorization/policyDefinitions/<guid>` literal, not `subscriptionResourceId`. Pass `listOfAllowedLocations`.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
