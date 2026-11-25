# a02-e02-advisor-recommendations `[CLI]` (S)

## Goal

Read `fixtures/advisor.json` (a course fixture in the shape of `az advisor recommendation list`) and write `ANSWER.md`. This is not live Azure.

## Constraints

- Identify every High-impact Cost recommendation and the resource it names.
- Say what you would do in this course to remove that cost (be specific: `lab-down`, deallocate, delete a disk).
- Explain one way Advisor differs from the A02 budget.

Required `ANSWER.md` headings (exact lines):

- `## High cost`
- `## What you would do`
- `## Why Advisor is not a budget`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
