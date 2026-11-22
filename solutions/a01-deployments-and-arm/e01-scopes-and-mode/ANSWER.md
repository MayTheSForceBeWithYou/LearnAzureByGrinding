# a01-e01-scopes-and-mode

## Four scopes
Resource group (most resources), subscription (resource groups, subscription Policy/RBAC), management group (Policy/RBAC at MG scope), tenant (management groups, tenant RBAC). `targetScope` on the file must match the `az deployment *` command you run.

## Incremental vs Complete
Incremental (default) adds or updates resources in the template and leaves others in the group alone, but the whole resource definition is redeployed so omitted properties (for example subnets on a VNet) may reset. Complete deletes resources in the group that are not in the template. Mode is a deployment setting, not a Bicep keyword. Complete applies only to resource-group deployments.

## What Complete will not delete
The resource group itself. Resources blocked by a lock. Resource types that do not support complete-mode deletion. It *will* delete a resource whose `condition` is false, because that resource is not deployed.
