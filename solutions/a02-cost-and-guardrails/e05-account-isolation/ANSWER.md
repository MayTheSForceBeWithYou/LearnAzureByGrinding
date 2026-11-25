# a02-e05-account-isolation

## Match
The fixture matches. `account-show.json` `tenantId` equals `expectedTenantId`, and `id` equals `expectedSubscriptionId`. `expectedEntraTenantId` is a different GUID (the A05 test tenant) and is not compared for a resource lab.

## Mismatch
If `tenantId` differed, run `az login --tenant <expectedTenantId>` then `az account set --subscription <expectedSubscriptionId>`. `lab-up` prints that fix and exits 3 until they match.

## Corporate refuse
`lab-up` refuses (exit 3) when the tenant display name, domain, or signed-in user contains `deloitte` (or another configured corporate pattern), or when a verified custom domain is not explicitly allowed. A missed `az login --tenant` must not land a lab in a work directory.
