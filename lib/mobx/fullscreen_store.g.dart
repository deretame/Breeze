// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fullscreen_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FullScreenStore on _FullScreenStoreBase, Store {
  late final _$fullscreenAtom =
      Atom(name: '_FullScreenStoreBase.fullscreen', context: context);

  @override
  bool get fullscreen {
    _$fullscreenAtom.reportRead();
    return super.fullscreen;
  }

  @override
  set fullscreen(bool value) {
    _$fullscreenAtom.reportWrite(value, super.fullscreen, () {
      super.fullscreen = value;
    });
  }

  late final _$_FullScreenStoreBaseActionController =
      ActionController(name: '_FullScreenStoreBase', context: context);

  @override
  void toggle() {
    final _$actionInfo = _$_FullScreenStoreBaseActionController.startAction(
        name: '_FullScreenStoreBase.toggle');
    try {
      return super.toggle();
    } finally {
      _$_FullScreenStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
fullscreen: ${fullscreen}
    ''';
  }
}
