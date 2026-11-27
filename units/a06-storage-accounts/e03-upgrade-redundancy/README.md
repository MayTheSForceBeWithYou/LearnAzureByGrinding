# a06-e03-upgrade-redundancy `[MODIFY]` (S)

## Goal

Add **geo-redundancy**: change the existing account's `sku.name` from `Standard_LRS` to `Standard_GRS`.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

This is a geo change, not a zone change. Learn's redundancy-migration table says switching **from LRS to GRS/RA-GRS** is "Use Azure portal, PowerShell, or CLI" — a SKU update. Switching **from LRS to ZRS** is "Perform a conversion" (`az storage account migration start` / `Start-AzStorageAccountMigration`). Quote:

> Add or remove geo-replication or read access to the secondary region.
> Add or remove zone-redundancy by performing a conversion.

Source: <https://learn.microsoft.com/azure/storage/common/redundancy-migration> (sections **Options for changing the replication type** and **Changing redundancy configuration**). Zone conversion is the e02 README; do not retarget this file to ZRS.

The target is `Standard_GRS`, not `Standard_RAGRS`. Secondary **read** access (RA-GRS vs GRS) is lesson prose, not this edit.

## Constraints

- The resource type stays `Microsoft.Storage/storageAccounts`.
- `sku.name` is `Standard_GRS`.
- Do not change HTTPS, TLS, public-access, or shared-key settings.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
