# Notes

**Why it is correct.** Replaced the subscription-scope lock with `module lock 'lock.bicep' = { scope: rg, … }`. Level and name stay as shipped.

**Numbers / SKUs.** Lock API `2020-05-01`. Level `CanNotDelete`.

**Alternatives.** None that compile on Bicep 0.49.2: `scope: rg` on the lock resource is BCP139.

**The usual mistake.** Adding `scope: rg` on the lock in `main.bicep` (does not compile). Renaming the lock or changing `level` instead of changing where it applies.
