# a00-e01-file-anatomy

## Parameters
`location` (string, default `resourceGroup().location`) and `namePrefix` (string, default `lagb`, constrained 3–9 characters so `st` + prefix + `uniqueString` (13 characters) stays within the storage-account 24-character max).

## Variables
`accountName` concatenates `st`, `namePrefix`, and `uniqueString(resourceGroup().id)`.

## Resources
One resource, symbolic name `storage`, type `Microsoft.Storage/storageAccounts@2023-05-01`.

## Outputs
`accountName` (the deployed account name) and `blobEndpoint` (the blob primary endpoint).
