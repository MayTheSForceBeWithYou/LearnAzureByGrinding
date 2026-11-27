# Notes

**Why it is correct.** LRS is one datacenter; ZRS survives a zone; GRS/GZRS secondary is dark until failover; RA adds a secondary read endpoint. Zone conversion is not a SKU edit.

**Numbers / SKUs.** LRS, ZRS, GRS, GZRS, RA-GZRS. e03 then changes LRS→`Standard_GRS`.

**Alternatives.** RA-GRS is the GRS equivalent of RA-GZRS; the table asked for RA-GZRS.

**The usual mistake.** Treating GRS as readable in the secondary without RA, answering LRS→ZRS as a `sku.name` change, or treating every zone outage as taking LRS/GRS down — it is down only if that outage hits the zone holding the account's data.
