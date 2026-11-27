# a05-r02-add-group-member `[DRILL]` (S)

## Skill

Look up a user and a security group by display name and add the membership **idempotently** (do not fail, and do not call `az ad group member add`, when the user is already a member). Always assert the A05 test-tenant guard first.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. Call `Assert-LabContext -Scope Entra -LabEnv $LabEnv` before any `az` call. Resolve both objects by name, then add membership only if `az ad group member check` says they are not already a member.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
