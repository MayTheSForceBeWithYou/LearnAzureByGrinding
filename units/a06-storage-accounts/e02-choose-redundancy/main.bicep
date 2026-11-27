targetScope = 'resourceGroup'

@description('Neighbour only. Predict read/write availability into ANSWER.md. Do not change this file.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'e02')}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a06-storage-accounts'
    exercise: 'a06-e02-choose-redundancy'
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
