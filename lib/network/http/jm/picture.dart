import '../../../config/jm/config.dart';

String get baseUrl => JmConfig.imagesUrl;

String getJmCoverUrl(String id) {
  return '$baseUrl/media/albums/${id}_3x4.jpg';
}

String getJmImagesUrl(String id, String imageName) {
  return '$baseUrl/media/photos/$id/$imageName';
}
