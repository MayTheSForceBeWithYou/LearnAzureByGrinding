# a03-e01-rg-at-subscription-scope `[WRITE]` (S)

## Goal

Write a subscription-scoped Bicep file that creates a resource group carrying the course tags.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- `targetScope` is `subscription`.
- The compiled `$schema` is `subscriptionDeploymentTemplate.json`.
- The compiled template contains `Microsoft.Resources/resourceGroups`.
- The group name uses the `lagb-` prefix.
- The group has the course tag set from A02 r01: `course`, `unit`, `exercise`, `expires`, `owner`.
- `course` is `LearnAzureByGrinding`. `unit` is `a03-resource-organization`. `expires` is UTC `yyyy-MM-ddTHH:mm:ssZ`.
- Location comes from the `location` parameter; do not hard-code a region on the resource.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`Microsoft.Resources/resourceGroups` is a subscription-scope type. Put `location: location` and the five tags on the group.

</details>
