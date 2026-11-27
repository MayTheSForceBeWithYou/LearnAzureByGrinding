# Notes

**Why it is correct.** `sku.name`, `kind`, and `accessTier` bind to parameters. HTTPS, TLS 1.2, no public blobs, no shared key, `lagb-` name.

**Numbers / SKUs.** Defaults `Standard_LRS`, `StorageV2`, `Hot`.

**Alternatives.** Hard-coding those three would compile for the defaults and fail the tests' `Match`.

**The usual mistake.** Writing `sku.name: 'Standard_LRS'` instead of `skuName`.
