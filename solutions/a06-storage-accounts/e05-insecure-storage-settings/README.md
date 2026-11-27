# a06-e05-insecure-storage-settings `[BUG]` (S)

## Goal

The storage account accepts TLS 1.0 and allows anonymous blob public access. Find and fix both settings. Write `ANSWER.md`.

## Constraints

- The starter compiles. The advertised defects are `minimumTlsVersion: 'TLS1_0'` and `allowBlobPublicAccess: true`.
- `allowSharedKeyAccess` stays `false`. Do not add a PSRule suppression.
- PSRule with the course baseline (`Azure.Pillar.Security.L1`) reports **`Azure.Storage.MinTLS`** on this starter. That is the `ExpectDiagnostics` id (ran on 27 November 2026 against PSRule.Rules.Azure 1.47.0).
- `Azure.Storage.BlobPublicAccess` is a real PSRule rule and does fail this template if you invoke PSRule **without** the L1 baseline, but it is **not** in `Azure.Pillar.Security.L1`. The Pester test grades public access.
- After the fix: `minimumTlsVersion` is `TLS1_2` and `allowBlobPublicAccess` is false.

Required `ANSWER.md` headings (exact lines):

- `## What was wrong`
- `## Mechanism`
- `## Which tool showed it`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
