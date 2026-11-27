# Notes

**Why it is correct.** `Assert-LabContext -Scope Entra` first. PATCH `usageLocation` on the user, then POST `assignLicense` with `addLicenses` / `removeLicenses`. Graph requires usage location before a licence: <https://learn.microsoft.com/graph/api/resources/user> and <https://learn.microsoft.com/graph/api/user-assignlicense>.

**Numbers / SKUs.** The test SKU is the all-zero GUID `00000000-0000-0000-0000-0000000000b1`, fake. P1 assignment is trial-in-test-tenant only. <https://learn.microsoft.com/entra/fundamentals/licensing>

**Alternatives.** Entra PowerShell `Set-EntraUserLicense` is the same two-step (usage location, then assign). Tests grade `az rest`.

**The usual mistake.** POSTing `assignLicense` before `usageLocation`, or assigning P1 in the personal Default Directory. Passing inline JSON to `az rest --body` loses quotes on Windows (`az` is a `.cmd`); the solution writes a temp file under `[IO.Path]::GetTempPath()` and passes `--body "@$path"`.
