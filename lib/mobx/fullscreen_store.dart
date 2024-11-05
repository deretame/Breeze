import 'package:mobx/mobx.dart';

part 'fullscreen_store.g.dart';

// ignore: library_private_types_in_public_api
class FullScreenStore = _FullScreenStoreBase with _$FullScreenStore;

abstract class _FullScreenStoreBase with Store {
  @observable
  bool fullscreen = false;

  @action
  void toggle() {
    fullscreen = !fullscreen;
  }
}
