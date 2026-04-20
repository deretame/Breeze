import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/github_proxy.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/toast.dart';

const _cloudPluginListUrl =
    'https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json';

@RoutePage()
class PluginStorePage extends StatefulWidget {
  const PluginStorePage({super.key});

  @override
  State<PluginStorePage> createState() => _PluginStorePageState();
}

class _PluginStorePageState extends State<PluginStorePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _installing = false;
  String _lastMessage = '';
  bool _cloudLoading = false;
  String _cloudError = '';
  List<_CloudPluginItem> _cloudPlugins = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCloudPlugins();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('插件商店')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSearchCard(colorScheme),
              const SizedBox(height: 14),
              _buildInstallButtons(colorScheme),
              const SizedBox(height: 16),
              _buildCloudPluginsSection(colorScheme),
              if (_installing) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '正在处理中...',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
              if (_lastMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          _lastMessage,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      enabled: !_installing,
      decoration: InputDecoration(
        hintText: '搜索插件名称或作者...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildInstallButtons(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _installing ? null : _installFromLocal,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('本地安装'),
        ),
        OutlinedButton.icon(
          onPressed: _installing ? null : _installFromNetwork,
          icon: const Icon(Icons.language_outlined, size: 18),
          label: const Text('网络安装'),
        ),
      ],
    );
  }

  Widget _buildCloudPluginsSection(ColorScheme colorScheme) {
    final query = _searchController.text.trim().toLowerCase();
    final displayPlugins = _cloudPlugins.where((item) {
      if (query.isEmpty) return true;
      final name = item.manifest.name.toLowerCase();
      final creator = item.manifest.creatorName.toLowerCase();
      final repo = item.repo.toLowerCase();
      return name.contains(query) ||
          creator.contains(query) ||
          repo.contains(query);
    }).toList();

    final hasData = _cloudPlugins.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_outlined, size: 18),
            const SizedBox(width: 8),
            Text('云端组件', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              tooltip: '刷新',
              visualDensity: VisualDensity.compact,
              onPressed: _cloudLoading ? null : _loadCloudPlugins,
              icon: _cloudLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_cloudLoading && !hasData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_cloudError.trim().isNotEmpty && !hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cloudError,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _cloudLoading ? null : _loadCloudPlugins,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          )
        else if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '暂无云端组件',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          )
        else
          Column(
            children: displayPlugins
                .map((item) => _buildCloudPluginCard(item, colorScheme))
                .toList(),
          ),
        if (_cloudError.trim().isNotEmpty && hasData) ...[
          const SizedBox(height: 8),
          Text(
            _cloudError,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildCloudPluginCard(_CloudPluginItem item, ColorScheme colorScheme) {
    final manifest = item.manifest;
    final localState = manifest.uuid.isNotEmpty
        ? PluginRegistryService.I.getByUuid(manifest.uuid)
        : null;
    final installed = localState != null;
    final localVersion = localState?.version.trim() ?? '';
    final creatorText = manifest.creatorName.trim().isNotEmpty
        ? manifest.creatorName.trim()
        : manifest.creatorDescribe.trim();
    final title = manifest.name.trim().isNotEmpty
        ? manifest.name.trim()
        : item.repo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CloudPluginIcon(iconUrl: manifest.iconUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localVersion.isNotEmpty
                          ? '云端 ${manifest.version}  ·  本地 $localVersion'
                          : '云端 ${manifest.version}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (manifest.describe.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        manifest.describe.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CloudMetaTag(label: '仓库', value: item.repo),
              if (manifest.uuid.trim().isNotEmpty)
                _CloudMetaTag(label: 'UUID', value: manifest.uuid.trim()),
              if (creatorText.isNotEmpty)
                _CloudMetaTag(label: '作者', value: creatorText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (installed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: colorScheme.primaryContainer,
                  ),
                  child: Text(
                    '已安装',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              if (installed) const SizedBox(width: 8),
              if (manifest.home.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _installing
                      ? null
                      : () => _openExternalUrl(manifest.home.trim()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('主页'),
                ),
              if (manifest.home.trim().isNotEmpty) const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _installing ? null : () => _installFromCloud(item),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(installed ? '下载更新' : '下载'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadCloudPlugins() async {
    if (mounted) {
      setState(() {
        _cloudLoading = true;
        _cloudError = '';
      });
    }

    try {
      final payload = await _fetchCloudPluginListPayload(_cloudPluginListUrl);
      final decoded = jsonDecode(payload);
      final entries = asJsonList(decoded)
          .map((item) => _CloudPluginItem.fromJson(asJsonMap(item)))
          .where((item) => item.manifest.uuid.trim().isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _cloudPlugins = entries;
        _cloudLoading = false;
        _cloudError = '';
      });
    } catch (e, stackTrace) {
      logger.w('拉取云端插件列表失败', error: e, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _cloudLoading = false;
        _cloudError = '云端组件列表加载失败: $e';
      });
    }
  }

  Future<String> _fetchCloudPluginListPayload(String sourceUrl) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    Object? lastError;
    for (final requestUrl in requestUrls) {
      try {
        final response = await client.get<String>(
          requestUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: {'Accept': 'application/json, text/plain, */*'},
          ),
        );
        final body = response.data?.trim() ?? '';
        if ((response.statusCode ?? 0) == 200 && body.isNotEmpty) {
          return body;
        }
      } catch (e, stackTrace) {
        lastError = e;
        logger.w('云端插件列表通道失败: $requestUrl', error: e, stackTrace: stackTrace);
      }
    }

    throw StateError('所有云端插件列表通道都不可用: $lastError');
  }

  List<String> _buildCloudRequestCandidates(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    final result = <String>[];
    if (uri != null) {
      final isGithubHost =
          uri.host == 'raw.githubusercontent.com' ||
          uri.host == 'github.com' ||
          uri.host == 'www.github.com';
      if (isGithubHost) {
        result.add('https://gh-proxy.org/$sourceUrl');
      }
    }
    result.add(sourceUrl);
    return result.toSet().toList();
  }

  Future<void> _openExternalUrl(String rawUrl) async {
    final resolved = rawUrl.trim();
    if (resolved.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      showErrorToast('无效链接: $resolved');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      showErrorToast('无法打开链接: $resolved');
    }
  }

  Future<void> _installFromCloud(_CloudPluginItem item) async {
    if (_installing) {
      return;
    }
    final updateUrl = item.manifest.updateUrl.trim();
    if (updateUrl.isEmpty) {
      _reportError('该插件未提供 updateUrl，无法下载');
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _installing = true;
      _lastMessage = '';
    });

    try {
      final release = await fetchReleaseData(updateUrl);
      final asset = _pickPreferredPluginAsset(asJsonList(release['assets']));
      if (asset == null) {
        throw StateError('未找到可安装资源（仅支持 .cjs.br 或 .cjs）');
      }
      final assetName = asset['name']?.toString().trim() ?? '';
      final downloadUrl =
          asset['browser_download_url']?.toString().trim() ?? '';
      if (downloadUrl.isEmpty) {
        throw StateError('release 资产缺少 browser_download_url');
      }

      final response = await _downloadPluginAssetWithFallback(downloadUrl);
      final script = await _decodeDownloadedPluginScript(
        response: response,
        resolvedUrl: downloadUrl,
      );
      await _savePluginByScript(
        script,
        sourceLabel:
            '云端组件: ${item.repo}${assetName.isNotEmpty ? '/$assetName' : ''}',
        allowReplaceExisting: true,
      );
    } catch (e) {
      _reportError('云端下载失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _installing = false;
        });
      }
    }
  }

  Map<String, dynamic>? _pickPreferredPluginAsset(List<dynamic> rawAssets) {
    final assets = rawAssets
        .map((item) => asJsonMap(item))
        .where(
          (item) =>
              (item['browser_download_url']?.toString().trim().isNotEmpty ??
                  false) &&
              (item['name']?.toString().trim().isNotEmpty ?? false),
        )
        .toList();
    if (assets.isEmpty) {
      return null;
    }

    Map<String, dynamic>? findByExt(String ext) {
      for (final asset in assets) {
        final name = asset['name']?.toString().toLowerCase().trim() ?? '';
        if (name.endsWith(ext)) {
          return asset;
        }
      }
      return null;
    }

    return findByExt('.cjs.br') ?? findByExt('.cjs');
  }

  Future<Response<List<int>>> _downloadPluginAssetWithFallback(
    String sourceUrl,
  ) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
      ),
    );

    Object? lastError;
    for (final requestUrl in requestUrls) {
      try {
        final response = await client.get<List<int>>(
          requestUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept': '*/*'},
          ),
        );
        final body = response.data ?? const <int>[];
        if (body.isNotEmpty) {
          return response;
        }
        lastError = StateError('空响应: $requestUrl');
      } catch (e, stackTrace) {
        lastError = e;
        logger.w('插件资源下载通道失败: $requestUrl', error: e, stackTrace: stackTrace);
      }
    }

    throw StateError('插件资源下载失败: $lastError');
  }

  Future<void> _installFromLocal() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'plugin script',
            extensions: ['js', 'cjs', 'br'],
            uniformTypeIdentifiers: ['public.javascript'],
          ),
        ],
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      final script = await _decodePluginScriptFromBytes(
        bytes: bytes,
        shouldUseBrotli: file.name.toLowerCase().endsWith('.br'),
      );
      await _installPluginByScript(script, sourceLabel: '本地文件: ${file.name}');
    } catch (e) {
      _reportError('读取本地插件失败: $e');
    }
  }

  Future<void> _installFromNetwork() async {
    final url = await _showInputDialog(
      context,
      title: '从网络添加插件',
      hintText: '请输入插件脚本 URL',
    );
    if (url == null) {
      return;
    }

    final resolvedUrl = url.trim();
    if (resolvedUrl.isEmpty) {
      _reportError('URL 不能为空');
      return;
    }

    try {
      final response = await directDio.get<List<int>>(
        resolvedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final script = await _decodeDownloadedPluginScript(
        response: response,
        resolvedUrl: resolvedUrl,
      );
      await _installPluginByScript(script, sourceLabel: '网络地址: $resolvedUrl');
    } catch (e) {
      _reportError('网络下载插件失败: $e');
    }
  }

  Future<String> _decodeDownloadedPluginScript({
    required Response<List<int>> response,
    required String resolvedUrl,
  }) async {
    final body = response.data ?? const <int>[];
    if (body.isEmpty) {
      return '';
    }

    final lowerUrl = resolvedUrl.toLowerCase();
    final contentEncoding = (response.headers.value('content-encoding') ?? '')
        .toLowerCase();
    final shouldUseBrotli =
        lowerUrl.endsWith('.br') || contentEncoding.contains('br');
    return _decodePluginScriptFromBytes(
      bytes: body,
      shouldUseBrotli: shouldUseBrotli,
    );
  }

  Future<String> _decodePluginScriptFromBytes({
    required List<int> bytes,
    required bool shouldUseBrotli,
  }) async {
    if (bytes.isEmpty) {
      return '';
    }
    final decodedBytes = shouldUseBrotli
        ? await decompressExtreme(data: bytes)
        : bytes;
    return utf8.decode(decodedBytes, allowMalformed: true);
  }

  Future<void> _installPluginByScript(
    String script, {
    required String sourceLabel,
    bool allowReplaceExisting = false,
  }) async {
    final normalizedScript = script.trim();
    if (normalizedScript.isEmpty) {
      _reportError('插件脚本内容为空，无法安装（$sourceLabel）');
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _installing = true;
      _lastMessage = '';
    });

    try {
      await _savePluginByScript(
        normalizedScript,
        sourceLabel: sourceLabel,
        allowReplaceExisting: allowReplaceExisting,
      );
    } catch (e) {
      _reportError('安装失败（$sourceLabel）: $e');
    } finally {
      if (mounted) {
        setState(() {
          _installing = false;
        });
      }
    }
  }

  Future<void> _savePluginByScript(
    String normalizedScript, {
    required String sourceLabel,
    bool allowReplaceExisting = false,
  }) async {
    final info = await _callGetInfoByGlobalQjs(normalizedScript);
    final resolvedUuid = _readUuidFromInfo(info);
    if (resolvedUuid.isEmpty) {
      throw StateError('getInfo 返回缺少 uuid');
    }
    final version = _readVersionFromInfo(info);

    final existing = PluginRegistryService.I.getByUuid(resolvedUuid);
    if (!allowReplaceExisting) {
      _validateUuidNotDuplicated(resolvedUuid);
    }

    final now = DateTime.now().toUtc();
    final existingInfo = _findExistingPluginInfoByUuid(resolvedUuid);
    final infoToSave = PluginInfo(
      id: existingInfo?.id ?? 0,
      uuid: resolvedUuid,
      version: version,
      originScript: normalizedScript,
      insertedAt: existingInfo?.insertedAt ?? existing?.insertedAt ?? now,
      updatedAt: now,
      isEnabled: true,
      isDeleted: false,
      deletedAt: null,
      lastLoadSuccess: false,
      lastLoadError: null,
      debug: existing?.debug ?? false,
      debugUrl: existing?.debugUrl,
    );

    await PluginRegistryService.I.upsert(infoToSave);
    await PluginRegistryService.I.setEnabled(resolvedUuid, true);

    final action = existing == null ? '安装成功' : '更新成功';
    if (!mounted) {
      return;
    }
    setState(() {
      _lastMessage = '';
    });
    showSuccessToast(
      '$action: uuid=$resolvedUuid, version=$version（$sourceLabel）',
    );
  }

  Future<Map<String, dynamic>> _callGetInfoByGlobalQjs(String bundleJs) async {
    await PluginRegistryService.I.initializeGlobalRuntime();
    final raw = await qjsCallOnce(
      runtimeName: 'global',
      bundleJs: bundleJs,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    return requireJsonMap(jsonDecode(raw), message: 'getInfo 返回格式错误');
  }

  String _readUuidFromInfo(Map<String, dynamic> info) {
    final uuid = info['uuid']?.toString().trim() ?? '';
    if (uuid.isNotEmpty) {
      return uuid;
    }
    final dataUuid = asJsonMap(info['data'])['uuid']?.toString().trim() ?? '';
    if (dataUuid.isNotEmpty) {
      return dataUuid;
    }
    return '';
  }

  String _readVersionFromInfo(Map<String, dynamic> info) {
    final version = info['version']?.toString().trim() ?? '';
    if (version.isNotEmpty) {
      return version;
    }
    final dataVersion =
        asJsonMap(info['data'])['version']?.toString().trim() ?? '';
    if (dataVersion.isNotEmpty) {
      return dataVersion;
    }
    return '0.0.0';
  }

  void _validateUuidNotDuplicated(String uuid) {
    final existing = PluginRegistryService.I.getByUuid(uuid);
    if (existing != null) {
      throw StateError('插件已存在，禁止重复安装: uuid=$uuid');
    }
  }

  PluginInfo? _findExistingPluginInfoByUuid(String uuid) {
    return objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
  }

  void _reportError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lastMessage = message;
    });
    showErrorToast(message);
  }

  Future<String?> _showInputDialog(
    BuildContext context, {
    required String title,
    required String hintText,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hintText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('开始安装'),
          ),
        ],
      ),
    );
  }
}

class _CloudPluginIcon extends StatelessWidget {
  const _CloudPluginIcon({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: colorScheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: iconUrl.trim().isEmpty
            ? Icon(
                Icons.extension_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              )
            : Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.extension_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _CloudMetaTag extends StatelessWidget {
  const _CloudMetaTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _CloudPluginItem {
  const _CloudPluginItem({required this.repo, required this.manifest});

  final String repo;
  final _CloudPluginManifest manifest;

  factory _CloudPluginItem.fromJson(Map<String, dynamic> json) {
    return _CloudPluginItem(
      repo: json['repo']?.toString().trim() ?? '',
      manifest: _CloudPluginManifest.fromJson(asJsonMap(json['manifest'])),
    );
  }
}

class _CloudPluginManifest {
  const _CloudPluginManifest({
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

  factory _CloudPluginManifest.fromJson(Map<String, dynamic> json) {
    final creator = asJsonMap(json['creator']);
    return _CloudPluginManifest(
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
