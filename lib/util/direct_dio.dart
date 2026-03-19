import 'package:dio/dio.dart';

// 为什么有这么个玩意儿呢？因为从127.0.0.1拉取的时候如果添加了代理的话就没法用了
// 所以这个的目的其实就是强制直连
final directDio = Dio();
  // ..httpClientAdapter = IOHttpClientAdapter(
  //   createHttpClient: () {
  //     final client = HttpClient();
  //     client.findProxy = (_) => 'DIRECT';
  //     return client;
  //   },
  // );
