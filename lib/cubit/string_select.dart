import 'package:flutter_bloc/flutter_bloc.dart';

class StringSelectCubit extends Cubit<String> {
  StringSelectCubit() : super('');

  void setDate(String newDate) {
    emit(newDate);
  }
}
