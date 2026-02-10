import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comments/widgets/title.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

class ComicReadAppBar extends StatelessWidget {
  final String title;
  final ValueChanged<int> changePageIndex;

  const ComicReadAppBar({
    super.key,
    required this.title,
    required this.changePageIndex,
  });

  // 弹出设置框
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsDialog(changePageIndex: changePageIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerCubit = context.watch<ReaderCubit>();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      top: readerCubit.state.isMenuVisible
          ? 0
          : -kToolbarHeight - MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AppBar(
            title: ScrollableTitle(text: title),
            backgroundColor: context.backgroundColor.withValues(alpha: 0.5),
            elevation: readerCubit.state.isMenuVisible ? 4.0 : 0.0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 设置对话框
class SettingsDialog extends StatefulWidget {
  final ValueChanged<int> changePageIndex;

  const SettingsDialog({super.key, required this.changePageIndex});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _selectedMode = 'topToBottom'; // 默认选中的阅读模式

  @override
  void initState() {
    super.initState();
    _selectedMode = _getReadModeLabel(SettingsHiveUtils.readMode);
  }

  // 获取阅读模式的标签
  String _getReadModeLabel(int mode) {
    // logger.d('mode: $mode');
    if (mode == 0) {
      return 'topToBottom';
    } else if (mode == 1) {
      return 'leftToRight';
    } else if (mode == 2) {
      return 'rightToLeft';
    } else {
      return '从上到下';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('阅读模式设置'),
      content: RadioGroup<String>(
        groupValue: _selectedMode,
        onChanged: (String? value) {
          if (value != null) {
            _onModeChanged(value);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeOption('从上到下', 'topToBottom'),
            _buildModeOption('从左到右', 'leftToRight'),
            _buildModeOption('从右到左', 'rightToLeft'),
          ],
        ),
      ),
      actions: [
        TextButton(child: const Text('关闭'), onPressed: () => context.pop()),
      ],
    );
  }

  void _onModeChanged(String newValue) {
    final gloablSettingCubit = context.read<GlobalSettingCubit>();
    setState(() => _selectedMode = newValue); // 更新选中的阅读模式

    if (newValue == 'topToBottom') {
      gloablSettingCubit.updateReadMode(0);
    } else if (newValue == 'leftToRight') {
      gloablSettingCubit.updateReadMode(1);
    } else if (newValue == 'rightToLeft') {
      gloablSettingCubit.updateReadMode(2);
    }
    widget.changePageIndex(2);
  }

  // 构建阅读模式选项
  Widget _buildModeOption(String label, String value) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(value: value),
      onTap: () => _onModeChanged(value),
    );
  }
}
