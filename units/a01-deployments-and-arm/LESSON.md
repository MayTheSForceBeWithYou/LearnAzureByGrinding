# A01: Deployments, what-if, and ARM JSON

> Length: this lesson uses the A01 450-line exception (SPEC 7.1).

## Advance organizer

You have written Bicep files that compile to ARM templates. This unit teaches deployments: how to place a deployment at resource-group, subscription, management-group, or tenant scope; how to choose Incremental vs Complete mode; how to validate and preview changes with what-if; and how to read, modify, compile, and decompile ARM JSON. You will not deploy to Azure in this unit; that starts in A02. All validation and what-if work uses fixtures.

You must already know: **A00** (Bicep language and structure).

After this unit you can:
- Set the target scope of a Bicep deployment
- Explain the difference between Incremental and Complete mode
- Read and modify an ARM template in JSON
- Compile Bicep to ARM JSON and decompile ARM JSON to Bicep
- Predict what a what-if operation shows and what a compile/decompile round trip rewrites

## Foundations

### Deployment scopes

Every deployment targets one of four scopes:

| Scope | What you deploy | Example resources |
|-------|-----------------|-------------------|
| Resource group | Resources that live in a resource group (most resources) | Storage accounts, virtual machines, networks |
| Subscription | Resources that span a subscription or have subscription scope | Resource groups, Policy assignments, role assignments at subscription scope |
| Management group | Policy and role assignments at management-group scope | Policy assignments, role assignments at management-group scope |
| Tenant | Resources at the tenant root | Management groups, tenant-level role assignments |

A Bicep file declares its scope with `targetScope` at the top:

```bicep
targetScope = 'resourceGroup'  // default; can be omitted
```

```bicep
targetScope = 'subscription'
```

```bicep
targetScope = 'managementGroup'
```

```bicep
targetScope = 'tenant'
```

If you omit `targetScope`, the default is `resourceGroup`. Most deployments are resource-group scoped.

To deploy a resource group from a subscription-scoped file:

```bicep
targetScope = 'subscription'

param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'my-rg'
  location: location
}
```

To deploy resources into that resource group from the same file, use a module:

```bicep
module storage 'storage.bicep' = {
  name: 'storageDeployment'
  scope: rg
  params: {
    storageAccountName: 'myaccount'
  }
}
```

The `scope` property tells Bicep where to deploy the module. The module file must have `targetScope = 'resourceGroup'` (or omit it, since that is the default).

### Incremental vs Complete mode

A deployment has a mode: **Incremental** or **Complete**. The mode determines what Azure does with resources that exist in the resource group but are not in the template.

| Mode | What happens to resources not in the template |
|------|-----------------------------------------------|
| Incremental | Azure leaves them alone. The deployment adds or updates resources; it does not delete anything. The entire resource definition is redeployed, so properties you omit may reset to defaults (for example, subnets left out of a VNet definition are removed). |
| Complete | Azure deletes them, except: Complete never deletes the resource group itself, locks block deletions, only resource types that support complete-mode deletion are removed, and a resource whose `condition` is false is deleted. |

Incremental is the default. Complete is opt-in, and it is dangerous: if you forget to include a resource in the template, Azure deletes it. Complete mode is used for environments where the template is the single source of truth, and anything not in the template is unwanted. It is not used for production environments where multiple teams manage different resources in the same resource group.

Complete mode only applies to resource-group-scoped deployments. Subscription, management-group, and tenant deployments are always Incremental.

You set the mode in the deployment command, not in the Bicep file. In the Azure CLI:

```bash
az deployment group create \
  --resource-group my-rg \
  --template-file main.bicep \
  --mode Incremental
```

or

```bash
az deployment group create \
  --resource-group my-rg \
  --template-file main.bicep \
  --mode Complete
```

Bicep does not have a `mode` keyword. The mode is a deployment setting, not a template setting.

### ARM templates

An ARM template is a JSON document that describes Azure resources. Bicep compiles to ARM JSON. The JSON has this structure:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": { ... },
  "variables": { ... },
  "resources": [ ... ],
  "outputs": { ... }
}
```

The `$schema` and `contentVersion` are required. The schema URL depends on the target scope:

| Scope | Schema URL |
|-------|------------|
| Resource group | `https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#` |
| Subscription | `https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#` |
| Management group | `https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#` |
| Tenant | `https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#` |

