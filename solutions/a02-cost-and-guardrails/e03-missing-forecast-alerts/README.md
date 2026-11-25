# a02-e03-missing-forecast-alerts `[BUG]` (S)

## Goal

The budget is missing Forecasted alerts. Find and fix it so the course set is complete (Actual 50/80/100 and Forecasted 80/100).

## Constraints

- Azure allows at most five notifications per budget. The course uses all five.
- The starter compiles. Forecasted 80 and 100 must exist after the fix.
- Do not change the budget name, amount, or action-group wiring except as required.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
