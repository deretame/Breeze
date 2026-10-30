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

/// 阅读模式区：同一套组件，全局 tab 和本漫 tab 共用。
///
/// 读目标值、显示有效值（本漫 tab 无覆盖时显示的即全局值，不搞特殊状态）；
/// 写走 scope 路由（全局 tab 写全局，本漫 tab 写 patch）。
class _ReadModeSection extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final ValueChanged<bool>? onLandscapeChanged;

  const _ReadModeSection({
    required this.changePageIndex,
    this.onLandscapeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final isDesktopPlatform =
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    // 本漫 tab 读有效值：无覆盖时显示的即全局值，不搞特殊状态；
    // 点选即写覆盖（点当前高亮的值 = 再确认一次，无变化不写库）。
    final effective = context.watchTargetReadSetting();
    final readMode = effective.readMode;

    Future<void> selectReadMode(int mode) async {
      HapticFeedback.selectionClick();
      await context.updateEffectiveReadSetting(
        effective,
        (current) => current.copyWith(readMode: mode),
      );
      changePageIndex(0);
    }

    return _SettingsSection(
      title: t.reader.readingMode,
      // 本漫 tab 有覆盖时标题右边挂“跟随全局”：删整行本漫设置，回到全局值。
      trailing:
          !context.isEditingPerComic ||
              context.watch<ComicReadPreferenceCubit>().state.override == null
          ? null
          : TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                await context.read<ComicReadPreferenceCubit>().clearOverride();
                changePageIndex(0);
              },
              child: Text(t.reader.perComicFollowGlobal),
            ),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.webtoon,
              selected: readMode == 0,
              onTap: () => selectReadMode(0),
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageLtr,
              selected: readMode == 1,
              onTap: () => selectReadMode(1),
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageRtl,
              selected: readMode == 2,
              onTap: () => selectReadMode(2),
            ),
          ],
        ),
        // 横屏阅读是设备级开关，只写全局；本漫 tab 里隐藏。
        if (!isDesktopPlatform &&
            onLandscapeChanged != null &&
            !context.isEditingPerComic)
          _SettingsSwitchTile(
            title: t.reader.landscapeReader,
            subtitle: t.reader.landscapeReaderSubtitle,
            value: effective.landscapeReader,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(landscapeReader: value),
              );
              onLandscapeChanged!(value);
            },
          ),
        if (!isDesktopPlatform)
          _SettingsSwitchTile(
            title: t.reader.showStatusBar,
            subtitle: t.reader.showStatusBarSubtitle,
            value: effective.showStatusBar,
            onChanged: (value) {
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(showStatusBar: value),
              );
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.doublePage,
          subtitle: t.reader.doublePageSubtitle,
          value: effective.doublePageMode,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(doublePageMode: value),
            );
            changePageIndex(0);
          },
        ),
        if (effective.doublePageMode && effective.readMode != 0)
          _SettingsSwitchTile(
            title: t.reader.doublePageSeamless,
            subtitle: t.reader.doublePageSeamlessSubtitle,
            value: effective.doublePageSeamless,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(doublePageSeamless: value),
              );
              changePageIndex(0);
            },
          ),
        if (effective.doublePageMode)
          _SettingsSwitchTile(
            title: t.reader.doublePageLeadingBlank,
            subtitle: t.reader.doublePageLeadingBlankSubtitle,
            value: effective.doublePageLeadingBlank,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(doublePageLeadingBlank: value),
              );
              changePageIndex(0);
            },
          ),
      ],
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
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.autoRead,
      children: [
        _SettingsSwitchTile(
          title: t.reader.autoRead,
          subtitle: t.reader.autoReadSubtitle,
          value: effective.autoScroll,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(autoScroll: value),
            );
          },
        ),
        if (effective.autoScroll)
          _SettingsSwitchTile(
            title: t.reader.autoReadHidePauseButton,
            subtitle: t.reader.autoReadHidePauseButtonSubtitle,
            value: effective.autoScrollHidePauseButton,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(autoScrollHidePauseButton: value),
              );
            },
          ),
        if (effective.autoScroll)
          _SettingsSwitchTile(
            title: t.reader.autoReadSmooth,
            subtitle: t.reader.autoReadSmoothSubtitle,
            value: effective.autoScrollSmooth,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(autoScrollSmooth: value),
              );
            },
          ),
        if (effective.autoScroll)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollDistance,
            value: effective.autoScrollColumnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: t.reader.screenHeightPercent,
            onChanged: (value) {
              final percent = value.clamp(10, 100);
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) =>
                    current.copyWith(autoScrollColumnDistancePercent: percent),
              );
            },
          ),
        if (effective.autoScroll)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollInterval,
            value: effective.autoScrollColumnIntervalMs.clamp(300, 5000),
            min: 300,
            max: 5000,
            divisions: 47,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final intervalMs = value.clamp(300, 5000);
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
                (current) =>
                    current.copyWith(autoScrollColumnIntervalMs: intervalMs),
              );
            },
          ),
        if (effective.autoScroll)
          _SettingsSliderCard(
            title: t.reader.singlePageScrollInterval,
            value: effective.autoScrollPageIntervalMs.clamp(800, 10000),
            min: 800,
            max: 10000,
            divisions: 92,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final intervalMs = value.clamp(800, 10000);
              HapticFeedback.selectionClick();
              context.updateEffectiveReadSetting(
                effective,
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
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.preload,
      children: [
        _SettingsDropdownTile(
          title: t.reader.preloadImageCount,
          subtitle: t.reader.preloadImageCountSubtitle,
          value: effective.preloadImageCount.clamp(2, 10).toInt(),
          values: List<int>.generate(9, (index) => index + 2),
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(preloadImageCount: value),
            );
          },
        ),
        _SettingsDropdownTile(
          title: t.reader.preloadChapterCount,
          subtitle: t.reader.preloadChapterCountSubtitle,
          value: effective.preloadChapterCount.clamp(1, 3).toInt(),
          values: List<int>.generate(3, (index) => index + 1),
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
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
    final effective = context.watchTargetReadSetting();

    Future<void> selectBackground(ReaderBackgroundMode mode) async {
      if (effective.readerBackgroundMode == mode) return;
      HapticFeedback.selectionClick();
      await context.updateEffectiveReadSetting(
        effective,
        (current) => current.copyWith(readerBackgroundMode: mode),
      );
    }

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
                  effective.readerBackgroundMode == ReaderBackgroundMode.auto,
              onTap: () => selectBackground(ReaderBackgroundMode.auto),
            ),
            _SettingsChoiceChip(
              title: t.reader.black,
              selected:
                  effective.readerBackgroundMode == ReaderBackgroundMode.black,
              onTap: () => selectBackground(ReaderBackgroundMode.black),
            ),
            _SettingsChoiceChip(
              title: t.reader.white,
              selected:
                  effective.readerBackgroundMode == ReaderBackgroundMode.white,
              onTap: () => selectBackground(ReaderBackgroundMode.white),
            ),
            _SettingsChoiceChip(
              title: t.reader.grey,
              selected:
                  effective.readerBackgroundMode == ReaderBackgroundMode.grey,
              onTap: () => selectBackground(ReaderBackgroundMode.grey),
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
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.readingExperience,
      children: [
        _SettingsSwitchTile(
          title: t.reader.disableAnimation,
          subtitle: t.reader.disableAnimationSubtitle,
          value: effective.noAnimation,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(noAnimation: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: t.reader.readFilter,
          subtitle: t.reader.readFilterSubtitle,
          value: effective.readFilterEnabled,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(readFilterEnabled: value),
            );
          },
        ),
        if (effective.readFilterEnabled)
          _SettingsSliderCard(
            title: t.reader.filterIntensity,
            value: effective.readFilterOpacityPercent.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            suffix: t.reader.percent,
            onChanged: (value) {
              final percent = value.clamp(0, 100);
              context.updateEffectiveReadSetting(
                effective,
                (current) =>
                    current.copyWith(readFilterOpacityPercent: percent),
              );
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.einkOptimization,
          subtitle: t.reader.einkOptimizationSubtitle,
          value: effective.einkOptimization,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(einkOptimization: value),
            );
          },
        ),
        if (effective.einkOptimization)
          _SettingsSliderCard(
            title: t.reader.einkDelay,
            value: effective.einkDelayMs.clamp(50, 500),
            min: 50,
            max: 500,
            divisions: 45,
            suffix: t.reader.milliseconds,
            onChanged: (value) {
              final delayMs = value.clamp(50, 500);
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(einkDelayMs: delayMs),
              );
            },
          ),
        _SettingsSwitchTile(
          title: t.reader.sidePadding,
          subtitle: t.reader.sidePaddingSubtitle,
          value: effective.sidePaddingEnabled,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(sidePaddingEnabled: value),
            );
          },
        ),
        if (effective.sidePaddingEnabled)
          _SettingsSliderCard(
            title: t.reader.sidePaddingPercent,
            value: effective.sidePaddingPercent.clamp(0, 30),
            min: 0,
            max: 30,
            divisions: 30,
            suffix: t.reader.percent,
            onChanged: (value) {
              final percent = value.clamp(0, 30);
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(sidePaddingPercent: percent),
              );
            },
          ),
      ],
    );
  }
}