You do not write the schema URL yourself; `bicep build` generates it based on the `targetScope`.

A resource in ARM JSON looks like this:

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "apiVersion": "2023-01-01",
  "name": "[parameters('storageAccountName')]",
  "location": "[parameters('location')]",
  "sku": {
    "name": "[parameters('skuName')]"
  },
  "kind": "StorageV2",
  "properties": {
    "supportsHttpsTrafficOnly": true
  }
}
```

The `[...]` syntax is ARM expression syntax. `[parameters('name')]` reads a parameter. `[variables('name')]` reads a variable. `[resourceId('Microsoft.Storage/storageAccounts', 'myaccount')]` computes a resource ID.

Bicep is more concise: you write `storageAccountName` instead of `[parameters('storageAccountName')]`. The Bicep compiler generates the ARM expressions.

### Compiling and decompiling

You compile Bicep to ARM JSON with `bicep build`:

```bash
bicep build main.bicep
```

This creates `main.json` in the same directory. The JSON is what Azure Resource Manager deploys.

You decompile ARM JSON to Bicep with `bicep decompile`:

```bash
bicep decompile main.json
```

This creates `main.bicep` in the same directory. The Bicep file is not guaranteed to be identical to the original. Decompile is best-effort: it reconstructs Bicep syntax from JSON, but some information is lost or rewritten.

Decompile is useful when you export a deployment from the portal or a live resource group and want to edit it in Bicep. You decompile, review the generated Bicep, and then maintain it as Bicep.

### Validation and what-if

Before you deploy, you can validate the template and preview the changes.

**Validation** and **what-if** both require Azure sign-in. For group-scope deployments, they require an existing resource group. Neither is offline.

**Validation** checks that the template is well-formed, required parameters are provided, and runs provider checks and Azure Policy deny rules. At the default `--validation-level Provider` (Azure CLI 2.76+), it also checks RBAC permissions. Run it with:

```bash
az deployment group validate \
  --resource-group my-rg \
  --template-file main.bicep
```

If validation succeeds, the command returns a validation result (not the compiled template). If it fails, it returns an error message. Validation does not guarantee the deployment will succeed.

**What-if** shows what Azure will do if you deploy the template. It compares the template to the current state of the resource group and predicts creates, updates, and deletes. Run it with:

```bash
az deployment group what-if \
  --resource-group my-rg \
  --template-file main.bicep
```

What-if output uses symbols:

| Symbol | Change type | Meaning |
|--------|-------------|---------|
| `+` | Create | Azure will create this resource |
| `-` | Delete | Azure will delete this resource (Complete mode only) |
| `~` | Modify | Azure will update this resource |
| `!` | Deploy | Azure will deploy this resource |
| `=` | NoChange | Azure will not change this resource (it already matches) |
| `*` | Ignore | Resource exists but is not in the template (Incremental mode) |
| `x` | Unsupported / NoEffect | Provider does not support what-if, or property change has no effect |

What-if also shows property-level changes for Modify operations.

What-if is not perfect. It is a prediction, not a guarantee. What-if has the same permission requirements as a deployment. It does not catch all deployment failures.

### Exporting a deployment

After a deployment completes, you can export the template Azure used. The exported template is ARM JSON, not Bicep. You can decompile it to Bicep if you want to edit it.

Export with:

```bash
az deployment group export \
  --resource-group my-rg \
  --name <deployment-name>
```

The result is JSON. Save it to a file:

```bash
az deployment group export \
  --resource-group my-rg \
  --name <deployment-name> \
  > exported.json
```

Then decompile:

```bash
bicep decompile exported.json
```

You can also export a live resource group (not a deployment):

```bash
az group export --resource-group my-rg > rg-export.json
```

This exports all resources in the resource group as an ARM template. It is not a deployment template; it is a snapshot of the current state. You decompile it the same way.

Exporting is useful when you want to capture what is running in Azure and convert it to Bicep for version control. The exported JSON often needs cleanup: it includes runtime values (like resource IDs) that should be replaced with parameters, and it may include resources you do not want to manage in Bicep.

## Worked example: A subscription-scoped deployment that creates a resource group

You need to create a resource group and deploy a storage account into it. The Bicep file must be subscription-scoped.

**main.bicep:**

```bicep
targetScope = 'subscription'

