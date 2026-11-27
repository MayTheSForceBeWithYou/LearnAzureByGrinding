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
var cryptoUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'lagb-a06-e04-id'
  location: location
  tags: tags
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'e04kv')}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

resource cmk 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: kv
  name: 'lagbcmk'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'wrapKey'
      'unwrapKey'
      'encrypt'
      'decrypt'
    ]
  }
}

resource cryptoRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // identity.properties.principalId is runtime (BCP120); identity.id is known at start and is unique per identity.
  name: guid(kv.id, identity.id, cryptoUserRoleId)
  scope: kv
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', cryptoUserRoleId)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource kvLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'audit'
  scope: kv
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'lagb${uniqueString(resourceGroup().id, 'e04st')}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyvaulturi: kv.properties.vaultUri
        keyname: cmk.name
      }
      identity: {
        userAssignedIdentity: identity.id
      }
      requireInfrastructureEncryption: true
    }
  }
  dependsOn: [
    cryptoRole
  ]
}
