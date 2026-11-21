// Selftest fixture: explain what this template outputs.
@description('Short prefix for lab names.')
param prefix string = 'lagb'

output groupName string = '${prefix}-demo'
