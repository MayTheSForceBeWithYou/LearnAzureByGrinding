# a00-e02-params-vars-outputs

## Parameter vs variable
`location` and `namePrefix` are parameters: the caller can set them. `accountName` is a variable: it is computed in the file and the caller cannot set it.

## Why the output is typed
`accountId` is declared `output accountId string`. Bicep outputs are typed. The value is `storage.id`, which is a string resource id.

## What @secure does
`@secure()` is a decorator you put on a `string` or `object` parameter (or output). ARM redacts that value in logs. It is not a type. This file has no secure parameter; a password or key would use `@secure()`, not a `securestring` type (that type does not exist in Bicep).
