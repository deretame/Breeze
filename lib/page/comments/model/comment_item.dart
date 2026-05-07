import 'package:zephyr/util/json/json_value.dart';

class CommentItem {
  const CommentItem({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.avatarPath,
    required this.content,
    required this.createdAt,
    required this.replyCount,
    required this.replies,
    required this.extern,
  });

  final String id;
  final String authorName;
  final String avatarUrl;
  final String avatarPath;
  final String content;
  final String createdAt;
  final int replyCount;
  final List<CommentItem> replies;
  final Map<String, dynamic> extern;

  CommentItem copyWith({int? replyCount}) {
    return CommentItem(
      id: id,
      authorName: authorName,
      avatarUrl: avatarUrl,
      avatarPath: avatarPath,
      content: content,
      createdAt: createdAt,
      replyCount: replyCount ?? this.replyCount,
      replies: replies,
      extern: extern,
    );
  }

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    final author = asJsonMap(map['author']);
    final avatar = asJsonMap(author['avatar']);
    final replies = asJsonList(
      map['replies'],
    ).map(asJsonMap).map(CommentItem.fromMap).toList();
    return CommentItem(
      id: map['id']?.toString() ?? '',
      authorName: author['name']?.toString() ?? '匿名用户',
      avatarUrl: avatar['url']?.toString() ?? '',
      avatarPath: avatar['path']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      replyCount: _toInt(map['replyCount']),
      replies: replies,
      extern: asJsonMap(map['extern']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
