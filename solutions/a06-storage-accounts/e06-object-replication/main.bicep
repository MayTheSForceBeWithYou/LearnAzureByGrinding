targetScope = 'resourceGroup'

@description('Azure region for both storage accounts.')
param location string = resourceGroup().location

@description('Course tags from SPEC 10.2. lab-up overwrites these with New-LabTags.')
param tags object = {
  course: 'LearnAzureByGrinding'
  unit: 'a06-storage-accounts'
  exercise: 'a06-e06-object-replication'
  owner: 'n8'
  expires: '2026-12-31T00:00:00Z'
}

output location string = location
output tags object = tags

// ---- Your resources go below this line. ----
resource sourceAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagbsrc${uniqueString(resourceGroup().id, 'src')}'
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

resource destAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagbdst${uniqueString(resourceGroup().id, 'dst')}'
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

resource sourceBlobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sourceAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
      retentionInDays: 7
    }
  }
}

resource destBlobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: destAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
  }
}

resource sourceContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: sourceBlobs
  name: 'src'
  properties: {
    publicAccess: 'None'
  }
}

resource destContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: destBlobs
  name: 'dst'
  properties: {
    publicAccess: 'None'
  }
}

resource destPolicy 'Microsoft.Storage/storageAccounts/objectReplicationPolicies@2023-05-01' = {
  parent: destAccount
  name: 'default'
  properties: {
    sourceAccount: sourceAccount.id
    destinationAccount: destAccount.id
    rules: [
      {
        sourceContainer: sourceContainer.name
        destinationContainer: destContainer.name
      }
    ]
  }
}

module sourcePolicy 'source-orp.bicep' = {
  name: 'lagb-a06-e06-source-orp'
  params: {
    sourceAccountName: sourceAccount.name
    sourceAccountId: sourceAccount.id
    destAccountId: destAccount.id
    #disable-next-line what-if-short-circuiting
    policyId: destPolicy.properties.policyId
    ruleId: destPolicy.properties.rules[0].ruleId
    sourceContainerName: sourceContainer.name
    destContainerName: destContainer.name
  }
}
