# a03-e02-tags-are-not-inherited `[PREDICT]` (S)

## Goal

Read `main.bicep` and `storage.bicep`. Predict which tags land on the resource group and which land on the storage account, and whether Azure copies resource-group tags onto resources by itself.

## Constraints

- The resource group has the course tag set (`course`, `unit`, `exercise`, `owner`, `expires`).
- The module call passes `tags: union(rg.tags, { purpose: 'predict' })` into `storage.bicep`.
- `ANSWER.md` uses the required headings exactly, with text under each.
- Do not change the Bicep. Do not invent portal or CLI output.

Required `ANSWER.md` headings (exact lines):

- `## Resource group tags`
- `## Resource tags`
- `## union()`
- `## Inheritance`

Under **Inheritance**, say whether tags inherit from a resource group onto its resources, and name the built-in Policy that would add them if you assigned it (modify effect).

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
