import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 下载章节的干净内部模型。
///
/// 负责把各种 legacy 数据格式（`UnifiedComicDownloadStoredChapter`、
/// `DownloadChapterTaskRef`、`UnifiedComicDownloadChapter` 等）中散落的
/// `id` / `logicalKey` / `requestId` / `taskChapterId` / `storageChapterId` /
/// `order` 字段统一成语义清晰的三个 key：
///
/// - [id]：宿主内部用于匹配章节的 key（历史记录、下载选中、跳章）
/// - [requestId]：调用插件 `getChapter` / `getReadSnapshot` 时使用的 key
/// - [storageId]：本地文件系统层面使用的 key（目录名等）
class DownloadChapter {
  const DownloadChapter({
    required this.id,
    required this.displayName,
    required this.order,
    this.requestId,
    this.storageId,
    required this.extern,
    required this.images,
  });

  /// 宿主内部匹配 key。
  ///
  /// 从 legacy 数据解析时，优先级为：
  /// `logicalKey > id > taskChapterId > requestId > order`
  final String id;

  /// 展示用章节名。
  final String displayName;

  /// 章节顺序。
  final int order;

  /// 网络请求 key。为空时使用 [id]。
  final String? requestId;

  /// 本地存储 key。为空时 [effectiveStorageId] 会基于 [id] 生成 hash。
  final String? storageId;

  /// 插件透传 extern。
  final Map<String, dynamic> extern;

  /// 已下载图片列表。
  final List<DownloadImage> images;

  /// 真正用于网络请求的章节 ID。
  String get effectiveRequestId {
    final trimmed = requestId?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : id;
  }

  /// 真正用于本地存储的章节 ID。
  ///
  /// 如果插件/数据没有显式提供 [storageId]，则对 [id] 做 MD5 hash，
  /// 避免路径型 ID 或特殊字符导致文件系统问题。
  String get effectiveStorageId {
    final trimmed = storageId?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : _hashForPath(id);
  }

  static String _hashForPath(String input) {
    final bytes = utf8.encode(input.trim());
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  DownloadChapter copyWith({
    String? id,
    String? displayName,
    int? order,
    String? requestId,
    String? storageId,
    Map<String, dynamic>? extern,
    List<DownloadImage>? images,
  }) {
    return DownloadChapter(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      order: order ?? this.order,
      requestId: requestId ?? this.requestId,
      storageId: storageId ?? this.storageId,
      extern: extern ?? this.extern,
      images: images ?? this.images,
    );
  }
}

class DownloadImage {
  const DownloadImage({
    required this.id,
    required this.name,
    required this.path,
    this.url = '',
    this.extern = const {},
  });

  final String id;
  final String name;
  final String path;
  final String url;
  final Map<String, dynamic> extern;

  DownloadImage copyWith({
    String? id,
    String? name,
    String? path,
    String? url,
    Map<String, dynamic>? extern,
  }) {
    return DownloadImage(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      url: url ?? this.url,
      extern: extern ?? this.extern,
    );
  }
}
