import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/type/enum.dart';

part 'search_cubit.freezed.dart';
part 'search_cubit.g.dart';
part 'search_states.dart';

class SearchCubit extends Cubit<SearchStates> {
  SearchCubit(super.initialState);

  void update(SearchStates states) {
    emit(states);
  }
}
