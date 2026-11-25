@description('Azure region for the resource.')
param location string = resourceGroup().location

@description('Storage account name.')
param storageName string = 'n8deploy20261122'

@description('Storage account SKU name.')
param storageSKU string = 'Standard_GRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
  }
}
