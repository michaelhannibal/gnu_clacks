/// Explicit, per-client GNU Clacks integration. No global interception.
library;

import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:http/http.dart' as http;

import 'src/transport_stub.dart'
    if (dart.library.io) 'src/transport_io.dart'
    as transport;

/// Wraps one client, retaining its redirect, timeout, TLS and proxy behaviour.
///
/// Generated headers are supported only on the tested native IOClient with
/// followRedirects already false. Browser/custom transports and automatic
/// redirects pass through without generated headers. Closing closes [inner].
final class ClacksClient extends http.BaseClient {
  ClacksClient(this.inner, {required this.registry, HeaderPolicy? policy})
    : policy = policy ?? HeaderPolicy();

  final http.Client inner;
  final MemorialRegistry registry;
  final HeaderPolicy policy;

  bool get _knownTransport => inner is ClacksClient
      ? (inner as ClacksClient)._knownTransport
      : transport.supported(inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is _ForwardedRequest ||
        !_knownTransport ||
        request.followRedirects ||
        !policy.enabled) {
      return inner.send(request);
    }
    // Freeze routing and redirect settings, but finalise the original body just
    // once. Multipart finalisation can add headers and compute content length.
    final outgoing = _ForwardedRequest(request, registry, policy);
    return inner.send(outgoing).whenComplete(outgoing.removeGeneratedHeader);
  }

  @override
  void close() => inner.close();
}

final class _ForwardedRequest extends http.BaseRequest
    implements http.Abortable {
  _ForwardedRequest(this.original, this.registry, this.policy)
    : abortTrigger = original is http.Abortable ? original.abortTrigger : null,
      super(original.method, original.url) {
    followRedirects = original.followRedirects;
    maxRedirects = original.maxRedirects;
    persistentConnection = original.persistentConnection;
    headers.addAll(original.headers);
  }

  final http.BaseRequest original;
  final MemorialRegistry registry;
  final HeaderPolicy policy;
  String? _generatedValue;

  void removeGeneratedHeader() {
    if (_generatedValue != null &&
        headers[HeaderPolicy.headerName] == _generatedValue) {
      headers.remove(HeaderPolicy.headerName);
    }
  }

  @override
  final Future<void>? abortTrigger;

  @override
  int? get contentLength => original.contentLength;

  @override
  http.ByteStream finalize() {
    super.finalize();
    final stream = original.finalize();
    headers
      ..clear()
      ..addAll(original.headers);
    final decision = policy.evaluate(
      requestUrl: url.toString(),
      registry: registry,
      redirectSafetyVerified: true,
      existingHeaderNames: headers.keys,
    );
    if (decision.value != null) {
      _generatedValue = decision.value;
      headers[HeaderPolicy.headerName] = decision.value!;
    }
    return stream;
  }
}
