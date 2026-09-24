part of 'reader_settings_sheet.dart';

class _ReaderSettingsReadTab extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final ValueChanged<bool>? onLandscapeChanged;
  final String source;
  final String comicId;

  const _ReaderSettingsReadTab({
    required this.changePageIndex,
    this.onLandscapeChanged,
    this.source = '',
    this.comicId = '',
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadModeSection(
            changePageIndex: changePageIndex,
            onLandscapeChanged: onLandscapeChanged,
            source: source,
            comicId: comicId,
          ),
          const SizedBox(height: 18),
          const _ThemeModeSection(),
          const SizedBox(height: 18),
          const _ReadBackgroundSection(),
          const SizedBox(height: 18),
          const _AutoReadSection(),
          const SizedBox(height: 18),
          const _PreloadSection(),
          const SizedBox(height: 18),
          const _ReadExperienceSection(),
        ],
      ),
    );
  }
}

class _ReadModeSection extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final ValueChanged<bool>? onLandscapeChanged;
  final String source;
  final String comicId;

  const _ReadModeSection({
    required this.changePageIndex,
    this.onLandscapeChanged,
    this.source = '',
    this.comicId = '',
  });

  bool get _perComicAvailable =>
      source.trim().isNotEmpty && comicId.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final isMobilePlatform =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !isTablet(context);
    // 本漫特定设置仅在阅读页入口（带 source/comicId）可用，全局设置页隐藏。
    final perComicState = _perComicAvailable
        ? context.watch<ComicReadPreferenceCubit>().state
        : const ComicReadPreferenceState();
    final perComicEnabled = _perComicAvailable && perComicState.hasOverride;
    // 有效阅读模式：启用本漫设置时用覆盖值，否则跟随全局。
    final effectiveReadMode =
        perComicState.overrideReadMode ??
        globalSettingState.readSetting.readMode;

    Future<void> selectGlobalReadMode(int mode) async {
      if (globalSettingState.readSetting.readMode == mode) return;
      HapticFeedback.selectionClick();
      globalSettingCubit.updateReadSetting(
        (current) => current.copyWith(readMode: mode),
      );
      changePageIndex(0);
    }

    Future<void> selectPerComicReadMode(int mode) async {
      if (perComicState.overrideReadMode == mode) return;
      HapticFeedback.selectionClick();
      await context.read<ComicReadPreferenceCubit>().setOverride(mode);
      changePageIndex(0);
    }

    return _SettingsSection(
      title: t.reader.readingMode,
      children: [
        if (_perComicAvailable) ...[
          _SettingsSwitchTile(
            title: t.reader.perComicReadMode,
            subtitle: t.reader.perComicReadModeSubtitle,
            value: perComicEnabled,
            onChanged: (value) async {
              HapticFeedback.selectionClick();
              final cubit = context.read<ComicReadPreferenceCubit>();
              if (value) {
                await cubit.setOverride(
                  globalSettingState.readSetting.readMode,
                );
              } else {
                await cubit.clearOverride();
              }
              changePageIndex(0);
            },
          ),
          // 开关打开后展开本漫独立选项，给出明确的展开/收起动效。
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: perComicEnabled
                ? _PerComicReadModeOptions(
                    overrideReadMode:
                        perComicState.overrideReadMode ??
                        globalSettingState.readSetting.readMode,
                    onSelect: selectPerComicReadMode,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
        // 全局阅读模式：任何时候改这里都是改全局。
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.webtoon,
              selected: globalSettingState.readSetting.readMode == 0,
              onTap: () => selectGlobalReadMode(0),
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageLtr,
              selected: globalSettingState.readSetting.readMode == 1,
              onTap: () => selectGlobalReadMode(1),
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageRtl,
              selected: globalSettingState.readSetting.readMode == 2,
              onTap: () => selectGlobalReadMode(2),
            ),
          ],
        ),
        if (isMobilePlatform && onLandscapeChanged != null)
          _SettingsSwitchTile(
            title: t.reader.landscapeReader,
            subtitle: t.reader.landscapeReaderSubtitle,
            value: globalSettingState.readSetting.landscapeReader,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(landscapeReader: value),
              );
              onLandscapeChanged!(value);
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.doublePage,
          subtitle: t.reader.doublePageSubtitle,
          value: globalSettingState.readSetting.doublePageMode,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(doublePageMode: value),
            );
            changePageIndex(0);
          },
        ),
        if (globalSettingState.readSetting.doublePageMode &&
            effectiveReadMode != 0)
          _SettingsSwitchTile(
            title: t.reader.doublePageSeamless,
            subtitle: t.reader.doublePageSeamlessSubtitle,
            value: globalSettingState.readSetting.doublePageSeamless,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(doublePageSeamless: value),
              );
              changePageIndex(0);
            },
          ),
        if (globalSettingState.readSetting.doublePageMode)
          _SettingsSwitchTile(
            title: t.reader.doublePageLeadingBlank,
            subtitle: t.reader.doublePageLeadingBlankSubtitle,
            value: globalSettingState.readSetting.doublePageLeadingBlank,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(doublePageLeadingBlank: value),
              );
              changePageIndex(0);
            },
          ),
      ],
    );
  }
}

