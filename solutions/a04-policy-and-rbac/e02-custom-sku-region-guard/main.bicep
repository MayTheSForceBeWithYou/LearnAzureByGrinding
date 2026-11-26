targetScope = 'subscription'

@description('Locations the lab guard allows.')
param allowedLocations array = [
  'eastus'
]

@description('VM SKUs the lab guard allows (B-series).')
param allowedVmSkus array = [
  'Standard_B1s'
  'Standard_B2s'
]

output allowedLocations array = allowedLocations
output allowedVmSkus array = allowedVmSkus

// ---- Your resources go below this line. ----

resource skuRegionGuard 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'lagb-sku-region-guard'
  properties: {
    displayName: 'Lab SKU and region guard'
    description: 'Deny lab resources outside the allowed locations, and deny VMs or scale sets whose SKU is not on the B-series allow-list.'
    mode: 'Indexed'
    policyType: 'Custom'
    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'Azure regions the lab may use.'
          strongType: 'location'
        }
      }
      allowedVmSkus: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed VM SKUs'
          description: 'Virtual machine SKUs the lab may use.'
        }
      }
    }
    policyRule: {
      if: {
        anyOf: [
          {
            allOf: [
              {
                field: 'location'
                notIn: '[parameters(\'allowedLocations\')]'
              }
              {
                field: 'location'
                notEquals: 'global'
              }
            ]
          }
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Compute/virtualMachines'
              }
              {
                field: 'Microsoft.Compute/virtualMachines/sku.name'
                notIn: '[parameters(\'allowedVmSkus\')]'
              }
            ]
          }
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Compute/virtualMachineScaleSets'
              }
              {
                field: 'Microsoft.Compute/virtualMachineScaleSets/sku.name'
                notIn: '[parameters(\'allowedVmSkus\')]'
              }
            ]
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource skuRegionAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lagb-sku-region-guard'
  properties: {
    displayName: 'Lab SKU and region guard'
    policyDefinitionId: skuRegionGuard.id
    parameters: {
      allowedLocations: {
        value: allowedLocations
      }
      allowedVmSkus: {
        value: allowedVmSkus
      }
    }
  }
}
