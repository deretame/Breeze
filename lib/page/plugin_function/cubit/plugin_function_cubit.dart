import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/error_filter.dart';

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
    emit(
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
      emit(
        state.copyWith(
          loading: false,
          error: '',
          scheme: envelope.scheme,
          data: asMap(envelope.data),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(loading: false, error: normalizeSearchErrorMessage(e)),
      );
    }
  }
}
