# Versioning and migration

## Current status

All four packages are unpublished at `0.1.0-dev.1`. No 1.0 stability or release-readiness claim is made. The old calculator scaffold was never a supported GNU Clacks API. Remove any Calculator import/test from a local prototype and choose the package matching the use case: Core, Flutter UI, HTTP or Dio.

## Upgrade policy

Until 1.0, a breaking public API change requires a minor-version increment and an explicit migration entry. Patch increments are for compatible corrections; development suffixes identify prereleases. After 1.0, use semantic versioning: major for breaking APIs/behaviour, minor for compatible additions and patch for compatible fixes. Package versions may evolve independently, but inter-package constraints and examples must be tested together.

Changes to wire grammar, origin interpretation, approval defaults, redirect handling or diagnostic content need recorded review and new vectors. Never turn a fail-closed configuration into transmission merely as an undocumented compatibility fix. Expanding transport/dependency support requires concrete evidence; preserve the current pins until that evidence exists.

## Before adopting this development suite

- Make display eligibility explicit; it defaults off.
- Supply a separate ASCII transmission alias and explicit network approval if needed. Display names are never transliterated automatically.
- Configure exact HTTPS origins and enable the policy explicitly; empty/invalid configuration sends no generated value.
- Current automatic redirects and browser transports omit generated headers. A host's explicit no-follow native request can qualify; the adapter never changes redirect settings for you.
- Existing host headers are preserved without merging. Do not copy captured generated values into a new host header map when redirecting/retrying.
- Replace remote portraits/fonts with packaged assets for default local behaviour. Preserve licence/attribution requirements.
- Validate platform claims and host CORS/security policy against the evidence for the exact dependency versions.

No public package upgrade command is provided before publication. The checked-out workspace/example remains the tested adoption path. Future releases must include per-package changelog entries, migration notes for breaking changes and human sign-off.
