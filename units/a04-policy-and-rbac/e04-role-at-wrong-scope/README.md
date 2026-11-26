# a04-e04-role-at-wrong-scope `[BUG]` (S)

## Goal

The Reader assignment's scope lands on the subscription instead of the resource group. Find and fix that scope mistake. Write `ANSWER.md`.

## Constraints

- The starter compiles. The defect is a real scope mistake, not a typo in a name or GUID.
- Keep the built-in Reader role (`acdd72a7-3385-48ef-bd42-f606fba81ae7` via `subscriptionResourceId`).
- Keep `name = guid(<the assignment's actual scope>, principalId, roleDefinitionId)`. After the fix, the first `guid` argument is the resource group, matching `scope: rg`.
- Do not hard-code a GUID and do not use `newGuid()`.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
