# A00: Bicep language and structure

## Advance organizer

You will write Azure infrastructure as Bicep files that compile to ARM templates. This unit teaches the Bicep language: parameters, variables, resources, modules, outputs, and types. After this unit you can read a Bicep file, explain what each section does, and write a small file that compiles and satisfies a structural test. You do not need prior Azure experience, but you must be comfortable reading code in a C-family language.

After this unit you can:
- Read a Bicep file and identify parameters, variables, resources, modules, and outputs
- Write a Bicep resource with typed parameters and outputs
- Call a module from another Bicep file
- Run `bicep build` and `bicep lint` and fix diagnostics

## Foundations

### What Bicep is

Bicep is a domain-specific language for deploying Azure resources. You write a `.bicep` file that declares what you want to exist. The Bicep CLI compiles that file to an ARM template (JSON), and Azure Resource Manager deploys the JSON. Bicep is declarative, not imperative: it describes the desired end state, not the steps to reach it.

Every Bicep file compiles to exactly one ARM template. The two commands you will use most are `bicep build <file>.bicep` (compile to JSON) and `bicep lint <file>.bicep` (check for common mistakes).

### File structure

A Bicep file has five sections, in any order: **Parameters** (inputs), **Variables** (computed values), **Resources** (Azure resources to create), **Modules** (calls to other Bicep files), and **Outputs** (returned values). No section is required. Resources and modules are where the work happens.

### Parameters

A parameter is an input. The caller supplies a value, and the Bicep file uses it. Parameters have types, and you can constrain them.

```bicep
param storageAccountName string
param location string = resourceGroup().location
param skuName string
```

The `=` syntax provides a default. The caller may omit that parameter, and the default is used. Parameters without defaults are required.

Types include `string`, `int`, `bool`, `object`, `array`, and `securestring` / `secureobject`. Use `securestring` for passwords and keys; Azure redacts them in logs.

You can add decorators to constrain a parameter:

```bicep
@minLength(3)
@maxLength(24)
@description('Storage account name')
param storageAccountName string

@allowed(['Standard_LRS', 'Standard_GRS'])
param skuName string
```

Decorators appear before the `param` line.

### Variables

A variable is a computed value used in the file. It does not cross the file boundary: the caller cannot set it, and it does not appear in outputs unless you explicitly output it.

```bicep
var uniqueSuffix = uniqueString(resourceGroup().id)
var fullName = '${storageAccountName}${uniqueSuffix}'
```

String interpolation uses `${expression}`. The `uniqueString` function produces a deterministic hash; it returns the same string every time for the same input.

### Resources

A resource is an Azure resource to create or update. The syntax is:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: fullName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
}
```

The parts:
- `resource storageAccount` — the symbolic name. You use this name to reference the resource elsewhere in the file.
- `'Microsoft.Storage/storageAccounts@2023-01-01'` — the resource type and API version. This is a literal string. The type is `namespace/type` (sometimes `namespace/parentType/childType`). The API version is a date, and it determines which properties are available.
- `= { ... }` — the resource body. This is the JSON shape of the resource, but written in Bicep syntax. The properties depend on the resource type and API version.

The `name` property is required for every resource. The `location` property is required for most resource types (not for role assignments or Policy, which are control-plane resources).

You reference a resource's properties with dot syntax:

```bicep
output accountId string = storageAccount.id
```

### Modules

A module is a call to another Bicep file. The called file is a Bicep file with parameters and outputs. The calling file passes parameters and can read the outputs.

```bicep
module storage 'storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    skuName: skuName
  }
}
```

The parts:
- `module storage` — the symbolic name.
- `'storage.bicep'` — the path to the module file, relative to the calling file.
- `name: 'storageDeployment'` — the deployment name. Azure records this in the deployment history. It must be unique within the scope.
- `params: { ... }` — the parameters passed to the module.

You reference a module's outputs with dot syntax:

```bicep
output storageEndpoint string = storage.outputs.primaryEndpoint
```

### Outputs

An output is a value returned to the caller. Outputs are typed, and they can reference resources or variables.

```bicep
output accountName string = storageAccount.name
output accountId string = storageAccount.id
```

After deployment, the caller can read these values. In the Azure CLI, `az deployment group show --name <deployment> --query properties.outputs` returns the outputs as JSON.

### The Bicep linter

The Bicep CLI includes a linter that checks for common mistakes. Run it with `bicep lint <file>.bicep`. The linter uses a configuration file, `bicepconfig.json`, which lives at the repository root. The course configuration enables a set of rules at `warning` level. The harness treats warnings as errors: a warning fails the build.

The course linter configuration catches hard-coded locations (`no-hardcoded-location`), unused parameters and variables (`no-unused-params`, `no-unused-vars`), insecure patterns (several rules for secrets and secure parameters), and many other anti-patterns. You will fix linter diagnostics in every unit. Treat a linter failure as a real bug.

### Types and constraints

| Concept | What it controls | Where you use it |
|---------|------------------|------------------|
| Type | The shape of the value (string, int, bool, object, array) | Every parameter, variable, and output |
| Constraint | The allowed values or range (minLength, maxLength, allowed, minValue, maxValue) | Parameters only |
| Secure type | Whether Azure redacts the value in logs (securestring, secureobject) | Parameters that hold passwords or keys |

## Worked example: A storage account with typed parameters

You need a storage account for lab artifacts. The account name must be globally unique, between 3 and 24 characters, and lowercase letters or digits only. The SKU must be `Standard_LRS` or `Standard_GRS`. The location defaults to the resource group's location, but the caller can override it.

Here is a complete Bicep file:

```bicep
@minLength(3)
@maxLength(24)
@description('Storage account name')
param storageAccountName string

