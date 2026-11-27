# A06: Storage accounts, redundancy, and encryption

## Advance organizer

You have organized Azure resources with groups, tags, locks, Policy, and RBAC, and you have managed Entra identities in a test tenant. This unit teaches Azure Storage accounts: creating an account with a chosen SKU and redundancy level, understanding LRS/ZRS/GRS/GZRS and their failover behavior, configuring customer-managed keys for encryption, enabling blob soft delete, and setting up object replication between accounts. After this unit you can author a storage account in Bicep with the correct SKU and redundancy for a scenario, explain when and how to change redundancy, and describe what customer-managed keys and infrastructure encryption protect.

You must already know: **A00** (Bicep language), **A01** (deployments and ARM), **A02** (cost control and tagging), **A03** (resource organization), and **A04** (Policy and RBAC).

After this unit you can:
- Declare a storage account with a chosen SKU (Standard_LRS, Standard_GRS, Standard_GZRS, etc.) and kind (StorageV2, BlockBlobStorage, FileStorage)
- Explain the difference between LRS, ZRS, GRS, RAGRS, GZRS, and RAGZRS redundancy
- Change redundancy: adding or removing geo-replication or read access is a SKU change; adding or removing zone redundancy requires a conversion
- Configure customer-managed keys for account encryption with a user-assigned managed identity and key vault key
- Enable blob soft delete and container soft delete via the `blobServices/default` child resource
- Configure object replication between two storage accounts (requires blob versioning)
- Describe what infrastructure encryption adds (double encryption with two separate keys)

## Foundations

### Storage accounts

A **storage account** is a container for Azure Storage data objects: blobs, files, queues, and tables. Every object you store in Azure Storage lives in a storage account. The storage account provides a unique namespace (for example, `mystorageaccount.blob.core.windows.net`) and sets the replication, encryption, and access control for all objects inside.

You declare a storage account in Bicep as `Microsoft.Storage/storageAccounts@2023-05-01`:

```bicep
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagbstpremium'
  location: location
  sku: {
    name: 'Premium_ZRS'
  }
  kind: 'BlockBlobStorage'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
  }
}
```

This example shows a premium block blob storage account optimized for low-latency workloads. For most workloads, use general-purpose v2 (`StorageV2`) with a Standard SKU.

**SKU** determines the redundancy and performance tier (Standard or Premium). **Kind** determines the service features the account supports. The most common kind is `StorageV2` (general-purpose v2), which supports all storage services (Blob, File, Queue, Table) and all blob access tiers. `BlockBlobStorage` is a premium kind for block blobs only (high throughput). `FileStorage` is a premium kind for Azure Files only.

General-purpose v2 accounts support a default **access tier** (hot or cool) set at the account level. Hot access tier has higher storage costs but lower data-access costs; cool access tier has lower storage costs but higher data-access costs. Individual blobs can override the account's default tier. The archive tier is blob-level only (not an account setting). Access tier is a billing optimization; it does not affect redundancy or encryption.

Storage account names must be globally unique, 3–24 lowercase letters and numbers, and DNS-compliant. The account is billed separately from the objects inside; you pay for the account's redundancy, outbound data transfer, and operations. The `allowSharedKeyAccess` property controls whether shared key (access key) authentication is allowed; setting it to `false` requires Microsoft Entra authorization; account and service SAS are denied, and only a user delegation SAS (Blob Storage, Entra-signed) still works. See <https://learn.microsoft.com/azure/storage/common/shared-key-authorization-prevent>.

### Storage account SKUs and redundancy

The **SKU** (`sku.name`) combines redundancy and performance tier:

