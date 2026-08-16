import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_mode_service.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

/// 将 CS 模式服务接入现有 Bloc 状态树。
///
/// 当前只负责暴露连接状态，具体的插件初始化、Repository 注入和下载队列
/// 切换由后续启动协调器完成，避免在这一阶段改变本地模式行为。
class CsModeCubit extends Cubit<CsConnectionSettings> {
  CsModeCubit({CsModeService? service})
    : _service = service ?? CsModeService(),
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

  void attachSession({required String userId, required String accessToken}) {
    _service.attachSession(userId: userId, accessToken: accessToken);
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
