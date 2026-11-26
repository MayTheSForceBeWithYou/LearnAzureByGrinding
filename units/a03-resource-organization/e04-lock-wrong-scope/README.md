# a03-e04-lock-wrong-scope `[BUG]` (S)

## Goal

The lock is at the wrong Azure scope. Find and fix it so it protects the resource group, not the subscription. Write `ANSWER.md`.

## Constraints

- The starter compiles. The defect is a real scope mistake: the lock is deployed at subscription scope instead of on the resource group.
- Do not "fix" it by renaming the lock or by changing `level`. Change where the lock applies.
- After the fix, `properties.level` is still `CanNotDelete`, and the lock's `scope` is the resource group `rg`.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
