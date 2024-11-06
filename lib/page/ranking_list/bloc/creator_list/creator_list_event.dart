part of 'creator_list_bloc.dart';

sealed class CreatorListEvent extends Equatable {
  const CreatorListEvent();

  @override
  List<Object> get props => [];
}

class FetchCreatorList extends CreatorListEvent {
  final GetInfo getInfo;

  const FetchCreatorList(this.getInfo);

  @override
  List<Object> get props => [getInfo];
}
