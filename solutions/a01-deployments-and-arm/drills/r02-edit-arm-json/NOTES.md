# Notes

**Why it is correct.** minimumTlsVersion TLS1_2 is the course floor, and `accountName` is a template output (the drill's ExpectOutputs symbol).

**Numbers / SKUs.** Starter was TLS1_0 and had no outputs.

**Alternatives.** Bicep decompile would also work; the drill is the JSON edit.

**The usual mistake.** Changing sku or kind instead of the TLS property, or adding the output but leaving TLS1_0.
