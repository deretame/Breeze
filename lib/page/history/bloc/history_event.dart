part of 'history_bloc.dart';

final class HistoryEvent extends Equatable {
  final SearchEnterConst searchEnterConst;

  const HistoryEvent(
    this.searchEnterConst,
  );

  @override
  List<Object> get props => [searchEnterConst];
}
