# Notes

**Why it is correct.** Resource labs pin expectedTenantId + expectedSubscriptionId. A05 pins expectedEntraTenantId separately.

**Numbers / SKUs.** GUIDs in the fixture are placeholders, not Nathan's real ids.

**Alternatives.** Live check is `az account show`; CI never runs it.

**The usual mistake.** Comparing only the subscription id and ignoring tenant id.
