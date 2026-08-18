import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_mode_service.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_migration_exporter.dart';
import 'package:zephyr/cs/data/cs_migration_importer.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 将 CS 模式服务接入现有 Bloc 状态树。
///
/// 当前负责暴露连接状态、登录和下载归属选择；本地插件及本地下载队列仍由原有路径维护。
class CsModeCubit extends Cubit<CsConnectionSettings> {
  CsModeCubit({
    CsModeService? service,
    CsMigrationExporter? migrationExporter,
    CsMigrationImporter? migrationImporter,
  }) : _service =
           service ??
           CsModeService(
             migrationExporter: migrationExporter,
             migrationImporter: migrationImporter,
           ),
       super(service?.settings ?? const CsConnectionSettings());

  final CsModeService _service;

  Future<void> init() async {
    await _service.load();
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> configure({
    required String serverUrl,
    CsDownloadMode? downloadMode,
  }) async {
    await _service.configure(serverUrl: serverUrl, downloadMode: downloadMode);
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> setMode(CsRunMode mode) async {
    await _service.setMode(mode);
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> closeCsMode({required bool overwriteRemoteData}) async {
    await _service.closeCsMode(overwriteRemoteData: overwriteRemoteData);
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> enableCsMode({
    required bool migrateData,
    required bool migrateDownloads,
    void Function(String message)? onMigrationProgress,
  }) async {
    await _service.enableCsMode(
      migrateData: migrateData,
      migrateDownloads: migrateDownloads,
      onMigrationProgress: onMigrationProgress,
    );
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> login({
    required String username,
    required String password,
    bool register = false,
  }) async {
    await _service.login(
      username: username,
      password: password,
      register: register,
    );
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> attachSession({
    required String userId,
    required String accessToken,
  }) async {
    await _service.attachSession(userId: userId, accessToken: accessToken);
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  void updateServerRevision(int revision) {
    _service.updateServerRevision(revision);
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  Future<void> signOut() async {
    await _service.signOut();
    CsRuntimeContext.I.update(_service.settings);
    emit(_service.settings);
  }

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
