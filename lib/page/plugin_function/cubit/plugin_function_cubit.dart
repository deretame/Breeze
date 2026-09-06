import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

class PluginFunctionState {
  const PluginFunctionState({
    this.loading = true,
    this.error = '',
    this.scheme = const <String, dynamic>{},
    this.data = const <String, dynamic>{},
  });

  final bool loading;
  final String error;
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> data;

  PluginFunctionState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? scheme,
    Map<String, dynamic>? data,
  }) {
    return PluginFunctionState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      scheme: scheme ?? this.scheme,
      data: data ?? this.data,
    );
  }
}

class PluginFunctionCubit extends Cubit<PluginFunctionState> {
  PluginFunctionCubit() : super(const PluginFunctionState());

  Future<void> load({required String from, required String functionId}) async {
    if (isClosed) return;
    _emit(
      state.copyWith(
        loading: true,
        error: '',
        scheme: const <String, dynamic>{},
        data: const <String, dynamic>{},
      ),
    );
    try {
      Map<String, dynamic> response;
      response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getFunctionPage',
        core: {'id': functionId},
        extern: const <String, dynamic>{},
      );

      final envelope = UnifiedPluginEnvelope.fromMap(response);
      _emit(
        state.copyWith(
          loading: false,
          error: '',
          scheme: envelope.scheme,
          data: asJsonMap(envelope.data),
        ),
      );
    } catch (e) {
      _emit(
        state.copyWith(loading: false, error: normalizeSearchErrorMessage(e)),
      );
    }
  }

  void _emit(PluginFunctionState nextState) {
    if (!isClosed) emit(nextState);
  }
}
