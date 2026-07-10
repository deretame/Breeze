import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/i18n/strings.g.dart';

Future<int?> showNumberInputDialog({
  required BuildContext context,
  String? title,
  String? hintText,
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
        title: Text(title ?? t.searchResult.enterPageNumber),
        content: TextField(
          focusNode: focusNode,
          controller: inputController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hintText ?? t.searchResult.pleaseEnterNumber,
          ),
          onSubmitted: (value) {
            final int? result = int.tryParse(value);
            if (result != null) Navigator.of(innerContext).pop(result);
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text(t.common.cancel),
            onPressed: () => Navigator.of(innerContext).pop(),
          ),
          TextButton(
            child: Text(t.common.ok),
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
