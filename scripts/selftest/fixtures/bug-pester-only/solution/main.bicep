// Selftest fixture: lint-clean [BUG] whose defect is only visible to Pester.
@description('Label used in the output.')
param label string = 'lab'

output label string = label
output ready bool = true
