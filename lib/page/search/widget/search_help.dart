import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';

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
                t.search.tipsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildTipCard(
                title: t.search.exactSearchTitle,
                example: t.search.exactSearchExample,
                desc: t.search.exactSearchDesc,
                color: Colors.blue[100]!,
              ),
              _buildTipCard(
                title: t.search.excludeSearchTitle,
                example: t.search.excludeSearchExample,
                desc: t.search.excludeSearchDesc,
                color: Colors.red[100]!,
              ),
              _buildTipCard(
                title: t.search.fuzzySearchTitle,
                example: t.search.fuzzySearchExample,
                desc: t.search.fuzzySearchDesc,
                color: Colors.green[100]!,
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
          style: TextStyle(backgroundColor: Colors.black12, fontSize: 15),
        ),
        SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    ),
  );
}
