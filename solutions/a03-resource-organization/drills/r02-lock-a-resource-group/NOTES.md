# Notes

**Why it is correct.** Tagged subscription-scope group plus a `CanNotDelete` lock in `lock.bicep`, deployed with `module … scope: rg`. Bicep 0.49.2 rejects `scope: rg` on the lock resource itself (BCP139).

**Numbers / SKUs.** Lock API `2020-05-01`. Name `lagb-cannotdelete`.

**Alternatives.** `ReadOnly` is the other lock level; this drill requires `CanNotDelete`.

**The usual mistake.** Putting `scope: rg` on the lock in `main.bicep` (BCP139), or omitting the module so the lock lands on the subscription.
