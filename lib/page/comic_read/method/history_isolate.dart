import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/comic_read/method/history_isolate_messages.dart';
import 'package:zephyr/type/enum.dart';

// Isolate 的入口点
Future<void> historyIsolateEntrypoint(Map<String, dynamic> context) async {
  final mainSendPort = context['mainSendPort'] as SendPort;
  final token = context['token'] as RootIsolateToken;
  // 1. 创建自己的接收端口，用来接收主 Isolate 的消息
  final isolateReceivePort = ReceivePort();

  // 2. 将自己的发送端口发送给主 Isolate，以便主 Isolate 能给我们发消息
  mainSendPort.send(isolateReceivePort.sendPort);

  // 3. 安全地初始化 ObjectBox store
  // 这里会调用您写的 ObjectBox.create()，它会 attach 到已存在的 store
  // 在执行任何插件代码之前，初始化通信绑定
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final objectbox = await ObjectBox.create();
  logger.d('History Isolate: ObjectBox store attached.');

  // 4. 开始监听来自主 Isolate 的消息
  await for (final message in isolateReceivePort) {
    if (message is UpdateHistoryMessage) {
      // 执行同步的写入操作，因为我们已经在后台线程了
      if (message.from == From.bika) {
        final box = objectbox.bikaHistoryBox;
        final data = message.data;
        box.put(data);
      } else if (message.from == From.jm) {
        final box = objectbox.jmHistoryBox;
        final data = message.data;
        box.put(data);
      }
    } else if (message is ShutdownMessage) {
      // 收到关闭消息，退出循环并关闭端口
      logger.d('History Isolate: Shutting down.');
      isolateReceivePort.close();
      // ObjectBox 的 store 在 Isolate 退出时会自动处理，但显式关闭更好
      objectbox.store.close();
      break; // 退出 for 循环，Isolate 执行完毕
    }
  }

  Isolate.exit(); // 确保 Isolate 退出
}
