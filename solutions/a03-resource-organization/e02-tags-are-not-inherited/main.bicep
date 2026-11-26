targetScope = 'subscription'

@description('Azure region for the resource group and the nested storage account.')
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'lagb-a03-e02-example'
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-e02-tags-are-not-inherited'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}

module storageMod 'storage.bicep' = {
  name: 'lagb-a03-e02-storage'
  scope: rg
  params: {
    location: location
    tags: union(rg.tags, { purpose: 'predict' })
  }
}
