# a06-e06-object-replication `[WRITE] [LAB]` (M)

## Goal

Author two storage accounts and an object-replication policy that copies blobs from a source container to a destination container. Optionally deploy the template as a same-day lab.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

Object replication requires **blob versioning on both accounts** and **change feed on the source**. Create the policy on the **destination** first with policy id `default` (empty rule ids); Azure fills in the policy id and rule ids. Then create the **source** policy using that policy id and those rule ids. Source: <https://learn.microsoft.com/azure/storage/blobs/object-replication-overview> (prerequisites and **Specify the policy and rule IDs**).

## Constraints

- Two `Microsoft.Storage/storageAccounts` (`StorageV2`, `lagb` prefix with no hyphen in the account name, course tags from the `tags` parameter, HTTPS, TLS 1.2, `allowBlobPublicAccess` false, `allowSharedKeyAccess` false). Prefer `Standard_LRS`.
- `blobServices/default` on both with `isVersioningEnabled: true`. Source also has `changeFeed.enabled: true` (a retention in days is allowed).
- A container on each account, then `objectReplicationPolicies`: destination `name: 'default'` first. The source-side policy name is the destination policyId, and each source rule carries the destination `ruleId`. A runtime property cannot be a resource `name` in the same file (BCP120); put the source-side policy in a module that receives those ids as parameters.
- Full resource ids for `sourceAccount` / `destinationAccount` when cross-tenant replication is disallowed (Learn, same page).
- Do not add a PSRule suppression.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

## Lab

Optional. **Cost class:** empty accounts in East US are effectively **$0** for a 1–2 hour lab. Capacity is billed per GB-month; an unused StorageV2 Hot LRS account with no data stored has no capacity line.

Retail Prices API query, run **27 November 2026** (UTC):

```
https://prices.azure.com/api/retail/prices?$filter=productName eq 'Blob Storage' and meterName eq 'Hot LRS Data Stored' and armRegionName eq 'eastus'
```

Result used: **Blob Storage**, sku **Hot LRS**, meter **Hot LRS Data Stored**, **$0.0208 / GB / Month**, currency USD, `armRegionName` eastus, `type` Consumption, `tierMinimumUnits` 0 (the first paid GB at the 0-tier). Official page: <https://azure.microsoft.com/pricing/details/storage/blobs/>.

Learn also says there is no cost to **configure** object replication (enabling change feed, versioning, and the policies); you pay transactions and egress when data actually replicates. Source: <https://learn.microsoft.com/azure/storage/blobs/object-replication-overview> (section **Estimated costs** / billing notes on that page).

**Nothing in this lab is assigned at subscription scope.** While it is up, only the course-tagged resource group is affected. Creating resources in other groups or regions is not denied by this lab.

**Teardown:** `pwsh -File ../../../scripts/lab/lab-down.ps1 -Path .`. `down.ps1` deletes the lab resource group. Soft-deleted storage can linger; `lab-sweep` still lists leftovers.

Live deploy is `pwsh -File ../../../scripts/lab/lab-up.ps1 -Path .` after `.lab-env.json` exists and the A02 budget is in place. `up.ps1` follows the C1 contract: LabGuard already refused a Deloitte/work tenant; it never runs `az login` or `az account set`; it honours `-WhatIf`; it throws on failure. A02's budget must already be in place.

<details>
<summary>Hint</summary>

Two accounts. Child `blobServices` named `default` with `isVersioningEnabled: true`; source `changeFeed: { enabled: true, retentionInDays: 7 }`. Child containers. Destination `objectReplicationPolicies` named `default` with a rule (empty `ruleId`). Put the source-side policy in a module that receives the destination policyId and ruleId as parameters.

</details>
