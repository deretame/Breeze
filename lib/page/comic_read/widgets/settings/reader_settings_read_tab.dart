part of 'reader_settings_sheet.dart';

class _ReaderSettingsReadTab extends StatelessWidget {
  final ValueChanged<int> changePageIndex;

  const _ReaderSettingsReadTab({required this.changePageIndex});

  @override
  Widget build(BuildContext context) {
    final readMode = context.select(
      (GlobalSettingCubit c) => c.state.readSetting.readMode,
    );
    return _SettingsTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadModeSection(changePageIndex: changePageIndex),
          if (readMode != 0) const SizedBox(height: 18),
          if (readMode != 0) const _TapPageTurnModeSection(),
          const SizedBox(height: 18),
          const _ThemeModeSection(),
          const SizedBox(height: 18),
          const _ReadBackgroundSection(),
          const SizedBox(height: 18),
          const _AutoReadSection(),
          const SizedBox(height: 18),
          const _ReadExperienceSection(),
        ],
      ),
    );
  }
}

class _TapPageTurnModeSection extends StatelessWidget {
  const _TapPageTurnModeSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final mode = globalSettingState.readSetting.tapPageTurnMode;

    return _SettingsSection(
      title: t.reader.pageMode,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.fullscreen,
              selected: mode == ReaderTapPageTurnMode.fullScreen,
              onTap: () {
                if (mode == ReaderTapPageTurnMode.fullScreen) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    tapPageTurnMode: ReaderTapPageTurnMode.fullScreen,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.leftHandMode,
              selected: mode == ReaderTapPageTurnMode.leftHand,
              onTap: () {
                if (mode == ReaderTapPageTurnMode.leftHand) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    tapPageTurnMode: ReaderTapPageTurnMode.leftHand,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.rightHandMode,
              selected: mode == ReaderTapPageTurnMode.rightHand,
              onTap: () {
                if (mode == ReaderTapPageTurnMode.rightHand) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    tapPageTurnMode: ReaderTapPageTurnMode.rightHand,
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

class _ReadModeSection extends StatelessWidget {
  final ValueChanged<int> changePageIndex;

  const _ReadModeSection({required this.changePageIndex});

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return _SettingsSection(
      title: t.reader.readingMode,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.webtoon,
              selected: globalSettingState.readSetting.readMode == 0,
              onTap: () {
                if (globalSettingState.readSetting.readMode == 0) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(readMode: 0),
                );
                changePageIndex(0);
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageLtr,
              selected: globalSettingState.readSetting.readMode == 1,
              onTap: () {
                if (globalSettingState.readSetting.readMode == 1) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(readMode: 1),
                );
                changePageIndex(0);
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.singlePageRtl,
              selected: globalSettingState.readSetting.readMode == 2,
              onTap: () {
                if (globalSettingState.readSetting.readMode == 2) {
                  return;
                }
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(readMode: 2),
                );
                changePageIndex(0);
              },
            ),
          ],
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
