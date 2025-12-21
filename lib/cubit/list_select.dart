import 'package:flutter_bloc/flutter_bloc.dart';

class ListSelectCubit<T> extends Cubit<List<T>> {
  ListSelectCubit() : super([]);

  void add(T item) {
    emit([...state, item]);
  }

  void remove(T item) {
    emit(state.where((e) => e != item).toList());
  }

  void setList(List<T> list) {
    emit(list);
  }

  void clear() {
    emit([]);
  }
}
