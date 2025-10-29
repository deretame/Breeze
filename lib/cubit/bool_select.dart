import 'package:flutter_bloc/flutter_bloc.dart';

class BoolSelectCubit extends Cubit<bool> {
  BoolSelectCubit() : super(false);

  void setDate(bool newDate) {
    emit(newDate);
  }

  void toggle() {
    emit(!state);
  }
}
