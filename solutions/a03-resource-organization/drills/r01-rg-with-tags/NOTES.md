# Notes

**Why it is correct.** Same motion as e01: subscription-scope resource group, `lagb-` prefix, five course tags, location from the parameter.

**Numbers / SKUs.** API `Microsoft.Resources/resourceGroups@2024-03-01`. `expires` is UTC `yyyy-MM-ddTHH:mm:ssZ`.

**Alternatives.** Any `lagb-` name and any non-empty `exercise` / `owner` / `expires` values pass the drill tests.

**The usual mistake.** Forgetting `expires` or putting the group in a resource-group-scope file.
