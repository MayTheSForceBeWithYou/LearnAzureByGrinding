// Selftest fixture: one storage account that only accepts HTTPS, plus its name as an output.
targetScope = 'resourceGroup'

// ---- Your resources go below this line. ----
@description('Region for the storage account.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
  }
}

output storageAccountName string = storage.name
