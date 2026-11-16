# GNU Clacks — HTTP wire and safety specification (proposed v1)

**Review status:** Rules accepted and Phase 0 closed by the human on 16 November 2026. Phase 1 implements pure Core policy; Phase 2 validates a conservative native no-follow path and browser fail-closed behaviour. See `HTTP_INTEGRATIONS.md` for the exact support boundary.

## Interoperability

- Conventional header field: `X-Clacks-Overhead` (HTTP field names are case-insensitive).
- Canonical example: `X-Clacks-Overhead: GNU Terry Pratchett`.
- Initial compatibility target: preserve the familiar single-name form without inventing new public fields.
- The human selected a **project-specific** policy for multi-name formatting; it is not a claim that the existing GNU tradition has standardised the grammar.

## Header content

- Only `networkApproved` memorial entries qualify.
- All memorials shown on-screen can remain private to network traffic.
- `networkName` is a separate developer-supplied, nonempty ASCII-safe name or alias. Never silently transliterate or expose `displayName`, dedication, dates, photos, IDs or other details.
- For a single name: `GNU {networkName}`.
- For multiple names, **selected project-specific v1 format**: one name per comma-separated segment, each with its own `GNU` prefix, e.g. `GNU Alex Example, GNU Sam Example`. Interoperability with existing consumers is explicitly unverified and is not a release claim. No escaping or quoted-name mode is defined.
- Sort eligible entries by explicit integer `sortOrder` ascending, with unspecified orders after specified ones, then by normalised `networkName` and stable ID in ascending Unicode scalar-value order, without locale collation. UI sorting is separate. Deduplicate normalised aliases case-sensitively, keeping the first entry; different IDs with the same alias emit one name. Do not add encoding or metadata.
- Reject all C0 controls (including tabs, CR and LF), DEL and non-ASCII characters before normalisation. Trim leading/trailing ASCII space and collapse internal runs of ASCII space to one. The resulting alias must be nonempty and contain only ASCII letters, digits, space, apostrophe, hyphen and full stop, with at least one letter or digit. Reject commas, quotes, backslashes and other punctuation; use an explicitly supplied alternative alias. No automatic transliteration occurs.
- Value budget: 512 bytes by default; configurable integer from 1 through 1024 inclusive. Invalid budgets disable generated transmission and produce a non-sensitive configuration diagnostic. Count the ASCII value only, including every `GNU ` prefix and each two-byte `, ` separator; exclude the field name and HTTP framing. Visit sorted, deduplicated aliases in order; skip any whole segment that does not fit and continue to later entries. Never truncate a name. If none fit, omit the header. These project limits are not a guarantee of server acceptance.
- Header must remain idempotent when the same adapter is installed more than once; do not duplicate names or create repeated fields.

## Destination policy

- `enabled=false` and an empty origin allowlist are hard defaults.
- Allowlisted origin = explicit scheme + hostname + effective port, HTTPS only (e.g. `https://api.example.org:443`). Exact matching; no subdomain wildcards, suffix/prefix matching, URL substring tests, userinfo or opaque origins.
- Parse structurally; lowercase scheme and ASCII DNS hostname, and treat omitted HTTPS port as 443. Accept only ports 1–65535. Allowlist entries have no path other than empty or `/`, and no userinfo, query or fragment, including empty delimiters. Request paths and queries do not affect origin matching; reject request userinfo and malformed authorities.
- Accepted conservative host profile: ASCII DNS labels (letters, digits and interior hyphens, 1–63 characters each, total hostname at most 253), or canonical dotted-decimal IPv4 with four octets 0–255 and no leading zeroes. Reject empty labels, trailing dots, percent-encoded hosts, backslashes, wildcards, ambiguous numeric forms and IPv6 literals in this v1 profile. IDNs must be supplied as externally validated ASCII punycode on both sides; no Unicode-to-IDNA conversion or equivalence is inferred. Unsupported forms fail closed for generated transmission while normal request behaviour is preserved.
- Policy applies to every request, including retries and redirects. A redirected request MUST be evaluated against the new origin before any header is transmitted. Drop on unknown/unapproved target.
- A hostname redirect, alternate port or downgrade to HTTP is **not approved** unless the final HTTPS origin is independently allowlisted.
- Local development HTTP exceptions: out of mainline v1 defaults; only if explicitly added as a gated development-only feature.
- Host applications should not allowlist arbitrary external payment, authentication, analytics or user-data services without considering how headers may be logged and whether the service allows them.

## Existing headers

- Detect the field case-insensitively. If any existing value is present, preserve it exactly without parsing, normalising, merging, replacing or adding another field. This also makes repeated adapter application idempotent.
- Approval and byte-budget guarantees apply only to package-generated values. A host header is not validated or approved by preservation; the host and underlying transport remain responsible for it. Invalid host values may be rejected by the transport.
- Any controlled redirect mechanism must track generated values separately from host values: remove stale generated values before policy recomputation. A generated value must not become an exempt host value simply because it survived a previous hop.
- The package should not change authentication, cookies, redirects, request bodies, response parsing, timeouts, TLS or proxy settings.

## Transport safety gate

Before initial attachment, establish that the concrete transport and configuration can enforce policy before every redirect hop. If this cannot be established, omit the package-generated header and preserve normal client behaviour. Do not silently change redirect settings, add retries or introduce a strict mode. A server promise never to redirect is not a transport guarantee.

| Transport | Implemented transmission boundary |
|---|---|
| http 1.6.0 native IOClient | Generate only if the host already set followRedirects=false; automatic redirects omit generated values from the initial request |
| http BrowserClient | Generated transmission disabled; preserve upstream behaviour |
| Dio 5.11.1 native IOHttpClientAdapter | Final dispatch guard; generate only with host-selected followRedirects=false |
| Dio default browser adapter | Generated transmission disabled regardless of redirect option |
| Other/custom/subclassed transports | Generated transmission disabled |

