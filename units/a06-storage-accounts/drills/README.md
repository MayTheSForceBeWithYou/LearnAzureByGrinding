# A06 Drills: Storage accounts

These drills make storage account declaration and configuration automatic. You will declare storage accounts with specified SKUs and kinds, enable blob versioning and soft delete via child resources, and verify the compiled templates until you can do so without hesitation. These skills are production skills: storage accounts are the foundation of Azure data services.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-storage-sku-and-kind** — Declare a storage account with a specified SKU (such as `Standard_GRS` or `Premium_LRS`) and kind (`StorageV2`, `BlockBlobStorage`, or `FileStorage`). Target: about 10 minutes per rep, 3+ reps on different days.

2. **r02-enable-blob-versioning** — Enable blob versioning and change feed via the `blobServices/default` child resource under a storage account. Target: about 10 minutes per rep, 3+ reps on different days.
