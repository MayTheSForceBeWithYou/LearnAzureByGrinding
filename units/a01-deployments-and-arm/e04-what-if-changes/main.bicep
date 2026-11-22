@description('Azure region for the resource.')
param location string = resourceGroup().location

param existingName string = 'st${uniqueString(resourceGroup().id)}'

resource existing 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: existingName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
    properties: {
      supportsHttpsTrafficOnly: true
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      allowSharedKeyAccess: false
    }
}

resource extra 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st2${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
    properties: {
      supportsHttpsTrafficOnly: true
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      allowSharedKeyAccess: false
    }
}
