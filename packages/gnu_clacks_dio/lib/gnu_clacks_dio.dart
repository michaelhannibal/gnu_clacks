/// Explicit, per-Dio GNU Clacks integration. No global interception.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';

import 'src/transport_stub.dart'
    if (dart.library.io) 'src/transport_io.dart'
    as transport;

/// Installs an opt-in interceptor and a final transport guard on one Dio.
///
/// The interceptor never adds names to RequestOptions. Its private guard checks
/// final routing/redirect settings after all request interceptors/transformers,
/// then adds only to a private options copy. Retries see unmodified host options.
/// Browser/custom adapters and automatic redirects never generate headers.
final class ClacksDioInterceptor extends Interceptor {
  ClacksDioInterceptor._();

  /// Repeated installation returns the active instance, retaining its original
  /// immutable policy and registry. To reconfigure, remove it then reinstall.
  /// Configure the underlying transport first. Removing this interceptor or
  /// replacing the guarded adapter disables generated transmission.
  static ClacksDioInterceptor install(
    Dio dio, {
    required MemorialRegistry registry,
    HeaderPolicy? policy,
  }) {
    final current = dio.httpClientAdapter;
    if (current is _Guard && dio.interceptors.contains(current.owner)) {
      return current.owner;
    }
    final owner = ClacksDioInterceptor._();
    final inner = current is _Guard ? current.inner : current;
    late final _Guard guard;
    guard = _Guard(
      inner,
      owner,
      registry,
      policy ?? HeaderPolicy(),
      () =>
          identical(dio.httpClientAdapter, guard) &&
          dio.interceptors.contains(owner),
    );
    dio.httpClientAdapter = guard;
    dio.interceptors.add(owner);
    return owner;
  }
}

final class _Guard implements HttpClientAdapter {
  _Guard(this.inner, this.owner, this.registry, this.policy, this.isActive);

  final HttpClientAdapter inner;
  final ClacksDioInterceptor owner;
  final MemorialRegistry registry;
  final HeaderPolicy policy;
  final bool Function() isActive;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!isActive() ||
        !transport.supported(inner) ||
        options.followRedirects ||
        !policy.enabled) {
      return inner.fetch(options, requestStream, cancelFuture);
    }
    // Check raw routing spellings as well as the resolved destination; Uri may
    // otherwise erase an encoded authority before Core sees it.
    final rawUrl = options.path.startsWith(RegExp(r'https?:'))
        ? options.path
        : '${options.baseUrl}${options.path}';
    final rawOrigin = HttpsOrigin.forRequest(rawUrl);
    if (rawOrigin == null ||
        rawOrigin != HttpsOrigin.forRequest(options.uri.toString())) {
      return inner.fetch(options, requestStream, cancelFuture);
    }
    final decision = policy.evaluate(
      requestUrl: options.uri.toString(),
      registry: registry,
      redirectSafetyVerified: true,
      existingHeaderNames: options.headers.keys,
    );
    if (decision.value == null) {
      return inner.fetch(options, requestStream, cancelFuture);
    }
    final outgoing = options.copyWith(
      headers: {...options.headers, HeaderPolicy.headerName: decision.value},
    );
    // Body streams, progress, cancellation and timeout options are delegated,
    // never consumed, retried or reset by this integration.
    try {
      return await inner.fetch(outgoing, requestStream, cancelFuture);
    } finally {
      // Native transport errors may retain this private options copy. Remove
      // our value before those errors can reach logging or retry interceptors.
      outgoing.headers.remove(HeaderPolicy.headerName);
    }
  }

  @override
  void close({bool force = false}) => inner.close(force: force);
}
