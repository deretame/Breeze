import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';

Future<void> nothingDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(t.common.underConstruction),
        content: SingleChildScrollView(
          child: ListBody(children: <Widget>[Text(t.common.comingSoon)]),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(t.common.gotIt),
            onPressed: () {
              context.pop();
            },
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
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(children: <Widget>[SelectableText(content)]),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(t.common.cancel),
            onPressed: () {
              context.pop();
            },
          ),
          TextButton(
            child: Text(t.common.ok),
            onPressed: () {
              context.pop();
            },
          ),
        ],
      );
    },
  );
}
