// 消息基类
import 'package:zephyr/type/enum.dart';

abstract class HistoryMessage {}

// 更新历史的消息，携带纯数据
class UpdateHistoryMessage extends HistoryMessage {
  final dynamic data;
  final From from;

  UpdateHistoryMessage(this.data, this.from);
}

// 关闭 Isolate 的消息
class ShutdownMessage extends HistoryMessage {}
