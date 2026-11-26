# Notes

**Why it is correct.** Resource-group-scope assignment of the built-in Allowed locations definition by **tenant-level** id (`tenantResourceId`). `listOfAllowedLocations` is the built-in parameter name and takes the `allowedLocations` param (default `eastus`). No `policyRule` is copied.

**Numbers / SKUs.** Built-in definition `e56962a6-4747-49cd-b67b-bf8b01975c4c` at `/providers/Microsoft.Authorization/policyDefinitions/<guid>`. Assignment API `Microsoft.Authorization/policyAssignments@2024-04-01`. Default effect on the built-in is Deny.

**Alternatives.** A literal `/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c` is the same id; `tenantResourceId` is the Bicep helper. `subscriptionResourceId` is the wrong scope for a built-in definition.

**The usual mistake.** Pasting the definition's `policyRule` into the assignment, or using a made-up parameter name instead of `listOfAllowedLocations`.
