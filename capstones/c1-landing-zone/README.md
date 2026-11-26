# C1: Landing zone — Governance baseline

## Overview

You have learned resource groups, tags, locks, Policy, and RBAC through units A02–A04. This capstone integrates those skills into a testable subscription-scoped governance baseline: a small landing zone that enforces organizational standards without the full complexity of a production Cloud Adoption Framework (CAF) or Azure Landing Zone (ALZ) deployment.

Attempt this capstone after completing **A04**. You will write a subscription-scoped Bicep deployment that creates the persistent guardrails resource group, applies course tags, sets a CanNotDelete lock, assigns a built-in Policy to restrict allowed locations, assigns a role for a given principal, and deploys the A02 budget pattern. The capstone is offline-testable and optionally deployable as a free `[LAB]` (Policy and RBAC are free; tags and locks are free; the budget is a monitoring resource with no direct cost).

After this capstone you can:
- Compose a subscription-scoped governance baseline from smaller governance pieces
- Deploy resource groups, Policy assignments, role assignments, and a budget in one template
- Verify the baseline offline and optionally deploy it to a lab subscription
- Explain how tags, locks, Policy, and RBAC interact at subscription scope

## What you will build

A subscription-scoped Bicep deployment (`main.bicep` at subscription scope) that declares:

1. **The guardrails resource group** (the persistent group that holds the budget's action group), with the five course tags except `expires` is replaced by `lifecycle=persistent`.
2. **A CanNotDelete lock** on the guardrails resource group to prevent accidental deletion.
3. **A Policy assignment** at subscription scope: the built-in "Allowed locations" Policy restricting deployments to `eastus` and `westus`.
4. **A role assignment** at subscription scope: assign the Reader role (or another built-in role of your choice) to a principal ID passed as a parameter. Use `guid()` for the assignment name.
5. **The budget and action group** (the A02 budget pattern): the action group in the guardrails resource group, and the subscription-scoped budget with Actual 50/80/100% and Forecasted 80/100% alerts.

Management groups and Microsoft Entra identities are **documentation only** in this capstone: include a brief explanation in `NOTES.md` (after you complete the exercise) of where management groups and Entra users fit in a production landing zone, but do not deploy them. The capstone tests subscription-scoped governance, not tenant-scoped identity or multi-subscription hierarchies.

## Constraints

- **Scope:** subscription. The main template is `targetScope = 'subscription'`.
- **Offline-testable:** the template must compile, lint clean, pass PSRule, and satisfy structural tests (ExpectResources, ExpectProperties) without deploying to Azure. The harness grades the compiled JSON.
- **Optional free `[LAB]`:** you may deploy this to your lab subscription with `lab-up` to verify the Policy and role assignment work. Policy, tags, locks, and RBAC assignments are free. The budget is a monitoring resource and does not bill. Tear down with `lab-down` as usual.
- **Parameterization:** the template must accept parameters for the guardrails resource group name, the budget name and amount, the action group email address, and the principal ID for the role assignment. Use defaults where sensible.
- **Idempotence:** redeploying the template must succeed without errors. Use `guid()` for the role assignment name so it generates the same GUID on every deploy.

## Verify

From the capstone exercise folder (`capstones/c1-landing-zone/e01-governance-baseline/`), run:

```powershell
pwsh -File ../../../scripts/check.ps1
```

The harness compiles the template, checks that it is lint- and PSRule-clean, and verifies the required resources and properties are present. It does not deploy to Azure unless you run `lab-up` separately.

## Hints

There is one hint: compose this from the patterns you have already written in A02 (budget and action group), A03 (resource groups, tags, locks), and A04 (Policy and role assignments). Do not start from scratch; copy and adapt the smaller pieces. The challenge is integration, not authoring each piece from memory.

## Related units

- **A02: Cost control and lab guardrails** — the budget and action group pattern, and the five course tags (modified here to use `lifecycle=persistent` instead of `expires`).
- **A03: Resource organization** — resource groups, tags, and locks at subscription scope.
- **A04: Policy and RBAC** — Policy and role assignments at subscription scope.
- **A05: Microsoft Entra users, groups, and directory access** (optional context) — where identity sits in a production landing zone. Identity is documentation only in this capstone; you do not deploy Entra users or groups.

## Exercise

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-governance-baseline | WRITE, LAB | L | Subscription-scoped governance baseline: guardrails RG, tags, lock, Policy, RBAC, and the A02 budget pattern |
