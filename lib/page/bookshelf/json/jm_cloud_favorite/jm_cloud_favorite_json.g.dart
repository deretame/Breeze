// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_cloud_favorite_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmCloudFavoriteJson _$JmCloudFavoriteJsonFromJson(Map<String, dynamic> json) =>
    _JmCloudFavoriteJson(
      list: (json['list'] as List<dynamic>)
          .map((e) => ListElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      folderList: (json['folder_list'] as List<dynamic>)
          .map((e) => FolderList.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$JmCloudFavoriteJsonToJson(
  _JmCloudFavoriteJson instance,
) => <String, dynamic>{
  'list': instance.list,
  'folder_list': instance.folderList,
  'total': instance.total,
  'count': instance.count,
};

_FolderList _$FolderListFromJson(Map<String, dynamic> json) => _FolderList(
  fid: json['FID'] as String,
  uid: json['UID'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$FolderListToJson(_FolderList instance) =>
    <String, dynamic>{
      'FID': instance.fid,
      'UID': instance.uid,
      'name': instance.name,
    };

_ListElement _$ListElementFromJson(Map<String, dynamic> json) => _ListElement(
  id: json['id'] as String,
  author: json['author'] as String,
  description: json['description'] as String,
  name: json['name'] as String,
  latestEp: json['latest_ep'] as String?,
  latestEpAid: json['latest_ep_aid'] as String?,
  image: json['image'] as String,
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  categorySub: CategorySub.fromJson(
    json['category_sub'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ListElementToJson(_ListElement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'description': instance.description,
      'name': instance.name,
      'latest_ep': instance.latestEp,
      'latest_ep_aid': instance.latestEpAid,
      'image': instance.image,
      'category': instance.category,
      'category_sub': instance.categorySub,
    };

_Category _$CategoryFromJson(Map<String, dynamic> json) =>
    _Category(id: json['id'] as String, title: json['title'] as String);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};

_CategorySub _$CategorySubFromJson(Map<String, dynamic> json) =>
    _CategorySub(id: json['id'] as String?, title: json['title'] as String?);

Map<String, dynamic> _$CategorySubToJson(_CategorySub instance) =>
    <String, dynamic>{'id': instance.id, 'title': instance.title};