@description('Resource group name')
param rgName string

@description('Resource group location')
param location string = 'eastus'

@description('Storage account name')
param storageAccountName string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module storage 'storage.bicep' = {
  name: 'storageDeployment'
  scope: rg
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

output resourceGroupId string = rg.id
output storageAccountId string = storage.outputs.accountId
```

**storage.bicep:**

```bicep
@description('Storage account name')
param storageAccountName string

@description('Resource location')
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

output accountId string = storageAccount.id
```

The reasoning:
1. The main file has `targetScope = 'subscription'`. This tells Bicep that the deployment targets a subscription, not a resource group.
2. The main file creates a resource group with `Microsoft.Resources/resourceGroups`. This resource type is only available at subscription scope. If the main file were resource-group scoped, this would fail.
3. The main file calls a module with `scope: rg`. This deploys the module into the resource group that was just created. The module file is resource-group scoped (the default), so it can deploy a storage account.
4. The module runs after the resource group is created. Bicep infers the dependency: the module references `rg`, so Bicep deploys `rg` first.

**The plausible wrong reading.** You might expect the main file to deploy the storage account directly, without a module. You could write:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  scope: rg
  // ...
}
```

This does not work. A storage account is a resource-group-scoped resource. You cannot deploy it directly from a subscription-scoped file, even with `scope: rg`. Non-extension resources you deploy must match the file's target scope. The `scope` property is valid on modules, on `existing` resources, and on extension resources (locks, role assignments, Policy assignments), but not on non-extension resources you are deploying. To deploy a resource at a different scope, use a module. The module file has the correct target scope, and the calling file sets the module's scope with `scope: rg`.

## Worked example: What a what-if output means

You have a resource group with one storage account: `myaccount`, SKU `Standard_LRS`. You prepare a template that includes the same storage account but changes the SKU to `Standard_GRS`, and adds a second storage account, `myaccount2`. You run what-if.

A raw `az deployment group what-if` transcript for this scenario is not in the lesson yet. It will be added from a live capture, and that same capture is the fixture for e04. Until then, use the symbol table and the reasoning below.

What-if uses symbols to indicate change types: `+` (Create), `-` (Delete), `~` (Modify), `!` (Deploy), `=` (NoChange), `*` (Ignore), and `x` (Unsupported / NoEffect). Create shows the full resource body that will be created. Delete shows the full resource body that will be deleted. Modify shows a property-level diff: which properties will change, and the old and new values. NoChange and Ignore show only the resource identifier.

The reasoning for this example: The first account exists in the resource group, and the template changes the SKU. What-if will show `~` (Modify) and the property diff. The second account does not exist, so what-if will show `+` (Create) with the full resource body. In Incremental mode (the default), resources not in the template show as `*` (Ignore). In Complete mode, what-if would show `-` (Delete) with the full resource body for any resource in the resource group that is not in the template.

**The plausible wrong reading.** You might expect what-if to show only the action symbol for Create, without the full body. That is not true. Create prints the full `after` body, Delete prints the full `before` body, and only Modify shows a diff. To see what will be created or deleted, read the what-if output, not just the template.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Target scope vs deployment scope | The target scope is the scope the Bicep file declares with `targetScope` (or defaults to `resourceGroup`). The deployment scope is the scope you pass to the deployment command (`--resource-group`, `--subscription`, etc.). They must match. A resource-group-scoped file cannot be deployed at subscription scope. |
| Incremental mode vs Complete mode | Incremental leaves resources not in the template alone. Complete deletes them. Incremental is the default. Complete is opt-in and only applies to resource-group deployments. |
| Validation vs what-if | Both are online ARM calls that require Azure sign-in (and for group-scope deployments, an existing resource group). Validation checks that the template is well-formed and runs provider and Policy checks. What-if predicts creates, updates, and deletes. What-if is slower because it compares the template to the current state. |
| Compile vs decompile | Compile turns Bicep into ARM JSON. Decompile turns ARM JSON into Bicep. Compile is semantics-preserving; comments are dropped. Decompile is best-effort: it may rewrite (for example, add parentheses), and the decompiled Bicep is usually valid but may need cleanup. |
| Export a deployment vs export a resource group | Exporting a deployment returns the template Azure used in that deployment. Exporting a resource group returns a snapshot of the current state as a template. The resource group export is generated from live resources and often needs cleanup. |
| Module scope vs target scope | A module's target scope is the scope declared in the module file (`targetScope = 'resourceGroup'`). The module's deployment scope is the scope set by the calling file (`scope: rg`). The two must be compatible. You cannot deploy a resource-group-scoped module at subscription scope without specifying a resource group in the `scope` property. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Deployment scopes in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-subscription) — subscription, management group, and tenant deployments
- [Resource group deployments](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-resource-group) — resource-group scope (the default)
- [Deployment modes](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-modes) — Incremental vs Complete
- [ARM template structure](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/syntax) — JSON syntax and schema
- [Decompile ARM JSON to Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/decompile) — `bicep decompile` and what it rewrites
- [Deploy what-if operation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-what-if) — preview changes before deployment
- [Validate ARM templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#validate-template) — `az deployment group validate`
- [Export templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/export-template-portal) — export a deployment or resource group
- [az deployment group](https://learn.microsoft.com/en-us/cli/azure/deployment/group) — CLI commands for resource-group deployments
- [az deployment sub](https://learn.microsoft.com/en-us/cli/azure/deployment/sub) — CLI commands for subscription deployments

## Check yourself

<details>
<summary>Answers</summary>

1. **You write a Bicep file with no `targetScope` line. You run `az deployment group create` and pass `--resource-group my-rg`. Does the deployment succeed?**  
   Yes. The default target scope is `resourceGroup`. If you omit `targetScope`, Bicep assumes resource-group scope, and the deployment command matches.

2. **You write a Bicep file with `targetScope = 'subscription'`. You run `az deployment group create` and pass `--resource-group my-rg`. What happens?**  
   The deployment fails. You cannot deploy a subscription-scoped file with `az deployment group create`. You must use `az deployment sub create` and pass `--location` (not `--resource-group`).

3. **A resource group contains two storage accounts: `account1` and `account2`. You deploy a template in Incremental mode that includes only `account1` (with no changes). What happens to `account2`?**  
   Nothing. Incremental mode leaves resources not in the template alone. `account2` remains in the resource group.

4. **The same resource group and template, but you deploy in Complete mode. What happens to `account2`?**  
   Azure deletes it. Complete mode deletes resources not in the template. Only `account1` remains.

5. **You run what-if on a template. What-if predicts a modify operation on a storage account SKU property (changing from one SKU to another). You deploy the template. What happens to the storage account?**  
   Azure updates the SKU in place. The account is not deleted and recreated; the SKU property is changed. What-if correctly predicted the update.

</details>

## Takeaways

- A Bicep file declares its target scope with `targetScope`; the default is `resourceGroup`.
- Incremental mode leaves resources not in the template alone; Complete mode deletes them.
- What-if predicts creates, updates, and deletes by comparing the template to the current state; it is not a guarantee.
- Compile is semantics-preserving; comments are dropped. Decompile is best-effort and may rename symbolic names or rewrite logical expressions.
- To deploy a non-extension resource at a different scope, use a module with the `scope` property; `scope` is valid on modules, `existing` resources, and extension resources.
- ARM JSON uses `[parameters('name')]` and `[variables('name')]` syntax; Bicep generates these expressions when you compile.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-scopes-and-mode | EXPLAIN | S | Explain deployment scopes and Incremental vs Complete |
| 2 | e02-resource-group-scope | WRITE | S | Write a resource-group-scoped Bicep deployment |
| 3 | e03-modify-arm-json | MODIFY | M | Modify an existing ARM template |
| 4 | e04-what-if-changes | WHATIF | S | Predict what-if change types from a fixture |
| 5 | e05-decompile-round-trip | PREDICT | S | Predict what a compile/decompile round trip rewrites |
| 6 | e06-complete-mode | BUG | S | Find and fix a Complete-mode deployment |
| 7 | e07-change-the-scope | MODIFY | M | Change an existing Bicep file to a new deployment scope |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-set-target-scope | Set targetScope and deploy a resource at that scope |
| 2 | r02-edit-arm-json | Read and modify ARM JSON by hand |