Native HTTPS loopback tests establish the supported no-follow behaviour; browser tests establish pass-through and CORS error/preflight handling. No automatic header-bearing redirect mechanism is implemented. Full UI and Core remain independent of these limitations. Future controlled redirects still require separate review of request semantics. See `HTTP_INTEGRATIONS.md` and `VALIDATION.md`.

## Browser CORS

Both current web integrations omit generated headers. Host-supplied headers remain untouched. On Flutter Web, adding a non-safelisted request header may cause an OPTIONS preflight and require the server's `Access-Control-Allow-Headers` to include `X-Clacks-Overhead`. This can make previously working cross-origin requests fail. **Do not** silently bypass browser policy. Provide a documented ability to disable the header for a web destination and explain server-side configuration options.

## What 'GNU' cannot guarantee

- A client-side request header is not automatically repeated by a server or downstream systems. True multi-hop signalling requires independent, cooperating servers.
- `N` is a symbolic homage, not a technical guarantee of 'no logging'. Proxies, servers and observability tooling might record a header.
- Some server infrastructure removes unknown headers; delivery is best-effort.
- The package never emits background requests simply to circulate names.

## Security test vectors / acceptance cases

1. Disabled policy + valid origin => no header.
2. Enabled policy + no allowlisted origins => no header.
3. Exact approved HTTPS origin => correct approved names only.
4. Same hostname at other port => no header.
5. `api.example.org.evil.tld` when `api.example.org` allowed => no header.
6. Subdomain not explicitly allowed => no header.
7. HTTP downgrade => no header.
8. Controlled cross-origin redirect => remove generated header before following; recompute only if the new origin is approved. Uncontrolled redirects => no initial generated header.
9. Relative same-origin redirect => policy reapplied, no duplicate.
10. Network-disallowed memorial => never transmitted, even when displayed.
11. Non-ASCII visible name with no ASCII-safe `networkName` => omit from wire; remain visible in UI.
12. CRLF/control injection => rejected from wire.
13. Header limit overflow => whole entries omitted, deterministic result.
14. Existing header in any field-name casing => preserve exactly; no merge, replacement or duplicate, including repeated adapter installation.
15. Flutter Web preflight failure => no insecure workaround or hidden network retry.

## Concrete policy vectors

These vectors are covered by Core tests; see `VALIDATION.md` for executed environments and limitations. Transport effects such as following redirects and preserving request headers remain adapter responsibilities. Unless stated otherwise, all entries are approved and the transport gate is asserted.

| Input | Expected generated value or decision |
|---|---|
| Aliases `Sam Example`, `Alex Example`, unspecified orders | `GNU Alex Example, GNU Sam Example` (33 bytes) |
| `Alex Example` order 2; `Sam Example` order 1 | `GNU Sam Example, GNU Alex Example` |
| Aliases ` Alex  Example ` and `Alex Example`, different IDs | `GNU Alex Example` once |
| Aliases `alex`, `Alex` | `GNU Alex, GNU alex` (case-sensitive deduplication) |
| Alias `Alex Example`, budget 15 / 16 | Omit / `GNU Alex Example` (16 bytes) |
| Aliases `Alex Example`, `Sam Example`, budget 32 / 33 | `GNU Alex Example` / both names |
| Aliases `AAAA` order 1, `B` order 2, budget 5 | Skip `AAAA`; emit `GNU B` |
| Alias containing tab, CR, LF, DEL, comma or non-ASCII | Reject from generated wire value before normalisation |
| Alias `O'Neil-Smith Jr.` | Accept punctuation under the accepted alias profile |
| Allowlist `https://api.example.org`; target `https://API.EXAMPLE.ORG:443/path?q=1` | Same origin |
| Same allowlist; target port 444, subdomain or HTTP scheme | No generated header |
| Allowlist with userinfo, query, fragment or non-root path | Reject configuration for transmission |
| Unicode hostname, trailing-dot hostname, encoded hostname or IPv6 literal | No generated header under accepted host profile |
| Existing field `x-clacks-overhead: host value` | Preserve `host value` exactly, even on an ineligible request |
| Unknown redirect capability or default Dio browser adapter | No package-generated header; preserve client behaviour |

## Sources reviewed during Phase 0

- [Dart redirect behaviour](https://api.dart.dev/dart-io/HttpClientRequest/followRedirects.html): custom headers are forwarded during automatic redirects.
- [http BrowserClient](https://pub.dev/documentation/http/latest/browser_client/BrowserClient-class.html): redirect-control limitations.
- [Dio 5.11.1 browser adapter source](https://raw.githubusercontent.com/cfug/dio/dio_v5.11.1/plugins/web_adapter/lib/src/adapter_impl.dart): XMLHttpRequest transport; no per-hop interception hook.
- [Fetch redirect algorithm](https://fetch.spec.whatwg.org/#http-redirect-fetch): CORS does not implement this project's allowlist or automatically strip arbitrary custom fields.
- [Community draft](https://raw.githubusercontent.com/clacks-overhead/clacks-protocol/master/middle.mkd): describes a different `Clacks` field; it does not verify this multi-name grammar.

## Standards and references for ongoing validation

- GNU community practice: https://www.gnuterrypratchett.com/
- HTTP Semantics RFC 9110: https://www.rfc-editor.org/rfc/rfc9110
- Fetch/CORS behaviour: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS
- Dio documentation: https://pub.dev/packages/dio
