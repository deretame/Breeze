import 'package:mobx/mobx.dart';

part 'int_select.g.dart';

// ignore: library_private_types_in_public_api
class IntSelectStore = _IntSelectStore with _$IntSelectStore;

abstract class _IntSelectStore with Store {
  @observable
  int date = 0; //MobX 管理的日期字符串

  @action
  void setDate(int newDate) {
    date = newDate;
  }
}
