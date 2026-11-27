# A06: Storage accounts, redundancy, and encryption

## Advance organizer

You have organized Azure resources with groups, tags, locks, Policy, and RBAC, and you have managed Entra identities in a test tenant. This unit teaches Azure Storage accounts: creating an account with a chosen SKU and redundancy level, understanding LRS/ZRS/GRS/GZRS and their failover behavior, configuring customer-managed keys for encryption, enabling blob soft delete, and setting up object replication between accounts. After this unit you can author a storage account in Bicep with the correct SKU and redundancy for a scenario, explain when and how to change redundancy, and describe what customer-managed keys and infrastructure encryption protect.

You must already know: **A00** (Bicep language), **A01** (deployments and ARM), **A02** (cost control and tagging), **A03** (resource organization), and **A04** (Policy and RBAC).

After this unit you can:
- Declare a storage account with a chosen SKU (Standard_LRS, Standard_GRS, Standard_GZRS, etc.) and kind (StorageV2, BlockBlobStorage, FileStorage)
- Explain the difference between LRS, ZRS, GRS, RA-GRS, GZRS, and RA-GZRS redundancy
- Change redundancy from LRS to ZRS (via conversion) or from LRS/ZRS to GRS/RA-GRS/GZRS/RA-GZRS (via SKU change)
- Configure customer-managed keys for account encryption with a user-assigned managed identity and key vault key
- Enable blob soft delete and container soft delete via the `blobServices/default` child resource
- Configure object replication between two storage accounts (requires blob versioning)
- Describe what infrastructure encryption adds (double encryption with two separate keys)

## Foundations

### Storage accounts

A **storage account** is a container for Azure Storage data objects: blobs, files, queues, and tables. Every object you store in Azure Storage lives in a storage account. The storage account provides a unique namespace (for example, `mystorageaccount.blob.core.windows.net`) and sets the replication, encryption, and access control for all objects inside.

You declare a storage account in Bicep as `Microsoft.Storage/storageAccounts@2023-05-01`:

```bicep
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'mystorageaccount'
  location: 'eastus'
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
  }
}
```

**SKU** determines the redundancy and performance tier (Standard or Premium). **Kind** determines the service features the account supports. The most common kind is `StorageV2` (general-purpose v2), which supports all storage services (Blob, File, Queue, Table) and all blob access tiers (hot, cool, cold, archive). `BlockBlobStorage` is a premium kind for block blobs only (high throughput). `FileStorage` is a premium kind for Azure Files only.

Storage account names must be globally unique, 3–24 lowercase letters and numbers, and DNS-compliant. The account is billed separately from the objects inside; you pay for the account's redundancy, outbound data transfer, and operations. The `allowSharedKeyAccess` property controls whether shared key (access key) authentication is allowed; setting it to `false` requires Microsoft Entra authentication or SAS tokens (shared key authentication is covered in A07).

### Storage account SKUs and redundancy

The **SKU** (`sku.name`) combines redundancy and performance tier:

- **Standard_LRS**: Locally redundant storage, standard performance. Three synchronous copies in one datacenter in the primary region. Lowest cost. No protection against datacenter failure.
- **Standard_ZRS**: Zone-redundant storage, standard performance. Three synchronous copies across three availability zones in the primary region. Protects against datacenter failure, but not against region failure.
- **Standard_GRS**: Geo-redundant storage, standard performance. LRS in the primary region, then asynchronously replicated to a secondary region (LRS in the secondary). Six total copies. Protects against region failure. The secondary endpoint is read-only after failover (you must initiate failover to make it writable).
- **Standard_RA-GRS**: Read-access geo-redundant storage. Same as GRS, but the secondary endpoint is always readable (even before failover). Useful for read-heavy workloads that tolerate stale data.
- **Standard_GZRS**: Geo-zone-redundant storage, standard performance. ZRS in the primary region, then asynchronously replicated to a secondary region (LRS in the secondary). Highest durability. Protects against zone and region failure.
- **Standard_RA-GZRS**: Read-access geo-zone-redundant storage. Same as GZRS, but the secondary endpoint is always readable. The highest redundancy and read availability combination.
- **Premium_LRS**: LRS, premium performance (SSDs). Used for `BlockBlobStorage`, `FileStorage`, or `StorageV2` with premium requirements.
- **Premium_ZRS**: ZRS, premium performance. Available for `BlockBlobStorage` and `FileStorage`.

You choose the SKU at account creation. Some SKU changes are live updates (LRS to ZRS is a **conversion**, not a simple property change, and may take hours or days; changing from LRS or ZRS to GRS/RA-GRS/GZRS/RA-GZRS is a live SKU change). Downgrading redundancy (for example, GRS to LRS) is a live SKU change. The official support and limitations are documented at <https://learn.microsoft.com/en-us/azure/storage/common/redundancy-migration>.

