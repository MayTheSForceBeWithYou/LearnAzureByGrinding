# a99-e02-https-bug

## What was wrong
The account accepted plain HTTP.

## Mechanism
supportsHttpsTrafficOnly was false, so requests over http:// were allowed.

## Which tool showed it
PSRule rule Azure.Storage.SecureTransfer.
