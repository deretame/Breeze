import 'package:flutter_bloc/flutter_bloc.dart';

class IntSelectCubit extends Cubit<int> {
  IntSelectCubit() : super(0);

  void setDate(int newDate) {
    emit(newDate);
  }

  void increment() {
    emit(state + 1);
  }
}
