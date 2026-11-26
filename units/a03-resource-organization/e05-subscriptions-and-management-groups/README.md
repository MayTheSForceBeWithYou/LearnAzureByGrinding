# a03-e05-subscriptions-and-management-groups `[EXPLAIN]` (S)

## Goal

Explain subscription scope versus management-group scope, and the move and billing boundaries between them. `main.bicep` is a neighbour (a tagged resource group), not a puzzle.

## Constraints

- `ANSWER.md` uses the required headings exactly.
- Under **Subscription scope**, say what you can place there (resource groups, subscription Policy, subscription RBAC, budgets) and that a personal lab subscription is the course's resource-lab boundary.
- Under **Management group scope**, say that management groups sit above subscriptions, that Policy and RBAC assigned there apply down the tree, and that a personal tenant often cannot create management groups (SPEC 13.3: this course has no MG `[LAB]`).
- Under **Move and billing**, cover: a resource move stays inside one subscription unless you use a subscription-to-subscription move; billing is a subscription (or billing-account) concern, not a management-group concern; moving a subscription between management groups does not by itself change the bill.

Required `ANSWER.md` headings (exact lines):

- `## Subscription scope`
- `## Management group scope`
- `## Move and billing`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
