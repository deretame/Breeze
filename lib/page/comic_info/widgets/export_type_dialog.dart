// import 'package:flutter/material.dart';
//
// enum ExportType {
//   zip, // 导出为压缩包
//   folder, // 导出为文件夹
// }
//
// // 弹出选择对话框，让用户选择导出为压缩包还是文件夹
// Future<ExportType?> showExportTypeDialog(BuildContext context) async {
//   return await showDialog<ExportType>(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text('选择导出方式'),
//         content: Text('请选择将漫画导出为压缩包还是文件夹：'),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(ExportType.zip); // 返回压缩包选项
//             },
//             child: Text('压缩包'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(ExportType.folder); // 返回文件夹选项
//             },
//             child: Text('文件夹'),
//           ),
//         ],
//       );
//     },
//   );
// }
