# Notes

**Why it is correct.** `Assert-LabContext -Scope Entra` runs before any `az` call. Then create user, `az ad user update --display-name` (that command has no `--job-title`), create the security group, add the member. Names stay `lagb-`.

**Numbers / SKUs.** Free covers create/manage cloud users and groups. <https://learn.microsoft.com/entra/fundamentals/licensing>

**Alternatives.** Microsoft Graph via `az rest` can do the same calls; the tests grade `az ad user` / `az ad group`.

**The usual mistake.** Calling `az` before the Entra guard, or targeting the personal Default Directory.
