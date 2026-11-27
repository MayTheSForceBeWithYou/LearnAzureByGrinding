targetScope = 'resourceGroup'

@description('Source storage account name.')
param sourceAccountName string = 'lagbsrce06orp'

@description('Full resource id of the source account.')
param sourceAccountId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/lagbsrce06orp'

@description('Full resource id of the destination account.')
param destAccountId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/lagbdste06orp'

@description('Destination object-replication policy id (filled in by Azure on the destination policy).')
param policyId string = '00000000-0000-0000-0000-000000000001'

@description('Destination object-replication rule id.')
param ruleId string = '00000000-0000-0000-0000-000000000002'

@description('Source container name.')
param sourceContainerName string = 'src'

@description('Destination container name.')
param destContainerName string = 'dst'

resource sourceAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: sourceAccountName
}

resource sourcePolicy 'Microsoft.Storage/storageAccounts/objectReplicationPolicies@2023-05-01' = {
  parent: sourceAccount
  name: policyId
  properties: {
    sourceAccount: sourceAccountId
    destinationAccount: destAccountId
    rules: [
      {
        ruleId: ruleId
        sourceContainer: sourceContainerName
        destinationContainer: destContainerName
      }
    ]
  }
}
