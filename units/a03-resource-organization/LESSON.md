# A03: Resource groups, tags, locks, subscriptions, and management groups

## Advance organizer

You have deployed a subscription-scoped budget and understand cost control. This unit teaches how to organize an Azure estate: resource groups declared at subscription scope, resource tags (and why tag inheritance requires Policy), CanNotDelete and ReadOnly locks (and what they protect), subscription boundaries, and management-group hierarchy. After this unit you can declare a resource group in Bicep at the correct scope, apply tags that survive into production, lock a resource group or resource against deletion or modification, and explain subscription and management-group organization.

You must already know: **A00** (Bicep language), **A01** (deployments and ARM), and **A02** (cost control and tagging).

After this unit you can:
- Declare a resource group at subscription scope with tags
- Apply tags to resource groups and resources, and explain that tags do not inherit automatically
- Set a CanNotDelete or ReadOnly lock on a resource group or resource
- Explain subscription boundaries (billing, RBAC, Policy) and when to move resources
- Describe management-group hierarchy and scope inheritance

## Foundations

### Resource groups

A **resource group** is a container for Azure resources. Every resource belongs to exactly one resource group, and the resource group defines the resource's region-level metadata (location, tags, locks, RBAC, Policy). Deleting a resource group deletes every resource in it. Resource groups are free; you pay only for the resources inside.

Resource groups are deployed at **subscription scope**. A subscription-scoped Bicep file declares resource groups with `Microsoft.Resources/resourceGroups@2024-03-01`:

```bicep
targetScope = 'subscription'

param location string = deployment().location
param resourceGroupName string

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: 'dev'
    owner: 'team-platform'
  }
}
```

The `location` property is required. The resource group's location is metadata only: it does not constrain the resources inside. You can deploy East US resources into a West US resource group. The resource group location controls where Azure stores the resource group's own metadata.

### Tags

A **tag** is a name-value pair attached to a resource or resource group. Tags organize resources for billing, automation, or policy enforcement. The Azure portal, CLI, and billing exports show tags. Common tag names include `environment`, `owner`, `cost-center`, and `expires`.

Tags are set in the `tags` property:

```bicep
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'my-rg'
  location: 'eastus'
  tags: {
    environment: 'production'
    cost-center: '1234'
  }
}
```

Tags on a resource group are **not automatically inherited** by the resources inside. If you want every resource in a production resource group to have an `environment=production` tag, you must set it on each resource, or use the built-in Azure Policy "Inherit a tag from the resource group" (Modify effect) to apply and enforce tag inheritance. Tag names and values are case-sensitive. Tag names can be up to 512 characters; tag values can be up to 256 characters.

The course requires five tags on lab resource groups and resources: `course`, `unit`, `exercise`, `expires`, and `owner` (section A02). The `lab-up` script writes these tags on the resource group it creates. Without Policy, resources deployed into that group do not inherit the tags unless you set them in the resource's own `tags` property.

### Locks

A **lock** prevents accidental deletion or modification. Azure supports two lock levels:

- **CanNotDelete**: allows reads and updates, but prevents deletion.
- **ReadOnly**: allows reads only. All writes (create, update, delete) are blocked.

Locks apply to the **control plane** (operations at `https://management.azure.com`), not the data plane. A CanNotDelete lock on a storage account prevents you from deleting the account, but it does not prevent you from uploading or deleting blobs. A ReadOnly lock on a storage account prevents you from changing the account's configuration (SKU, firewall rules) and blocks the `listKeys` POST operation (because it returns secrets), but it does not prevent data-plane operations like blob uploads.

