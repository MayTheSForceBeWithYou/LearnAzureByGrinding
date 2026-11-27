# a05-e05-licence-needs-usage-location `[CLI]` (S)

## Goal

Fill in `Invoke-AssignLicence` so it sets `usageLocation` on a user, then assigns a licence through Microsoft Graph via `az rest`. Directory work runs only in the disposable A05 test tenant.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

A user must have a two-letter ISO 3166 `usageLocation` before you assign a licence (legal check for service availability). Graph documents `usageLocation` as required for licensed users: <https://learn.microsoft.com/graph/api/resources/user>. Then `POST /users/{id}/assignLicense` with `addLicenses` / `removeLicenses`: <https://learn.microsoft.com/graph/api/user-assignlicense>. Entra PowerShell says the same: set usage location, then assign. <https://learn.microsoft.com/powershell/module/microsoft.entra.users/set-entrauserlicense>

P1 (or P2) licence assignment in this course is **trial-in-test-tenant** only. The one-month P1/P2 trial requires a credit card and, when the trial ends, automatically converts into a 12-month paid subscription unless you cancel during the trial; read the terms at Start, and start it only in the test tenant. Do not assign paid P1/P2 in the personal Default Directory. Confirm which SKU includes P1 on <https://learn.microsoft.com/entra/fundamentals/licensing>. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote on the one-month free trial).

## Constraints

- Call `Assert-LabContext -Scope Entra -LabEnv $LabEnv` **before** any `az` / Graph call. Never `az login`, `Connect-AzAccount`, `Connect-MgGraph`, or `az account set`.
- Set `usageLocation` first (PATCH the user through `az rest` to Graph). Then POST `assignLicense` through `az rest`.
- Use the `-UserId`, `-SkuId`, and `-UsageLocation` parameters. The all-zero SKU in the tests is fake.
- Tests mock `az` and `Assert-LabContext`. Live Graph against the test tenant is optional, student-run, never CI.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`Assert-LabContext -Scope Entra -LabEnv $LabEnv` first. Then `az rest --method PATCH --uri https://graph.microsoft.com/v1.0/users/<id> --body '{"usageLocation":"US"}' --headers Content-Type=application/json`, then `az rest --method POST --uri https://graph.microsoft.com/v1.0/users/<id>/assignLicense --body '{"addLicenses":[{"skuId":"<sku>","disabledPlans":[]}],"removeLicenses":[]}'`.

</details>