The **secondary region** for GRS/RA-GRS/GZRS/RA-GZRS is determined by the primary region and is fixed by Azure (for example, East US pairs with West US, North Europe pairs with West Europe). You cannot choose the secondary region. The secondary endpoint for blobs is `<account-name>-secondary.blob.core.windows.net`. For RA-GRS and RA-GZRS, you can read from this endpoint at any time. For GRS and GZRS, the secondary endpoint becomes readable only after you initiate a failover.

### Changing redundancy

You can change a storage account's redundancy in the portal (Storage account → Configuration → Redundancy dropdown, then save) or via CLI (`az storage account update --sku <new-sku>`). Some transitions are instant SKU changes; others are **migrations** or **conversions** that copy data to new infrastructure.

**LRS → ZRS** is a **conversion** (also called a live migration). Azure copies the data from one datacenter to three availability zones. The account remains online (no downtime), but the conversion can take hours or days depending on the data size. Initiating a conversion is a support request or a CLI operation with `az storage account migration start`. The alternative is to perform a **manual migration**: create a new ZRS account, copy the data with AzCopy or another tool, then delete the old account. Manual migration has downtime but completes faster.

**LRS → GRS/RA-GRS** is a live SKU change (instant). The account starts replicating to the secondary region. The secondary endpoint becomes available once the initial replication completes (this can take hours for large accounts, but the account is online).

**LRS → GZRS/RA-GZRS** requires TWO steps: first use the portal/PowerShell/CLI to switch the SKU from LRS to GRS/RA-GRS (a live SKU change), then perform a conversion to GZRS/RA-GZRS (a ZRS conversion in the primary region). The two steps can be performed in any order, but both are required.

**ZRS → GZRS/RA-GZRS** is a live SKU change.

**GRS/RA-GRS → GZRS/RA-GZRS** is a conversion (the primary region must convert from LRS to ZRS).

See <https://learn.microsoft.com/en-us/azure/storage/common/redundancy-migration> for the complete table of supported transitions.

Downgrading (for example, GZRS → LRS) is a live SKU change, but you lose the redundancy immediately. Azure does not keep copies in multiple zones or regions after the downgrade.

### Customer-managed keys

Azure Storage encrypts all data at rest by default using **Microsoft-managed keys**. You can instead use **customer-managed keys** (CMK) stored in Azure Key Vault or Azure Key Vault Managed HSM. With CMK, you control the encryption key: you can rotate it, revoke access, and audit its use.

To configure CMK, you create an Azure Key Vault (with soft delete and purge protection enabled), create an RSA or RSA-HSM key in the key vault (2048, 3072, or 4096 bits), assign a **managed identity** to the storage account (a system-assigned identity created by Azure on the account, or a user-assigned identity you provision separately), and grant that identity permissions on the key (`wrapKey`, `unwrapKey`, `get`). Azure Storage uses the key to wrap the account encryption key. The data remains encrypted at all times; switching from Microsoft-managed keys to customer-managed keys re-encrypts the account encryption key (the root key), not the data itself.

CMK applies to Blob Storage and Azure Files automatically. For Queue and Table storage, you must enable CMK support when you create the account (set `encryption.services.queue.keyType: 'Account'` and `encryption.services.table.keyType: 'Account'` in the template, or check the boxes in the portal at account creation). You cannot add CMK to Queue and Table on an existing account that was not created with this option. See <https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview>.

### Infrastructure encryption

**Infrastructure encryption** (also called double encryption) encrypts data twice: once at the service level (with the account encryption key), and once at the infrastructure level (with a separate Microsoft-managed key). The two keys are independent. Infrastructure encryption is recommended when compliance requires double encryption. It is set at account creation by passing `requireInfrastructureEncryption: true` in the `encryption` property. You cannot enable it on an existing account. See <https://learn.microsoft.com/en-us/azure/storage/common/infrastructure-encryption-enable>.

Infrastructure encryption is a creation-time-only setting. It does not affect performance noticeably, but it provides an additional layer of protection if one encryption algorithm or key is compromised.

### Blob soft delete and container soft delete

**Blob soft delete** protects individual blobs from accidental deletion or overwrite. When you delete a soft-deleted blob, it is marked as deleted but retained for a specified retention period (for example, 7 days). During the retention period, you can undelete the blob. After the retention period expires, Azure permanently deletes it.

**Container soft delete** protects blob containers from accidental deletion. When you delete a soft-deleted container, it is retained for the retention period, and you can recover it (with all its blobs).

You enable soft delete settings in Bicep via the `blobServices/default` child resource under the storage account. Here is container soft delete:

```bicep
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
```

