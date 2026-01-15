import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/util/update/json/github_release_json.dart';

@RoutePage()
class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  final Dio _dio = Dio();

  List<GithubReleaseJson> _releases = [];
  bool _isLoading = true; // 首次加载状态
  String? _errorMsg;

  // 分页相关变量
  int _page = 1;
  static const int _perPage = 20; // 每次请求多少条
  bool _hasMore = true; // 是否还有更多数据

  @override
  void initState() {
    super.initState();
    // 首次进入自动刷新
    _fetchReleases(refresh: true);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _dio.close();
    super.dispose();
  }

  /// 获取数据
  /// [refresh] 为 true 代表下拉刷新（重置页码），false 代表上拉加载（页码+1）
  Future<void> _fetchReleases({bool refresh = false}) async {
    try {
      final requestPage = refresh ? 1 : _page;

      final response = await _dio.get(
        'https://api.github.com/repos/deretame/Breeze/releases',
        queryParameters: {'page': requestPage, 'per_page': _perPage},
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        final List<GithubReleaseJson> newData = githubReleaseJsonFromJson(
          response.data as String,
        );

        if (mounted) {
          setState(() {
            if (refresh) {
              _releases = newData;
              _errorMsg = null; // 刷新成功清除错误
            } else {
              _releases.addAll(newData);
            }

            // 更新页码和是否还有更多数据
            _page = requestPage + 1;
            // 如果返回的数据条数少于每页最大条数，说明没有下一页了
            _hasMore = newData.length >= _perPage;

            // 首次加载完成
            _isLoading = false;
          });
        }

        // 告诉 EasyRefresh 动作完成了
        if (refresh) {
          _refreshController.finishRefresh();
          _refreshController.resetFooter(); // 重置底部状态
        } else {
          _refreshController.finishLoad(
            _hasMore ? IndicatorResult.success : IndicatorResult.noMore,
          );
        }
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        // 如果是首次加载出错，显示全屏错误页面
        if (_releases.isEmpty && refresh) {
          setState(() {
            _isLoading = false;
            _errorMsg = e.toString();
          });
        } else {
          // 如果是加载更多时出错，提示 Toast 或在底部显示失败
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
        }
      }

      // 结束 EasyRefresh 状态
      if (refresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      } else {
        _refreshController.finishLoad(IndicatorResult.fail);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('更新日志'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    // 首次全屏 Loading
    if (_isLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: colorScheme.primary,
          size: 50,
        ),
      );
    }

    // 首次全屏错误
    if (_errorMsg != null && _releases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '加载失败，请检查网络',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMsg = null;
                });
                _fetchReleases(refresh: true);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_releases.isEmpty) {
      return EasyRefresh(
        header: const MaterialHeader(),
        onRefresh: () => _fetchReleases(refresh: true),
        child: const Center(child: Text('暂无更新日志')),
      );
    }

    return EasyRefresh(
      controller: _refreshController,
      header: const MaterialHeader(),
      footer: const MaterialFooter(),
      // 下拉刷新
      onRefresh: () async {
        await _fetchReleases(refresh: true);
      },

      // 上拉加载
      onLoad: () async {
        if (!_hasMore) {
          _refreshController.finishLoad(IndicatorResult.noMore);
          return;
        }
        await _fetchReleases(refresh: false);
      },

      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _releases.length,
        itemBuilder: (context, index) {
          final release = _releases[index];
          return Container(
            key: ValueKey(release.id), // 添加 Key 提高性能
            child: _ReleaseCard(release: release, onLinkTap: _launchUrl)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
          );
        },
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final GithubReleaseJson release;
  final Function(String) onLinkTap;

  const _ReleaseCard({required this.release, required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateStr = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(release.publishedAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shadowColor: Colors.transparent,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),

      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            release.tagName,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (release.prerelease)
                          _TagChip(text: 'Pre', color: Colors.orange),
                        if (release.draft) ...[
                          const SizedBox(width: 4),
                          _TagChip(text: 'Draft', color: Colors.grey),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '发布于 $dateStr',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: '在浏览器中查看',
                child: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onLinkTap(release.htmlUrl),
                ),
              ),
            ],
          ),
          children: [
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            MarkdownWidget(
              data: release.body,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              config: MarkdownConfig(
                configs: [
                  PConfig(
                    textStyle: textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  LinkConfig(
                    style: TextStyle(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    onTap: (url) => onLinkTap(url),
                  ),
                  CodeConfig(
                    style: TextStyle(
                      backgroundColor: colorScheme.surface,
                      fontFamily: 'monospace',
                    ),
                  ),
                  PreConfig(
                    decoration: BoxDecoration(
                      color: colorScheme.surface, // 代码块背景
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (release.assets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // 附件区域背景色，使用 surface 形成凹陷感，或者 secondaryContainer 形成凸起感
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '附件下载',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: release.assets.map((asset) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            Icons.download_rounded,
                            size: 14,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          label: Text(asset.name),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                          side: BorderSide.none,
                          onPressed: () => onLinkTap(asset.browserDownloadUrl),
                          tooltip:
                              '${(asset.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
