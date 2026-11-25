# Notes

**Why it is correct.** Default targetScope is resourceGroup; the schema URL follows.

**Numbers / SKUs.** Standard_LRS.

**Alternatives.** You may omit the `targetScope` line; the test matches the compiled schema either way.

**The usual mistake.** Setting `targetScope = 'subscription'` and then failing `az deployment group` later. This file must stay RG-scoped.
