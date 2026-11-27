# Notes

**Why it is correct.** Entra guard first, then `az ad user list` with a department filter, then UPNs from the JSON.

**Numbers / SKUs.** Fixture users are fake all-zero GUIDs (`fixtures/NOTE.md`).

**Alternatives.** `--query "[].userPrincipalName"` is equivalent; the tests only require the filter and the returned UPNs.

**The usual mistake.** Filtering in PowerShell after `az ad user list` with no filter, or skipping `Assert-LabContext`.
