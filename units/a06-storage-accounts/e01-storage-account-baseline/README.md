# a06-e01-storage-account-baseline `[WRITE]` (S)

## Goal

Author a general-purpose v2 storage account with the course security defaults and tags.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled template contains one `Microsoft.Storage/storageAccounts`.
- `kind` is `StorageV2`. `sku.name` is `Standard_LRS`.
- `supportsHttpsTrafficOnly` is true. `minimumTlsVersion` is `TLS1_2`. `allowBlobPublicAccess` is false. `allowSharedKeyAccess` is false.
- The account name uses the `lagb` prefix (no hyphen: storage names are 3–24 lowercase letters and numbers; `uniqueString` is allowed).
- Location comes from the `location` parameter. Tags use the `tags` parameter (course set: `course`, `unit`, `exercise`, `expires`, `owner`).
- Do not add a PSRule suppression.

Secure transfer, TLS 1.2, and disabling anonymous blob access are the documented defaults this baseline is teaching. Shared-key access stays off (`allowSharedKeyAccess: false`) on every account in this course. Sources: <https://learn.microsoft.com/azure/storage/common/storage-account-create> and <https://learn.microsoft.com/azure/storage/common/storage-require-secure-transfer>.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`Microsoft.Storage/storageAccounts@2023-05-01`, `kind: 'StorageV2'`, `sku.name: 'Standard_LRS'`, then `supportsHttpsTrafficOnly`, `minimumTlsVersion: 'TLS1_2'`, `allowBlobPublicAccess: false`, `allowSharedKeyAccess: false`, plus `tags: tags`.

</details>
