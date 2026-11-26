# Notes

**Why it is correct.** The answers name only groups in the schema-derived fixture. Parent of `mg-course-example` is the all-zero Tenant Root Group. SPEC 13.3 is the reason there is no MG lab.

**Numbers / SKUs.** Fixture tenant id and root name are `00000000-0000-0000-0000-000000000000`.

**Alternatives.** Live `az account management-group list` is the same command; CI never runs it.

**The usual mistake.** Treating the fixture as a real tenant dump, or inventing extra management groups that are not in the JSON.
