import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/comic_read/widgets/settings/reader_settings_sheet.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/config/router/router.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';

class BottomWidget extends StatefulWidget {
  final ComicEntryType type;
  final dynamic comicInfo;
  final Widget sliderWidget;
  final int order;
  final int epsNumber;
  final String comicId;
  final String from;
  final JumpChapter jumpChapter;
  final ValueChanged<bool>? onLandscapeChanged;

  const BottomWidget({
    super.key,
    required this.type,
    required this.comicInfo,
    required this.sliderWidget,
    required this.order,
    required this.epsNumber,
    required this.comicId,
    required this.from,
    required this.jumpChapter,
    this.onLandscapeChanged,
  });

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  bool get isDownload =>
      widget.type == ComicEntryType.download ||
      widget.type == ComicEntryType.historyAndDownload;

  JumpChapter get jumpChapter => widget.jumpChapter;

  final Duration _animationDuration = const Duration(milliseconds: 300); // 动画时长

  late ComicEntryType tempType;
  late String comicId;
  List<UnifiedComicChapterRef> chapterRefs = [];

  @override
  void initState() {
    super.initState();

    tempType = widget.type;
    comicId = widget.comicId;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
    chapterRefs = resolveUnifiedComicChapters(widget.comicInfo, widget.from);
  }

