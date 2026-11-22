@description('Azure region for the resource.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(9)
param namePrefix string = 'lagb'

var accountName = 'st${namePrefix}${uniqueString(resourceGroup().id)}'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
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

output accountId string = storage.id
