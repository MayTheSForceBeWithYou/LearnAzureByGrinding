# a01-e06-complete-mode

## What was wrong
The `dropped` storage account was declared `= if (false) { ... }`, so ARM compiled a `condition` of false.

## Mechanism
In Complete mode a resource whose condition is false is not deployed and is deleted if it exists. Incremental would leave an existing account alone; Complete would remove it because it is not in the deployed set.

## Which tool showed it
The Pester test `deploys two storage accounts and none are condition:false` (and reading the `if (false)` in `main.bicep`).
