# A05 Drills: Entra identity

These drills make Entra user and group queries automatic. You will read users and groups with `az ad` commands, filter results, and add group members in CLI scripts until you can do so without hesitation. These skills are production skills: querying directory objects and managing group membership are common administrator tasks.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-query-users** — Query users and groups with `az ad user list`, `az ad group list`, and filter by display name, department, or other properties. Target: about 10 minutes per rep, 3+ reps on different days.

2. **r02-add-group-member** — Add a member to a group via CLI script using `az ad group member add` and verify membership with `az ad group member check`. Target: about 10 minutes per rep, 3+ reps on different days.
