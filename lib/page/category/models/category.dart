import 'package:equatable/equatable.dart';

class HomeCategory extends Equatable {
  final String title;
  final HomeThumb homeThumb;
  final bool isWeb;
  final bool active;
  final String link;
  final String id;
  final String description;

  const HomeCategory({
    required this.title,
    required this.homeThumb,
    required this.isWeb,
    required this.active,
    required this.link,
    required this.id,
    required this.description,
  });

  @override
  List<Object?> get props => [
        title,
        homeThumb,
        isWeb,
        active,
        link,
        id,
        description,
      ];
}

class HomeThumb {
  final String originalName;
  final String path;
  final String fileServer;

  HomeThumb({
    required this.originalName,
    required this.path,
    required this.fileServer,
  });
}
