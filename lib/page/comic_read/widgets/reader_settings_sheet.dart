import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/util/context/context_extensions.dart';

Future<void> showReaderSettingsSheet(
  BuildContext context, {
  required ValueChanged<int> changePageIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ReaderSettingsSheet(changePageIndex: changePageIndex);
    },
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final ValueChanged<int> changePageIndex;

  const _ReaderSettingsSheet({required this.changePageIndex});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.7;
    final isAndroidPhone =
        !kIsWeb && Platform.isAndroid && mediaQuery.size.shortestSide < 600;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          height: maxHeight,
          child: _ReaderSettingsCard(
            changePageIndex: changePageIndex,
            isAndroidPhone: isAndroidPhone,
          ),
        ),
      ),
    );
  }
}

class _ReaderSettingsCard extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final bool isAndroidPhone;

  const _ReaderSettingsCard({
    required this.changePageIndex,
    required this.isAndroidPhone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.96),
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ReaderSettingsHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _ReaderSettingsReadTab(changePageIndex: changePageIndex),
                  _ReaderSettingsGestureTab(isAndroidPhone: isAndroidPhone),
                  const _ReaderSettingsInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderSettingsHeader extends StatelessWidget {
  const _ReaderSettingsHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          TabBar(
            dividerColor: Colors.transparent,
            labelStyle: context.theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: '阅读设置'),
              Tab(text: '手势'),
              Tab(text: '信息条'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReaderSettingsReadTab extends StatelessWidget {
  final ValueChanged<int> changePageIndex;

  const _ReaderSettingsReadTab({required this.changePageIndex});

  @override
  Widget build(BuildContext context) {
    return _SettingsTabContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadModeSection(changePageIndex: changePageIndex),
          const SizedBox(height: 18),
          const _ThemeModeSection(),
          const SizedBox(height: 18),
          const _AutoReadSection(),
          const SizedBox(height: 18),
          const _ReadExperienceSection(),
        ],
      ),
    );
  }
}

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

class _ReadModeSection extends StatelessWidget {
  final ValueChanged<int> changePageIndex;

  const _ReadModeSection({required this.changePageIndex});

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return _SettingsSection(
      title: '阅读模式',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: '条漫',
              selected: globalSettingState.readMode == 0,
              onTap: () {
                if (globalSettingState.readMode == 0) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(readMode: 0),
                );
                changePageIndex(0);
              },
            ),
            _SettingsChoiceChip(
              title: '单页式（从左到右）',
              selected: globalSettingState.readMode == 1,
              onTap: () {
                if (globalSettingState.readMode == 1) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(readMode: 1),
                );
                changePageIndex(0);
              },
            ),
            _SettingsChoiceChip(
              title: '单页式（从右到左）',
              selected: globalSettingState.readMode == 2,
              onTap: () {
                if (globalSettingState.readMode == 2) {
                  return;
                }
                globalSettingCubit.updateState(
                  (current) => current.copyWith(readMode: 2),
                );
                changePageIndex(0);
              },
            ),
          ],
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
      title: '系统模式',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SettingsChoiceChip(
              title: '浅色模式',
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
              title: '深色模式',
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
              title: '跟随系统',
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
      title: '自动阅读',
      children: [
        _SettingsSwitchTile(
          title: '自动阅读',
          subtitle: '开启后自动滚动，并在右下角显示暂停/播放按钮',
          value: readSetting.autoScroll,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(autoScroll: value),
            );
          },
        ),
        if (readSetting.autoScroll)
          _SettingsSliderCard(
            title: '条漫滚动距离',
            value: readSetting.autoScrollColumnDistancePercent.clamp(10, 100),
            min: 10,
            max: 100,
            divisions: 90,
            suffix: '% 屏高',
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
            title: '条漫滚动间隔',
            value: readSetting.autoScrollColumnIntervalMs.clamp(300, 5000),
            min: 300,
            max: 5000,
            divisions: 47,
            suffix: 'ms',
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
            title: '单页式滚动间隔',
            value: readSetting.autoScrollPageIntervalMs.clamp(800, 10000),
            min: 800,
            max: 10000,
            divisions: 92,
            suffix: 'ms',
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

class _ReadExperienceSection extends StatelessWidget {
  const _ReadExperienceSection();

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readSetting = globalSettingState.readSetting;

    return _SettingsSection(
      title: '阅读体验',
      children: [
        _SettingsSwitchTile(
          title: '关闭翻页动画',
          subtitle: '关闭整页翻页动画，小幅滚动动画不受影响',
          value: readSetting.noAnimation,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(noAnimation: value),
            );
          },
        ),
        _SettingsSwitchTile(
          title: '墨水屏优化（仅横向）',
          subtitle: '翻页后先白屏再显示图片',
          value: readSetting.einkOptimization,
          onChanged: (value) {
            globalSettingCubit.updateReadSetting(
              (current) => current.copyWith(einkOptimization: value),
            );
          },
        ),
        if (readSetting.einkOptimization)
          _SettingsSliderCard(
            title: '白屏时长',
            value: readSetting.einkDelayMs.clamp(50, 500),
            min: 50,
            max: 500,
            divisions: 45,
            suffix: 'ms',
            onChanged: (value) {
              final delayMs = value.clamp(50, 500);
              globalSettingCubit.updateReadSetting(
                (current) => current.copyWith(einkDelayMs: delayMs),
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

class _SettingsNoticeCard extends StatelessWidget {
  final String text;

  const _SettingsNoticeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        text,
        style: context.theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _SettingsTabContent extends StatelessWidget {
  final Widget child;

  const _SettingsTabContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: child,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SettingsChoiceChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsChoiceChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
      selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.92),
      side: BorderSide(
        color: selected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.7),
        width: selected ? 1.4 : 1,
      ),
      labelStyle: context.theme.textTheme.bodyMedium?.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 12, right: 8),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
      ),
    );
  }
}

class _SettingsSliderCard extends StatelessWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String suffix;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _SettingsSliderCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: enabled ? 0.45 : 0.28,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: context.theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '$value $suffix',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Slider(
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            value: value.clamp(min, max).toDouble(),
            label: '$value$suffix',
            onChanged: !enabled
                ? null
                : (newValue) {
                    final nextValue = newValue.round().clamp(min, max);
                    if (nextValue != value) {
                      HapticFeedback.selectionClick();
                      onChanged(nextValue);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
