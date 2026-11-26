# Notes

**Why it is correct.** Subscription-scope baseline: tagged guardrails RG from `rgName`/`tags`; `CanNotDelete` lock in `lock.bicep` deployed with `scope: rg`; Allowed locations assignment at subscription scope named `lagb-allowed-locations` via `tenantResourceId` (no module — it stays at subscription so `down.ps1` can delete it by name); Reader in `reader.bicep` deployed with `scope: rg` and `guid(resourceGroup().id, principalId, roleDefinitionId)`; Monthly Cost budget named `lagb-c1-baseline` with Actual 50/80/100 and Forecasted 80/100. `down.ps1` (harness) removes the lock before `az group delete`. Bicep 0.49.2 requires the modules (BCP139).

**Numbers / SKUs.** Allowed locations `e56962a6-4747-49cd-b67b-bf8b01975c4c` at tenant scope. Reader `acdd72a7-3385-48ef-bd42-f606fba81ae7`. Budget API `Microsoft.Consumption/budgets@2024-08-01`. Lock name `lagb-cannotdelete`. Cost class $0 East US (Policy, RBAC, locks, an empty group, and a Consumption budget do not meter compute).

**Alternatives.** An action group on the budget notifications (A02's pattern) is valid; C1 does not require one.

**The usual mistake.** `scope: rg` on the lock or Reader in `main.bicep` (BCP139). Putting `scope: rg` on the Allowed locations assignment (then `down.ps1` cannot delete it as a subscription assignment). Naming the budget `lagb-monthly`. Leaving the lock in place and watching `az group delete` fail.
