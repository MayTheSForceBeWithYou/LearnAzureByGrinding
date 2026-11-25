# a01-e05-decompile-round-trip `[PREDICT]` (S)

## Goal

Compare `main.bicep` with `fixtures/decompiled.bicep` (produced by `bicep build` then `bicep decompile --force` on this file) and predict what a compile/decompile round trip drops or rewrites.

## Constraints

- `fixtures/compiled.json` is `bicep build` of `main.bicep` (not committed next to the `.bicep`, which lint forbids).
- `ANSWER.md` uses the required headings.
- Do not invent CLI output. Quote only from the shipped files.

Required `ANSWER.md` headings (exact lines):

- `## Always lost`
- `## Often rewritten`
- `## Usually preserved`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
