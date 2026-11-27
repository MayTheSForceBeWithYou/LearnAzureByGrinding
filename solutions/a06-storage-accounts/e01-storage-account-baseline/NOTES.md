# Notes

**Why it is correct.** One StorageV2 Standard_LRS account with HTTPS, TLS 1.2, no public blobs, no shared key, `lagb` name (no hyphen), and `tags: tags`.

**Numbers / SKUs.** `Standard_LRS`. API `Microsoft.Storage/storageAccounts@2023-05-01`. `allowSharedKeyAccess: false` on every account in this course.

**Alternatives.** ZRS/GRS would also compile; the tests require LRS and the course default is LRS (SPEC 10.4).

**The usual mistake.** Leaving shared-key access on (PSRule `Azure.Storage.LocalAuth`) or hard-coding `location: 'eastus'`. A hyphen in the account name (`lagb-`) is invalid.
