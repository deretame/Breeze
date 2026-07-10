import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/service/update/check_update.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

import 'method.dart';

@RoutePage()
class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  bool _includeDownloads = true;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.dataBackup.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: ListView(
            children: [
              _buildSectionTitle(
                context,
                t.dataBackup.exportSection,
                Icons.file_upload_outlined,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.folder_outlined),
                title: Text(t.dataBackup.includeDownloads),
                subtitle: Text(t.dataBackup.includeDownloadsSubtitle),
                thumbIcon: kSettingSwitchThumbIcon,
                value: _includeDownloads,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _includeDownloads = value),
              ),
              const Divider(height: 1, thickness: 0.3),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(t.dataBackup.exportData),
                subtitle: Text(t.dataBackup.exportDataSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : _exportData,
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.3),
              _buildSectionTitle(
                context,
                t.dataBackup.importSection,
                Icons.file_download_outlined,
              ),
              ListTile(
                leading: const Icon(Icons.unarchive_outlined),
                title: Text(t.dataBackup.importData),
                subtitle: Text(t.dataBackup.importDataSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : _importData,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    String? selectedDir;
    try {
      selectedDir = await getDirectoryPath();
    } catch (e, s) {
      logger.e('选择导出目录失败', error: e, stackTrace: s);
      showErrorToast('${t.dataBackup.selectExportDirFailed}：$e');
      return;
    }

    if (selectedDir == null || selectedDir.trim().isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = p.join(selectedDir, 'Breeze-export-$timestamp.zip');

    if (!mounted) return;
    _setBusy(true);
    _showLoadingDialog(t.dataBackup.exporting);

    try {
      await exportBreezeBackup(
        zipPath: zipPath,
        includeDownloads: _includeDownloads,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showResultDialog(
        t.dataBackup.exportSuccess,
        t.dataBackup.savedTo(path: zipPath),
      );
    } catch (e, s) {
      if (mounted) Navigator.of(context).pop();
      logger.e('导出数据失败', error: e, stackTrace: s);
      showErrorToast('${t.dataBackup.exportFailed}：$e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _importData() async {
    if (!mounted) return;
    _setBusy(true);
    _showLoadingDialog(t.dataBackup.processingBackup);

    final String? filePath;
    try {
      filePath = await _pickImportZipPath();
    } catch (e, s) {
      if (mounted) Navigator.of(context).pop();
      logger.e('选择备份文件失败', error: e, stackTrace: s);
      showErrorToast('${t.dataBackup.selectBackupFailed}：$e');
      _setBusy(false);
      return;
    }

    if (filePath == null) {
      if (mounted) Navigator.of(context).pop();
      _setBusy(false);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _showLoadingDialog(t.dataBackup.readingBackup);

    late final BackupConfig config;
    try {
      config = await readBackupConfig(filePath, skipCopy: Platform.isAndroid);
    } catch (e, s) {
      if (mounted) Navigator.of(context).pop();
      logger.e('读取备份失败', error: e, stackTrace: s);
      showErrorToast('${t.dataBackup.readBackupFailed}：$e');
      _setBusy(false);
      return;
    }

    if (!mounted) {
      _cleanupImportCache(config);
      _setBusy(false);
      return;
    }
    Navigator.of(context).pop();

    final currentVersion = await getAppVersion();
    final confirmed = await _showImportConfirmDialog(
      exportedVersion: config.version,
      currentVersion: currentVersion,
      includeDownloads: config.includeDownloads,
    );

    if (!confirmed) {
      _cleanupImportCache(config);
      _setBusy(false);
      return;
    }

    if (!mounted) {
      _cleanupImportCache(config);
      _setBusy(false);
      return;
    }
    _showLoadingDialog(t.dataBackup.importing);

    try {
      await applyBreezeBackupImport(config);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showRestartDialog();
    } catch (e, s) {
      if (mounted) Navigator.of(context).pop();
      logger.e('导入数据失败', error: e, stackTrace: s);
      showErrorToast('${t.dataBackup.importFailed}：$e');
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (mounted) setState(() => _busy = value);
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 选择要导入的 zip 备份文件。
  ///
  /// Android 上使用原生 MethodChannel 选择器，把文件直接拷贝到应用缓存，
  /// 绕过 [file_selector] 选择大文件时把整个文件读入内存导致的 OOM；
  /// 其他平台继续使用 [file_selector]。
  Future<String?> _pickImportZipPath() async {
    if (Platform.isAndroid) {
      logger.i('Android 平台，使用原生选择器');
      return pickBackupZipAndroid();
    }

    logger.i('非 Android 平台，使用 file_selector');
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'zip', extensions: ['zip']),
      ],
    );
    return file?.path;
  }

  void _cleanupImportCache(BackupConfig config) {
    try {
      Directory(config.cacheDir).deleteSync(recursive: true);
    } catch (_) {}
  }

  void _showLoadingDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResultDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
  }

  Future<bool> _showImportConfirmDialog({
    required String exportedVersion,
    required String currentVersion,
    required bool includeDownloads,
  }) async {
    if (!mounted) return false;
    final versionMismatch = exportedVersion != currentVersion;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dataBackup.importTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dataBackup.importConfirm),
              if (includeDownloads) ...[
                const SizedBox(height: 12),
                Text(t.dataBackup.includesDownloadsWarning),
              ],
              if (versionMismatch) ...[
                const SizedBox(height: 12),
                Text(
                  t.dataBackup.versionMismatch,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(t.dataBackup.exportedVersion(version: exportedVersion)),
                Text(t.dataBackup.currentVersion(version: currentVersion)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.dataBackup.kContinue),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _showRestartDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dataBackup.importSuccess),
        content: Text(t.dataBackup.restartPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
  }
}
