# Notes

**Why it is correct.** Same motion as e01: built-in Allowed locations by `tenantResourceId` (tenant-level `/providers/Microsoft.Authorization/policyDefinitions/<guid>`), parameter `listOfAllowedLocations`, no copied `policyRule`.

**Numbers / SKUs.** Definition id `e56962a6-4747-49cd-b67b-bf8b01975c4c`.

**Alternatives.** A literal tenant-level resource id string is the same definition.

**The usual mistake.** Copying the definition body, using `subscriptionResourceId` for a built-in, or assigning at subscription scope when the file is `targetScope = 'resourceGroup'`.
