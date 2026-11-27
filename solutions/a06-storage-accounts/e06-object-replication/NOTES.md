# Notes

**Why it is correct.** Two StorageV2 accounts, versioning on both `blobServices/default`, change feed on the source, a container on each, destination `objectReplicationPolicies` named `default` first, source policy named from that `policyId` with the destination `ruleId`. The source policy is a module because `name: destPolicy.properties.policyId` in `main.bicep` is BCP120. `allowSharedKeyAccess: false` on both.

**Numbers / SKUs.** `Standard_LRS`. Change-feed retention 7 days. Empty accounts in East US are effectively $0 for a short lab (Retail Prices API 27 November 2026, General Block Blob LRS Data Stored $0.024 / GB / Month).

**Alternatives.** Cross-tenant replication needs the full account resource ids (used here anyway) and a different permission path. Same-tenant can use account names; ids are unambiguous.

**The usual mistake.** Creating the source policy first (Azure has no destination policyId/ruleId yet) or enabling versioning on only one account. `tags: tags` is what lab-up wants; the tests read compiled `tags.course` and need a literal tag object. Nested `source-orp.bicep` has dummy param defaults so `scripts/psrule.ps1` can expand it as a standalone file. `down.ps1` (`--no-wait` vs "tore down") and unused `up.bicepparam` are harness copies of the starter; they stay byte-identical until Jack changes `units/` (round 2). `Start-LabDeployment` now accepts extra `-Parameters` so that overlay can land then.
