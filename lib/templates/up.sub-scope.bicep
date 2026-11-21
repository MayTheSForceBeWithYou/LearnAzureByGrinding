// Neutral skeleton for a subscription-scope lab template, deployed by lib/templates/up.sub-scope.ps1
// (see docs/AUTHORING-INFRA.md "Subscription-scope up.ps1"). It declares the parameters the
// reference up.ps1 passes and deploys nothing. The exercise's own Bicep supplies the resources;
// this file must never hold an exercise's solution (the repo is public).
targetScope = 'subscription'

@description('Guardrail tags from up.ps1: the New-LabTags set minus expires, with lifecycle=persistent.')
param guardrailTags object

@description('Budget name; equals .lab-env.json budget.name (default lagb-monthly), which the lab-up budget gate looks for.')
param budgetName string = 'lagb-monthly'

@description('Monthly amount from .lab-env.json budget.amount. Must be > 0.')
@minValue(1)
param amount int = 25

@description('Name of the persistent guardrails resource group up.ps1 created or reused (.lab-env.json guardrails.resourceGroup).')
param guardrailsResourceGroup string = 'lagb-guardrails'

@description('Email address from .lab-env.json budget.contactEmail.')
param contactEmail string

@description('First day of the budget period (first of a month). Pass the original date when redeploying in a later month.')
param startDate string = utcNow('yyyy-MM-01')

// Resources go here, in the exercise's own copy of this file.

output guardrailTags object = guardrailTags
output budgetName string = budgetName
output amount int = amount
output guardrailsResourceGroup string = guardrailsResourceGroup
output contactEmail string = contactEmail
output startDate string = startDate
