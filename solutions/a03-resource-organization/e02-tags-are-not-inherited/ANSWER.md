# a03-e02-tags-are-not-inherited

## Resource group tags
The group `lagb-a03-e02-example` gets the five course tags from `main.bicep`: `course=LearnAzureByGrinding`, `unit=a03-resource-organization`, `exercise=a03-e02-tags-are-not-inherited`, `owner=n8`, `expires=2026-12-31T00:00:00Z`. Azure does not add any others.

## Resource tags
The storage account gets whatever the module caller passed as `tags`. Here that is `union(rg.tags, { purpose: 'predict' })`, so the account has the five course tags **and** `purpose=predict`. Those tags are on the account because Bicep wrote them, not because Azure copied them from the group.

## union()
`union(rg.tags, { purpose: 'predict' })` merges two objects. Keys in the second object win on conflict. `purpose` is new, so the result is the five course tags plus `purpose`. If the storage module had been called with `tags: {}` (its default), the account would have no tags even though the group has five.

## Inheritance
Azure does **not** inherit resource-group tags onto resources. A tag on the group is only on the group. The way to copy a group tag onto resources is to assign a Policy such as the built-in **Inherit a tag from the resource group** (`cd3aa116-8754-49c9-a813-ad46512ece54`), which uses a **modify** effect. That assignment needs a managed identity, a location, and a role (Contributor on the built-in). Existing resources pick the tag up only after a remediation task.
