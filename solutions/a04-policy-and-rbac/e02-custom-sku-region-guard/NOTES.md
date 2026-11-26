# Notes

**Why it is correct.** Custom definition and assignment both named `lagb-sku-region-guard`. Effect is `deny` (not modify/DINE). The assignment's `policyDefinitionId` is `skuRegionGuard.id`. `down.ps1` (harness) deletes the assignment before the definition.

**Numbers / SKUs.** Defaults: locations `eastus`; VM SKUs `Standard_B1s`, `Standard_B2s`. Definition API `Microsoft.Authorization/policyDefinitions@2021-06-01` (0.49.2 has types for this version; `2024-04-01` is BCP081). Lab cost class $0 East US (Policy does not meter compute).

**Alternatives.** `audit` also passes the effect test. Parameterising `effect` as a definition parameter is fine if the assigned value stays deny or audit.

**The usual mistake.** Using modify or deployIfNotExists (needs identity + location + a role). Deleting the definition before the assignment (`az` refuses). Running `up.ps1` outside LabGuard / on a work tenant.
