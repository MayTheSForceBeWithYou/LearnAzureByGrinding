# a03-e05-subscriptions-and-management-groups

## Subscription scope
A subscription is the billing and quota boundary, and the course's resource-lab boundary (the personal MSA subscription in `.lab-env.json`). At this scope you place resource groups, subscription Policy assignments, subscription role assignments, and Consumption budgets. Most resources still live *in* a resource group; the subscription is the parent of those groups. `targetScope = 'subscription'` in Bicep matches `az deployment sub create`.

## Management group scope
Management groups sit **above** subscriptions in the control plane. Policy and RBAC assigned on a management group apply down the tree to child management groups and subscriptions (unless excluded). They do not create resources and they do not change the bill. A personal tenant often cannot create management groups — that right is commonly reserved for Enterprise Agreement / Microsoft Customer Agreement admins. This course has no management-group `[LAB]` (SPEC 13.3): A03 covers them as `[EXPLAIN]` plus a read-only `[CLI]`.

## Move and billing
A resource move (`az resource move`) stays inside **one** subscription unless you use a subscription-to-subscription move, which still requires the resource type to support moving and both subscriptions to be in the same tenant. Billing is a subscription (or billing-account) concern, not a management-group concern. Moving a subscription from one management group to another changes which Policy/RBAC the subscription inherits; it does not by itself change the bill, the invoice, or Cost Management meters.
