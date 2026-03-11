import 'package:flutter/material.dart';

Future<bool> buttonDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 不允许点击外部区域关闭对话框
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop(false); // 返回 false
                },
              ),
              TextButton(
                child: Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop(true); // 返回 true
                },
              ),
            ],
          );
        },
      ) ??
      false; // 处理返回值为空的情况
}
