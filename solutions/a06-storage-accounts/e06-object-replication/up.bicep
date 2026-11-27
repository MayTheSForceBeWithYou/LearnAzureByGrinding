targetScope = 'resourceGroup'

@description('Azure region for the lab.')
param location string = resourceGroup().location

@description('Course tags from lab-up (New-LabTags).')
param tags object = {}

output location string = location

module exercise 'main.bicep' = {
  name: 'lagb-a06-e06-object-replication'
  params: {
    location: location
    tags: tags
  }
}
