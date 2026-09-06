import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/wind_http.dart';
import 'package:zephyr/network/utils/github_proxy.dart';
import 'package:zephyr/service/update/json/github_release_json.dart';
import 'package:zephyr/util/error_filter.dart';

const _proxyReleasesApiUrl = '$breezeGithubApi/repos/deretame/Breeze/releases';
const _githubReleasesApiUrl =
    'https://api.github.com/repos/deretame/Breeze/releases';

@RoutePage()
class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  final ScrollController _scrollController = ScrollController();

  List<GithubReleaseJson> _releases = [];
  bool _isLoading = true; // 首次加载状态
  String? _errorMsg;

  // 分页相关变量
  int _page = 1;
  static const int _perPage = 20; // 每次请求多少条
  bool _hasMore = true; // 是否还有更多数据
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    // 首次进入自动刷新
    _fetchReleases(refresh: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _isFetching ||
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 400) {
      return;
    }
    _fetchReleases();
  }

  /// 获取数据
  /// [refresh] 为 true 代表下拉刷新（重置页码），false 代表上拉加载（页码+1）
  Future<void> _fetchReleases({bool refresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!refresh && mounted) {
      setState(() {});
    }

    try {
      final requestPage = refresh ? 1 : _page;

      List<GithubReleaseJson>? newData;
      for (final url in [_proxyReleasesApiUrl, _githubReleasesApiUrl]) {
        try {
          final response = await fetch(
            url,
            query: {'page': requestPage, 'per_page': _perPage},
            headers: {'Accept': 'application/vnd.github.v3+json'},
          );

          if (response.ok) {
            newData = githubReleaseJsonFromJson(response.text);
            break;
          }
        } catch (_) {
          // 当前请求失败时继续尝试下一个地址。
        }
      }

      final releases = newData;
      if (releases != null) {
        if (mounted) {
          setState(() {
            if (refresh) {
              _releases = releases;
              _errorMsg = null; // 刷新成功清除错误
            } else {
              _releases.addAll(releases);
            }

            // 更新页码和是否还有更多数据
            _page = requestPage + 1;
            // 如果返回的数据条数少于每页最大条数，说明没有下一页了
            _hasMore = releases.length >= _perPage;

            // 首次加载完成
            _isLoading = false;
          });
        }
      } else {
        throw Exception('所有更新日志请求地址均失败');
      }
    } catch (e) {
      if (mounted) {
        // 如果是首次加载出错，显示全屏错误页面
        if (_releases.isEmpty && refresh) {
          setState(() {
            _isLoading = false;
            _errorMsg = normalizeSearchErrorMessage(e);
          });
        } else {
          // 如果是加载更多时出错，提示 Toast 或在底部显示失败
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.changelog.loadFailedWithError(error: e))),
          );
        }
      }
    } finally {
      _isFetching = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.changelog.cannotOpenLink(url: urlString))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.changelog.title),
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
              t.changelog.checkNetwork,
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
              child: Text(t.changelog.retry),
            ),
          ],
        ),
      );
    }

    if (_releases.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchReleases(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: Center(child: Text(t.changelog.empty)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchReleases(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _releases.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _releases.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
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
                      t.changelog.publishedAt(date: dateStr),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: t.changelog.viewInBrowser,
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
                          t.changelog.attachments,
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
