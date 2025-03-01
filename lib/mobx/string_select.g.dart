// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'string_select.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StringSelectStore on _StringSelectStore, Store {
  late final _$dateAtom =
      Atom(name: '_StringSelectStore.date', context: context);

  @override
  String get date {
    _$dateAtom.reportRead();
    return super.date;
  }

  @override
  set date(String value) {
    _$dateAtom.reportWrite(value, super.date, () {
      super.date = value;
    });
  }

  late final _$_StringSelectStoreActionController =
      ActionController(name: '_StringSelectStore', context: context);

  @override
  void setDate(String newDate) {
    final _$actionInfo = _$_StringSelectStoreActionController.startAction(
        name: '_StringSelectStore.setDate');
    try {
      return super.setDate(newDate);
    } finally {
      _$_StringSelectStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
date: ${date}
    ''';
  }
}
