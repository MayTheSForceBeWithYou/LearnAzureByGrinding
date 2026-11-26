# a01-e04-what-if-changes `[WHATIF]` (S)

## Goal

Predict the what-if change types in `capture.txt` for this Incremental deployment. Do not sign into Azure. Write `ANSWER.md` first, then check it against the capture.

## Constraints

- Current state (described, not live): resource group `arm-template-group` does not already contain storage account `n8deploy20261122`.
- The capture was taken from ARM JSON `arm-parameterized-storage-template.json` with `storageSKU=Standard_GRS` and `storageName=n8deploy20261122`. `main.bicep` in this folder is a neighbour (one parameterized StorageV2 account). It is not the captured ARM JSON.
- Incremental mode (the default).
- `ANSWER.md` uses the required headings. Quote symbols from the lesson table and from `capture.txt`. Do not invent a full what-if payload. Do not write a Modify (`~`) transcript; this capture does not contain one.

Required `ANSWER.md` headings (exact lines):

- `## Create`
- `## Modify`
- `## Ignore`

<details>
<summary>Hint</summary>

Read the legend under `Resource and property changes are indicated with this symbol` and the `Resource changes:` summary line. Those lines list every change type this capture actually predicted.

</details>

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
