# Notes

**Why it is correct.** Replacing the literal with a location parameter clears the only advertised diagnostic.

**Numbers / SKUs.** Region was eastus in the starter; the solution does not pin a region.

**Alternatives.** You could pass location from the parent module instead of defaulting to the resource group.

**The usual mistake.** Disabling the rule with `#disable-next-line`. Starters and solutions must not suppress diagnostics.
