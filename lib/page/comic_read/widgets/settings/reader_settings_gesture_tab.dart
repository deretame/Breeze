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
          const _TapPageTurnModeSection(),
          const SizedBox(height: 18),
          const _WebtoonTapPageTurnSection(),
          const SizedBox(height: 18),
          const _DoubleTapSection(),
          if (isAndroidPhone) const SizedBox(height: 18),
          if (isAndroidPhone) const _VolumeKeyPageTurnSection(),
        ],
      ),
    );
  }
}

class _TapPageTurnModeSection extends StatelessWidget {
  const _TapPageTurnModeSection();

  @override
  Widget build(BuildContext context) {
    final effective = context.watchTargetReadSetting();
    final mode = effective.tapPageTurnMode;

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
                context.updateEffectiveReadSetting(
                  effective,
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
                context.updateEffectiveReadSetting(
                  effective,
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
                context.updateEffectiveReadSetting(
                  effective,
                  (current) => current.copyWith(
                    tapPageTurnMode: ReaderTapPageTurnMode.rightHand,
                  ),
                );
              },
            ),
          ],
        ),
        _SettingsSwitchTile(
          title: t.reader.reverseHorizontalPageTurn,
          subtitle: t.reader.reverseHorizontalPageTurnSubtitle,
          value: effective.reverseHorizontalPageTurn,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(reverseHorizontalPageTurn: value),
            );
          },
        ),
      ],
    );
  }
}

class _WebtoonTapPageTurnSection extends StatelessWidget {
  const _WebtoonTapPageTurnSection();

  @override
  Widget build(BuildContext context) {
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.webtoonTapPageTurn,
      children: [
        _SettingsSwitchTile(
          title: t.reader.enableWebtoonTapPageTurn,
          subtitle: t.reader.webtoonTapPageTurnSubtitle,
          value: effective.tapPageTurnInWebtoon,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(tapPageTurnInWebtoon: value),
            );
          },
        ),
      ],
    );
  }
}

class _DoubleTapSection extends StatelessWidget {
  const _DoubleTapSection();

  @override
  Widget build(BuildContext context) {
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.doubleTapAction,
      children: [
        _SettingsSwitchTile(
          title: t.reader.doubleTapZoom,
          subtitle: t.reader.doubleTapZoomSubtitle,
          value: effective.doubleTapZoom,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
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
          value: effective.doubleTapOpenMenu,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
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
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.volumeKeyPageTurn,
      children: [
        _SettingsSwitchTile(
          title: t.reader.enableVolumeKeyPageTurn,
          subtitle: t.reader.volumeKeyPageTurnSubtitle,
          value: effective.volumeKeyPageTurn,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(volumeKeyPageTurn: value),
            );
          },
        ),
        if (effective.volumeKeyPageTurn)
          _SettingsSliderCard(
            title: t.reader.webtoonScrollDistance,
            value: effective.volumeKeyPageTurnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: t.reader.screenHeightPercent,
            onChanged: (value) {
              final percent = value.clamp(10, 100);
              context.updateEffectiveReadSetting(
                effective,
                (current) =>
                    current.copyWith(volumeKeyPageTurnDistancePercent: percent),
              );
            },
          ),
      ],
    );
  }
}
