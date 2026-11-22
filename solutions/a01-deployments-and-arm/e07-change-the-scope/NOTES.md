# Notes

**Why it is correct.** targetScope plus the resourceGroups type is what changes the schema and the deploy command you would run.

**Numbers / SKUs.** API version 2024-03-01. Default name lagb-a01-e07.

**Alternatives.** You could then module-deploy into `scope: rg`; out of scope here.

**The usual mistake.** Putting `scope:` on the storage resource in a subscription file. Non-extension resources you deploy must match the file scope.
