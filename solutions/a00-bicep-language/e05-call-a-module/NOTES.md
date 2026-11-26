# Notes

**Why it is correct.** main.bicep deploys nothing itself; the module does, and the id is re-exported.

**Numbers / SKUs.** SKU Standard_LRS inside the module.

**Alternatives.** You can inline the resource in main.bicep and still pass ExpectResources, but that is not a module call and misses the point.

**The usual mistake.** Passing `name:` of the module as a parameter name. `name` is the nested deployment name, not a module parameter.
