# a06-r02-enable-blob-versioning `[DRILL]` (S)

## Skill

Enable blob versioning and the change feed on `blobServices/default` of an existing storage account. Versioning is the object-replication prerequisite; change feed is the source-side one. The lesson's worked snippet is blob/container **soft delete** — this drill is versioning and change feed, not delete retention.

Sources: <https://learn.microsoft.com/azure/storage/blobs/versioning-overview> and <https://learn.microsoft.com/azure/storage/blobs/storage-blob-change-feed>.

## Rules

Fresh copy via `scripts/rep.ps1`. No live Azure. No hints. Child resource `blobServices` named `default`, `isVersioningEnabled: true`, `changeFeed.enabled: true` with a `retentionInDays`. Do not add delete retention here.

## Target

About 10 minutes per rep. Three reps on different days.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Verify

From this folder: `pwsh -File ../../../../scripts/check.ps1`. Copy a fresh rep with `pwsh -File ../../../../scripts/rep.ps1 .` (trailing dot required), then from the repo root `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>`.
