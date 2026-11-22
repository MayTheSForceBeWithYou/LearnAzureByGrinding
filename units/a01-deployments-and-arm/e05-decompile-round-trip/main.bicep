// Course original. Comments are load-bearing for this exercise.
@description('Azure region for the resource.')
param location string = resourceGroup().location

var suffix = uniqueString(resourceGroup().id)
var fullName = 'st${suffix}'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: fullName
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

output accountName string = storage.name
