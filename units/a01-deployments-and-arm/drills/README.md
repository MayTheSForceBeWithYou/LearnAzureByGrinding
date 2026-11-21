# A01 Drills: Deployments and ARM JSON

These drills make deployment scope changes and ARM JSON editing automatic. You will set target scopes and modify ARM templates by hand until you can do so without hesitation. These skills are production skills: when you export a deployment or troubleshoot a failing template, you read and edit JSON directly.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. Run `pwsh -File ../../../../../scripts/check.ps1` from the rep folder to verify your work. Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-set-target-scope** — Set targetScope and deploy a resource at that scope. Target: 3 minutes per rep, 3+ reps on different days.

2. **r02-edit-arm-json** — Read and modify ARM JSON by hand. Target: 5 minutes per rep, 3+ reps on different days.
