# Notes

**Why it is correct.** SKU name Standard_LRS is the in-place cheaper redundancy.

**Numbers / SKUs.** Starter was Standard_GRS.

**Alternatives.** ZRS is also local to a region but is not the cheapest and is not what the test asks for.

**The usual mistake.** Changing `kind` instead of `sku.name`. `kind` cannot always change in place.