The same `blobServices/default` resource also supports blob soft delete (`deleteRetentionPolicy`), blob versioning (`isVersioningEnabled`), and change feed (`isVersioningEnabled` must be true for change feed). Blob soft delete and container soft delete are independent settings. You can enable one, both, or neither. Soft delete incurs storage costs for the retained data. See <https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview>.

### Object replication

**Object replication** asynchronously copies block blobs from a source storage account to a destination account. You configure replication policies that specify source and destination containers and optional filters (for example, replicate only blobs with a specific prefix). Object replication requires **blob versioning** enabled on both source and destination accounts. See <https://learn.microsoft.com/en-us/azure/storage/blobs/object-replication-overview>.

Object replication is useful for:
- Minimizing latency by serving blobs from a region closer to users
- Disaster recovery (a second copy of data in another region)
- Isolating production and test data

Object replication policies are created in the portal (Storage account → Object replication) or via ARM/Bicep as `Microsoft.Storage/storageAccounts/objectReplicationPolicies`. The destination account must exist and must have versioning enabled before you create the policy on the source account. The lesson teaches object replication at the concept level; the hands-on exercise is optional or a lab.

## Worked example: Failover consequences and Last Sync Time

You have a storage account with SKU `Standard_GRS` in East US (primary), which Azure pairs with West US (secondary). The account has geo-redundant replication: data written to the primary is asynchronously replicated to the secondary. Azure exposes a **Last Sync Time** property (readable via the portal, CLI, or REST API) that shows when the secondary was last synchronized with the primary. Last Sync Time can lag behind the current time by seconds, minutes, or longer if the primary region is under heavy load or experiencing connectivity issues.

You write blobs at 10:00 AM. Last Sync Time shows 9:58 AM. The primary region becomes unavailable at 10:05 AM. You initiate a **customer-managed failover** (a manual operation). Azure makes the secondary region (West US) the new primary. After failover completes:

- The account is now writable in West US. The blob endpoint `https://mystorageaccount.blob.core.windows.net` points to West US.
- **Data written between Last Sync Time (9:58 AM) and the outage (10:05 AM) is lost.** Any blobs written or updated after 9:58 AM are not in the secondary and cannot be recovered.
- The account's redundancy changes: a GRS account becomes LRS in the new primary region (West US). You must manually change the SKU back to GRS (or another geo-redundant SKU) if you want geo-redundancy again. See <https://learn.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance>.

**Microsoft-managed failover** (initiated by Microsoft during a large-scale disaster) follows the same Last Sync Time rules. After either failover type completes, the old primary (East US) eventually becomes the new secondary when connectivity is restored, but this can take hours or days.

**The plausible wrong reading.** You might expect that all data written to the primary before the outage is replicated to the secondary. That is not true. Only data written before Last Sync Time is guaranteed to be in the secondary. The replication lag (the time between Last Sync Time and the current time) determines how much data is at risk. You might also expect the account to remain GRS after failover. That is not true: a customer-managed failover converts the account to LRS, and you must manually restore geo-redundancy.

## Worked example: Soft delete protects against accidental deletion, not malicious deletion

You enable blob soft delete with a 7-day retention period on a storage account. A user (or an automated script) with the Storage Blob Data Contributor role deletes a blob `report.pdf`. Azure marks the blob as deleted but retains it for 7 days. During those 7 days, an administrator can undelete `report.pdf` in the portal (Blob containers → <container> → Show deleted blobs → Undelete) or via the CLI with `az storage blob undelete`.

If the blob is not undeleted within 7 days, Azure permanently deletes it. Soft delete does not protect against malicious deletion: an attacker with Storage Blob Data Contributor or higher access can delete blobs (or purge soft-deleted blobs) if they also have permission to manage soft delete policies. To protect against malicious or accidental administrative actions, use **immutable storage** (time-based retention policies or legal holds, taught in A08) or **RBAC least privilege** (grant only the minimum necessary roles).

**The plausible wrong reading.** You might expect soft delete to prevent all deletions, or to protect against purge operations. That is not true. Soft delete retains deleted blobs for the retention period, but it does not prevent deletion or purge. An administrator or user with sufficient permissions can still delete and purge blobs. To block deletion permanently for a specified period, use immutable storage with a time-based retention policy.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| LRS vs ZRS | LRS: three synchronous copies in one datacenter. No protection against datacenter failure. ZRS: three synchronous copies across three availability zones in one region. Protects against datacenter failure, but not region failure. |
| GRS vs RA-GRS | Both replicate to a secondary region (six total copies). GRS: the secondary endpoint is readable only after failover. RA-GRS: the secondary endpoint is always readable (even before failover). RA-GRS is useful for read-heavy workloads that tolerate stale data. |
| GZRS vs RA-GZRS | Both are ZRS in the primary region plus LRS in the secondary. GZRS: the secondary endpoint is readable only after failover. RA-GZRS: the secondary endpoint is always readable. The highest redundancy and read availability. |
| LRS→ZRS conversion vs LRS→GRS change | LRS→ZRS is a **conversion** (data is copied to new infrastructure; can take hours or days; no downtime). LRS→GRS is a live SKU change (instant; replication to the secondary starts immediately). |
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

