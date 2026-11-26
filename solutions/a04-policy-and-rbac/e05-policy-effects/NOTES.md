# Notes

**Why it is correct.** Evaluation order is Disabled → Append/Modify → Deny → Audit, with DINE after the resource exists. Deny does not delete existing non-compliant resources. Modify/DINE need identity + location + a role; existing resources need a remediation task.

**Numbers / SKUs.** Neighbour definition id `e56962a6-4747-49cd-b67b-bf8b01975c4c`. Allowed location in the neighbour is `eastus`; the hypothetical new account is `westus`.

**Alternatives.** The built-in Allowed locations effect is Deny (parameterised Audit/Deny/Disabled). The Modify-sets-location case is the exercise premise, not that built-in's default.

**The usual mistake.** Believing Deny will delete or relocate the existing westus account, or that a Modify assignment works without a managed identity.
