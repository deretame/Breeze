part of 'reader_settings_sheet.dart';

class _ReaderSettingsInfoTab extends StatelessWidget {
  const _ReaderSettingsInfoTab();

  @override
  Widget build(BuildContext context) {
    return const _SettingsTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageInfoVisibilitySection(),
          SizedBox(height: 18),
          _PageInfoPlacementSection(),
          SizedBox(height: 18),
          _PageInfoAppearanceSection(),
        ],
      ),
    );
  }
}

class _PageInfoVisibilitySection extends StatelessWidget {
  const _PageInfoVisibilitySection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;
    final allHidden =
        !readSetting.pageInfoShowPage &&
        !readSetting.pageInfoShowNetwork &&
        !readSetting.pageInfoShowBattery &&
        !readSetting.pageInfoShowTime;

    return _SettingsSection(
      title: '信息项显示',
      children: [
        _SettingsSwitchTile(
          title: '页数',
          subtitle: '显示当前页/总页数',
          value: readSetting.pageInfoShowPage,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoShowPage: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: '网络状态',
          subtitle: 'Linux 下可能不准确',
          value: readSetting.pageInfoShowNetwork,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoShowNetwork: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: '电池',
          subtitle: '默认关闭，可按需开启',
          value: readSetting.pageInfoShowBattery,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoShowBattery: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: '时间',
          subtitle: '显示当前时间',
          value: readSetting.pageInfoShowTime,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoShowTime: value),
            );
          },
        ),
        if (allHidden) _SettingsNoticeCard(text: '当前已全部关闭，阅读页中的信息条会完全隐藏。'),
      ],
    );
  }
}

class _PageInfoPlacementSection extends StatelessWidget {
  const _PageInfoPlacementSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;
    final isHorizontalCenter =
        readSetting.pageInfoHorizontalPosition ==
        ReaderInfoHorizontalPosition.center;

    return _SettingsSection(
      title: '信息条位置',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: '顶部',
              selected:
                  readSetting.pageInfoVerticalPosition ==
                  ReaderInfoVerticalPosition.top,
              onTap: () {
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    pageInfoVerticalPosition: ReaderInfoVerticalPosition.top,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: '底部',
              selected:
                  readSetting.pageInfoVerticalPosition ==
                  ReaderInfoVerticalPosition.bottom,
              onTap: () {
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    pageInfoVerticalPosition: ReaderInfoVerticalPosition.bottom,
                  ),
                );
              },
            ),
          ],
        ),
        if (readSetting.pageInfoVerticalPosition ==
            ReaderInfoVerticalPosition.top)
          _SettingsSwitchTile(
            title: '显示在状态栏',
            subtitle: '开启后，顶部信息条会进入系统状态栏区域',
            value: readSetting.pageInfoTopInStatusBar,
            onChanged: (value) {
              logger.d('pageInfoTopInStatusBar: $value');
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(pageInfoTopInStatusBar: value),
              );
            },
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: '左侧',
              selected:
                  readSetting.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.left,
              onTap: () {
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    pageInfoHorizontalPosition:
                        ReaderInfoHorizontalPosition.left,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: '中间',
              selected:
                  readSetting.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.center,
              onTap: () {
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    pageInfoHorizontalPosition:
                        ReaderInfoHorizontalPosition.center,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: '右侧',
              selected:
                  readSetting.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.right,
              onTap: () {
                globalSettingCubit.updateReadSetting(
                  (current) => current.copyWith(
                    pageInfoHorizontalPosition:
                        ReaderInfoHorizontalPosition.right,
                  ),
                );
              },
            ),
          ],
        ),
        _SettingsSliderCard(
          title: '边缘间距',
          value: readSetting.pageInfoEdgePadding.clamp(0, 48),
          min: 0,
          max: 48,
          divisions: 48,
          suffix: 'px',
          enabled: !isHorizontalCenter,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoEdgePadding: value),
            );
          },
        ),
        if (isHorizontalCenter) _SettingsNoticeCard(text: '横向在中间时，边缘间距不会生效。'),
      ],
    );
  }
}

class _PageInfoAppearanceSection extends StatelessWidget {
  const _PageInfoAppearanceSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: '信息条样式',
      children: [
        _SettingsSliderCard(
          title: '背景透明度',
          value: readSetting.pageInfoOpacityPercent.clamp(20, 100),
          min: 20,
          max: 100,
          divisions: 80,
          suffix: '%',
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoOpacityPercent: value),
            );
          },
        ),
        _SettingsSliderCard(
          title: '字体大小',
          value: readSetting.pageInfoFontSize.clamp(10, 20),
          min: 10,
          max: 20,
          divisions: 10,
          suffix: 'px',
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(pageInfoFontSize: value),
            );
          },
        ),
      ],
    );
  }
}
