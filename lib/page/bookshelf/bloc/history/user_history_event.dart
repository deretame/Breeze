part of 'user_history_bloc.dart';

final class UserHistoryEvent extends Equatable {
  final SearchEnter searchEnterConst;
  final int comicChoice;

  const UserHistoryEvent(this.searchEnterConst, this.comicChoice);

  @override
  List<Object> get props => [searchEnterConst, comicChoice];
}
