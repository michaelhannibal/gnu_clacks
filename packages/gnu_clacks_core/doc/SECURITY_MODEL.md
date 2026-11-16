# Security and privacy model

GNU Clacks is embedded in a developer-owned application. It has no backend, telemetry, accounts, identity discovery, asset discovery or global network hook. Memorial permissions and rights remain the host developer's responsibility. UI eligibility and network approval are separate, default-off flags.

## Transmission requirements

A generated value requires an installed, explicitly enabled adapter, an explicitly network-approved ASCII alias, an exactly allowlisted HTTPS origin and a recognised redirect-safe transport configuration. Origin identity includes scheme, normalised hostname and effective port. No suffix, substring, wildcard or HTTP-development exception is enabled.

Current adapters generate only for standard native IOClient / IOHttpClientAdapter requests for which the host has already chosen `followRedirects=false`. They never silently disable redirects. Automatic redirects, browser transports and unknown/subclassed transports omit generated values from the initial request. No header-bearing redirect/replay mechanism is implemented. Manual requests are evaluated separately. Do not infer safety from a server promise never to redirect.

Dio checks final routing/options at transport dispatch, after host interceptors/transforms. Generated values live only in private outgoing snapshots and are removed before reusable response/error metadata reaches retry/logging handlers. Existing host headers are preserved exactly without merging; they are outside package-generated-value guarantees. Host-supplied values can still be logged or propagated by the host's own clients.

## Wire content

Only explicit approved aliases enter the header. Display names, dates, dedications, portraits, stable IDs and identity metadata are never inferred or appended. Controls, non-ASCII characters and unsupported punctuation are rejected before space normalisation. Sorting and case-sensitive deduplication are deterministic. Values are bounded (512 bytes default, 1024 maximum); whole segments are skipped rather than truncated. The multi-name grammar is project-specific and interoperability is unverified. See `PROTOCOL.md`.

Diagnostics contain fixed enum codes only. Header values themselves contain memorial names: do not log them. GNU's N is a literary homage, not an enforceable no-logging instruction; proxies, servers and host observability systems may record requests. Delivery and propagation are not guaranteed.

## UI, assets and motion

The Flutter package depends on Core and Flutter only. It uses packaged AssetImage content, with a local drawn fallback while loading or on errors. It renders supplied attribution offline and does not interpret a network flag as personal consent. Hidden entries are checked in direct detail and composed content widgets. No remote asset or font loader is included.

Reduced motion overrides package animation. TickerMode, ordinary viewport visibility, app lifecycle and explicit host activity control stop the signal. The signal spells the display name locally in a nine-lamp ASCII code and transmits nothing; it never uses `networkName` or approval state. Host caching determines disconnected web cold-load availability; static web deployment is not a hosted memorial service.

## Trust boundaries and evidence

TLS, authentication, cookies, proxies, timeout budgets, retries and body replay remain host/upstream responsibilities. Arbitrary low-level replacements that violate their documented transport contracts are outside the tested guarantee. The package does not bypass CORS, trust certificates automatically or silently retry without a header.

Automated policy, transport, widget, semantics and browser tests have recorded evidence, but they do not replace real-device/screen-reader review, platform-specific builds, cold-start profiling or a release security assessment. See `PLATFORM_MATRIX.md`. Advisory results cover server-listed known versions at the recorded date, not unknown vulnerabilities, native SDKs or all host behaviour.

Public test fixture keys are deliberately test data and are excluded from package archives. Never deploy them. Report suspected vulnerabilities privately to [apps@ydesignz.co.za](mailto:apps@ydesignz.co.za), the contact supplied by project steward Ydesignz. Include a minimal fictional-data reproduction, affected versions and impact; never send credentials or real memorial data. Delivery and monitoring have not been independently tested; no response-time commitment is promised. The project homepage is [ydesignz.co.za](https://ydesignz.co.za). Other release gates remain documented by the repository.
