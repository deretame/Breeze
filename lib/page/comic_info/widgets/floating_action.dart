// import 'package:auto_route/auto_route.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../../main.dart';
// import '../../../object_box/model.dart';
// import '../../../object_box/objectbox.g.dart';
// import '../../../util/router/router.gr.dart';
// import '../../../widgets/comic_entry/comic_entry.dart';
//
// class FloatingAction extends StatelessWidget {
//   final String comicId;
//   final String from;
//   final ComicEntryType type;
//
//   const FloatingAction({
//     super.key,
//     required this.comicId,
//     required this.from,
//     required this.type,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     BikaComicHistory? comicHistory;
//
//     return SizedBox(
//       width: 100,
//       height: 56,
//       child: FloatingActionButton(
//         onPressed: () {
//           if (comicHistory != null) {
//             comicHistory =
//                 objectbox.bikaHistoryBox
//                     .query(BikaComicHistory_.comicId.equals(comicId))
//                     .build()
//                     .findFirst();
//             context.pushRoute(
//               ComicReadRoute(
//                 comicInfo: comicInfo,
//                 epsInfo: _epsInfo,
//                 doc: Doc(
//                   id: "history",
//                   title: comicHistory!.epTitle,
//                   order: comicHistory!.order,
//                   updatedAt: comicHistory!.history,
//                   docId: (comicHistory!.epPageCount - 1).toString(),
//                 ),
//                 comicId: comicInfo.id,
//                 type:
//                     _type == ComicEntryType.download
//                         ? ComicEntryType.historyAndDownload
//                         : ComicEntryType.history,
//               ),
//             );
//           } else {
//             AutoRouter.of(context).push(
//               ComicReadRoute(
//                 comicInfo: comicInfo,
//                 epsInfo: _epsInfo,
//                 doc: _epsInfo[0],
//                 comicId: comicInfo.id,
//                 type: _type,
//               ),
//             );
//           }
//         },
//         child: Text(
//           comicHistory != null ? '继续阅读' : '开始阅读',
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//       ),
//     );
//   }
// }
