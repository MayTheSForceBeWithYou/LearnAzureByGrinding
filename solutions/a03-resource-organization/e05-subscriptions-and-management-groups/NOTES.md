# Notes

**Why it is correct.** Subscription is the lab and billing boundary. Management groups are a control-plane hierarchy above subscriptions. SPEC 13.3: no MG lab on a personal tenant.

**Numbers / SKUs.** None.

**Alternatives.** A Bicep `[LAB]` at management-group scope is allowed only when the personal tenant actually permits MG create/assign; this course does not ship one.

**The usual mistake.** Thinking a management group is a billing unit, or that moving a subscription between management groups changes the invoice.
