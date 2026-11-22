# Notes

**Why it is correct.** One StorageV2 account, HTTPS only, two outputs.

**Numbers / SKUs.** SKU Standard_LRS. API version 2023-05-01.

**Alternatives.** Premium_LRS would also compile; the tests do not require a SKU, but Standard_LRS is the course default.

**The usual mistake.** Hard-coding `location: 'eastus'` fails `no-hardcoded-location`.
