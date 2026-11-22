# Notes

**Why it is correct.** Subscription budget plus a module-scoped action group in the persistent guardrails RG. Five notifications, contactGroups wired to the action group id.

**Numbers / SKUs.** API Microsoft.Consumption/budgets@2024-08-01, actionGroups@2023-01-01. Amount default 25. Actual 50/80/100, Forecasted 80/100.

**Alternatives.** contactEmails on the notifications plus the action group is belt-and-suspenders; the gate does not check notifications at all.

**The usual mistake.** Using Microsoft.CostManagement/budgets (not a Bicep type the gate lists) or a resource-group-scoped budget (az consumption budget list will not see it).
