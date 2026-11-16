import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';
import 'package:gnu_clacks_http/gnu_clacks_http.dart';
import 'package:http/http.dart' as http;

/// Example-only endpoint restriction. All protocol rules still live in Core.
/// No client is created until an explicit send. No automatic retry or TLS bypass.
final class DemoNetwork {
  DemoNetwork({
    required this.registry,
    this.origin = const String.fromEnvironment('GNU_CLACKS_TEST_ORIGIN'),
    http.Client Function()? httpFactory,
    Dio Function()? dioFactory,
  }) : _httpFactory = httpFactory ?? http.Client.new,
       _dioFactory = dioFactory ?? Dio.new;
  final MemorialRegistry registry;
  final String origin;
  final http.Client Function() _httpFactory;
  final Dio Function() _dioFactory;
  HttpsOrigin? get _localOrigin {
    final parsed = HttpsOrigin.tryParse(origin);
    return parsed != null &&
            (parsed.hostname == 'localhost' || parsed.hostname == '127.0.0.1')
        ? parsed
        : null;
  }

  bool get configured => _localOrigin != null;
  HeaderPolicy policy({required bool enabled}) => HeaderPolicy(
    enabled: enabled,
    allowlistedOrigins: configured ? [origin] : const [],
  );

  Uri get _echo {
    if (!configured) {
      throw StateError(
        'Configure an HTTPS localhost test origin at build time.',
      );
    }
    return Uri.parse(origin).resolve('/echo');
  }

  Future<DemoResponse> sendHttp({required bool enabled}) async {
    final url =
        _echo; // Validate before creating a client, including on failure.
    final client = ClacksClient(
      _httpFactory(),
      registry: registry,
      policy: policy(enabled: enabled),
    );
    try {
      // The demonstration host deliberately chooses a no-follow request. The
      // adapter does not modify redirects. This is not a production default.
      final request = http.Request('GET', url)..followRedirects = false;
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 5));
      return DemoResponse.decode(response.statusCode, response.body);
    } finally {
      client.close();
    }
  }

  Future<DemoResponse> sendDio({required bool enabled}) async {
    final url = _echo;
    final dio = _dioFactory();
    ClacksDioInterceptor.install(
      dio,
      registry: registry,
      policy: policy(enabled: enabled),
    );
    try {
      final response = await dio
          .get<String>(
            url.toString(),
            options: Options(
              followRedirects: false,
              responseType: ResponseType.plain,
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          )
          .timeout(const Duration(seconds: 5));
      return DemoResponse.decode(response.statusCode ?? 0, response.data ?? '');
    } finally {
      dio.close(force: true);
    }
  }
}

final class DemoResponse {
  const DemoResponse(this.status, this.receivedHeader);
  final int status;
  final String? receivedHeader;
  factory DemoResponse.decode(int status, String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> ||
        (decoded['receivedHeader'] != null &&
            decoded['receivedHeader'] is! String)) {
      throw const FormatException('Unexpected local fixture response.');
    }
    return DemoResponse(status, decoded['receivedHeader'] as String?);
  }
}
