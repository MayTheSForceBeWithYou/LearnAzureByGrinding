# Notes

**Why it is correct.** Entra directory roles act on the tenant (users, groups, guests, licences). Azure RBAC acts on ARM scopes. Each scenario names one role at one scope; the other system does not fill the gap.

**Numbers / SKUs.** No SKU. Directory work stays in the A05 test tenant, never the MSA Default Directory.

**Alternatives.** Global Administrator can elevate access to Azure RBAC; that path is the lesson's worked example and is out of scope here.

**The usual mistake.** Treating Contributor as able to invite guests (it cannot; members can invite under the default Guest invite settings), or treating User Administrator as able to create resource groups.
