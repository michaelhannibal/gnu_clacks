import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';
import 'package:test/test.dart';

final class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? received;
  Stream<Uint8List>? stream;
  Future<void>? cancel;
  bool? closeForce;
  Object? error;
  final response = ResponseBody.fromString('retained', 201);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received = options;
    stream = requestStream;
    cancel = cancelFuture;
    if (error != null) throw error!;
    return response;
  }

  @override
  void close({bool force = false}) => closeForce = force;
}

void main() {
  test('custom transport receives original options/stream/cancellation and response is unchanged', () async {
    final inner = RecordingAdapter();
    final dio = Dio()..httpClientAdapter = inner;
    ClacksDioInterceptor.install(
      dio,
      registry: MemorialRegistry([
        Memorial(
          id: 'a',
          displayName: 'Private',
          networkName: 'Alex',
          networkApproved: true,
        ),
      ]),
      policy: HeaderPolicy(
        enabled: true,
        allowlistedOrigins: ['https://approved.example'],
      ),
    );
    final options = RequestOptions(
      path: 'https://approved.example/path',
      followRedirects: false,
      headers: {'x-clacks-overhead': 'host', 'Authorization': 'secret'},
      sendTimeout: const Duration(seconds: 2),
    );
    final stream = Stream<Uint8List>.value(Uint8List.fromList([65]));
    final cancel = Completer<void>().future;
    final response = await dio.httpClientAdapter.fetch(options, stream, cancel);
    expect(inner.received, same(options));
    expect(inner.stream, same(stream));
    expect(inner.cancel, same(cancel));
    expect(response, same(inner.response));
    expect(options.headers['x-clacks-overhead'], 'host');
    expect(options.followRedirects, isFalse);
    dio.close(force: true);
    expect(inner.closeForce, isTrue);
  });

  test('replacing adapter disables guard and original custom errors propagate unchanged', () async {
    final original = RecordingAdapter();
    final dio = Dio()..httpClientAdapter = original;
    ClacksDioInterceptor.install(dio, registry: MemorialRegistry([]));
    final error = StateError('failure');
    original.error = error;
    final options = RequestOptions(
      path: 'https://approved.example',
      followRedirects: false,
    );
    await expectLater(
      dio.httpClientAdapter.fetch(options, null, null),
      throwsA(same(error)),
    );
    final replacement = RecordingAdapter();
    dio.httpClientAdapter = replacement;
    await dio.httpClientAdapter.fetch(options, null, null);
    expect(
      replacement.received!.headers.keys.map((s) => s.toLowerCase()),
      isNot(contains('x-clacks-overhead')),
    );
    dio.close();
    // A replaced adapter remains host-owned, following Dio's normal behaviour.
    original.close();
  });
}
