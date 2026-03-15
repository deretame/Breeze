import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

final directDio = Dio()
  ..httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (_) => 'DIRECT';
      return client;
    },
  );
