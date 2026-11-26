# Notes

**Why it is correct.** The two fixture rows are named, scoped, and tied to the well-known Reader GUID. The JSON is schema-derived, not a live capture.

**Numbers / SKUs.** Reader `acdd72a7-3385-48ef-bd42-f606fba81ae7`. Contributor `b24988ac-6180-42a0-ab88-20f7382dd24c`. Group `lagb-course-example`.

**Alternatives.** Live `az role assignment list --output json` is the same command; CI never runs it.

**The usual mistake.** Treating Contributor at subscription scope as an Entra directory role, or inventing assignments that are not in the fixture.
