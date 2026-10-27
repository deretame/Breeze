import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/main.dart';

class PluginSettingsState {
  const PluginSettingsState({
    this.loading = true,
    this.error = '',
    this.sections = const <Map<String, dynamic>>[],
    this.actions = const <Map<String, dynamic>>[],
    this.values = const <String, dynamic>{},
    this.userInfo = const <String, dynamic>{},
    this.canShowUserInfo = false,
    this.loginSupported = false,
    this.loginTitle = '',
    this.loginSubtitle = '',
    this.detailSupported = false,
    this.loadingUserInfo = false,
    this.userInfoError = '',
  });

  final bool loading;
  final String error;
  final List<Map<String, dynamic>> sections;
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic> values;
  final Map<String, dynamic> userInfo;
  final bool canShowUserInfo;
  final bool loginSupported;
  final String loginTitle;
  final String loginSubtitle;
  final bool detailSupported;
  final bool loadingUserInfo;
  final String userInfoError;
  PluginSettingsState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? sections,
    List<Map<String, dynamic>>? actions,
    Map<String, dynamic>? values,
    Map<String, dynamic>? userInfo,
    bool? canShowUserInfo,
    bool? loginSupported,
    String? loginTitle,
    String? loginSubtitle,
    bool? detailSupported,
    bool? loadingUserInfo,
    String? userInfoError,
  }) {
    return PluginSettingsState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      sections: sections ?? this.sections,
      actions: actions ?? this.actions,
      values: values ?? this.values,
      userInfo: userInfo ?? this.userInfo,
      canShowUserInfo: canShowUserInfo ?? this.canShowUserInfo,
      loginSupported: loginSupported ?? this.loginSupported,
      loginTitle: loginTitle ?? this.loginTitle,
      loginSubtitle: loginSubtitle ?? this.loginSubtitle,
      detailSupported: detailSupported ?? this.detailSupported,
      loadingUserInfo: loadingUserInfo ?? this.loadingUserInfo,
      userInfoError: userInfoError ?? this.userInfoError,
    );
  }
}

class PluginSettingsCubit extends Cubit<PluginSettingsState> {
  PluginSettingsCubit() : super(const PluginSettingsState());

  Future<void> load(String from) async {
    emit(state.copyWith(loading: true, error: ''));

    try {
      final settingsResponse = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getSettingsBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final settingsEnvelope = UnifiedPluginEnvelope.fromMap(settingsResponse);
      final settingsSections = asJsonList(
        settingsEnvelope.scheme['sections'],
      ).map((item) => asJsonMap(item)).toList();
      final values = asJsonMap(settingsEnvelope.data['values']);
      final canShowUserInfo = settingsEnvelope.data['canShowUserInfo'] == true;
      final loginSupported = await _resolveLoginSupported(
        from,
        settingsEnvelope.data,
      );

      List<Map<String, dynamic>> actions = const [];
      try {
        final capabilityResponse = await callUnifiedComicPlugin(
          from: from,
          fnPath: 'getCapabilitiesBundle',
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
        );
        final capabilityEnvelope = UnifiedPluginEnvelope.fromMap(
          capabilityResponse,
        );
        actions = asJsonList(capabilityEnvelope.scheme['actions'])
            .map((item) => asJsonMap(item))
            .where((item) => item['fnPath']?.toString() != 'dumpRuntimeInfo')
            .toList();
      } catch (_) {}

      emit(
        state.copyWith(
          loading: false,
          error: '',
          sections: settingsSections,
          values: values,
          userInfo: const <String, dynamic>{},
          canShowUserInfo: canShowUserInfo,
          loginSupported: loginSupported,
          loginTitle: _resolveLoginText(settingsEnvelope.data['loginTitle']),
          loginSubtitle: _resolveLoginText(
            settingsEnvelope.data['loginSubtitle'],
          ),
          detailSupported: settingsEnvelope.data['canShowDetail'] == true,
          userInfoError: '',
          actions: actions,
        ),
      );

      if (canShowUserInfo) {
        unawaited(loadUserInfo(from));
      }
    } catch (e) {
      logger.e(e);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(loading: false, error: normalizeSearchErrorMessage(e)),
      );
    }
  }

  /// 登录入口文案：插件可经 `loginTitle` / `loginSubtitle` 自定义，空白回退宿主默认。
  String _resolveLoginText(dynamic value) => value?.toString().trim() ?? '';

  /// 插件在 getSettingsBundle 的 data 中声明 `canLogin: true` 即支持登录。
  Future<bool> _resolveLoginSupported(
    String from,
    Map<String, dynamic> data,
  ) async {
    if (data['canLogin'] == true) {
      return true;
    }
    if (data.containsKey('canLogin')) {
      return false;
    }
    try {
      await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getLoginBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadUserInfo(String from) async {
    if (state.loadingUserInfo) {
      return;
    }
    emit(state.copyWith(loadingUserInfo: true, userInfoError: ''));
    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      emit(
        state.copyWith(
          userInfo: asJsonMap(envelope.data),
          loadingUserInfo: false,
          userInfoError: '',
        ),
      );
    } catch (e, st) {
      logger.e(e, stackTrace: st);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          loadingUserInfo: false,
          userInfoError: t.plugin.userInfoLoadFailed,
        ),
      );
    }
  }

  void saveFieldValue(String key, dynamic value) {
    if (key.isEmpty) {
      return;
    }
    emit(
      state.copyWith(
        values: Map<String, dynamic>.from(state.values)..[key] = value,
      ),
    );
  }
}
