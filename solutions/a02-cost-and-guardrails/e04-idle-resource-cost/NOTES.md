# Notes

**Why it is correct.** Compute stops only on deallocate; leftover disks/IPs need group delete.

**Numbers / SKUs.** Public IP ~$0.005/hr. Recovery Services protected-instance ~$10/month per VM is out of scope here but is in the lesson.

**Alternatives.** Auto-shutdown helps compute; it does not delete IPs.

**The usual mistake.** Reading portal Stopped as deallocated.
