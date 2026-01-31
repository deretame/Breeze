import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_filter_cubit.freezed.dart';

@freezed
abstract class ComicFilterState with _$ComicFilterState {
  const factory ComicFilterState({
    @Default('') String mainKey,
    @Default('') String subKey,
    @Default('new') String rankingKey,
  }) = _ComicFilterState;
}

class ComicFilterCubit extends Cubit<ComicFilterState> {
  // ================= 静态数据源 =================
  static const tongRenTypeMap = {
    '全部': 'doujin',
    '汉化': 'doujin_chinese',
    '日语': 'doujin_japanese',
    'CG图集': 'doujin_CG',
  };
  static const danBenTypeMap = {
    '全部': 'single',
    '汉化': 'single_chinese',
    '日语': 'single_japanese',
    '青年漫': 'single_youth',
  };
  static const duanPianTypeMap = {
    '全部': 'short',
    '汉化': 'short_chinese',
    '日语': 'short_japanese',
  };
  static const qiTaLeiTypeMap = {
    '全部': 'another',
    '其他漫画': 'another_other',
    '3D': 'another_3d',
    '角色扮演': 'another_cosplay',
  };
  static const hanManTypeMap = {'全部': 'hanman', '汉化': 'hanman_chinese'};
  static const meiManTypeMap = {
    '全部': 'meiman',
    'IRODORI': 'meiman_irodori',
    'FAKKU': 'meiman_fakku',
    '18scan': 'meiman_18scan',
    'Manhwa': 'meiman_manhwa',
    'Comic': 'meiman_comic',
    'Other': 'meiman_other',
  };

  static const categoryMap = {
    '最新a漫': '0',
    '同人': tongRenTypeMap,
    '单本': danBenTypeMap,
    '短篇': duanPianTypeMap,
    '其他类': qiTaLeiTypeMap,
    '韩漫': hanManTypeMap,
    'English Manga': meiManTypeMap,
    'Cosplay': 'another_cosplay',
    '3D': '3D',
    '禁漫汉化组': '禁漫汉化组',
  };

  static const rankingTypeMap = {
    '最新': 'new',
    '最多点赞': 'tf',
    '总排行': 'mv',
    '月排行': 'mv_m',
    '周排行': 'mv_w',
    '日排行': 'mv_t',
  };

  ComicFilterCubit(List<String>? initialValues)
    : super(_calculateInitState(initialValues));

  static ComicFilterState _calculateInitState(List<String>? initialValues) {
    String defaultMain = categoryMap.keys.first;
    String defaultSub = '';
    String defaultRank = '最新';

    if (initialValues != null && initialValues.length >= 2) {
      final targetCategoryVal = initialValues[0];
      final targetRankVal = initialValues[1];

      for (var entry in rankingTypeMap.entries) {
        if (entry.value == targetRankVal) {
          defaultRank = entry.key;
          break;
        }
      }

      bool found = false;
      for (var mainEntry in categoryMap.entries) {
        final mainKey = mainEntry.key;
        final mainVal = mainEntry.value;

        if (mainVal is String) {
          if (mainVal == targetCategoryVal) {
            defaultMain = mainKey;
            defaultSub = '';
            found = true;
          }
        } else if (mainVal is Map) {
          for (var subEntry in mainVal.entries) {
            if (subEntry.value == targetCategoryVal) {
              defaultMain = mainKey;
              defaultSub = subEntry.key;
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }
    }

    final checkMainVal = categoryMap[defaultMain];
    if (checkMainVal is Map && defaultSub.isEmpty) {
      defaultSub = checkMainVal.keys.first;
    }

    return ComicFilterState(
      mainKey: defaultMain,
      subKey: defaultSub,
      rankingKey: defaultRank,
    );
  }

  void setMainKey(String key) {
    String newSubKey = '';
    final value = categoryMap[key];
    if (value is Map) {
      newSubKey = value.keys.first;
    }
    emit(state.copyWith(mainKey: key, subKey: newSubKey));
  }

  void setSubKey(String key) {
    emit(state.copyWith(subKey: key));
  }

  void setRankingKey(String key) {
    emit(state.copyWith(rankingKey: key));
  }

  List<String> generateResult() {
    final mainValue = categoryMap[state.mainKey];
    final rankingValue = rankingTypeMap[state.rankingKey] ?? '';

    String finalCategoryVal = '';

    if (mainValue is String) {
      finalCategoryVal = mainValue;
    } else if (mainValue is Map) {
      finalCategoryVal = mainValue[state.subKey] ?? '';
    }

    return [finalCategoryVal, rankingValue];
  }
}
