class CsLibraryRecord {
  const CsLibraryRecord({
    required this.uniqueKey,
    required this.source,
    required this.comicId,
    required this.payload,
    required this.updatedAt,
    this.deletedAt,
  });

  final String uniqueKey;
  final String source;
  final String comicId;
  final Map<String, dynamic> payload;
  final String updatedAt;
  final String? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory CsLibraryRecord.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    if (payload is! Map) {
      throw const FormatException('CS library payload must be a JSON object');
    }
    return CsLibraryRecord(
      uniqueKey: json['unique_key'] as String? ?? '',
      source: json['source'] as String? ?? '',
      comicId: json['comic_id'] as String? ?? '',
      payload: Map<String, dynamic>.from(payload),
      updatedAt: json['updated_at'] as String? ?? '',
      deletedAt: json['deleted_at'] as String?,
    );
  }
}
