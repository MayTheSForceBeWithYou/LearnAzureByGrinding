# A03 Drills: Resource organization

These drills make resource-group declaration and lock configuration automatic. You will declare resource groups at subscription scope with tags, set locks, and verify lock inheritance until you can do so without hesitation. These skills are production skills: resource groups, tags, and locks are the first layer of estate organization and protection.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-rg-with-tags** — Declare a resource group with tags at subscription scope. Target: 3 minutes per rep, 3+ reps on different days.

2. **r02-lock-a-resource-group** — Set a lock on a resource group and verify inheritance. Target: 4 minutes per rep, 3+ reps on different days.
