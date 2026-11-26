# C1: Landing zone — Governance baseline

## Overview

You have learned resource groups, tags, locks, Policy, and RBAC through units A02–A04. This capstone integrates those skills into a testable subscription-scoped governance baseline: a small landing zone that enforces organizational standards without the full complexity of a production Cloud Adoption Framework (CAF) or Azure Landing Zone (ALZ) deployment.

Attempt this capstone after completing **A04**. You will write a subscription-scoped Bicep deployment that creates a resource group for this exercise, applies course tags, sets a CanNotDelete lock on that group, assigns a built-in Policy to restrict allowed locations at subscription scope, assigns a role for a given principal, and deploys a budget (separate from the A02 gate budget). The capstone is offline-testable and optionally deployable as a free `[LAB]` (Policy and RBAC are free; tags and locks are free; the budget is a monitoring resource with no direct cost).

After this capstone you can:
- Compose a subscription-scoped governance baseline from smaller governance pieces
- Deploy resource groups, Policy assignments, role assignments, locks, and a budget in one template
- Verify the baseline offline and optionally deploy it to a lab subscription
- Explain how tags, locks, Policy, and RBAC interact at subscription scope

## What you will build

A subscription-scoped Bicep deployment (`main.bicep` at subscription scope) that declares:

1. **A resource group** named `lagb-c1-e01-governance-baseline` (from `rgName` parameter), with the five course tags (`course`, `unit`, `exercise`, `expires`, `owner`). `lab-up` overwrites `tags` with fresh values including a new `expires`.
2. **A CanNotDelete lock** named `lagb-cannotdelete` on the resource group (not the subscription), scoped with `scope: rg` or via a module.
3. **A Policy assignment** at subscription scope: the built-in "Allowed locations" Policy (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) restricting deployments to allowed locations. Use `subscriptionResourceId` or `tenantResourceId` to reference the built-in definition; do not copy the definition. Deny or audit only.
4. **A role assignment** at resource-group scope: assign the built-in Reader role (`acdd72a7-3385-48ef-bd42-f606fba81ae7`) to a principal ID passed as a parameter, `name = guid(<rg scope>, principalId, roleDefinitionId)`. Pass `principalId` and `principalType` as parameters. Do not hard-code a GUID; do not use `newGuid()`.
5. **A budget** named `lagb-c1-baseline` (from `budgetName` parameter; **not** the A02 gate budget `lagb-monthly`): `Microsoft.Consumption/budgets@2024-08-01` at subscription scope with Actual 50/80/100% and Forecasted 80/100% alerts (five notifications, the per-budget maximum).

Management groups and Microsoft Entra identities are **documentation only** in this capstone: they are explained below but not deployed. The capstone tests subscription-scoped governance, not tenant-scoped identity or multi-subscription hierarchies.

## Constraints

- **Scope:** subscription. The main template is `targetScope = 'subscription'`.
- **Offline-testable:** the template must compile, lint clean, pass PSRule, and satisfy structural tests (ExpectResources, ExpectProperties) without deploying to Azure. The harness grades the compiled JSON.
- **Optional free `[LAB]`:** you may deploy this to your lab subscription with `lab-up` to verify the Policy and role assignment work. Policy, tags, locks, and RBAC assignments are free. The budget is a monitoring resource and does not bill. **Teardown:** `lab-down` calls `down.ps1`, which removes the lock **before** deleting the group, then removes the Policy assignment, role assignments, budget, and resource group.
- **Parameterization:** the template must accept parameters for the resource group name, budget name and amount, and the principal ID and type for the role assignment. Use defaults where sensible.
- **Idempotence:** redeploying the template must succeed without errors. Use `guid()` for the role assignment name so it generates the same GUID on every deploy.

## Verify

From the capstone exercise folder (`capstones/c1-landing-zone/e01-governance-baseline/`), run:

```powershell
pwsh -File ../../../scripts/check.ps1
```

The harness compiles the template, checks that it is lint- and PSRule-clean, and verifies the required resources and properties are present. It does not deploy to Azure unless you run `lab-up` separately.

## Hints

There is one hint: compose this from the patterns you have already written in A02 (budget and action group), A03 (resource groups, tags, locks), and A04 (Policy and role assignments). Do not start from scratch; copy and adapt the smaller pieces. The challenge is integration, not authoring each piece from memory. For the lock, use a module deployed with `scope: rg`, or deploy it in a resource-group-scoped file called as a module.

## Documentation-only (not in the template)

- **Management groups:** A03 teaches management groups as `[EXPLAIN]` and read-only `[CLI]` when creation is not available. A personal tenant often requires rights at `/` (tenant root) to deploy `targetScope='tenant'` templates. No MG `[LAB]` (SPEC 13.3). In a production landing zone, management groups organize subscriptions into a hierarchy, and you assign Policy and RBAC at management-group scope to inherit downward to all subscriptions in that group.
- **Identity:** Entra users, groups, and directory roles wait for A05 in the disposable test tenant. This capstone only assigns Azure RBAC to a `principalId` you pass in. In a production landing zone, Entra users and groups are assigned Azure RBAC roles, and Conditional Access policies and directory roles govern identity and access.

## Related units

- **A02: Cost control and lab guardrails** — the budget and action group pattern, and the five course tags.
- **A03: Resource organization** — resource groups, tags, and locks at subscription scope.
- **A04: Policy and RBAC** — Policy and role assignments at subscription scope.
- **A05: Microsoft Entra users, groups, and directory access** (optional context) — where identity sits in a production landing zone.

## Exercise

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-governance-baseline | WRITE, LAB | L | Subscription-scoped governance baseline: RG, tags, lock, Policy, RBAC, and budget |
