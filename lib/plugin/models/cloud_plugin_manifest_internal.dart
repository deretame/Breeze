import 'package:zephyr/util/json/json_value.dart';

class CloudPluginCatalogItem {
  const CloudPluginCatalogItem({required this.repo, required this.manifest});

  final String repo;
  final CloudPluginManifestInternal manifest;

  factory CloudPluginCatalogItem.fromJson(Map<String, dynamic> json) {
    return CloudPluginCatalogItem(
      repo: json['repo']?.toString().trim() ?? '',
      manifest: CloudPluginManifestInternal.fromJson(
        asJsonMap(json['manifest']),
      ),
    );
  }
}

class CloudPluginManifestInternal {
  const CloudPluginManifestInternal({
    required this.uuid,
    required this.version,
    required this.updateUrl,
    required this.npmName,
  });

  final String uuid;
  final String version;
  final String updateUrl;
  final String npmName;

  factory CloudPluginManifestInternal.fromJson(Map<String, dynamic> json) {
    return CloudPluginManifestInternal(
      uuid: json['uuid']?.toString().trim() ?? '',
      version: json['version']?.toString().trim() ?? '',
      updateUrl: json['updateUrl']?.toString().trim() ?? '',
      npmName: json['npmName']?.toString().trim() ?? '',
    );
  }
}
