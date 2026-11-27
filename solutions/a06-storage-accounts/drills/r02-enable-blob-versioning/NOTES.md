# Notes

**Why it is correct.** Child `blobServices` named `default` with `isVersioningEnabled: true` and `changeFeed.enabled: true` plus `retentionInDays`. No delete retention (that is the lesson snippet, not this drill).

**Numbers / SKUs.** Retention 7 days. Account stays `Standard_LRS`.

**Alternatives.** Soft-delete retention is a different property (`deleteRetentionPolicy`) and is out of scope.

**The usual mistake.** Enabling blob *soft delete* instead of versioning and change feed.
