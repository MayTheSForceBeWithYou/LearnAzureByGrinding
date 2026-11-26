# a02-e05-account-isolation `[CLI]` (S)

## Goal

Compare `fixtures/account-show.json` (shape of `az account show`) with `fixtures/lab-env.json` and write `ANSWER.md`. No live `az login`.

## Constraints

- Say whether the active tenant and subscription match the lab pin, and which fields you compared.
- State the `az login --tenant` / `az account set --subscription` fix for a mismatch.
- State what `lab-up` does if the tenant looks corporate (including a name or domain containing `deloitte`): it refuses, exit code 3.

Required `ANSWER.md` headings (exact lines):

- `## Match`
- `## Mismatch`
- `## Corporate refuse`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
