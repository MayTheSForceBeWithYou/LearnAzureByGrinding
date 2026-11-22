# a02-e04-idle-resource-cost `[PREDICT]` (S)

## Goal

Predict what still costs money if a lab VM with a public IP and a managed OS disk is left overnight. `main.bicep` is a neighbour (a storage account), not the VM.

## Constraints

- Cover Stopped vs Stopped (deallocated) vs deleted VM.
- Public IPs bill hourly until the IP resource is deleted (about $0.005/hr for Standard).
- Do not invent Advisor quotes. Use the lesson and SPEC §10.4.

Required `ANSWER.md` headings (exact lines):

- `## Still bills compute`
- `## Disks and IPs`
- `## What lab-down does`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
