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
      title: t.reader.doubleTapAction,
      children: [
        _SettingsSwitchTile(
          title: t.reader.doubleTapZoom,
          subtitle: t.reader.doubleTapZoomSubtitle,
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
          title: t.reader.doubleTapOpenMenu,
          subtitle: t.reader.doubleTapOpenMenuSubtitle,
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
      title: t.reader.volumeKeyPageTurn,
      children: [
        _SettingsSwitchTile(
          title: t.reader.enableVolumeKeyPageTurn,
          subtitle: t.reader.volumeKeyPageTurnSubtitle,
          value: readSetting.volumeKeyPageTurn,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(volumeKeyPageTurn: value),
            );
          },
        ),
        if (readSetting.volumeKeyPageTurn)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollDistance,
            value: readSetting.volumeKeyPageTurnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: t.reader.screenHeightPercent,
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
