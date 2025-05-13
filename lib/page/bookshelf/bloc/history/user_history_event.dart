part of 'user_history_bloc.dart';

final class UserHistoryEvent extends Equatable {
  final SearchEnter searchEnterConst;

  const UserHistoryEvent(this.searchEnterConst);

  @override
  List<Object> get props => [searchEnterConst];
}
