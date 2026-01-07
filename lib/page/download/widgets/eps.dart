import 'package:flutter/material.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../comic_info/json/bika/eps/eps.dart';

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
      setState(() => _isChecked = widget.downloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _isChecked = !_isChecked);
        widget.onUpdateDownloadInfo(widget.doc.order);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: context.theme.colorScheme.secondaryFixedDim,
              spreadRadius: 0,
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
                setState(() => _isChecked = value ?? false);
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
