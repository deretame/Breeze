import 'package:mobx/mobx.dart';

part 'bool_select.g.dart';

// ignore: library_private_types_in_public_api
class BoolSelectStore = _BoolSelectStore with _$BoolSelectStore;

abstract class _BoolSelectStore with Store {
  @observable
  bool date = false;

  @action
  void setDate(bool newDate) {
    date = newDate;
  }
}
