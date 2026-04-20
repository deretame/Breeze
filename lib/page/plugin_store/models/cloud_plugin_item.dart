import 'package:zephyr/util/json/json_value.dart';

class CloudPluginItem {
  const CloudPluginItem({required this.repo, required this.manifest});

  final String repo;
  final CloudPluginManifest manifest;

  factory CloudPluginItem.fromJson(Map<String, dynamic> json) {
    return CloudPluginItem(
      repo: json['repo']?.toString().trim() ?? '',
      manifest: CloudPluginManifest.fromJson(asJsonMap(json['manifest'])),
    );
  }
}

class CloudPluginManifest {
  const CloudPluginManifest({
    required this.name,
    required this.uuid,
    required this.iconUrl,
    required this.creatorName,
    required this.creatorDescribe,
    required this.describe,
    required this.version,
    required this.home,
    required this.updateUrl,
  });

  final String name;
  final String uuid;
  final String iconUrl;
  final String creatorName;
  final String creatorDescribe;
  final String describe;
  final String version;
  final String home;
  final String updateUrl;

  factory CloudPluginManifest.fromJson(Map<String, dynamic> json) {
    final creator = asJsonMap(json['creator']);
    return CloudPluginManifest(
      name: json['name']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? '',
      creatorName: creator['name']?.toString() ?? '',
      creatorDescribe: creator['describe']?.toString() ?? '',
      describe: json['describe']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      home: json['home']?.toString() ?? '',
      updateUrl: json['updateUrl']?.toString() ?? '',
    );
  }
}