Locks are `Microsoft.Authorization/locks@2020-05-01`, scoped to a resource group or a specific resource:

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'prod-rg'
  location: 'eastus'
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  scope: rg
  name: 'delete-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents accidental deletion of production resources'
  }
}
```

The `scope` property attaches the lock to the resource group. To lock a specific resource, `scope: <resource-symbolic-name>`. Locks **inherit downward**: a lock on a resource group applies to every resource in the group, and a lock on a subscription applies to every resource group and resource in the subscription. A child resource cannot remove a parent lock. To delete a resource in a locked resource group, you must first remove the lock at the resource group level.

To create or delete locks, you need `Microsoft.Authorization/*` or `Microsoft.Authorization/locks/*` actions. The Owner and User Access Administrator built-in roles have these permissions. Contributor does not.

### Subscriptions

A **subscription** is the billing and administrative boundary. Every resource belongs to one subscription, and Azure bills by subscription. Subscriptions also define RBAC and Policy boundaries: a Policy assignment at subscription scope applies to every resource group and resource in that subscription, and a subscription-scoped role assignment grants access across the entire subscription.

You can move resources between resource groups in the same subscription with `az resource move`. Moving resources between subscriptions is also possible, but not all resource types support it, and both subscriptions must be in the same Microsoft Entra tenant. The move operation locks both source and target resource groups (you cannot create, delete, or update resources in those groups while the move is in progress; the lock can last up to four hours). The Azure portal and CLI validate move operations before execution. A move changes the resource's resource ID but not its location.

**Subscription management** (changing spend limits, cancelling, viewing billing) is a portal and CLI task, not Bicep. You cannot deploy or modify subscription settings in a template. The course subscription is the personal MSA subscription recorded in `.lab-env.json` `expectedSubscriptionId`. The lab guard refuses a different subscription to prevent deploying into work accounts.

### Management groups

A **management group** is a container for subscriptions. Management groups organize subscriptions into a hierarchy, and you assign Policy and RBAC at the management-group level to inherit downward to all subscriptions in that group. The hierarchy can be up to six levels deep (not counting the root management group). Every tenant has a root management group, created automatically.

Management-group creation may be blocked on a personal tenant (the tenant must enable it, and the user must have the right role). When creation is allowed, you declare management groups at **tenant scope** in Bicep:

```bicep
targetScope = 'tenant'

resource mg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'prod-mg'
  properties: {
    displayName: 'Production'
  }
}
```

The `name` is the management group's ID; the `displayName` is what the portal shows. When management-group creation is not available, A03 teaches management groups as `[EXPLAIN]` plus read-only CLI commands (`az account management-group list`, `az account management-group show`). The lesson does not require a live management-group deployment.

Management-group scope is wider than subscription scope: a Policy or role assignment at management-group scope applies to every subscription in that management group and their resource groups and resources. This is the same inheritance model as locks and tags (with Policy for tags).

## Worked example: A resource group with tags and a CanNotDelete lock

You need a production resource group in East US, tagged for the platform team and cost center 1234, locked against accidental deletion. You will deploy it at subscription scope and verify the lock prevents deletion.

Here is the Bicep file:

```bicep
targetScope = 'subscription'

param location string = deployment().location
param resourceGroupName string = 'prod-platform-rg'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: 'production'
    owner: 'team-platform'
    'cost-center': '1234'
  }
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  scope: rg
  name: 'prevent-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Production resource group must not be deleted accidentally'
  }
}

output resourceGroupId string = rg.id
```

You deploy this with:

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters location=eastus
```

After deployment, the resource group exists with the tags. If you try to delete the resource group with `az group delete`, Azure refuses because of the lock. To delete the resource group, you must first delete the lock with `az lock delete`, or redeploy the template without the lock resource.

**The plausible wrong reading.** You might expect the tags on the resource group to automatically apply to resources you deploy into it, so a storage account in this resource group would inherit the `environment=production` tag. That is not true. Tags do not inherit by default. If you deploy a storage account into this resource group without setting its `tags` property, the account has no tags. To enforce tag inheritance, use Azure Policy with the `inherit` or `modify` effect.

## Worked example: What a ReadOnly lock blocks

A resource group contains a storage account with a ReadOnly lock. You can read the account's properties and list its containers in the portal. You can upload a blob to a container (data-plane operation). You try to change the account's SKU from Standard_LRS to Standard_GRS in the portal. Azure blocks the operation because the lock prevents configuration changes. If you try to list the account keys with `az storage account keys list`, Azure blocks it because that operation uses a POST request to the control plane (it returns secrets).

If you try to delete a blob inside the account, that succeeds. The lock applies to the control plane (operations at `https://management.azure.com`), not the data plane (blob operations at the storage endpoint). A ReadOnly lock on a VM prevents you from starting or stopping it (those are POST operations), but it does not prevent you from connecting and modifying files inside.

**The plausible wrong reading.** You might expect a ReadOnly lock on a storage account to make the account's data read-only, preventing blob uploads or deletions. That is not true. Locks apply to the control plane only. To restrict data-plane operations, use RBAC (covered in A04) or storage-account firewall rules (covered in A07 and A10).

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Resource group location vs resource location | The resource group's `location` is metadata only: it controls where Azure stores the resource group's own metadata. It does not constrain the resources inside. You can deploy East US resources into a West US resource group. Each resource has its own `location` property. |
| Tags on a resource group vs tags on resources | Tags on a resource group are independent of tags on the resources inside. Setting a tag on the resource group does not set it on the resources. To enforce tag inheritance, use the built-in Policy "Inherit a tag from the resource group". |
| CanNotDelete lock vs ReadOnly lock | CanNotDelete allows updates but prevents deletion. ReadOnly prevents all writes (create, update, delete) and blocks operations like `listKeys` (POST requests that return secrets). Both apply to the control plane only. |
| Control plane vs data plane | The control plane is operations at `https://management.azure.com`: creating, updating, deleting resources. The data plane is operations on the resource's data at service endpoints: uploading blobs, writing to a database. Locks apply to the control plane only. |
| Lock inheritance | A lock on a resource group applies to every resource in the group. A lock on a subscription applies to every resource group and resource in the subscription. A child cannot remove a parent lock. To create or delete locks, you need Owner or User Access Administrator (Contributor cannot). |
| Subscription vs management group | A subscription is the billing and administrative boundary. A management group is a container for subscriptions, used for Policy and RBAC inheritance. Policy and RBAC assigned at management-group scope apply to all subscriptions in that group. |
| Moving resources between resource groups vs subscriptions | Moving within a subscription is straightforward (validation, then move). Moving between subscriptions is possible for some resource types but not all, and both subscriptions must be in the same Microsoft Entra tenant. The move locks both source and target resource groups (you cannot create, delete, or update resources in those groups; lock can last up to four hours). A move changes the resource's resource ID but not its location. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Resource groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) — managing resource groups in the portal and CLI
- [Use tags to organize Azure resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) — tag syntax, limits, and best practices
- [Tag inheritance with Azure Policy](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-policies) — built-in Policy definitions for tag inheritance
- [Lock resources to prevent changes](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources) — CanNotDelete and ReadOnly locks
- [Control plane and data plane operations](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/control-plane-and-data-plane) — what locks protect
- [Move resources to a new resource group or subscription](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/move-resource-group-and-subscription) — move validation and resource-type support
- [Organize resources with management groups](https://learn.microsoft.com/en-us/azure/governance/management-groups/overview) — management-group hierarchy and scope inheritance
- [Microsoft.Resources/resourceGroups](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups) — Bicep/ARM template reference
- [Microsoft.Authorization/locks](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/locks) — Bicep/ARM template reference for locks
- [az group](https://learn.microsoft.com/en-us/cli/azure/group) — CLI commands for resource groups
- [az lock](https://learn.microsoft.com/en-us/cli/azure/lock) — CLI commands for locks
- [az account management-group](https://learn.microsoft.com/en-us/cli/azure/account/management-group) — CLI commands for management groups

## Check yourself

<details>
<summary>Answers</summary>

1. **A resource group in West US contains a storage account. You set the storage account's location to East US. What happens?**  
   The deployment succeeds. The resource group's location is metadata only and does not constrain the resources inside. The storage account is created in East US, and the resource group metadata stays in West US.

2. **A resource group has the tag `environment=production`. You deploy a storage account into that resource group without setting the account's `tags` property. What tags does the storage account have?**  
   None. Tags do not inherit automatically. If you want the storage account to have the `environment=production` tag, you must set it in the account's `tags` property, or use Azure Policy to apply tag inheritance.

3. **A resource group has a CanNotDelete lock. You try to change a storage account's SKU inside that group. What happens?**  
   The SKU change succeeds. CanNotDelete allows reads and updates; it only prevents deletion. If the resource group had a ReadOnly lock, the SKU change would be blocked.

4. **A storage account has a ReadOnly lock. You upload a blob to a container in that account. What happens?**  
   The upload succeeds. ReadOnly locks apply to the control plane (Azure Resource Manager operations on the storage account resource), not the data plane (blob operations).

5. **You move a storage account from one resource group to another in the same subscription. Does the storage account's location change?**  
   No. Moving a resource between resource groups (or subscriptions) changes which container the resource belongs to, but it does not change the resource's location. The storage account stays in the same Azure region.

</details>

## Takeaways

- Resource groups are deployed at subscription scope and contain resources, but the resource group's location is metadata only and does not constrain the resources inside.
- Tags on a resource group do not automatically apply to the resources inside; tag inheritance requires the built-in Policy "Inherit a tag from the resource group".
- CanNotDelete locks allow updates but prevent deletion; ReadOnly locks prevent all writes and block operations like `listKeys`; both apply to the control plane only. To create or delete locks, you need Owner or User Access Administrator.
- Locks inherit downward: a lock on a resource group applies to every resource in the group, and a lock on a subscription applies to every resource group and resource in the subscription.
- Subscriptions are the billing and administrative boundary; management groups organize subscriptions into a hierarchy for Policy and RBAC inheritance.
- Moving resources between resource groups or subscriptions changes the resource ID but not its location. Moving between subscriptions requires both subscriptions to be in the same Microsoft Entra tenant, and the move locks both source and target resource groups (up to four hours).

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-rg-at-subscription-scope | WRITE | S | Declare a resource group at subscription scope with course tags |
| 2 | e02-tags-are-not-inherited | PREDICT | S | Predict resource tags when the resource group is tagged |
| 3 | e03-cannotdelete-lock | WRITE | S | Set a CanNotDelete lock on a resource group |
| 4 | e04-lock-wrong-scope | BUG | S | Find and fix a lock at the wrong scope or level |
| 5 | e05-subscriptions-and-management-groups | EXPLAIN | S | Explain subscription and management-group scope and move boundaries |
| 6 | e06-list-management-groups | CLI | S | Read-only mocked `az account management-group` commands |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-rg-with-tags | Declare a resource group with tags at subscription scope |
| 2 | r02-lock-a-resource-group | Set a lock on a resource group and verify inheritance |
