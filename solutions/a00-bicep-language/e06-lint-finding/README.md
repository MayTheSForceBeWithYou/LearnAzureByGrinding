# a00-e06-lint-finding `[BUG]` (S)

## Goal

Find and fix the Bicep linter failure in `main.bicep`. Write `ANSWER.md` with what was wrong, the mechanism, and which tool showed it.

## Constraints

- The starter compiles.
- The starter fails exactly the diagnostic `no-hardcoded-location` (no extra lint or PSRule ids).
- The solution is lint- and PSRule-clean.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
