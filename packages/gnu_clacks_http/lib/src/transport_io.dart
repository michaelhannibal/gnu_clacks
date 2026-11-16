import 'package:http/http.dart';
import 'package:http/io_client.dart';

// A subclass or decorating client can implement different redirect semantics.
bool supported(Client client) => client.runtimeType == IOClient;
