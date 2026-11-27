targetScope = 'resourceGroup'

@description('Azure region for the vault, identity, and storage account.')
param location string = resourceGroup().location

@description('Log Analytics workspace resource id for Key Vault AuditEvent logs (Security L1 Azure.KeyVault.Logs).')
param logAnalyticsWorkspaceId string = resourceId('Microsoft.OperationalInsights/workspaces', 'lagb-a06-e04-logs')

@description('Course tags from SPEC 10.2.')
param tags object = {
  course: 'LearnAzureByGrinding'
  unit: 'a06-storage-accounts'
  exercise: 'a06-e04-customer-managed-key'
  owner: 'n8'
  expires: '2026-12-31T00:00:00Z'
}

output location string = location
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId
output tags object = tags

// ---- Your resources go below this line. ----
