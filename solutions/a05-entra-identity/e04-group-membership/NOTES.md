# Notes

**Why it is correct.** Assigned groups list the fixture member ids. The dynamic group applies the department rule to the four users; it is P1.

**Numbers / SKUs.** P1 (or Intune for Education) per unique dynamic-group member. Free does not cover dynamic membership.

**Alternatives.** Live Graph `member` / `memberOf` is the same schema; CI never calls it.

**The usual mistake.** Copying the empty `members` array for the dynamic group instead of applying the rule, or creating a dynamic group on Entra ID Free.