/// 开关打开后展开的本漫独立选项卡。
///
/// 用高亮边框 + 全局对照文案明确告知用户“现在改的是本漫，不是全局”，
/// 配合外层 [AnimatedSize] 实现展开/收起动效。
class _PerComicReadModeOptions extends StatelessWidget {
  final int overrideReadMode;
  final Future<void> Function(int mode) onSelect;

  const _PerComicReadModeOptions({
    required this.overrideReadMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(overrideReadMode),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SettingsChoiceChip(
                  title: t.reader.webtoon,
                  selected: overrideReadMode == 0,
                  onTap: () => onSelect(0),
                ),
                _SettingsChoiceChip(
                  title: t.reader.singlePageLtr,
                  selected: overrideReadMode == 1,
                  onTap: () => onSelect(1),
                ),
                _SettingsChoiceChip(
                  title: t.reader.singlePageRtl,
                  selected: overrideReadMode == 2,
                  onTap: () => onSelect(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return _SettingsSection(
      title: t.reader.themeMode,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.common.lightMode,
              selected: globalSettingState.themeMode == ThemeMode.light,
              onTap: () {
                if (globalSettingState.themeMode == ThemeMode.light) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(themeMode: ThemeMode.light),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.common.darkMode,
              selected: globalSettingState.themeMode == ThemeMode.dark,
              onTap: () {
                if (globalSettingState.themeMode == ThemeMode.dark) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(themeMode: ThemeMode.dark),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.common.followSystem,
              selected: globalSettingState.themeMode == ThemeMode.system,
              onTap: () {
                if (globalSettingState.themeMode == ThemeMode.system) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(themeMode: ThemeMode.system),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AutoReadSection extends StatelessWidget {
  const _AutoReadSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: t.reader.autoRead,
      children: [
        _SettingsSwitchTile(
          title: t.reader.autoRead,
          subtitle: t.reader.autoReadSubtitle,
          value: readSetting.autoScroll,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(autoScroll: value),
            );
          },
        ),
        if (readSetting.autoScroll)
          _SettingsSwitchTile(
            title: t.reader.autoReadHidePauseButton,
            subtitle: t.reader.autoReadHidePauseButtonSubtitle,
            value: readSetting.autoScrollHidePauseButton,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(autoScrollHidePauseButton: value),
              );
            },
          ),
        if (readSetting.autoScroll)
          _SettingsSwitchTile(
            title: t.reader.autoReadSmooth,
            subtitle: t.reader.autoReadSmoothSubtitle,
            value: readSetting.autoScrollSmooth,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(autoScrollSmooth: value),
              );
            },
          ),
        if (readSetting.autoScroll)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollDistance,
            value: readSetting.autoScrollColumnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: t.reader.screenHeightPercent,
            onChanged: (value) {
              final percent = value.clamp(10, 100);
              globalSettingCubit.updateReadSetting(
                (current) =>
                    current.copyWith(autoScrollColumnDistancePercent: percent),
              );
            },
          ),
        if (readSetting.autoScroll)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollInterval,
            value: readSetting.autoScrollColumnIntervalMs.clamp(300, 5000),
            min: 300,
            max: 5000,
            divisions: 47,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final intervalMs = value.clamp(300, 5000);
              globalSettingCubit.updateReadSetting(
                (current) =>
                    current.copyWith(autoScrollColumnIntervalMs: intervalMs),
              );
            },
          ),
        if (readSetting.autoScroll)
          _SettingsSliderCard(
            title: t.reader.singlePageScrollInterval,
            value: readSetting.autoScrollPageIntervalMs.clamp(800, 10000),
            min: 800,
            max: 10000,
            divisions: 92,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final intervalMs = value.clamp(800, 10000);
              globalSettingCubit.updateReadSetting(
                (current) =>
                    current.copyWith(autoScrollPageIntervalMs: intervalMs),
              );
            },
          ),
      ],
    );
  }
}

