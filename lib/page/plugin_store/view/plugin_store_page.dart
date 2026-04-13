import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/toast.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('插件商店')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchCard(colorScheme),
          const SizedBox(height: 14),
          _buildInstallButtons(colorScheme),
          if (_installing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (_lastMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(
              _lastMessage,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: !_installing,
              decoration: const InputDecoration(
                hintText: '搜索插件（即将支持）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _installing
                ? null
                : () {
                    showInfoToast('搜索功能开发中');
                  },
            icon: const Icon(Icons.search),
            label: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        _WideActionButton(
          icon: Icons.folder_open_outlined,
          title: '从本地添加插件',
          subtitle: '选择本地 JS/CJS/BR 插件文件',
          enabled: !_installing,
          onTap: _installFromLocal,
        ),
        const SizedBox(height: 10),
        _WideActionButton(
          icon: Icons.language_outlined,
          title: '从网络添加插件',
          subtitle: '输入可访问的插件脚本 URL',
          enabled: !_installing,
          onTap: _installFromNetwork,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '安装时会先调用 getInfo 获取 uuid，若与现有插件重复将禁止安装。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ),
      ],
    );
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
      final info = await _callGetInfoByGlobalQjs(normalizedScript);
      final resolvedUuid = _readUuidFromInfo(info);
      if (resolvedUuid.isEmpty) {
        throw StateError('getInfo 返回缺少 uuid');
      }
      final version = _readVersionFromInfo(info);

      _validateUuidNotDuplicated(resolvedUuid);

      final now = DateTime.now().toUtc();
      final existingInfo = _findExistingPluginInfoByUuid(resolvedUuid);
      final existing = PluginRegistryService.I.getByUuid(resolvedUuid);
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

      final success =
          '安装成功: uuid=$resolvedUuid, version=$version（$sourceLabel）';
      if (!mounted) {
        return;
      }
      setState(() {
        _lastMessage = '';
      });
      showSuccessToast(success);
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

class _WideActionButton extends StatelessWidget {
  const _WideActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
