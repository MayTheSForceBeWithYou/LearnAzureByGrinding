# Notes

**Why it is correct.** The ARM JSON SKU object is the same property the Bicep `sku.name` compiles to.

**Numbers / SKUs.** Standard_GRS → Standard_LRS.

**Alternatives.** You could decompile, edit Bicep, and rebuild; this exercise grades the JSON file.

**The usual mistake.** Editing `kind` or the API version instead of `sku.name`.
