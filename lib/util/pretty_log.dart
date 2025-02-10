import 'package:logger/logger.dart';
import 'package:stack_trace/stack_trace.dart';

class CustomPrinter extends LogPrinter {
  final PrettyPrinter _prettyPrinter = PrettyPrinter();

  @override
  List<String> log(LogEvent event) {
    var message = event.message;
    var error = event.error;
    var stackTrace = event.stackTrace;

    // 如果有堆栈信息，使用TersePrinter来简化它
    if (stackTrace != null) {
      Chain chain = Chain.forTrace(Trace.from(stackTrace));
      Chain terseChain = chain.terse;
      stackTrace = terseChain.toTrace();
    }

    // 使用PrettyPrinter来格式化日志
    return _prettyPrinter.log(
      LogEvent(event.level, message, error: error, stackTrace: stackTrace),
    );
  }
}