  @override
  Widget build(BuildContext context) {
    final isMenuVisible = context.select(
      (ReaderCubit cubit) => cubit.state.isMenuVisible,
    );
    final bottomSafeHeight = context.bottomSafeHeight;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideLayout = screenWidth >= 840;
    final topMaxWidth = (screenWidth * 0.56).clamp(380.0, 720.0).toDouble();
    final bottomMaxWidth = (screenWidth * (screenWidth >= 1200 ? 0.62 : 0.74))
        .clamp(560.0, 980.0)
        .toDouble();
    final isCompactLayout =
        screenWidth >= 600 && MediaQuery.sizeOf(context).height <= 600;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isMenuVisible,
        child: AnimatedSlide(
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          offset: isMenuVisible ? Offset.zero : const Offset(0, 1),
          child: Padding(
            padding: EdgeInsets.only(bottom: 6 + bottomSafeHeight),
            child: isCompactLayout
                ? _buildCompactControls(
                    maxWidth: bottomMaxWidth,
                    isWideLayout: isWideLayout,
                  )
                : _buildRegularControls(
                    topMaxWidth: topMaxWidth,
                    bottomMaxWidth: bottomMaxWidth,
                    isWideLayout: isWideLayout,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularControls({
    required double topMaxWidth,
    required double bottomMaxWidth,
    required bool isWideLayout,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWideLayout ? topMaxWidth : double.infinity,
              ),
              child: _buildControlButtons(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWideLayout ? bottomMaxWidth : double.infinity,
              ),
              child: Row(children: [widget.sliderWidget]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactControls({
    required double maxWidth,
    required bool isWideLayout,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideLayout ? maxWidth : double.infinity,
          ),
          child: Row(
            children: [
              _buildControlButtons(),
              const SizedBox(width: 12),
              widget.sliderWidget,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChapterNavigationButton(
          icon: Icons.skip_previous_rounded,
          tooltip: t.reader.previousChapter,
          isEnabled: jumpChapter.havePrev,
          onTap: () => _jumpToChapter(true),
        ),
        const SizedBox(width: 10),
        FloatingActionIconButton(
          icon: Icons.home_rounded,
          tooltip: t.reader.backToHome,
          onPressed: () => popToRoot(context),
        ),
        const SizedBox(width: 10),
        FloatingActionIconButton(
          icon: Icons.list_alt_rounded,
          tooltip: t.reader.selectChapter,
          isEnabled: chapterRefs.isNotEmpty,
          onPressed: _selectJumpChapter,
        ),
        const SizedBox(width: 10),
        FloatingActionIconButton(
          icon: Icons.tune_rounded,
          tooltip: t.reader.settings,
          onPressed: _openSettingsPanel,
        ),
        const SizedBox(width: 10),
        ChapterNavigationButton(
          icon: Icons.skip_next_rounded,
          tooltip: t.reader.nextChapter,
          isEnabled: jumpChapter.haveNext,
          onTap: () => _jumpToChapter(false),
        ),
      ],
    );
  }

  void _openSettingsPanel() {
    final readerCubit = context.read<ReaderCubit>();
    showReaderSettingsSheet(
      context,
      changePageIndex: (int value) {
        readerCubit.updateCurrentSlot(value);
        readerCubit.updateSliderChanged(0.0);
      },
      onLandscapeChanged: widget.onLandscapeChanged,
      source: widget.from,
      comicId: widget.comicId,
    );
  }

  Future<bool> _bottomButtonDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 不允许点击外部区域关闭对话框
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  child: Text(t.common.cancel),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 返回 false
                  },
                ),
                TextButton(
                  child: Text(t.common.ok),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 返回 true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 处理返回值为空的情况
  }

  Future<void> _jumpToChapter(bool isPrev) async {
    final dialogMessage = isPrev
        ? t.reader.previousChapter
        : t.reader.nextChapter;
    final result = await _bottomButtonDialog(
      context,
      t.reader.jumpToChapterTitle,
      t.reader.jumpToChapterMessage(chapter: dialogMessage),
    );
    if (!result) return;
    if (!mounted) return;
    jumpChapter.jumpToChapter(context, isPrev);
  }

  Future<void> _selectJumpChapter() async {
    final router = AutoRouter.of(context);
    final initialIndex = jumpChapter.currentChapterIndexIn(chapterRefs);
    final result = await showDialog<UnifiedComicChapterRef?>(
      context: context,
      barrierDismissible: false, // 不允许点击外部区域关闭对话框
      builder: (BuildContext context) {
        return _ChapterPickerDialog(
          refs: chapterRefs,
          initialIndex: initialIndex,
          onSelected: (ep) =>
              Navigator.of(context, rootNavigator: false).pop(ep),
        );
      },
    );
    if (result != null && mounted) {
      final chapter = const DownloadChapterAdapter().fromChapterRef(result);
      router.replace(
        ComicReadRoute(
          key: Key(Uuid().v4()),
          comicInfo: widget.comicInfo,
          comicId: comicId,
          type: tempType,
          order: chapter.order,
          chapterId: chapter.id,
          requestId: result.requestId.trim(),
          storageChapterId: result.storageChapterId.trim(),
          logicalKey: chapter.id,
          chapterExtern: Map<String, dynamic>.from(chapter.extern),
          epsNumber: widget.epsNumber,
          from: widget.from,
          stringSelectCubit: context.read<StringSelectCubit>(),
        ),
      );
    }
  }
}

class _ChapterPickerDialog extends StatefulWidget {
  final List<UnifiedComicChapterRef> refs;
  final int initialIndex;
  final ValueChanged<UnifiedComicChapterRef> onSelected;

  const _ChapterPickerDialog({
    required this.refs,
    required this.initialIndex,
    required this.onSelected,
  });

  @override
  State<_ChapterPickerDialog> createState() => _ChapterPickerDialogState();
}

class _ChapterPickerDialogState extends State<_ChapterPickerDialog> {
  // 行高只是估算（章节名可能换行），用于对话框高度与首屏定位；
  // 精确定位靠 _targetKey + ensureVisible。
  static const double _estimatedRowHeight = 52.0;
  static const int _maxRevealAttempts = 3;

  GlobalKey? _targetKey;
  late final ScrollController _scrollController;
  int _revealAttempts = 0;

  bool get _hasValidInitial =>
      widget.initialIndex >= 0 && widget.initialIndex < widget.refs.length;

  @override
  void initState() {
    super.initState();
    // 原来是 List.generate(refs.length) 建 N 个 GlobalKey，
    // 全局注册 + 阻碍复用；现在只给当前章节留 1 个。
    if (_hasValidInitial) {
      _targetKey = GlobalKey();
      _scrollController = ScrollController(
        initialScrollOffset: widget.initialIndex * _estimatedRowHeight,
      );
    } else {
      _scrollController = ScrollController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealInitial());
  }

  /// 直接定位到当前章节（无动画）。目标行还没建出来时先跳到估算位置，
  /// 下一帧再精确定位；超过次数就停在估算位置附近，不死循环。
  void _revealInitial() {
    if (!mounted || _revealAttempts >= _maxRevealAttempts) return;
    _revealAttempts++;
    final key = _targetKey;
    if (key == null) return;
    final targetContext = key.currentContext;
    if (targetContext == null) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(
          (widget.initialIndex * _estimatedRowHeight).clamp(0.0, max),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealInitial());
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onPrimaryContainer,
      backgroundColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    // 定高（按估算行高撑，封顶 60% 屏高）：ListView 高度有界，
    // 不用 shrinkWrap 也能懒加载，只建可视行。
    final screenSize = MediaQuery.sizeOf(context);
    final maxHeight = screenSize.height * 0.6;
    final listHeight = (widget.refs.length * _estimatedRowHeight + 16).clamp(
      120.0,
      maxHeight,
    );
    // 桌面端别撑满：最多 440，手机上占 90% 屏宽。
    final listWidth = (screenSize.width * 0.9).clamp(0.0, 440.0).toDouble();

    return AlertDialog(
      title: Text(t.reader.selectChapter),
      content: SizedBox(
        width: listWidth,
        height: listHeight,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.refs.length,
          itemBuilder: (context, i) {
            final ref = widget.refs[i];
            final isCurrent = i == widget.initialIndex;
            return Padding(
              key: isCurrent ? _targetKey : null,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TextButton(
                style: isCurrent ? highlightStyle : null,
                onPressed: () => widget.onSelected(ref),
                child: Row(
                  children: [
                    Expanded(child: Text(ref.name)),
                    if (isCurrent)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text(t.common.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class ChapterNavigationButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onTap;

  const ChapterNavigationButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return _FrostedCircleIconButton(
      tooltip: tooltip,
      isEnabled: isEnabled,
      onPressed: onTap,
      icon: icon,
      foregroundColor: colorScheme.onSecondaryContainer,
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.72),
      disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.38,
      ),
    );
  }
}

class FloatingActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onPressed;

  const FloatingActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return _FrostedCircleIconButton(
      tooltip: tooltip,
      isEnabled: isEnabled,
      onPressed: onPressed,
      icon: icon,
      foregroundColor: colorScheme.onPrimaryContainer,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.76),
      disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.38,
      ),
    );
  }
}

class _FrostedCircleIconButton extends StatelessWidget {
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onPressed;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color disabledBackgroundColor;

  const _FrostedCircleIconButton({
    required this.tooltip,
    required this.isEnabled,
    required this.onPressed,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.disabledBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: IconButton(
          tooltip: tooltip,
          onPressed: isEnabled ? onPressed : null,
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            shape: const CircleBorder(),
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            disabledForegroundColor: colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            disabledBackgroundColor: disabledBackgroundColor,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
