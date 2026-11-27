# Notes

**Why it is correct.** Entra guard first. Resolve user and group with an exact Graph filter (`displayName eq '...'`), not `--display-name` (prefix match). Throw if the list is not exactly one hit. Then `az ad group member check`, add only when `value` is false.

**Numbers / SKUs.** Fixture ids `00000000-0000-0000-0000-000000000001` (user) and `...000101` (group).

**Alternatives.** Graph `$filter=displayName eq '...'` is the same lookup; the tests grade `az ad user list` / `az ad group list`.

**The usual mistake.** Calling `az ad group member add` when the user is already a member, which fails on a second run.
