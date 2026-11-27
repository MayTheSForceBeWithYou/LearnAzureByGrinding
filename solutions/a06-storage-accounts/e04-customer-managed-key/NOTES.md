# Notes

**Why it is correct.** User-assigned identity, RBAC Key Vault with soft delete and purge protection, Crypto Service Encryption User (`e147488a-f6f5-4113-8e2d-b22465e65bf6`) named with `guid(kv.id, identity.id, roleId)` and `principalType: ServicePrincipal`, CMK plus `requireInfrastructureEncryption`, `allowSharedKeyAccess: false`. `identity.properties.principalId` in the assignment *name* is BCP120 (runtime); `identity.id` is known at start. The properties still use `principalId`.

**Numbers / SKUs.** Storage `Standard_LRS`. Vault SKU `standard`. Role id `e147488a-f6f5-4113-8e2d-b22465e65bf6`. RSA 2048.

**Alternatives.** System-assigned identity cannot set CMK at create time. Access policies are the old model; Security L1 wants RBAC (`Azure.KeyVault.RBAC`).

**The usual mistake.** `subscriptionResourceId` for the role definition, `newGuid()` for the assignment name, or turning infrastructure encryption on after create (it is create-time only).
