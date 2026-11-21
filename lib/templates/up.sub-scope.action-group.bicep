// Reference module for lib/templates/up.sub-scope.bicep: the A02 budget's action group.
// Deployed into the persistent guardrails resource group (module scope set by the caller).
// Action groups are global resources, so location is 'global'.

@description('Action group name.')
param name string

@description('Short name shown in notifications (max 12 characters).')
@maxLength(12)
param shortName string

@description('Email address that receives budget alerts.')
param contactEmail string

@description('Tags for the action group: the guardrail tags (lifecycle=persistent, no expires).')
param tags object

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: name
  location: 'global'
  tags: tags
  properties: {
    enabled: true
    groupShortName: shortName
    emailReceivers: [
      {
        name: 'owner-email'
        emailAddress: contactEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
