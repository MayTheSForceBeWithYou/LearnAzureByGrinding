targetScope = 'resourceGroup'

@description('Azure region for the storage account.')
param location string = resourceGroup().location

@description('Course tags from SPEC 10.2.')
param tags object = {
  course: 'LearnAzureByGrinding'
  unit: 'a06-storage-accounts'
  exercise: 'a06-e01-storage-account-baseline'
  owner: 'n8'
  expires: '2026-12-31T00:00:00Z'
}

output location string = location
output tags object = tags

// ---- Your resources go below this line. ----
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'e01')}'
  location: location
  tags: tags
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
