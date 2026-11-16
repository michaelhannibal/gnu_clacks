import 'package:http/http.dart';

// Web and other transports remain unproven and do not generate headers.
bool supported(Client client) => false;
