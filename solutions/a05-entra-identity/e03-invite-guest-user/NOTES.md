# Notes

**Why it is correct.** The invite is in the A05 test tenant. UserType Guest and the `#EXT#` UPN shape match the Learn user-properties page.

**Numbers / SKUs.** Free covers guest invite. <https://learn.microsoft.com/entra/fundamentals/licensing>

**Alternatives.** `az ad user create` with `--user-type Guest` is CLI; this exercise is portal `ANSWER.md`.

**The usual mistake.** Inviting into the personal Default Directory, or inventing Graph JSON that was never captured.
