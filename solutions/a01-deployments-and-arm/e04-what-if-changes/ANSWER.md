# a01-e04-what-if-changes

## Create
`+` on the second storage account (`extra` / `st2…`). It is not in the current group, so what-if prints the full after body.

## Modify
`~` on the existing account. The SKU changes from Standard_LRS (current) to Standard_GRS (template). Only Modify shows a property-level diff.

## Ignore
`*` for any resource in the group that is not in the template. In the described state there is none. In Complete mode that case would be `-` Delete instead.
