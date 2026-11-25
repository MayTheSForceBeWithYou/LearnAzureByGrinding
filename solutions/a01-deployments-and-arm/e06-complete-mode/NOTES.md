# Notes

**Why it is correct.** Removing the `if (false)` puts both accounts in the Complete-mode set.

**Numbers / SKUs.** Two Standard_LRS accounts.

**Alternatives.** A parameterised condition that is true in this lab would also pass; a literal false would not.

**The usual mistake.** Thinking Complete only deletes resources omitted from the file, not resources with condition false.
