import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/comic_read_preference_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';

part 'reader_settings_gesture_tab.dart';
part 'reader_settings_info_tab.dart';
part 'reader_settings_read_tab.dart';
part 'reader_settings_per_comic_tab.dart';

Future<void> showReaderSettingsSheet(
  BuildContext context, {
  ValueChanged<int>? changePageIndex,
  ValueChanged<bool>? onLandscapeChanged,
  String source = '',
  String comicId = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierLabel: t.common.close,
    isDismissible: true,
    enableDrag: true,
    builder: (context) {
      // 外层钉死全局：前三个 tab 与全局入口恒写全局，不回退读 cubit；
      // 第四个 tab 内层的 perComic:true 会覆盖这一层。
      return _PerComicScope(
        perComic: false,
        child: _ReaderSettingsSheet(
          changePageIndex: changePageIndex ?? (_) {},
          onLandscapeChanged: onLandscapeChanged,
          source: source,
          comicId: comicId,
        ),
      );
    },
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final ValueChanged<bool>? onLandscapeChanged;
  final String source;
  final String comicId;

  const _ReaderSettingsSheet({
    required this.changePageIndex,
    this.onLandscapeChanged,
    this.source = '',
    this.comicId = '',
  });

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final maxHeight = mediaSize.height * 0.7;
    final isAndroidPhone =
        !kIsWeb && Platform.isAndroid && mediaSize.shortestSide < 600;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Stack(
          children: [
            // 卡片外部的空白点击直接关闭（框体自身占满全屏，默认遮罩点不透）。
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SizedBox(
                  height: maxHeight,
                  child: _ReaderSettingsCard(
                    changePageIndex: changePageIndex,
                    isAndroidPhone: isAndroidPhone,
                    onLandscapeChanged: onLandscapeChanged,
                    source: source,
                    comicId: comicId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderSettingsCard extends StatelessWidget {
  final ValueChanged<int> changePageIndex;
  final bool isAndroidPhone;
  final ValueChanged<bool>? onLandscapeChanged;
  final String source;
  final String comicId;

  const _ReaderSettingsCard({
    required this.changePageIndex,
    required this.isAndroidPhone,
    this.onLandscapeChanged,
    this.source = '',
    this.comicId = '',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    final perComicAvailable =
        source.trim().isNotEmpty && comicId.trim().isNotEmpty;
    final tabLength = perComicAvailable ? 4 : 3;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.96),
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: DefaultTabController(
        length: tabLength,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReaderSettingsHeader(showPerComicTab: perComicAvailable),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _ReaderSettingsReadTab(
                    changePageIndex: changePageIndex,
                    onLandscapeChanged: onLandscapeChanged,
                    source: source,
                    comicId: comicId,
                  ),
                  _ReaderSettingsGestureTab(isAndroidPhone: isAndroidPhone),
                  const _ReaderSettingsInfoTab(),
                  if (perComicAvailable)
                    _ReaderSettingsPerComicTab(
                      changePageIndex: changePageIndex,
                      onLandscapeChanged: onLandscapeChanged,
                      source: source,
                      comicId: comicId,
                      isAndroidPhone: isAndroidPhone,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置页头部：把手 + TabBar（阅读页入口多一个“本漫”tab）。
class _ReaderSettingsHeader extends StatelessWidget {
  final bool showPerComicTab;

  const _ReaderSettingsHeader({this.showPerComicTab = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          TabBar(
            dividerColor: Colors.transparent,
            labelStyle: context.theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: t.reader.settings),
              Tab(text: t.reader.gesture),
              Tab(text: t.reader.infoBar),
              if (showPerComicTab) Tab(text: t.reader.perComicThisComic),
            ],
          ),
        ],
      ),
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

/// 阅读设置 sheet 内通用的“读目标值 + 按目标写”。
/// 读：[watchTargetReadSetting]——本漫 tab 读有效值（patch 已合并），其余只读全局。
/// 写：按当前编辑目标路由——改全局走 `GlobalSettingCubit`，
/// 改本漫走 `ComicReadPreferenceCubit.updateField`，只写变化的 key。
/// 需要震动反馈由调用方自己加；需要跳页（如切阅读模式）也由调用方自己调。
///
/// 写目标只看 [_PerComicScope]：外层恒包 `perComic: false`，
/// 第四个“本漫”tab 内层包 `perComic: true`，里面所有控件读写全钉本漫。
/// 加新设置项只写一遍 Section，第四 tab 复用同一个，不写第二遍。
extension EffectiveReadSettingX on BuildContext {
  /// 当前编辑目标是不是本漫：只看最近的 [_PerComicScope]，不回退读 cubit。
  ///
  /// 旧漫画的绑定状态漏不进全局页——全局入口与前三个 tab 恒为 false。
  bool get isEditingPerComic => _PerComicScope.maybeOf(this)?.perComic ?? false;

  /// 当前编辑目标的值：本漫 tab 读有效值，其余只读全局。
  ///
  /// 设置 UI 一律读这个，保证“显示什么就改什么”；渲染层继续用
  /// [ComicReadPreferenceContextX.watchEffectiveReadSetting]。
  ReadSettingState watchTargetReadSetting() {
    if (isEditingPerComic) return watchEffectiveReadSetting();
    return watch<GlobalSettingCubit>().state.readSetting;
  }

  /// 按编辑目标写入：本漫→patch（只含变化 key），全局→全局设置。
  Future<Set<String>> updateEffectiveReadSetting(
    ReadSettingState effective,
    ReadSettingState Function(ReadSettingState current) fn,
  ) {
    if (isEditingPerComic) {
      return read<ComicReadPreferenceCubit>().updateField(effective, fn);
    }
    read<GlobalSettingCubit>().updateReadSetting(fn);
    return Future.value(const <String>{});
  }
}

/// 钉死子树写目标：`perComic: true` 包住第四 tab，里面全写本漫。
class _PerComicScope extends InheritedWidget {
  final bool perComic;

  const _PerComicScope({required this.perComic, required super.child});

  static _PerComicScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PerComicScope>();
  }

  @override
  bool updateShouldNotify(_PerComicScope oldWidget) {
    return perComic != oldWidget.perComic;
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// 标题行右侧动作（如本漫 tab 阅读模式旁的“跟随全局”）。
  final Widget? trailing;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...?trailing != null ? [trailing!] : null,
          ],
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
  static const WidgetStateProperty<Icon> _thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

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
        trailing: Switch.adaptive(
          thumbIcon: _thumbIcon,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _SettingsDropdownTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.values,
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
        trailing: FluentDropdown<int>(
          value: value,
          displayValue: value.toString(),
          items: {for (final option in values) option: option.toString()},
          onChanged: onChanged,
        ),
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
