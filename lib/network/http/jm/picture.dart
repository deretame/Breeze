import '../../../config/jm/config.dart';

String getBaseUrl() {
  return JmConfig.imagesUrl;
}

String getJmCoverUrl(String id) {
  return '${getBaseUrl()}/media/albums/${id}_3x4.jpg';
}

String getJmImagesUrl(String id, String imageName) {
  return '${getBaseUrl()}/media/photos/$id/$imageName';
}
