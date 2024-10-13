import 'package:mobx/mobx.dart';

part 'string_select.g.dart';

// ignore: library_private_types_in_public_api
class StringSelectStore = _StringSelectStore with _$StringSelectStore;

abstract class _StringSelectStore with Store {
  @observable
  String date = ''; //MobX 管理的日期字符串

  @action
  void setDate(String newDate) {
    date = newDate;
  }
}
