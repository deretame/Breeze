class ComicEntryInfo {
  final DateTime updatedAt;
  final Thumb thumb;
  final String author;
  final String description;
  final String chineseTeam;
  final DateTime createdAt;
  final bool finished;
  final List<String> categories;
  final String title;
  final List<String> tags;
  final String id;
  final int likesCount;

  ComicEntryInfo({
    required this.updatedAt,
    required this.thumb,
    required this.author,
    required this.description,
    required this.chineseTeam,
    required this.createdAt,
    required this.finished,
    required this.categories,
    required this.title,
    required this.tags,
    required this.id,
    required this.likesCount,
  });
}

class Thumb {
  final String originalName;
  final String path;
  final String fileServer;

  Thumb({
    required this.originalName,
    required this.path,
    required this.fileServer,
  });
}
