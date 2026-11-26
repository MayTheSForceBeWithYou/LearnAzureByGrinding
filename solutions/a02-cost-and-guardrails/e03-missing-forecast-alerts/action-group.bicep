@description('Email the budget alerts go to.')
param contactEmail string = 'student@example.com'

@description('Action groups use the Global region.')
param location string = 'global'

@description('Tags for the action group.')
param tags object = {}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'lagb-budget-ag'
  location: location
  tags: tags
  properties: {
    groupShortName: 'lagbbudg'
    enabled: true
    emailReceivers: [
      {
        name: 'budget-email'
        emailAddress: contactEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output id string = actionGroup.id
