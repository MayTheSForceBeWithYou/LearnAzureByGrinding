# Notes

**Why it is correct.** The storage tags match the `union()` argument. Azure does not copy resource-group tags by itself. The built-in inherit policy is modify, not deny.

**Numbers / SKUs.** Inherit-a-tag-from-the-resource-group definition id `cd3aa116-8754-49c9-a813-ad46512ece54`. Storage SKU in the neighbour is `Standard_LRS`.

**Alternatives.** `Inherit a tag from the resource group if missing` (`ea3f2387-9b95-492a-a190-fcdc54f7b070`) uses modify `add` instead of `addOrReplace`. Either is a modify assignment.

**The usual mistake.** Reading the storage tags and concluding "tags inherit." They are there because the module call passed `union(rg.tags, …)`.