- **Standard_LRS**: Locally redundant storage, standard performance. Three synchronous copies in one datacenter in the primary region. Lowest cost. No protection against datacenter failure.
- **Standard_ZRS**: Zone-redundant storage, standard performance. Three synchronous copies across three availability zones in the primary region. Protects against datacenter failure, but not against region failure.
- **Standard_GRS**: Geo-redundant storage, standard performance. LRS in the primary region, then asynchronously replicated to a secondary region (LRS in the secondary). Six total copies. Protects against region failure. The secondary region is not readable until you initiate failover; after failover, the secondary becomes the new primary (readable and writable).
- **Standard_RAGRS**: Read-access geo-redundant storage. Same as GRS, but the secondary endpoint is always readable (even before failover). Useful for read-heavy workloads that tolerate stale data.
- **Standard_GZRS**: Geo-zone-redundant storage, standard performance. ZRS in the primary region, then asynchronously replicated to a secondary region (LRS in the secondary). Highest durability. Protects against zone and region failure. The secondary region is not readable until you initiate failover.
- **Standard_RAGZRS**: Read-access geo-zone-redundant storage. Same as GZRS, but the secondary endpoint is always readable. The highest redundancy and read availability combination.
- **Premium_LRS**: LRS, premium performance (SSDs). Used for `BlockBlobStorage`, `FileStorage`, or `StorageV2` with premium requirements.
- **Premium_ZRS**: ZRS, premium performance. Available for `BlockBlobStorage` and `FileStorage`.

You choose the SKU at account creation. Some SKU changes are live updates; adding or removing zone redundancy requires a conversion (not a simple property change, and may take hours or days). The official support and limitations are documented at <https://learn.microsoft.com/azure/storage/common/redundancy-migration>.

The **secondary region** for GRS/RAGRS/GZRS/RAGZRS is determined by the primary region and is fixed by Azure (for example, East US pairs with West US, North Europe pairs with West Europe). You cannot choose the secondary region. The secondary endpoint for blobs is `<account-name>-secondary.blob.core.windows.net`. For RAGRS and RAGZRS, you can read from this endpoint at any time. For GRS and GZRS, after failover the primary endpoint's DNS moves to the new primary region.

### Changing redundancy

You can change a storage account's redundancy in the portal (Storage account → Data management → Redundancy dropdown, then save) or via CLI (`az storage account update --sku <new-sku>`). Some transitions are instant SKU changes; others require a **conversion** (a data migration that copies data to new infrastructure).

