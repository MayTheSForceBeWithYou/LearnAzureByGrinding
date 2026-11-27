# Notes

**Why it is correct.** TLS 1.2 and `allowBlobPublicAccess: false`. Shared key stays false. No PSRule suppression.

**Numbers / SKUs.** Unchanged `Standard_LRS`. ExpectDiagnostics is `Azure.Storage.MinTLS` only.

**Alternatives.** A private endpoint would also hide the public blob surface; this bug is the two advertised properties.

**The usual mistake.** Listing `Azure.Storage.BlobPublicAccess` in ExpectDiagnostics — that rule is not in Security L1, so verify-all would fail the starter for extra/missing diagnostics.
