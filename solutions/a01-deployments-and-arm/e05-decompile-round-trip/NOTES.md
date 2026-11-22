# Notes

**Why it is correct.** The checked-in decompile is the source of truth for this answer, not a remembered Microsoft blog.

**Numbers / SKUs.** API version 2023-05-01, SKU Standard_LRS.

**Alternatives.** Modules decompile to separate files plus `module` calls, not inlined resources. This file has no modules.

**The usual mistake.** Expecting the decompiled file to match `main.bicep` byte-for-byte, including comments.
