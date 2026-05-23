import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

class PluginSettingsState {
  const PluginSettingsState({
    this.loading = true,
    this.error = '',
    this.sections = const <Map<String, dynamic>>[],
    this.actions = const <Map<String, dynamic>>[],
    this.values = const <String, dynamic>{},
    this.userInfo = const <String, dynamic>{},
    this.canShowUserInfo = false,
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
      final values = asMap(settingsEnvelope.data['values']);
      final canShowUserInfo = settingsEnvelope.data['canShowUserInfo'] == true;

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
          userInfoError: '',
          actions: actions,
        ),
      );

      if (canShowUserInfo) {
        unawaited(loadUserInfo(from));
      }
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(loading: false, error: normalizeSearchErrorMessage(e)),
      );
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
          userInfo: asMap(envelope.data),
          loadingUserInfo: false,
          userInfoError: '',
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(loadingUserInfo: false, userInfoError: '用户信息加载失败'));
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
