# Notes

**Why it is correct.** The answer quotes only the real 25 Nov 2026 capture: one Create, no Modify, no Ignore.

**Numbers / SKUs.** StorageV2, `Standard_GRS`, `westus`, name `n8deploy20261122`. Subscription ID in the fixture is redacted.

**Alternatives.** A later live capture against an existing LRS account would show Modify; that transcript is not in the tree. The neighbour `main.bicep` is not the captured ARM JSON.

**The usual mistake.** Predicting a Modify because the lesson table includes `~`, or inventing a property diff the capture does not contain. Create prints the full after body, not a diff.
