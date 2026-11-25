# a01-e04-what-if-changes

## Create
The capture legend lists only `+ Create`. What-if predicts creating one resource: `Microsoft.Storage/storageAccounts/n8deploy20261122` at API version `2025-01-01`. Resource group `arm-template-group` did not already contain that account. Create prints the full after body: `kind` `StorageV2`, `location` `westus`, `name` `n8deploy20261122`, `properties.supportsHttpsTrafficOnly` true, `sku.name` `Standard_GRS`, and tag `displayName` `n8deploy20261122`. The summary line is `Resource changes: 1 to create.`

## Modify
This capture does not show a Modify (`~`). Modify appears when a resource already exists and the template changes a property — for example an existing account whose SKU would move from `Standard_LRS` to `Standard_GRS`. The named account was not present, so Azure will create it rather than update it. `capture.txt` has no Modify transcript; do not invent one.

## Ignore
This capture does not show Ignore (`*`). Ignore is an Incremental-mode mark for a resource that already exists in the group but is not in the template. The capture legend lists only Create, so that case is not in this output.
