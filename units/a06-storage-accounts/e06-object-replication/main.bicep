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
