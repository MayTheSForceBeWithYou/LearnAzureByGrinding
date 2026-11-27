# a06-e02-choose-redundancy

Assume no customer-initiated failover. Read and write below are against the account's **normal** endpoint unless a heading names the secondary. Source: <https://learn.microsoft.com/azure/storage/common/storage-redundancy>.

## LRS zone outage
read **no**, write **no**. LRS keeps three copies in a single physical datacenter. A zone (or that datacenter) outage takes the only copies offline.

## LRS region outage
read **no**, write **no**. LRS has no secondary region. A primary-region outage takes the account down.

## ZRS zone outage
read **yes**, write **yes**. Learn: "your data remains accessible for both read and write operations even if a zone becomes unavailable."

## ZRS region outage
read **no**, write **no**. ZRS is primary-region only. A region-wide outage has no geo copy to fail over to.

## GRS zone outage
read **no**, write **no**. GRS uses LRS in the primary region, so a zone/datacenter outage in primary takes the normal endpoint down. The geo copy is not readable or writable until a failover. Learn: "the data in the secondary region isn't available for read or write access unless there's a failover to the secondary region."

## GRS region outage
read **no**, write **no** on the normal endpoint. Secondary data is durable but not exposed until failover. No RA, so there is no secondary read endpoint.

## GZRS zone outage
read **yes**, write **yes**. GZRS uses ZRS in the primary region, so a zone outage leaves read and write on the normal endpoint.

## GZRS region outage
read **no**, write **no** on the normal endpoint. Secondary is not accessible until failover (same GRS/GZRS sentence as above). Write availability after a region outage needs account failover.

## RA-GZRS zone outage
read **yes**, write **yes** on the normal endpoint (ZRS in primary). The **secondary** read endpoint is also available (RA). Learn: RA-GZRS and RA-GRS "permit read access to the secondary region."

## RA-GZRS region outage
read **no**, write **no** on the normal endpoint (primary is down; no failover yet). The **secondary** read endpoint is **yes**. Write stays no until failover.

## Adding zone redundancy
LRS→ZRS is not a template `sku.name` edit you can count on for an **existing** account. Learn's redundancy-migration table: add or remove zone-redundancy by **performing a conversion** (portal, `Start-AzStorageAccountMigration`, or `az storage account migration start`). LRS→GRS/RA-GRS is a SKU update. Source: <https://learn.microsoft.com/azure/storage/common/redundancy-migration>.
