targetScope = 'resourceGroup'

// ---- Your resources go below this line. ----
@description('Azure region for the resource.')
param location string = resourceGroup().location

module storageModule 'storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
  }
}

output accountId string = storageModule.outputs.accountId
