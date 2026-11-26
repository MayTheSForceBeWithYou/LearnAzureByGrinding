targetScope = 'resourceGroup'

// ---- Your resources go below this line. ----
@description('Azure region for the resource.')
param location string = resourceGroup().location

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a02-cost-and-guardrails'
    exercise: 'a02-r01-course-tags'
    expires: '2026-12-02T00:00:00Z'
    owner: 'student'
  }
    properties: {
      supportsHttpsTrafficOnly: true
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      allowSharedKeyAccess: false
    }
}
