# A00 Drills: Bicep language fundamentals

These drills make Bicep syntax automatic. You will write parameters, resources, outputs, and module calls from memory until you can do so without consulting the lesson or official docs. Speed and accuracy matter: a production Bicep file is not written by copying and pasting from examples.

## How to use drills

Run `pwsh -File ../../../../scripts/rep.ps1 .` from a drill folder to copy the starter into a new timestamped `reps/` directory. Work in that copy. From the repository root, run `pwsh -File scripts/check.ps1 -Path reps/<id>/<stamp>` to verify your work (`rep.ps1` prints this command). Repeat the drill on different days until you meet the target time and accuracy.

Drills have no hints. The starter fails its tests until you write the required code. If you get stuck, review the lesson, then start a fresh rep.

## Drills

1. **r01-params-and-resource** — Write a parameter and a resource from memory. Target: 3 minutes per rep, 3+ reps on different days.

2. **r02-outputs** — Write outputs that reference a resource. Target: 2 minutes per rep, 3+ reps on different days.

3. **r03-module-call** — Write a module call with parameter passing. Target: 4 minutes per rep, 3+ reps on different days.
