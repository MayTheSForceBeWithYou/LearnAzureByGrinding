# Notes

**Why it is correct.** subscription targetScope plus Microsoft.Resources/resourceGroups.

**Numbers / SKUs.** API 2024-03-01.

**Alternatives.** Management-group and tenant scopes are the same motion with a different targetScope and type.

**The usual mistake.** Leaving targetScope at resourceGroup and declaring a resource group — that type is not valid there.
