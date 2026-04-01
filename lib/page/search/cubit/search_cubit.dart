import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

part 'search_cubit.freezed.dart';
part 'search_cubit.g.dart';
part 'search_states.dart';

class SearchCubit extends Cubit<SearchStates> {
  SearchCubit(super.initialState);

  void update(SearchStates states) {
    emit(states);
  }
}
