part of 'reader_settings_sheet.dart';

class _ReaderSettingsGestureTab extends StatelessWidget {
  final bool isAndroidPhone;

  const _ReaderSettingsGestureTab({required this.isAndroidPhone});

  @override
  Widget build(BuildContext context) {
    return _SettingsTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DoubleTapSection(),
          if (isAndroidPhone) const SizedBox(height: 18),
          if (isAndroidPhone) const _VolumeKeyPageTurnSection(),
        ],
      ),
    );
  }
}

class _DoubleTapSection extends StatelessWidget {
  const _DoubleTapSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: '双击操作',
      children: [
        _SettingsSwitchTile(
          title: '双击缩放',
          subtitle: '双击图片可在缩放和还原之间切换',
          value: readSetting.doubleTapZoom,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(
                doubleTapZoom: value,
                doubleTapOpenMenu: value ? false : current.doubleTapOpenMenu,
              ),
            );
          },
        ),
        _SettingsSwitchTile(
          title: '双击打开操作栏',
          subtitle: '双击页面打开操作栏（与双击缩放互斥）',
          value: readSetting.doubleTapOpenMenu,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(
                doubleTapOpenMenu: value,
                doubleTapZoom: value ? false : current.doubleTapZoom,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VolumeKeyPageTurnSection extends StatelessWidget {
  const _VolumeKeyPageTurnSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: '音量键翻页',
      children: [
        _SettingsSwitchTile(
          title: '启用音量键翻页',
          subtitle: '开启后可用音量键上下翻页/滑动',
          value: readSetting.volumeKeyPageTurn,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(volumeKeyPageTurn: value),
            );
          },
        ),
        if (readSetting.volumeKeyPageTurn)
          _SettingsSliderCard(
            title: '条漫滑动距离',
            value: readSetting.volumeKeyPageTurnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: '% 屏高',
            onChanged: (value) {
              final percent = value.clamp(10, 100);
              globalSettingCubit.updateReadSetting(
                (current) =>
                    current.copyWith(volumeKeyPageTurnDistancePercent: percent),
              );
            },
          ),
      ],
    );
  }
}
