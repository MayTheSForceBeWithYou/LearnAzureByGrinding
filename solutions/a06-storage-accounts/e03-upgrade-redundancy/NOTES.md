# Notes

**Why it is correct.** `sku.name` is `Standard_GRS`. HTTPS, TLS 1.2, no public blobs, no shared key stay as shipped. This is a geo SKU update, not a zone conversion.

**Numbers / SKUs.** `Standard_LRS` → `Standard_GRS`. Not `Standard_RAGRS` and not ZRS.

**Alternatives.** RA-GRS would add secondary read; the tests require GRS.

**The usual mistake.** Retargeting to ZRS (`az storage account migration start`) instead of the GRS SKU change this file asks for.
