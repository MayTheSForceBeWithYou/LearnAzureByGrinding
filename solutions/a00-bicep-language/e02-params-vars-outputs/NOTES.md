# Notes

**Why it is correct.** Parameters cross the file boundary inward; variables do not; outputs cross it outward.

**Numbers / SKUs.** namePrefix default lagb, 3–9 characters (`st` + prefix + uniqueString must stay ≤ 24).

**Alternatives.** A secure output uses `@secure()` on the output as well, if you must return a secret.

**The usual mistake.** Writing `param adminPassword securestring` — that type does not exist; use `@secure()` on `string`.