class _PreloadSection extends StatelessWidget {
  const _PreloadSection();

  @override
  Widget build(BuildContext context) {
    final readSetting = context.watch<GlobalSettingCubit>().state.readSetting;
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return _SettingsSection(
      title: t.reader.preload,
      children: [
        _SettingsDropdownTile(
          title: t.reader.preloadImageCount,
          subtitle: t.reader.preloadImageCountSubtitle,
          value: readSetting.preloadImageCount.clamp(2, 10).toInt(),
          values: List<int>.generate(9, (index) => index + 2),
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(preloadImageCount: value),
            );
          },
        ),
        _SettingsDropdownTile(
          title: t.reader.preloadChapterCount,
          subtitle: t.reader.preloadChapterCountSubtitle,
          value: readSetting.preloadChapterCount.clamp(1, 3).toInt(),
          values: List<int>.generate(3, (index) => index + 1),
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(preloadChapterCount: value),
            );
          },
        ),
      ],
    );
  }
}

class _ReadBackgroundSection extends StatelessWidget {
  const _ReadBackgroundSection();

  @override
  Widget build(BuildContext context) {
    final readSetting = context.watch<GlobalSettingCubit>().state.readSetting;
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return _SettingsSection(
      title: t.reader.background,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.auto,
              selected:
                  readSetting.readerBackgroundMode == ReaderBackgroundMode.auto,
              onTap: () {
                if (readSetting.readerBackgroundMode ==
                    ReaderBackgroundMode.auto) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    readerBackgroundMode: ReaderBackgroundMode.auto,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.black,
              selected:
                  readSetting.readerBackgroundMode ==
                  ReaderBackgroundMode.black,
              onTap: () {
                if (readSetting.readerBackgroundMode ==
                    ReaderBackgroundMode.black) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    readerBackgroundMode: ReaderBackgroundMode.black,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.white,
              selected:
                  readSetting.readerBackgroundMode ==
                  ReaderBackgroundMode.white,
              onTap: () {
                if (readSetting.readerBackgroundMode ==
                    ReaderBackgroundMode.white) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    readerBackgroundMode: ReaderBackgroundMode.white,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.grey,
              selected:
                  readSetting.readerBackgroundMode == ReaderBackgroundMode.grey,
              onTap: () {
                if (readSetting.readerBackgroundMode ==
                    ReaderBackgroundMode.grey) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    readerBackgroundMode: ReaderBackgroundMode.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadExperienceSection extends StatelessWidget {
  const _ReadExperienceSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: t.reader.readingExperience,
      children: [
        _SettingsSwitchTile(
          title: t.reader.disableAnimation,
          subtitle: t.reader.disableAnimationSubtitle,
          value: readSetting.noAnimation,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(noAnimation: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: t.reader.readFilter,
          subtitle: t.reader.readFilterSubtitle,
          value: readSetting.readFilterEnabled,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(readFilterEnabled: value),
            );
          },
        ),
        if (readSetting.readFilterEnabled)
          _SettingsSliderCard(
            title: t.reader.filterIntensity,
            value: readSetting.readFilterOpacityPercent.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            suffix: t.reader.percent,
            onChanged: (value) {
              final percent = value.clamp(0, 100);
              globalSettingCubit.updateReadSetting(
                (current) =>
                    current.copyWith(readFilterOpacityPercent: percent),
              );
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.einkOptimization,
          subtitle: t.reader.einkOptimizationSubtitle,
          value: readSetting.einkOptimization,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(einkOptimization: value),
            );
          },
        ),
        if (readSetting.einkOptimization)
          _SettingsSliderCard(
            title: t.reader.einkDelay,
            value: readSetting.einkDelayMs.clamp(50, 500),
            min: 50,
            max: 500,
            divisions: 45,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final delayMs = value.clamp(50, 500);
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(einkDelayMs: delayMs),
              );
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.sidePadding,
          subtitle: t.reader.sidePaddingSubtitle,
          value: readSetting.sidePaddingEnabled,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(sidePaddingEnabled: value),
            );
          },
        ),
        if (readSetting.sidePaddingEnabled)
          _SettingsSliderCard(
            title: t.reader.sidePaddingPercent,
            value: readSetting.sidePaddingPercent.clamp(0, 30),
            min: 0,
            max: 30,
            divisions: 30,
            suffix: t.reader.percent,
            onChanged: (value) {
              final percent = value.clamp(0, 30);
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(sidePaddingPercent: percent),
              );
            },
          ),
      ],
    );
  }
}
