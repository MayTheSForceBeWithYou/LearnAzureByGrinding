# a05-r01-query-users `[DRILL]` (S)

## Skill

List Entra users filtered by department and output their UPNs, after asserting the A05 test-tenant guard. This is the motion A05 e02 used for `az ad user`.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. Call `Assert-LabContext -Scope Entra -LabEnv $LabEnv` before any `az` call. Filter on the server (`az ad user list` with a department filter), then return `userPrincipalName` values.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