The [redundancy migration guide](https://learn.microsoft.com/azure/storage/common/redundancy-migration) states two rules:

> Add or remove geo-replication or read access to the secondary region.

> Add or remove zone-redundancy by performing a conversion.

**Adding or removing geo-replication or read access** is a SKU change (LRS↔GRS/RAGRS, ZRS↔GZRS/RAGZRS, GRS↔RAGRS). The account starts or stops replicating to the secondary region, or makes the secondary endpoint readable. No conversion needed.

**Adding or removing zone redundancy** (LRS↔ZRS, GRS↔GZRS, LRS→GZRS) needs a conversion. A conversion is a live migration: Azure copies data from one infrastructure configuration to another (for example, from one datacenter to three availability zones, or from three zones to one). The account remains online (no downtime), but the conversion can take hours or days depending on data size.

There are two ways to initiate a conversion:

- **Customer-initiated conversion**: You start the conversion in the portal, PowerShell, or Azure CLI. The conversion typically begins within 72 hours but can take longer due to resource availability and data volume. No support request needed. Available in most regions. See the [customer-initiated conversion section](https://learn.microsoft.com/azure/storage/common/redundancy-migration#customer-initiated-conversion).
- **Manual migration**: Create a new account with the target redundancy, copy data with AzCopy or another tool, then delete the old account. Manual migration gives you full control over timing. Use this when customer-initiated conversion is unavailable or when you need a specific completion window.

LRS → GZRS adds both geo-redundancy and zone redundancy. You can do this in two steps: first add geo-replication (LRS → GRS, a SKU change), then add zone redundancy (GRS → GZRS, a conversion). The 24-hour wait applies after a zone-redundancy conversion.

See <https://learn.microsoft.com/azure/storage/common/redundancy-migration> for the complete table of supported transitions.

### Customer-managed keys

Azure Storage encrypts all data at rest by default using **Microsoft-managed keys**. You can instead use **customer-managed keys** (CMK) stored in Azure Key Vault or Azure Key Vault Managed HSM. With CMK, you control the encryption key: you can rotate it, revoke access, and audit its use.

To configure CMK, you create an Azure Key Vault (with soft delete and purge protection enabled), create an RSA or RSA-HSM key in the key vault (2048, 3072, or 4096 bits), assign a **managed identity** to the storage account, and grant that identity permissions on the key (`wrapKey`, `unwrapKey`, `get`). CMK requires a managed identity (user-assigned when configured at account creation; system-assigned or user-assigned for an existing account). Azure Storage uses the key to wrap the account encryption key. The data remains encrypted at all times; switching from Microsoft-managed keys to customer-managed keys re-encrypts the account encryption key (the root key), not the data itself.

CMK applies to Blob Storage and Azure Files automatically. For Queue and Table storage, you must enable CMK support when you create the account (set `encryption.services.queue.keyType: 'Account'` and `encryption.services.table.keyType: 'Account'` in the template, or check the boxes in the portal at account creation). You cannot add CMK to Queue and Table on an existing account that was not created with this option. See <https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview>.

### Infrastructure encryption

**Infrastructure encryption** (also called double encryption) encrypts data twice: once at the service level (with the account encryption key), and once at the infrastructure level (with a separate Microsoft-managed key). The two keys are independent. Infrastructure encryption is recommended when compliance requires double encryption. It is a creation-time-only setting: you configure it when you create the storage account, and you cannot enable it on an existing account. See <https://learn.microsoft.com/en-us/azure/storage/common/infrastructure-encryption-enable>.

Infrastructure encryption does not affect performance noticeably, but it provides an additional layer of protection if one encryption algorithm or key is compromised.

### Blob soft delete and container soft delete

**Blob soft delete** protects individual blobs from accidental deletion or overwrite. When you delete a blob with soft delete enabled, it is marked as deleted but retained for a specified retention period (for example, 7 days). During the retention period, you can undelete the blob. After the retention period expires, Azure permanently deletes it.

**Container soft delete** protects blob containers from accidental deletion. When you delete a container with container soft delete enabled, it is retained for the retention period, and you can recover it (with all its blobs).

You enable soft delete settings in Bicep via the `blobServices/default` child resource under the storage account:

```bicep
param storageAccountName string

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
```

The same `blobServices/default` resource also supports blob versioning (`isVersioningEnabled`) and change feed. These are independent settings; object replication needs versioning on both accounts and change feed on the source. Blob soft delete and container soft delete are independent settings. You can enable one, both, or neither. Soft delete incurs storage costs for the retained data. See <https://learn.microsoft.com/azure/storage/blobs/soft-delete-blob-overview>.

### Object replication

**Object replication** asynchronously copies block blobs from a source storage account to a destination account. You configure replication policies that specify source and destination containers and optional filters (for example, replicate only blobs with a specific prefix). Object replication requires **blob versioning** enabled on both source and destination accounts. See <https://learn.microsoft.com/en-us/azure/storage/blobs/object-replication-overview>.

Object replication is useful for:
- Minimizing latency by serving blobs from a region closer to users
- Disaster recovery (a second copy of data in another region)
- Isolating production and test data

Object replication policies are created in the portal (Storage account → Object replication) or via ARM/Bicep as `Microsoft.Storage/storageAccounts/objectReplicationPolicies`. The destination account must exist and must have versioning enabled before you create the policy on the source account. The lesson teaches object replication at the concept level; the hands-on exercise is optional or a lab.

## Worked example: Failover consequences and Last Sync Time

You have a storage account with SKU `Standard_GRS` in East US (primary), which Azure pairs with West US (secondary). The account has geo-redundant replication: data written to the primary is asynchronously replicated to the secondary. Azure exposes a **Last Sync Time** property (readable via the portal, CLI, or REST API) that shows when the secondary was last synchronized with the primary. Last Sync Time can lag behind the current time by seconds, minutes, or longer if the primary region is under heavy load or experiencing connectivity issues.

You write blobs at 10:00 AM. Last Sync Time shows 9:58 AM. The primary region becomes unavailable at 10:05 AM. You initiate a **customer-managed unplanned failover** (a manual operation). Azure makes the secondary region (West US) the new primary. After failover completes:

- The account is now writable in West US. The blob endpoint `https://mystorageaccount.blob.core.windows.net` points to West US.
- **Data written between Last Sync Time (9:58 AM) and the outage (10:05 AM) is lost.** Any blobs written or updated after 9:58 AM are not in the secondary and cannot be recovered.
- The account's redundancy changes. According to the [disaster recovery guidance](https://learn.microsoft.com/azure/storage/common/storage-disaster-recovery-guidance): "The new primary region is configured to be locally redundant (LRS) after the failover." You must manually change the SKU back to GRS (or another geo-redundant SKU) if you want geo-redundancy again.

After a planned failover the regions swap and geo-redundancy continues. After an unplanned failover the account is LRS in the new primary, and you must reconfigure geo-redundancy to get a secondary back. See <https://learn.microsoft.com/azure/storage/common/storage-disaster-recovery-guidance>. **Microsoft-managed failover** (initiated by Microsoft during a large-scale disaster) follows the same Last Sync Time rules as unplanned failover.

**The plausible wrong reading.** You might expect that all data written to the primary before the outage is replicated to the secondary. That is not true. Only data written before Last Sync Time is guaranteed to be in the secondary. The replication lag determines how much data is at risk. You might also expect the account to remain GRS after an unplanned failover. That is not true: an unplanned failover converts the account to LRS, and you must manually restore geo-redundancy.

## Worked example: Soft delete protects against accidental deletion, not malicious deletion

You enable blob soft delete with a 7-day retention period on a storage account. A user (or an automated script) with the Storage Blob Data Contributor role deletes a blob `report.pdf`. Azure marks the blob as deleted but retains it for 7 days. During those 7 days, an administrator can undelete `report.pdf` in the portal (Blob containers → <container> → Show deleted blobs → Undelete) or via the CLI with `az storage blob undelete`.

If the blob is not undeleted within 7 days, Azure permanently deletes it. Soft delete does not protect against malicious deletion: an attacker with Storage Blob Data Contributor or higher access can delete blobs. If the **Permanent Delete feature** is enabled on the account, a caller with appropriate permissions can permanently remove soft-deleted snapshots and versions before the retention period expires (see [soft delete overview](https://learn.microsoft.com/azure/storage/blobs/soft-delete-blob-overview)). To protect against malicious or accidental administrative actions, use **immutable storage** (time-based retention policies or legal holds, taught in A08) or **RBAC least privilege** (grant only the minimum necessary roles).

**The plausible wrong reading.** You might expect soft delete to prevent all deletions, or that shortening the retention period purges existing soft-deleted blobs. Neither is true. Soft delete retains deleted blobs for the retention period, but it does not prevent deletion. The soft delete overview states: "In order to permanently delete blobs that have already been soft deleted, undelete the soft deleted blobs, turn off the blob soft delete feature, and redelete the blobs." Shortening the retention period does not purge blobs that are already soft-deleted, because their expiry was set when they were deleted. The Permanent Delete feature exists for removing soft-deleted snapshots and versions early. See <https://learn.microsoft.com/azure/storage/blobs/soft-delete-blob-overview>. To block deletion permanently for a specified period, use immutable storage with a time-based retention policy.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| LRS vs ZRS | LRS: three synchronous copies in one datacenter. No protection against datacenter failure. ZRS: three synchronous copies across three availability zones in one region. Protects against datacenter failure, but not region failure. |
| GRS vs RAGRS | Both replicate to a secondary region (six total copies). GRS: after failover the primary endpoint's DNS moves. RAGRS: the secondary endpoint is always readable (even before failover). RAGRS is useful for read-heavy workloads that tolerate stale data. |
| GZRS vs RAGZRS | Both are ZRS in the primary region plus LRS in the secondary. GZRS: after failover the primary endpoint's DNS moves. RAGZRS: the secondary endpoint is always readable. The highest redundancy and read availability. |
| Adding zone redundancy vs adding geo-replication | Adding or removing zone redundancy (LRS→ZRS, ZRS→LRS, GRS→GZRS, GZRS→GRS) requires a **conversion** (data is copied to new infrastructure; can take hours or days; no downtime). Adding or removing geo-replication or read access (LRS→GRS, GRS→RA-GRS, RA-GRS→GRS, GRS→LRS) is a live SKU change (instant). |
| Customer-managed keys vs Microsoft-managed keys | Microsoft-managed keys: Azure controls the encryption key. No action required. Customer-managed keys: you store the key in Azure Key Vault, control rotation and revocation, and assign a managed identity to access it. CMK requires a key vault with soft delete and purge protection enabled. |
| Infrastructure encryption vs service-level encryption | Service-level encryption: all data is encrypted once at the service level using 256-bit AES (always enabled). Infrastructure encryption: data is encrypted twice (once at the service level, once at the infrastructure level) with two separate keys. Infrastructure encryption is a creation-time-only setting and is recommended only when compliance requires double encryption. |
| Blob soft delete vs container soft delete | Blob soft delete: individual blobs are retained after deletion for a retention period. Container soft delete: entire containers (and all their blobs) are retained after deletion. Both are configured via the `blobServices/default` child resource. Both incur storage costs for retained data. |
| Object replication vs geo-redundant storage | Object replication: you explicitly configure policies to copy specific containers or blobs from a source account to a destination account. Requires blob versioning. GRS/GZRS: Azure automatically replicates the entire account to a secondary region. No explicit policy needed. Object replication is for selective cross-region copies; GRS/GZRS is for full-account redundancy. |
| SKU name vs kind | SKU (`sku.name`) determines redundancy and performance (Standard_LRS, Standard_GRS, Premium_LRS, etc.). Kind (`kind`) determines the account's supported services and features (StorageV2 is general-purpose v2, BlockBlobStorage is premium block blobs only, FileStorage is premium files only). Not every kind supports every SKU. |
| Soft delete retention period | Measured in days (1–365). After the retention period expires, Azure permanently deletes the soft-deleted blob or container. Setting a longer retention period increases storage costs (you pay for the retained data). Setting it to 1 day provides minimal protection; 7 days is a common choice. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Storage account overview](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Azure Storage redundancy](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy)
- [Change the redundancy option](https://learn.microsoft.com/en-us/azure/storage/common/redundancy-migration)
- [Customer-managed keys for Azure Storage encryption](https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview)
- [Enable infrastructure encryption for double encryption](https://learn.microsoft.com/en-us/azure/storage/common/infrastructure-encryption-enable)
- [Soft delete for blobs](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview)
- [Soft delete for containers](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-container-overview)
- [Object replication for block blobs](https://learn.microsoft.com/en-us/azure/storage/blobs/object-replication-overview)
- [Microsoft.Storage/storageAccounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts)
- [az storage account](https://learn.microsoft.com/en-us/cli/azure/storage/account)

## Check yourself

1. **A storage account has GRS redundancy. The Last Sync Time property shows 2:45 PM. The primary region fails at 2:50 PM. You initiate a customer-managed unplanned failover. What happens to blobs written between 2:45 PM and 2:50 PM?**
2. **After a customer-managed unplanned failover completes, what is the storage account's redundancy configuration?**
3. **You enable blob soft delete with a 7-day retention period. You delete a blob on Monday. On Friday (5 days later), can you undelete it?**
4. **You want to change a storage account's redundancy from LRS to ZRS. What operation does Azure perform?**
5. **The storage account's managed identity loses its Key Vault Crypto Service Encryption User role (or the key is disabled). What happens to blob reads and writes?**

<details>
<summary>Answers</summary>

1. Those blobs are lost when you fail over. Last Sync Time indicates the most recent time data from the primary was written to the secondary. Data written after Last Sync Time has not yet been copied to the secondary. When you initiate an unplanned failover, the secondary becomes the new primary, and any data not yet replicated is permanently lost. If the primary region recovers before failover, no data is lost. The replication lag (5 minutes in this case) determines potential data loss on failover.
2. LRS (locally redundant storage) in the new primary region. The disaster recovery guidance states: "The new primary region is configured to be locally redundant (LRS) after the failover." Geo-redundancy is lost. You must manually change the SKU back to GRS (or another geo-redundant SKU) if you want geo-redundancy again.
3. Yes. Soft delete retains the blob for 7 days. On Friday, the blob is still within the retention period, so you can undelete it. If you wait until the following Tuesday (8 days later), the blob is permanently deleted.
4. A **conversion** (also called a live migration). Azure copies the data from one datacenter to three availability zones. The account remains online (no downtime), but the conversion can take hours or days. The alternative is a manual migration (create a new ZRS account, copy data with AzCopy, delete the old account). An LRS→ZRS conversion is not a simple SKU property change; it is a data migration.
5. They fail until access is restored. Azure Storage cannot decrypt the data without the customer-managed key. Read and write operations fail with error code 403 (Forbidden). To restore access, reassign the role or re-enable the key. See <https://learn.microsoft.com/azure/storage/common/customer-managed-keys-overview>.

</details>

## Takeaways

- Storage account SKU determines redundancy and performance. LRS (three copies in one datacenter) makes the account unavailable if the datacenter fails. ZRS (three copies across three zones) protects against datacenter failure. GRS/GZRS replicate to a secondary region (six copies total). RAGRS and RAGZRS make the secondary endpoint readable before failover.
- Adding or removing **geo-replication or read access** to the secondary region is a live SKU change (instant). Adding or removing **zone redundancy** requires a conversion (data is copied to new infrastructure; takes hours or days; no downtime). Customer-managed unplanned failover converts the account to LRS in the new primary region.
- Customer-managed keys (CMK) store the encryption key in Azure Key Vault. You control rotation and revocation. CMK requires a managed identity (system-assigned or user-assigned), a key vault with soft delete and purge protection, and an RSA key (2048, 3072, or 4096 bits). Infrastructure encryption (double encryption) is a creation-time-only setting.
- Blob soft delete and container soft delete retain deleted objects for a retention period (1–365 days). You can undelete them during that period. Soft delete does not prevent deletion or purge; it only delays permanent deletion.
- Object replication asynchronously copies block blobs from a source account to a destination account. It requires blob versioning enabled on both accounts. Use it for latency minimization, disaster recovery, or prod/test isolation.
- The secondary region for GRS/RAGRS/GZRS/RAGZRS is determined by Azure and cannot be changed. The secondary endpoint for blobs is `<account>-secondary.blob.core.windows.net`. Without `RA` in the SKU, after failover the primary endpoint's DNS moves to the new primary region.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-storage-account-baseline | WRITE | S | A secure storage account |
| 2 | e02-choose-redundancy | PREDICT | S | What survives the outage? |
| 3 | e03-upgrade-redundancy | MODIFY | S | Add geo-redundancy (LRS → GRS) |
| 4 | e04-customer-managed-key | WRITE | M | Encrypt with your own key |
| 5 | e05-insecure-storage-settings | BUG | S | Find the insecure settings |
| 6 | e06-object-replication | WRITE, LAB | M | Replicate blobs between accounts |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-storage-sku-and-kind | Declare a storage account with a specified SKU and kind |
| 2 | r02-enable-blob-versioning | Enable blob versioning via the `blobServices/default` child resource |
