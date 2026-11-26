# a03-r01-rg-with-tags `[DRILL]` (S)

## Skill

Write a subscription-scoped resource group with the `lagb-` prefix and the five course tags (`course`, `unit`, `exercise`, `expires`, `owner`). This is the motion A03 e01 used.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. `expires` is UTC `yyyy-MM-ddTHH:mm:ssZ`.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