@allowed(['Standard_LRS', 'Standard_GRS'])
@description('Storage account SKU')
param skuName string = 'Standard_LRS'

@description('Resource location')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

output accountName string = storageAccount.name
output accountId string = storageAccount.id
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

The reasoning:
1. The name parameter has `minLength` and `maxLength`. The caller cannot pass a name that is too short or too long. The Bicep compiler enforces this at compile time (if the value is a literal) or at deployment time (if the value is dynamic).
2. The SKU parameter uses `@allowed`. The caller must pass one of the two listed values. This prevents the caller from requesting `Premium_LRS` or another SKU.
3. The location parameter has a default. If the caller omits it, the storage account is created in the same location as the resource group.
4. The resource block sets `supportsHttpsTrafficOnly: true`. This is a security baseline: the storage account refuses HTTP requests.
5. The outputs return the account name, the resource ID, and the blob endpoint. The caller can use these values in later steps.

**The plausible wrong reading.** The storage account name must be globally unique. You might expect Bicep to enforce this: if the name is already taken, the compile fails. That is not how it works. Bicep only checks the constraints you write: `minLength`, `maxLength`, `@allowed`. The uniqueness check happens at deployment time, when Azure Resource Manager tries to create the account. If the name is taken, the deployment fails with a conflict error. Bicep does not prevent this at compile time because Bicep does not have access to the Azure control plane; it only knows the syntax and the constraints you declared. To avoid conflicts, use `uniqueString(resourceGroup().id)` to generate a suffix, or let the caller provide a unique name.

## Worked example: Calling a module

The main file calls a storage module:

```bicep
param storageName string
param location string = resourceGroup().location

module storage 'storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageName
    location: location
    skuName: 'Standard_GRS'
  }
}

output storageId string = storage.outputs.accountId
```

The reasoning: The main file accepts `storageName` and passes it as `storageAccountName` to the module. Parameter names in the call must match the module's parameter names; Bicep does not map them automatically. The main file overrides the module's `skuName` default and reads the module's `accountId` output.