1. **A storage account has SKU `Standard_LRS`. An availability zone in the datacenter fails. What happens to the account?**
2. **A storage account has SKU `Standard_RA-GRS`. The primary region (East US) becomes unavailable. Can you read blobs from the secondary endpoint?**
3. **You enable blob soft delete with a 7-day retention period. You delete a blob on Monday. On Friday (5 days later), can you undelete it?**
4. **You want to change a storage account's redundancy from LRS to ZRS. What operation does Azure perform?**
5. **You configure customer-managed keys for a storage account. The key vault key is deleted (and purge protection is disabled, so the key is purged immediately). What happens to the blobs in the account?**

<details>
<summary>Answers</summary>

1. The account becomes unavailable. LRS stores three synchronous copies in one datacenter. If that datacenter (or an availability zone within it, in regions that support zones) fails, all three copies are lost. LRS has no protection against datacenter failure. Use ZRS or GRS/GZRS for zone or region failure protection.
2. Yes. RA-GRS (read-access geo-redundant storage) makes the secondary endpoint (`<account>-secondary.blob.core.windows.net`) readable at all times, even before failover. The data at the secondary may lag behind the primary (eventual consistency). Without `RA-` (for example, `Standard_GRS`), the secondary endpoint is readable only after failover.
3. Yes. Soft delete retains the blob for 7 days. On Friday, the blob is still within the retention period, so you can undelete it. If you wait until the following Tuesday (8 days later), the blob is permanently deleted.
4. A **conversion** (also called a live migration). Azure copies the data from one datacenter to three availability zones. The account remains online (no downtime), but the conversion can take hours or days. The alternative is a manual migration (create a new ZRS account, copy data with AzCopy, delete the old account). An LRS→ZRS conversion is not a simple SKU property change; it is a data migration.
5. The blobs become inaccessible. Azure Storage cannot decrypt the data without the customer-managed key. Read and write operations fail with errors indicating the key is unavailable. To restore access, you must recover the key (if it is in the key vault's soft-deleted state) or restore it from a backup. If the key is permanently lost, the data is unrecoverable. This is why purge protection is required for key vaults used with customer-managed keys.

</details>

## Takeaways

- Storage account SKU determines redundancy and performance. LRS (three copies in one datacenter) has no datacenter-failure protection. ZRS (three copies across three zones) protects against datacenter failure. GRS/GZRS replicate to a secondary region (six copies total). RA-GRS and RA-GZRS make the secondary endpoint readable before failover.
- LRS→ZRS is a **conversion** (data is copied to new infrastructure; takes hours or days; no downtime). LRS→GRS is a live SKU change (instant). Downgrading (GZRS→LRS) is a live SKU change, and you lose redundancy immediately.
- Customer-managed keys (CMK) store the encryption key in Azure Key Vault. You control rotation and revocation. CMK requires a managed identity (system-assigned or user-assigned), a key vault with soft delete and purge protection, and an RSA key (2048, 3072, or 4096 bits). Infrastructure encryption (double encryption) is a creation-time-only setting.
- Blob soft delete and container soft delete retain deleted objects for a retention period (1–365 days). You can undelete them during that period. Soft delete does not prevent deletion or purge; it only delays permanent deletion.
- Object replication asynchronously copies block blobs from a source account to a destination account. It requires blob versioning enabled on both accounts. Use it for latency minimization, disaster recovery, or prod/test isolation.
- The secondary region for GRS/RA-GRS/GZRS/RA-GZRS is determined by Azure and cannot be changed. The secondary endpoint for blobs is `<account>-secondary.blob.core.windows.net`. Without `RA-` in the SKU, the secondary endpoint is not accessible until after failover.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-storage-account-baseline | WRITE | S | A secure storage account |
| 2 | e02-choose-redundancy | PREDICT | S | What survives the outage? |
| 3 | e03-upgrade-redundancy | MODIFY | S | Upgrade to geo-zone redundancy |
| 4 | e04-customer-managed-key | WRITE | M | Encrypt with your own key |
| 5 | e05-insecure-storage-settings | BUG | S | Find the insecure settings |
| 6 | e06-object-replication | WRITE, LAB | M | Replicate blobs between accounts |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-storage-sku-and-kind | Declare a storage account with a specified SKU and kind |
| 2 | r02-enable-blob-versioning | Enable blob versioning via the `blobServices/default` child resource |
