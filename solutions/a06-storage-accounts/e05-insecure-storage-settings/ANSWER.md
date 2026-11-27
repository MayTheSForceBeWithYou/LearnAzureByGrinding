# a06-e05-insecure-storage-settings

## What was wrong
`minimumTlsVersion` was `TLS1_0` and `allowBlobPublicAccess` was `true`. Shared-key access was already off.

## Mechanism
TLS 1.0 is below the platform floor this course uses (TLS 1.2). Anonymous blob public access lets a container be opened to the internet without a key or Entra identity. Both are properties on the storage account; fixing them is a `minimumTlsVersion: 'TLS1_2'` and `allowBlobPublicAccess: false` edit, not a SKU change.

## Which tool showed it
PSRule Security L1 reports **`Azure.Storage.MinTLS`** on the starter (`ExpectDiagnostics`). `Azure.Storage.BlobPublicAccess` is a real PSRule rule but is **not** in L1; the Pester tests `disallows anonymous blob public access` and `requires TLS 1.2` grade that half. After the fix both checks pass.
