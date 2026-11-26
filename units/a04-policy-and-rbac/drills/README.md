# A04 Drills: Policy and RBAC

These drills make Policy and role assignments automatic. You will assign built-in Policy definitions, write role assignments with guid() names, and verify scope inheritance until you can do so without hesitation. These skills are production skills: Policy and RBAC are the enforcement layer of organizational governance and least-privilege access.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-policy-assignment** — Assign a built-in Policy at subscription or resource-group scope. Target: 4 minutes per rep, 3+ reps on different days.

2. **r02-role-assignment-name** — Assign a role with a guid() name for idempotence. Target: 4 minutes per rep, 3+ reps on different days.
