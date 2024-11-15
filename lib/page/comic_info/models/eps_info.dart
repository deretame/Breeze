import 'package:equatable/equatable.dart';

class EpsInfo extends Equatable {
  final String comicId;
  final int pageCount;

  const EpsInfo({
    required this.comicId,
    required this.pageCount,
  });

  @override
  List<Object?> get props => [comicId, pageCount];
}
