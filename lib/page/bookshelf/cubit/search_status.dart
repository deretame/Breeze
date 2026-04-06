import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_status.freezed.dart'; // 运行 build_runner 生成

@freezed
abstract class SearchStatusState with _$SearchStatusState {
  const factory SearchStatusState({
    @Default("") String keyword,
    @Default("dd") String sort,
    @Default(<String>[]) List<String> categories,
    @Default(<String>[]) List<String> sources,
  }) = _SearchStatusState;
}
