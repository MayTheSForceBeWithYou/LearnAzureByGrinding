# a01-e01-scopes-and-mode `[EXPLAIN]` (S)

## Goal

Explain the four deployment scopes and Incremental vs Complete mode. `main.bicep` is a resource-group-scoped neighbour, not a puzzle.

## Constraints

- `ANSWER.md` uses the required headings exactly.
- Complete mode caveats: the resource group itself is never deleted; locks block deletions; only types that support complete-mode deletion are removed; a resource with `condition: false` is deleted.

Required `ANSWER.md` headings (exact lines):

- `## Four scopes`
- `## Incremental vs Complete`
- `## What Complete will not delete`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
