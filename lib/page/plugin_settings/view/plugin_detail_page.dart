import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/plugin_settings/models/plugin_detail.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/plugin_icon.dart';
import 'package:zephyr/widgets/toast.dart';
import 'package:zephyr/main.dart';

/// 新插件详情页：简介 + 作者 + md 长文 + 主页入口。
/// 长文按需调 `getPluginDetail` 获取，不在列表/设置页预取。
@RoutePage()
class PluginDetailPage extends StatefulWidget {
  const PluginDetailPage({
    super.key,
    required this.from,
    required this.pluginUuid,
    required this.pluginDisplayName,
  });

  final String from;
  final String pluginUuid;
  final String pluginDisplayName;

  @override
  State<PluginDetailPage> createState() => _PluginDetailPageState();
}

class _PluginDetailPageState extends State<PluginDetailPage> {
  bool _loading = true;
  String? _error;
  PluginDetail? _detail;
  String _iconUrl = '';
  String _version = '';
  String _cachedHome = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final registry = context.read<PluginRegistryCubit>().state;
      final cached = registry.infos[widget.pluginUuid];
      final localVersion =
          registry.plugins[widget.pluginUuid]?.version.trim() ?? '';
      final response = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'getPluginDetail',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final detail = PluginDetail.fromMap(response);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        final cachedMap = asJsonMap(cached);
        _iconUrl = cachedMap['iconUrl']?.toString().trim() ?? '';
        _version = localVersion;
        _cachedHome = cachedMap['home']?.toString().trim() ?? '';
        _loading = false;
      });
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      setState(() {
        _error = normalizeSearchErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _openHome(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      showErrorToast(t.plugin.invalidLink(url: url.trim()));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      showErrorToast(t.plugin.cannotOpenLink(url: url.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final home = _detail?.homeWithFallback(_cachedHome) ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pluginDisplayName),
        actions: [
          if (home.isNotEmpty)
            IconButton(
              tooltip: t.plugin.homepage,
              icon: const Icon(Icons.home_outlined),
              onPressed: () => _openHome(home),
            ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(t.common.retry)),
            ],
          ),
        ),
      );
    }
    final detail = _detail!;
    final home = detail.homeWithFallback(_cachedHome);
    final markdownConfig = MarkdownConfig(
      configs: [
        LinkConfig(
          style: TextStyle(
            color: colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          onTap: _openHome,
        ),
      ],
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCenterHeader(colorScheme, detail),
            if (detail.creatorName.isNotEmpty ||
                detail.creatorDescribe.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAuthorCard(colorScheme, detail, markdownConfig),
            ],
            if (detail.describe.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMarkdownCard(markdownConfig, detail.describe),
            ],
            if (home.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _openHome(home),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(t.plugin.homepage),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 顶部居中：插件头像 + 插件名 + 本地版本。
  Widget _buildCenterHeader(ColorScheme colorScheme, PluginDetail detail) {
    return Column(
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 88,
            height: 88,
            child: PluginIcon(
              url: _iconUrl,
              placeholder: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.extension_outlined, size: 40),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.pluginDisplayName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_version.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _version,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  /// 作者区：独立卡片，简介走 md 渲染，与插件描述视觉分离。
  Widget _buildAuthorCard(
    ColorScheme colorScheme,
    PluginDetail detail,
    MarkdownConfig markdownConfig,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorIcon(colorScheme, detail),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail.creatorName.isNotEmpty
                        ? detail.creatorName
                        : t.plugin.author,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (detail.creatorDescribe.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownWidget(
                data: detail.creatorDescribe,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                config: markdownConfig,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownCard(MarkdownConfig markdownConfig, String data) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MarkdownWidget(
          data: data,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          config: markdownConfig,
        ),
      ),
    );
  }

  /// 作者头像：有则 40px 圆角展示，无则人形图标占位。
  Widget _buildAuthorIcon(ColorScheme colorScheme, PluginDetail detail) {
    if (detail.creatorIconUrl.isEmpty) {
      return const Icon(Icons.person_outline, size: 40);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: PluginIcon(
          url: detail.creatorIconUrl,
          placeholder: ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.person_outline, size: 20)),
          ),
        ),
      ),
    );
  }
}
