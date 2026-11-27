# a06-e02-choose-redundancy `[PREDICT]` (S)

## Goal

Predict **read** and **write** availability for LRS, ZRS, GRS, GZRS, and RA-GZRS under a **zone outage** in the primary region and under a **region outage** of the primary region. Write `ANSWER.md`. Do not change `main.bicep`.

Assume **no customer-initiated failover** has run yet. Use the official redundancy page, not memory:

<https://learn.microsoft.com/azure/storage/common/storage-redundancy>

That page states:

- LRS keeps copies in a **single physical datacenter** in the primary region.
- ZRS: "your data remains accessible for both read and write operations even if a zone becomes unavailable."
- GRS uses LRS in the primary region, then asynchronous geo-replication. GZRS uses ZRS in the primary region, then geo-replication.
- With GRS or GZRS, "the data in the secondary region isn't available for read or write access unless there's a failover to the secondary region."
- RA-GZRS (and RA-GRS) "permit read access to the secondary region."

## Adding zone redundancy (why e03 is a geo change)

Moving **LRS → ZRS / GZRS** is not a `sku.name` edit you can count on in a template for an **existing** account. Learn's redundancy-migration page says you **add or remove zone-redundancy by performing a conversion**, and the LRS→ZRS cell is **Perform a conversion** (portal, `Start-AzStorageAccountMigration`, or `az storage account migration start`). LRS→GRS/RA-GRS is **Use Azure portal, PowerShell, or CLI** (a SKU change). Source: <https://learn.microsoft.com/azure/storage/common/redundancy-migration>.

e03 therefore adds **geo-redundancy** (`Standard_GRS`). Zone conversion stays here as prose.

## Constraints

- `ANSWER.md` uses the required headings exactly, with text under each.
- Under each outage heading, say whether **read** and **write** against the account's normal endpoint are available (`yes` / `no`), and one sentence why. For RA-GZRS, say whether the **secondary** read endpoint is available.
- Under **Adding zone redundancy**, quote that LRS→ZRS needs a conversion, not only a template `sku.name` edit.
- Do not invent portal or CLI output. Do not change `main.bicep`.

Required `ANSWER.md` headings (exact lines):

- `## LRS zone outage`
- `## LRS region outage`
- `## ZRS zone outage`
- `## ZRS region outage`
- `## GRS zone outage`
- `## GRS region outage`
- `## GZRS zone outage`
- `## GZRS region outage`
- `## RA-GZRS zone outage`
- `## RA-GZRS region outage`
- `## Adding zone redundancy`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
