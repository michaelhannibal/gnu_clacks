import 'package:dio/dio.dart';
import 'package:dio/io.dart';

bool supported(HttpClientAdapter adapter) =>
    adapter.runtimeType == IOHttpClientAdapter;
