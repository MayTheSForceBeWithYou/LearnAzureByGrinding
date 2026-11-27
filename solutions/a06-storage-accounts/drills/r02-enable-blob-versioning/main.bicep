targetScope = 'resourceGroup'

@description('Azure region for the storage account.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'r02')}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a06-storage-accounts'
    exercise: 'a06-r02-enable-blob-versioning'
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

// ---- Your resources go below this line. ----
resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
      retentionInDays: 7
    }
  }
}
