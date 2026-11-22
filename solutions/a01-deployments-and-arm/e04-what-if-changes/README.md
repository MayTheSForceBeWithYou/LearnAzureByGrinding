# a01-e04-what-if-changes `[WHATIF]` (S)

## Goal

Predict what-if change types for this template against the current state described below. Do not sign into Azure. A live `az deployment group what-if` capture is not in the tree yet.

## Constraints

- Current state (described, not live): the resource group already has one storage account whose name equals `existingName` (the default `st${uniqueString(resourceGroup().id)}`) with SKU `Standard_LRS`. Nothing else is in the group.
- The template changes that account's SKU to `Standard_GRS` and adds a second account.
- Incremental mode (the default).
- `ANSWER.md` uses the required headings. Quote symbols from the lesson table (`+` Create, `~` Modify, `*` Ignore). Do not invent a full what-if payload.
- `capture.txt` holds the pending live what-if marker until a real `az deployment group what-if` capture is dropped in. Do not invent az stdout. That pending marker fails lint and verify-all on purpose.

Required `ANSWER.md` headings (exact lines):

- `## Create`
- `## Modify`
- `## Ignore`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
