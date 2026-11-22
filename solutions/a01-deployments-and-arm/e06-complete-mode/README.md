# a01-e06-complete-mode `[BUG]` (S)

## Goal

This template is the sole source of truth for a Complete-mode resource-group deployment. Find and fix the defect that would delete a storage account under Complete mode.

## Constraints

- The compiled template contains two storage accounts.
- Neither resource has `condition` false (a resource with `condition: false` is deleted in Complete mode).
- Do not change SKU, HTTPS, or names except as required to compile.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
