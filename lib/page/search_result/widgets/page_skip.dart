import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<int?> showNumberInputDialog({
  required BuildContext context,
  String title = '输入页数',
  String hintText = '请输入数字',
  int? initialValue,
}) {
  final TextEditingController inputController = TextEditingController(
    text: initialValue?.toString() ?? '',
  );
  final FocusNode focusNode = FocusNode();

  return showDialog<int?>(
    context: context,
    builder: (BuildContext innerContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });

      return AlertDialog(
        title: Text(title),
        content: TextField(
          focusNode: focusNode,
          controller: inputController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: hintText),
          onSubmitted: (value) {
            final int? result = int.tryParse(value);
            if (result != null) Navigator.of(innerContext).pop(result);
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(innerContext).pop(),
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              final int? result = int.tryParse(inputController.text);
              Navigator.of(innerContext).pop(result);
            },
          ),
        ],
      );
    },
  );
}