**The plausible wrong reading.** You might expect parameters to be inherited automatically if names match. That does not happen. Every module call is explicit: you must pass every parameter the module requires, even if the calling file has a parameter with the same name. Modules are reusable, and the calling file controls what values the module sees.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Parameter vs variable | A parameter is an input the caller provides. A variable is a computed value internal to the file. Variables cannot be set by the caller. |
| Resource symbolic name vs resource name | The symbolic name (e.g., `storageAccount`) is the identifier you use in the Bicep file. The resource name (the `name` property) is the name Azure uses. The symbolic name can be any valid identifier; the resource name must follow Azure naming rules. |
| API version in Bicep vs API version in the portal | Bicep requires an API version in the resource type string (e.g., `@2023-01-01`). The portal does not show API versions in the UI. When you export a resource from the portal, the JSON includes the API version. Use a recent stable version (not a preview version) unless you need a preview feature. |
| Module name vs module symbolic name | The module symbolic name (e.g., `storage`) is the identifier you use in the Bicep file. The `name` property (e.g., `'storageDeployment'`) is the deployment name Azure records. The symbolic name can be any valid identifier; the deployment name must be unique within the scope. |
| Secure parameter vs secure property | A secure parameter (`securestring` or `secureobject`) is redacted in logs. A secure property (e.g., a storage account key) is returned by Azure as a runtime value. To retrieve a secure property, use `listKeys` or another `list*` function. Bicep does not redact resource properties; it only redacts secure parameters. |
| Compile-time iteration vs deployment-time loops | Bicep supports `for` loops that expand at compile time. The compiled JSON contains one copy of the resource for each iteration. There is no deployment-time loop: you cannot loop over the results of a runtime function. If you need to create ten storage accounts, write a `for` loop over a range or an array literal, and Bicep expands it when you run `bicep build`. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Bicep documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) — overview and quickstarts
- [Bicep file structure and syntax](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file) — detailed syntax reference
- [Parameters in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameters) — parameter types, decorators, and defaults
- [Variables in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/variables) — variable syntax and usage
- [Resource declaration in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-declaration) — resource syntax, symbolic names, and API versions
- [Modules in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules) — module syntax and parameter passing
- [Outputs in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/outputs) — output syntax and types
- [Bicep functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions) — built-in functions reference
- [Bicep linter](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter) — linter rules and configuration
- [bicep CLI reference](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli) — `bicep build`, `bicep lint`, and other commands

## Check yourself

<details>
<summary>Answers</summary>

1. **A Bicep file has a parameter with no default. The caller omits that parameter. What happens?**  
   The deployment fails at validation time. Parameters without defaults are required. Azure Resource Manager rejects the deployment before it starts.

2. **You write a resource with symbolic name `vm`. You reference `vm.location` in an output. What value does that output return?**  
   It returns the location property of the deployed resource. If you set `location: 'eastus'` in the resource body, the output returns `'eastus'`. If you set `location: resourceGroup().location`, the output returns the resource group's location.

3. **You write a module call and pass a parameter called `name`. The module file has a parameter called `resourceName`. Does Bicep map `name` to `resourceName`?**  
   No. Bicep does not map parameter names. The module call must use the parameter names the module declares. If the module expects `resourceName`, the calling file must pass `resourceName: <value>`. If the calling file passes `name: <value>`, the module does not see it (unless the module also has a parameter called `name`).

4. **A storage account resource has `kind: 'StorageV2'` and `sku.name: 'Standard_LRS'`. You compile the Bicep file, deploy it, and then change `sku.name` to `'Standard_GRS'` and deploy again. What happens to the storage account?**  
   Azure updates the existing storage account to use the new SKU. The account is not deleted and recreated; the SKU is changed in place. This is an Incremental deployment (the default mode): Azure updates the resource to match the template. If the property cannot be changed in place (for example, the storage account name), Azure would fail the deployment.

5. **You write a Bicep file with a parameter of type `string`. The caller passes an integer. What happens?**  
   The deployment fails at validation time. Bicep is strongly typed. If the parameter is `string`, the caller must pass a string (or a default must supply one). Passing an integer is a type error, and Azure Resource Manager rejects the deployment.

</details>

## Takeaways

- Every Bicep file compiles to exactly one ARM template; Bicep is a language, not a runtime.
- Parameters are inputs, variables are internal, and outputs are returned values; only parameters cross the boundary inward.
- A resource symbolic name is a Bicep identifier; the resource name property is what Azure stores.
- The Bicep linter catches hard-coded locations, unused parameters and variables, and security anti-patterns; treat warnings as errors.
- Modules are Bicep files called from other Bicep files; parameter names in the call must match the module's parameter names.
- Constraints on parameters (`minLength`, `@allowed`) are enforced at deployment time for dynamic values and at compile time for literals.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-file-anatomy | PREDICT | S | Predict the parts of a Bicep file |
| 2 | e02-params-vars-outputs | EXPLAIN | S | Explain parameters, variables, outputs, and types |
| 3 | e03-first-resource | WRITE | S | Write a first resource with parameters and outputs |
| 4 | e04-change-the-sku | MODIFY | S | Change a resource SKU in an existing Bicep file |
| 5 | e05-call-a-module | WRITE | M | Write a module and call it |
| 6 | e06-lint-finding | BUG | S | Find and fix a Bicep linter failure |
| 7 | e07-typed-parameters | WRITE | S | Write typed parameters with constraints |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-params-and-resource | Write a parameter and a resource from memory |
| 2 | r02-outputs | Write outputs that reference a resource |
| 3 | r03-module-call | Write a module call with parameter passing |
