targetScope = 'resourceGroup'

// ---- Your resources go below this line. ----
@description('Azure region for the resource.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(24)
@description('Storage account name (3-24 chars).')
param accountName string = 'stlagbstu001'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param skuName string = 'Standard_LRS'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
    properties: {
      supportsHttpsTrafficOnly: true
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      allowSharedKeyAccess: false
    }
}

output accountName string = storage.name
