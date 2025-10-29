import 'package:flutter_bloc/flutter_bloc.dart';

class StringSelectCubit extends Cubit<String> {
  StringSelectCubit() : super('');

  void updateDate(String newDate) {
    emit(newDate);
  }
}
