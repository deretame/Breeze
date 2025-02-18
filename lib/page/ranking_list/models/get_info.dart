import 'package:equatable/equatable.dart';

class GetInfo extends Equatable {
  final String days;
  final String type;

  const GetInfo({this.days = '', this.type = ''});

  @override
  List<Object?> get props => [days, type];
}
