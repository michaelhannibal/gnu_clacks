import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_http/gnu_clacks_http.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final class RecordingClient extends http.BaseClient {
  http.BaseRequest? received;
  bool closed = false;
  Object? error;
  final response = http.StreamedResponse(
    Stream.value([65]),
    201,
    headers: {'x-host': 'retained'},
  );
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    received = request;
    if (error != null) throw error!;
    return response;
  }

  @override
  void close() => closed = true;
}

void main() {
  test(
    'unknown transport stays unchanged even with host-disabled redirects',
    () async {
      final inner = RecordingClient();
      final request =
          http.Request('POST', Uri.parse('https://approved.example/path'))
            ..followRedirects = false
            ..body = 'preserved';
      request.headers['X-Host'] = 'original';
      final wrapper = ClacksClient(
        inner,
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
      final before = Map.of(request.headers);
      final response = await wrapper.send(request);
      expect(inner.received, same(request));
      expect(response, same(inner.response));
      expect(request.headers, before);
      expect(request.finalized, isFalse);
      expect(request.body, 'preserved');
      expect(response.statusCode, 201);
      wrapper.close();
      expect(inner.closed, isTrue);
    },
  );

  test('unknown client errors propagate unchanged and unrelated clients are unaffected', () async {
    final inner = RecordingClient();
    final error = StateError('transport failure');
    inner.error = error;
    final wrapper = ClacksClient(inner, registry: MemorialRegistry([]));
    await expectLater(
      wrapper.send(http.Request('GET', Uri.parse('https://example.org'))),
      throwsA(same(error)),
    );
    final unrelated = RecordingClient();
    final request = http.Request('GET', Uri.parse('https://example.org'));
    await unrelated.send(request);
    expect(unrelated.received!.headers, isEmpty);
    wrapper.close();
    unrelated.close();
  });
}
