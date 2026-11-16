# HTTP integrations — Phase 2

Two optional Dart packages depend on Core without importing Flutter. Both are unpublished development packages. They act only on the client explicitly wrapped or configured by the developer; no global hooks, discovery, pings or telemetry are installed.

## Transmission contract

The tested native configuration is the standard Dart `HttpClient` through http 1.6.0 `IOClient` or Dio 5.11.1 `IOHttpClientAdapter`, with **automatic redirects already disabled by the host for that request**. The integration does not disable redirects, implement redirect following or add retries. With automatic redirects enabled, generated headers are omitted even from the initial request, preserving normal client behaviour. The host must still explicitly enable Core policy, approve each alias and allowlist the exact HTTPS origin.

| Configuration | Generated header |
|---|---|
| Tested native transport, host `followRedirects=false`, all Core checks pass | One bounded value |
| Automatic redirects enabled (the normal upstream default) | Omitted on initial request and all automatic hops |
| BrowserClient, including host `followRedirects=false` | Omitted |
| Dio browser adapter, regardless of redirect options | Omitted |
| Custom/subclassed/decorated transport | Omitted |
| Missing approval, disabled/invalid policy or unapproved origin | Omitted |
| Existing field in any casing | Host value preserved without merging |

Runtime type recognition deliberately excludes subclasses and unknown decorators. It is not verification of an arbitrary replacement low-level `HttpClient`: configuring a recognised native transport with a custom implementation that violates Dart's redirect contract is outside support. Host TLS, proxy and certificate settings remain host-owned and are never changed by these integrations.

The implementation is deliberately conservative. Requests made through convenience methods that retain the upstream automatic-redirect default will not transmit a generated tribute. If the application already uses no-follow requests, the adapters can add eligible headers to them without changing that behaviour. Do not disable redirects merely as an undocumented side effect of enabling tributes.

## package:http

`ClacksClient(inner, registry: ..., policy: ...)` wraps an explicitly supplied `http.Client`. Policy is default-off when omitted. `close()` delegates to the wrapped client, so do not continue using an inner client after closing its wrapper.

For supported native no-follow requests, a private forwarding request freezes routing and redirect settings. It finalises the original request exactly once and forwards its original body stream without buffering or replaying it. Multipart finalisation can add content headers; the decision is made after that finalisation. Abort triggers, byte length, connection settings and redirect limits are retained. Generated headers never enter the original caller request, and are removed from private response/error snapshots after transport dispatch. The returned response stream is not consumed or replaced.

`response.request` may reference the transport's forwarding snapshot rather than the caller object; its routing/options match the outgoing request, and it does not retain a generated tribute value. Existing host headers remain intact. Names can still be observed or logged by the destination or host transport while the request is in flight.

Repeated Clacks wrappers do not stack values. For a supported request, the outer enabled wrapper owns the forwarding decision; inner Clacks wrappers pass that private request through. An outer disabled wrapper lets the inner wrapper apply its policy. Prefer one wrapper per client for clear configuration.

When retrying, put a host-selected `RetryClient` **outside** `ClacksClient`. Each retry is evaluated freshly against the underlying recognised transport. A `RetryClient` placed inside `ClacksClient` is an unknown decorator, so generation is disabled. No retry package behaviour is introduced automatically. Cancellation and timeout semantics remain upstream-owned; a caller's ordinary `Future.timeout` does not itself abort HTTP I/O.

`package:http` exposes request URLs as `Uri`. Authority spellings already normalised by the host cannot be reconstructed by the adapter. Supply canonical URLs and configure explicit ASCII origins as required by Core.

## Dio

Configure the desired transport first, then call `ClacksDioInterceptor.install(dio, registry: ..., policy: ...)`. It installs a per-Dio interceptor and a private guard around that instance's current `HttpClientAdapter`. An ordinary request interceptor alone cannot enforce redirect safety: later interceptors or transforms could change the destination/options. The guard therefore evaluates final options immediately before transport dispatch, after all request interceptors and request transformation.

Generation uses a private `RequestOptions` copy. Routing, timeouts, callbacks and cancellation remain unchanged; the existing body stream is delegated without consumption or replay. Caller options are not given generated headers. The generated value is removed from the private copy in a `finally` block, including when native timeout/connection errors retain that copy. Retrying an error with a new destination therefore recomputes policy without stale generated values. Host retry interceptors still own body replayability and retry limits.

Raw Dio routing spellings and the resolved URL must agree on a supported origin; encoded raw authorities are not approved through URI normalisation. Existing host fields are detected after all earlier host interceptors/transforms have run.

Repeated installation on an active guard returns the existing interceptor and retains its original immutable registry/policy. To change them, remove the interceptor and reinstall. Removing it disables the guard. Replacing `dio.httpClientAdapter` also disables generation; configure a replacement before reinstalling. Replaced adapters remain host-owned under Dio's normal lifecycle rules. Closing Dio delegates adapter close and its `force` setting to the original transport.

## Redirects and retries

No adapter automatically follows a header-bearing request. A host no-follow request may receive a redirect response (or the host's existing status-validation error), but that redirect is not followed by the integration. Manual follow-up requests are new requests and are evaluated again, including origin/port, approvals and redirect settings. Do not copy an actual captured outgoing header into a new host header map: host-supplied values are outside generated-value guarantees.

Automatic same-origin, cross-origin, alternate-port and downgrade redirects remain upstream-owned, with generated values omitted from the start. HTTP-to-HTTPS redirects also do not acquire a tribute at the final destination. There is no development HTTP exception.

## Browser CORS

Both web integrations currently omit generated headers for all destinations. They do not override Fetch/XHR redirect behaviour, retry failed requests or bypass browser restrictions. BrowserClient retains its own failure on redirects when the host sets `followRedirects=false`; Dio's XHR adapter can follow redirects despite that option. Neither behaviour is changed.

Host-supplied `X-Clacks-Overhead` headers are still preserved and can cause OPTIONS preflight. Servers must authorise the calling origin/method and include the field in `Access-Control-Allow-Headers`; credentialed requests also need the appropriate credentials policy and explicit origin. Denied preflights and ordinary CORS errors propagate normally, without hidden retries. Exposing a response header with `Access-Control-Expose-Headers` does not authorise sending a request header.

Real Chrome tests cover successful and denied preflights with a host-supplied header, cross-port redirects and ordinary CORS rejection. These loopback browser fixtures use HTTP and do not prove header-bearing HTTPS browser redirects; generation there is disabled. No browser certificate checking is relaxed.

## Validation and release limits

See `VALIDATION.md` for commands and counts. Native tests use local HTTPS endpoints and a bundled public test-only self-signed key. Their clients explicitly trust that certificate; production integrations never add trust or accept invalid certificates. The fixture certificate is not a production credential.

Dependencies are pinned to the tested http 1.6.0 and Dio 5.11.1 versions while transport guarantees are under review. Other versions, native OS/Flutter builds and release security review are not claimed. Package-name availability and multi-name interoperability remain unverified. Publication and later implementation phases require separate instruction.
