targetScope = 'resourceGroup'

@description('Azure region for the storage account.')
param location string = resourceGroup().location

@description('SKU name to author (for example Standard_LRS).')
param skuName string = 'Standard_LRS'

@description('Account kind (StorageV2).')
param kind string = 'StorageV2'

@description('Blob access tier (Hot or Cool).')
param accessTier string = 'Hot'

output location string = location
output skuName string = skuName
output kind string = kind
output accessTier string = accessTier

// ---- Your resources go below this line. ----
