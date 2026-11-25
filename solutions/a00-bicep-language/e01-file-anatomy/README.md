# a00-e01-file-anatomy `[PREDICT]` (S)

## Goal

Read `main.bicep` and predict which declarations are parameters, variables, resources, and outputs.

## Constraints

- `ANSWER.md` uses the required headings exactly, with text under each.
- Name every parameter, variable, resource symbolic name, and output in the file.
- Do not change `main.bicep`.

Required `ANSWER.md` headings (exact lines):

- `## Parameters`
- `## Variables`
- `## Resources`
- `## Outputs`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
