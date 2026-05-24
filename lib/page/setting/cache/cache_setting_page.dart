import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/widgets/toast.dart';

import '../common/setting_ui.dart';

const Map<int, String> _cacheLimitLabels = {
  536870912: '512 MB',
  1073741824: '1 GB',
  2147483648: '2 GB',
  4294967296: '4 GB',
  8589934592: '8 GB',
  17179869184: '16 GB',
};

final List<int> _cacheLimitOptions = _cacheLimitLabels.keys.toList()..sort();

@RoutePage()
class CacheSettingPage extends StatefulWidget {
  const CacheSettingPage({super.key});

  @override
  State<CacheSettingPage> createState() => _CacheSettingPageState();
}

class _CacheSettingPageState extends State<CacheSettingPage> {
  int? _cacheSizeBytes;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    if (_calculating) return;
    setState(() => _calculating = true);

    try {
      final cachePath = await getCachePath();
      final directory = Directory(cachePath);
      if (!await directory.exists()) {
        if (!mounted) return;
        setState(() {
          _cacheSizeBytes = 0;
          _calculating = false;
        });
        return;
      }

      int totalSize = 0;
      final entities = directory.listSync(recursive: true);
      for (final entity in entities) {
        final isSentry = entity.path
            .split(Platform.pathSeparator)
            .contains('sentry');
        if (entity is File && !isSentry) {
          try {
            totalSize += await entity.length();
          } on FileSystemException {
            continue;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _cacheSizeBytes = totalSize;
        _calculating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cacheSizeBytes = null;
        _calculating = false;
      });
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '计算失败';
    if (bytes == 0) return '0 B';

    const gb = 1 << 30;
    const mb = 1 << 20;
    const kb = 1 << 10;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(2)} GB';
    } else if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  Future<void> _handleClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理所有缓存文件吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final cachePath = await getCachePath();
      await clearCache(cachePath);
      showSuccessToast('缓存已清理');
      _calculateCacheSize();
    } catch (_) {
      showSuccessToast('清理失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '缓存管理',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: ListView(
            children: [
              _buildSectionTitle(context, '当前缓存'),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('缓存大小'),
                subtitle: Text(
                  _calculating ? '计算中…' : _formatSize(_cacheSizeBytes),
                ),
                trailing: _calculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: '重新计算',
                        onPressed: _calculateCacheSize,
                      ),
              ),
              const Divider(height: 1, thickness: 0.3),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('手动清理缓存'),
                subtitle: const Text('立即删除所有缓存文件'),
                trailing: FilledButton.tonalIcon(
                  onPressed: _handleClearCache,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('清理'),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '缓存限制'),
              ListTile(
                leading: const Icon(Icons.data_thresholding_outlined),
                title: const Text('缓存上限'),
                subtitle: const Text('达到上限后将自动清理旧缓存'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value:
                        _cacheLimitOptions.contains(
                          state.cacheSetting.cacheSizeLimit,
                        )
                        ? state.cacheSetting.cacheSizeLimit
                        : 1073741824,
                    icon: const Icon(Icons.expand_more),
                    onChanged: (int? value) {
                      if (value != null) {
                        cubit.updateCacheSetting(
                          (current) => current.copyWith(cacheSizeLimit: value),
                        );
                      }
                    },
                    items: _cacheLimitOptions.map<DropdownMenuItem<int>>((
                      size,
                    ) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text(_cacheLimitLabels[size] ?? '$size'),
                      );
                    }).toList(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(context, '自动清理'),
              SwitchListTile(
                secondary: const Icon(Icons.auto_delete_outlined),
                title: const Text('自动清理缓存'),
                subtitle: const Text('关闭后将不再自动清理任何缓存'),
                thumbIcon: kSettingSwitchThumbIcon,
                value: state.cacheSetting.autoCleanCache,
                onChanged: (bool value) {
                  cubit.updateCacheSetting(
                    (current) => current.copyWith(autoCleanCache: value),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
