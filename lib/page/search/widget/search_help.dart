import 'package:zephyr/util/ui/fluent_compat.dart';

void showSearchHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔍 搜索技巧',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildTipCard(
                title: '精准搜索（同时满足）',
                example: '全彩(空格)+人妻',
                desc: '显示同时包含这两个标签的结果',
                color: Colors.blue.withValues(alpha: 0.2),
              ),
              _buildTipCard(
                title: '排除搜索（不要某类）',
                example: '全彩(空格)-人妻',
                desc: '显示"全彩"但排除含"人妻"的结果',
                color: Colors.red.withValues(alpha: 0.2),
              ),
              _buildTipCard(
                title: '模糊搜索（包含任一）',
                example: '全彩(空格)人妻',
                desc: '显示包含任意一个关键词的结果',
                color: Colors.green.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildTipCard({
  required String title,
  required String example,
  required String desc,
  required Color color,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 6),
        Text(
          example,
          style: TextStyle(backgroundColor: Colors.black.withValues(alpha: 0.12), fontSize: 15),
        ),
        SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.87))),
      ],
    ),
  );
}


