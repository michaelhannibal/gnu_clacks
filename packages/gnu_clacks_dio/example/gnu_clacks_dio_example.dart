import 'package:dio/dio.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';
import 'package:gnu_clacks_dio/gnu_clacks_dio.dart';

/// Configure the transport before calling this function. The caller owns Dio's
/// lifecycle and deliberately chooses no-follow behaviour for this request.
Future<Response<String>> fetchWithTribute({
  required Dio dio,
  required String destination,
  required MemorialRegistry registry,
  required HeaderPolicy policy,
}) async {
  ClacksDioInterceptor.install(dio, registry: registry, policy: policy);
  return dio.get<String>(
    destination,
    options: Options(followRedirects: false, responseType: ResponseType.plain),
  );
}

/// Running this file does not create a client or contact any destination.
void main() {}
