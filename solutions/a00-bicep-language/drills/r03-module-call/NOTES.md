# Notes

**Why it is correct.** The call passes `location` and reads `outputs.accountId`.

**Numbers / SKUs.** None.

**Alternatives.** Omitting `name` on the module is legal; this drill still sets one.

**The usual mistake.** Using the caller's parameter name when the module's parameter is different.
