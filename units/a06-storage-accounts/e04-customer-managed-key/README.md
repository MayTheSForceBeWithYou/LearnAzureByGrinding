# a06-e04-customer-managed-key `[WRITE]` (M)

## Goal

Encrypt a storage account with a customer-managed key in Key Vault, using a user-assigned identity.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

A CMK Key Vault must have **soft delete** and **purge protection** enabled; the key is RSA. When you set CMK at **create** time you must use a **user-assigned** managed identity. Source: <https://learn.microsoft.com/azure/storage/common/customer-managed-keys-overview> (sections **Key vault requirements** and **Customer-managed keys with a key vault in the same tenant**).

`requireInfrastructureEncryption` can **only** be set at account creation. You cannot enable or disable infrastructure encryption later. Source: <https://learn.microsoft.com/azure/storage/common/infrastructure-encryption-enable> — "you must configure a storage account to use infrastructure encryption when you create the account. You can't enable or disable infrastructure encryption after you create the account."

The identity needs wrap/unwrap/get on the key. With Key Vault RBAC that is the built-in **Key Vault Crypto Service Encryption User** role, id `e147488a-f6f5-4113-8e2d-b22465e65bf6` (tenant-level `/providers/Microsoft.Authorization/roleDefinitions/e147488a-f6f5-4113-8e2d-b22465e65bf6` or `tenantResourceId`). Confirmed on <https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-crypto-service-encryption-user>.

## Constraints

- The compiled template contains `Microsoft.KeyVault/vaults`, `Microsoft.KeyVault/vaults/keys`, `Microsoft.ManagedIdentity/userAssignedIdentities`, `Microsoft.Authorization/roleAssignments`, and `Microsoft.Storage/storageAccounts`.
- Key Vault: `enableRbacAuthorization` true, purge protection true, soft delete on (property or the platform default plus `softDeleteRetentionInDays`). Do not use access policies. Security L1 also includes `Azure.KeyVault.RBAC`, `Azure.KeyVault.AccessPolicy`, and `Azure.KeyVault.Logs` — send **AuditEvent** (or `audit` / `allLogs`) diagnostics to `logAnalyticsWorkspaceId` (the parameter's default is a fake all-zero example id; supply your own workspace).
- Role assignment: `name = guid(<key-vault-id>, <identity resource id>, <roleDefinitionId>)` (the identity's `.id`, not `.properties.principalId` — that is BCP120 on Bicep 0.49.2), `principalType: 'ServicePrincipal'`. Do not hard-code a GUID; do not use `newGuid()`. Use the tenant-level role definition id, not `subscriptionResourceId`.
- Storage: `encryption.keySource` `Microsoft.Keyvault`, identity is the user-assigned identity, `requireInfrastructureEncryption` true, `allowSharedKeyAccess` false, HTTPS, TLS 1.2, no public blobs, course tags, `lagb` prefix on storage and vault names (no hyphen; identity names may include hyphens).
- Do not add a PSRule suppression.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

Create the identity, the vault (`enableRbacAuthorization: true`, `enablePurgeProtection: true`), a key, then a role assignment of `e147488a-f6f5-4113-8e2d-b22465e65bf6` with `guid(vault.id, identity.id, roleId)` and `principalType: 'ServicePrincipal'`. On the storage account set `identity.userAssignedIdentities`, `encryption.keySource: 'Microsoft.Keyvault'`, `encryption.identity.userAssignedIdentity`, `keyvaultproperties`, and `requireInfrastructureEncryption: true`.

</details>
