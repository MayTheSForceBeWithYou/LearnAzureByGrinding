# a06-r01-storage-sku-and-kind `[DRILL]` (S)

## Skill

Author a storage account whose SKU, kind, and blob access tier come from parameters. This is the motion A06 e01 used, with the SKU/kind/tier chosen up front.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. `lagb` name prefix (no hyphen: storage account names are letters and numbers only). `allowSharedKeyAccess: false`, HTTPS, TLS 1.2, no public blobs. Bind `sku.name`, `kind`, and `properties.accessTier` to the parameters (do not hard-code those three).

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
