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

  /// 直达 GitHub 仓库的 URL：优先 manifest 的 `breeze-plugin-github-repository`，
  /// 缺失时由顶层 `repo`（owner/name）推导；仍无效则为空，调用方隐藏按钮。
  String get githubRepositoryUrl {
    final explicit = manifest.githubRepository.trim();
    if (_isHttpUrl(explicit)) return explicit;
    final slug = repo.trim();
    if (RegExp(r'^[\w.\-]+/[\w.\-]+$').hasMatch(slug)) {
      return 'https://github.com/$slug';
    }
    return '';
  }
}

bool _isHttpUrl(String value) {
  if (value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
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
    required this.npmName,
    required this.githubRepository,
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
  final String npmName;
  final String githubRepository;

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
      npmName: json['npmName']?.toString() ?? '',
      githubRepository:
          json['breeze-plugin-github-repository']?.toString().trim() ?? '',
    );
  }
}
