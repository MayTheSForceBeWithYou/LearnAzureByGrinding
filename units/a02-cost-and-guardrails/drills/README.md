# A02 Drills: Cost control and lab guardrails

These drills make cost-control patterns automatic. You will write course tags and budget alert configurations from memory until they are second nature. Every lab resource must be tagged correctly, and every budget must include both Actual and Forecasted alerts. These are not guidelines; they are requirements the harness enforces.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-course-tags** — Write the five course tags on a resource. Target: 2 minutes per rep, 3+ reps on different days.

2. **r02-budget-alert-thresholds** — Write budget notifications with Actual and Forecasted thresholds. Target: 5 minutes per rep, 3+ reps on different days.
