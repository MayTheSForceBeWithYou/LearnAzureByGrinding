# a04-r02-role-assignment-name `[DRILL]` (S)

## Skill

Name a resource-group-scope Reader assignment `guid(scope, principalId, roleDefinitionId)` and reference the built-in Reader definition. A hard-coded GUID or `newGuid()` is wrong.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. Reader id `acdd72a7-3385-48ef-bd42-f606fba81ae7` through `subscriptionResourceId`. `principalId` and `principalType` are already parameters.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
