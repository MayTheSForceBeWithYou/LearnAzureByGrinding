targetScope = 'resourceGroup'

@description('Name of the CanNotDelete lock.')
param lockName string = 'lagb-cannotdelete'

@description('Notes stored on the lock.')
param notes string = 'Intended to protect the resource group, not the subscription.'

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: lockName
  properties: {
    level: 'CanNotDelete'
    notes: notes
  }
}
