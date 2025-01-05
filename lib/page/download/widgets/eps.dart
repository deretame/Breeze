import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../main.dart';
import '../../comic_info/json/eps/eps.dart';

class EpsWidget extends StatefulWidget {
  final Doc doc;
  final bool downloaded;
  final Function(int order) onUpdateDownloadInfo; // 用来更新观看按钮信息

  const EpsWidget({
    super.key,
    required this.doc,
    required this.downloaded,
    required this.onUpdateDownloadInfo,
  });

  @override
  State<EpsWidget> createState() => _EpsWidgetState();
}

class _EpsWidgetState extends State<EpsWidget> {
  bool _isChecked = false; // 复选框状态

  @override
  void initState() {
    super.initState();
    _isChecked = widget.downloaded; // 初始化复选框状态
  }

  @override
  void didUpdateWidget(EpsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloaded != widget.downloaded) {
      // 当父组件的状态变化时，更新复选框状态
      setState(() {
        _isChecked = widget.downloaded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isChecked = !_isChecked; // 切换复选框状态
        });
        widget.onUpdateDownloadInfo(widget.doc.order);
      },
      child: Observer(
        builder: (context) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 0),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: globalSetting.themeType
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 改为整体居中
              children: <Widget>[
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false; // 更新复选框状态
                    });
                    widget.onUpdateDownloadInfo(widget.doc.order);
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.doc.title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Text(
                            timeDecode(widget.doc.updatedAt),
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Expanded(child: Container()),
                          widget.doc.id == 'history'
                              ? Text("观看历史", style: TextStyle(fontSize: 14))
                              : Text(
                                  "number : ${widget.doc.order.toString()}",
                                  style: TextStyle(
                                    fontFamily: "Pacifico-Regular",
                                    fontSize: 14,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String timeDecode(DateTime originalTime) {
    DateTime newDateTime;
    newDateTime = originalTime.add(const Duration(hours: 8));
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';
    return "$formattedTime 更新";
  }
}
