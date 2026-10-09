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
    final effective = context.watchTargetReadSetting();
    final allHidden =
        !effective.pageInfoShowPage &&
        !effective.pageInfoShowNetwork &&
        !effective.pageInfoShowBattery &&
        !effective.pageInfoShowTime;

    return _SettingsSection(
      title: t.reader.infoDisplay,
      children: [
        _SettingsSwitchTile(
          title: t.reader.pageNumber,
          subtitle: t.reader.pageNumberSubtitle,
          value: effective.pageInfoShowPage,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoShowPage: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: t.reader.networkStatus,
          subtitle: t.reader.networkStatusSubtitle,
          value: effective.pageInfoShowNetwork,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoShowNetwork: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: t.reader.battery,
          subtitle: t.reader.batterySubtitle,
          value: effective.pageInfoShowBattery,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoShowBattery: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: t.reader.time,
          subtitle: t.reader.timeSubtitle,
          value: effective.pageInfoShowTime,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoShowTime: value),
            );
          },
        ),
        if (allHidden) _SettingsNoticeCard(text: t.reader.allHiddenNotice),
      ],
    );
  }
}

class _PageInfoPlacementSection extends StatelessWidget {
  const _PageInfoPlacementSection();

  @override
  Widget build(BuildContext context) {
    final effective = context.watchTargetReadSetting();
    final isHorizontalCenter =
        effective.pageInfoHorizontalPosition ==
        ReaderInfoHorizontalPosition.center;

    return _SettingsSection(
      title: t.reader.infoBarPosition,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.verticalPositionTop,
              selected:
                  effective.pageInfoVerticalPosition ==
                  ReaderInfoVerticalPosition.top,
              onTap: () {
                context.updateEffectiveReadSetting(
                  effective,
                  (current) => current.copyWith(
                    pageInfoVerticalPosition: ReaderInfoVerticalPosition.top,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.verticalPositionBottom,
              selected:
                  effective.pageInfoVerticalPosition ==
                  ReaderInfoVerticalPosition.bottom,
              onTap: () {
                context.updateEffectiveReadSetting(
                  effective,
                  (current) => current.copyWith(
                    pageInfoVerticalPosition: ReaderInfoVerticalPosition.bottom,
                  ),
                );
              },
            ),
          ],
        ),
        if (effective.pageInfoVerticalPosition ==
            ReaderInfoVerticalPosition.top)
          _SettingsSwitchTile(
            title: t.reader.showInStatusBar,
            subtitle: t.reader.showInStatusBarSubtitle,
            value: effective.pageInfoTopInStatusBar,
            onChanged: (value) {
              logger.d('pageInfoTopInStatusBar: $value');
              context.updateEffectiveReadSetting(
                effective,
                (current) => current.copyWith(pageInfoTopInStatusBar: value),
              );
            },
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: t.reader.horizontalPositionLeft,
              selected:
                  effective.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.left,
              onTap: () {
                context.updateEffectiveReadSetting(
                  effective,
                  (current) => current.copyWith(
                    pageInfoHorizontalPosition:
                        ReaderInfoHorizontalPosition.left,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.horizontalPositionCenter,
              selected:
                  effective.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.center,
              onTap: () {
                context.updateEffectiveReadSetting(
                  effective,
                  (current) => current.copyWith(
                    pageInfoHorizontalPosition:
                        ReaderInfoHorizontalPosition.center,
                  ),
                );
              },
            ),
            _SettingsChoiceChip(
              title: t.reader.horizontalPositionRight,
              selected:
                  effective.pageInfoHorizontalPosition ==
                  ReaderInfoHorizontalPosition.right,
              onTap: () {
                context.updateEffectiveReadSetting(
                  effective,
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
          title: t.reader.edgePadding,
          value: effective.pageInfoEdgePadding.clamp(0, 48),
          min: 0,
          max: 48,
          divisions: 48,
          suffix: t.reader.pixels,
          enabled: !isHorizontalCenter,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoEdgePadding: value),
            );
          },
        ),
        if (isHorizontalCenter)
          _SettingsNoticeCard(text: t.reader.edgePaddingDisabled),
      ],
    );
  }
}

class _PageInfoAppearanceSection extends StatelessWidget {
  const _PageInfoAppearanceSection();

  @override
  Widget build(BuildContext context) {
    final effective = context.watchTargetReadSetting();

    return _SettingsSection(
      title: t.reader.infoBarStyle,
      children: [
        _SettingsSliderCard(
          title: t.reader.backgroundOpacity,
          value: effective.pageInfoOpacityPercent.clamp(20, 100),
          min: 20,
          max: 100,
          divisions: 80,
          suffix: t.reader.percent,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoOpacityPercent: value),
            );
          },
        ),
        _SettingsSliderCard(
          title: t.reader.fontSize,
          value: effective.pageInfoFontSize.clamp(10, 20),
          min: 10,
          max: 20,
          divisions: 10,
          suffix: t.reader.pixels,
          onChanged: (value) {
            context.updateEffectiveReadSetting(
              effective,
              (current) => current.copyWith(pageInfoFontSize: value),
            );
          },
        ),
      ],
    );
  }
}
