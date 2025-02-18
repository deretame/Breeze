// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bool_select.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BoolSelectStore on _BoolSelectStore, Store {
  late final _$dateAtom = Atom(name: '_BoolSelectStore.date', context: context);

  @override
  bool get date {
    _$dateAtom.reportRead();
    return super.date;
  }

  @override
  set date(bool value) {
    _$dateAtom.reportWrite(value, super.date, () {
      super.date = value;
    });
  }

  late final _$_BoolSelectStoreActionController = ActionController(
    name: '_BoolSelectStore',
    context: context,
  );

  @override
  void setDate(bool newDate) {
    final _$actionInfo = _$_BoolSelectStoreActionController.startAction(
      name: '_BoolSelectStore.setDate',
    );
    try {
      return super.setDate(newDate);
    } finally {
      _$_BoolSelectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
date: ${date}
    ''';
  }
}
