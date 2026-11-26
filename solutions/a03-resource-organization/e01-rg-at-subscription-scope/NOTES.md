# Notes

**Why it is correct.** Subscription-scope file. One `Microsoft.Resources/resourceGroups` named with the `lagb-` prefix, `location` from the parameter, and the five course tags.

**Numbers / SKUs.** API `Microsoft.Resources/resourceGroups@2024-03-01`. Tags: `course=LearnAzureByGrinding`, `unit=a03-resource-organization`, `exercise=a03-e01-rg-at-subscription-scope`, `owner=n8`, `expires=2026-12-31T00:00:00Z`.

**Alternatives.** A shorter `lagb-a03-e01` name also matches the prefix test. Putting the tags in a `var` and spreading them is the same compiled result.

**The usual mistake.** Resource-group `targetScope` (the compiled `$schema` would not be `subscriptionDeploymentTemplate.json`) or hard-coding `location: 'eastus'` (`no-hardcoded-location`).
