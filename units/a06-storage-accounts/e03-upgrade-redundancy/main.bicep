targetScope = 'resourceGroup'

@description('Azure region for the storage account.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'e03')}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a06-storage-accounts'
    exercise: 'a06-e03-upgrade-redundancy'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
  }
}
