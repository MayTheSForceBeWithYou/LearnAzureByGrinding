# a05-e02-create-user-and-group `[CLI]` (S)

## Goal

Fill in `Invoke-CreateUserAndGroup` so it creates a cloud user, updates one property, creates a security group, and adds the user to the group. Directory work runs only in the disposable A05 test tenant.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- Call `Assert-LabContext -Scope Entra -LabEnv $LabEnv` **before** any `az` call. Never `az login`, `Connect-AzAccount`, `Connect-MgGraph`, or `az account set`.
- Run `az ad user create` (display name, UPN, password from the function parameters).
- Run `az ad user update` with `--display-name` (the `az ad user update` command has no `--job-title` or department flag: <https://learn.microsoft.com/cli/azure/ad/user#az-ad-user-update>).
- Run `az ad group create` (security group) and `az ad group member add`.
- Use the `lagb-` names already passed in. Do not target the personal Default Directory or a work tenant.
- Free tier covers create/manage cloud users and groups (<https://learn.microsoft.com/entra/fundamentals/licensing>).
- Tests mock `az` and `Assert-LabContext`. Live `az` against the test tenant is optional, student-run, never CI.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`Assert-LabContext -Scope Entra -LabEnv $LabEnv` first. Then `az ad user create --display-name … --user-principal-name … --password …`, `az ad user update --id … --display-name …`, `az ad group create --display-name … --mail-nickname …`, `az ad group member add --group … --member-id …`. Stay on `az ad` (no `az rest`).

</details>
