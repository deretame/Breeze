import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';

Future<void> nothingDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return ContentDialog(
        title: const Text('施工中'),
        content: const Text("在写了，在写了"),
        actions: <Widget>[
          FilledButton(
            child: const Text('知道了'),
            onPressed: () => context.pop(),
          ),
        ],
      );
    },
  );
}

// 通用对话框
// 只用来提示信息
Future<void> commonDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return ContentDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(content)),
        actions: <Widget>[
          Button(child: const Text('取消'), onPressed: () => context.pop()),
          FilledButton(child: const Text('确定'), onPressed: () => context.pop()),
        ],
      );
    },
  );
}
