// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadTaskJson {

 String get from; String get comicId; String get comicName; BikaInfo get bikaInfo; List<String> get selectedChapters; bool get slowDownload;
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskJsonCopyWith<DownloadTaskJson> get copyWith => _$DownloadTaskJsonCopyWithImpl<DownloadTaskJson>(this as DownloadTaskJson, _$identity);

  /// Serializes this DownloadTaskJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&(identical(other.bikaInfo, bikaInfo) || other.bikaInfo == bikaInfo)&&const DeepCollectionEquality().equals(other.selectedChapters, selectedChapters)&&(identical(other.slowDownload, slowDownload) || other.slowDownload == slowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,bikaInfo,const DeepCollectionEquality().hash(selectedChapters),slowDownload);

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, bikaInfo: $bikaInfo, selectedChapters: $selectedChapters, slowDownload: $slowDownload)';
}


}

/// @nodoc
abstract mixin class $DownloadTaskJsonCopyWith<$Res>  {
  factory $DownloadTaskJsonCopyWith(DownloadTaskJson value, $Res Function(DownloadTaskJson) _then) = _$DownloadTaskJsonCopyWithImpl;
@useResult
$Res call({
 String from, String comicId, String comicName, BikaInfo bikaInfo, List<String> selectedChapters, bool slowDownload
});


$BikaInfoCopyWith<$Res> get bikaInfo;

}
/// @nodoc
class _$DownloadTaskJsonCopyWithImpl<$Res>
    implements $DownloadTaskJsonCopyWith<$Res> {
  _$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final DownloadTaskJson _self;
  final $Res Function(DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? bikaInfo = null,Object? selectedChapters = null,Object? slowDownload = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,bikaInfo: null == bikaInfo ? _self.bikaInfo : bikaInfo // ignore: cast_nullable_to_non_nullable
as BikaInfo,selectedChapters: null == selectedChapters ? _self.selectedChapters : selectedChapters // ignore: cast_nullable_to_non_nullable
as List<String>,slowDownload: null == slowDownload ? _self.slowDownload : slowDownload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BikaInfoCopyWith<$Res> get bikaInfo {
  
  return $BikaInfoCopyWith<$Res>(_self.bikaInfo, (value) {
    return _then(_self.copyWith(bikaInfo: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _DownloadTaskJson implements DownloadTaskJson {
  const _DownloadTaskJson({required this.from, required this.comicId, required this.comicName, required this.bikaInfo, required final  List<String> selectedChapters, required this.slowDownload}): _selectedChapters = selectedChapters;
  factory _DownloadTaskJson.fromJson(Map<String, dynamic> json) => _$DownloadTaskJsonFromJson(json);

@override final  String from;
@override final  String comicId;
@override final  String comicName;
@override final  BikaInfo bikaInfo;
 final  List<String> _selectedChapters;
@override List<String> get selectedChapters {
  if (_selectedChapters is EqualUnmodifiableListView) return _selectedChapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedChapters);
}

@override final  bool slowDownload;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadTaskJsonCopyWith<_DownloadTaskJson> get copyWith => __$DownloadTaskJsonCopyWithImpl<_DownloadTaskJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadTaskJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&(identical(other.bikaInfo, bikaInfo) || other.bikaInfo == bikaInfo)&&const DeepCollectionEquality().equals(other._selectedChapters, _selectedChapters)&&(identical(other.slowDownload, slowDownload) || other.slowDownload == slowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,bikaInfo,const DeepCollectionEquality().hash(_selectedChapters),slowDownload);

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, bikaInfo: $bikaInfo, selectedChapters: $selectedChapters, slowDownload: $slowDownload)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskJsonCopyWith<$Res> implements $DownloadTaskJsonCopyWith<$Res> {
  factory _$DownloadTaskJsonCopyWith(_DownloadTaskJson value, $Res Function(_DownloadTaskJson) _then) = __$DownloadTaskJsonCopyWithImpl;
@override @useResult
$Res call({
 String from, String comicId, String comicName, BikaInfo bikaInfo, List<String> selectedChapters, bool slowDownload
});


@override $BikaInfoCopyWith<$Res> get bikaInfo;

}
/// @nodoc
class __$DownloadTaskJsonCopyWithImpl<$Res>
    implements _$DownloadTaskJsonCopyWith<$Res> {
  __$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final _DownloadTaskJson _self;
  final $Res Function(_DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? bikaInfo = null,Object? selectedChapters = null,Object? slowDownload = null,}) {
  return _then(_DownloadTaskJson(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,bikaInfo: null == bikaInfo ? _self.bikaInfo : bikaInfo // ignore: cast_nullable_to_non_nullable
as BikaInfo,selectedChapters: null == selectedChapters ? _self._selectedChapters : selectedChapters // ignore: cast_nullable_to_non_nullable
as List<String>,slowDownload: null == slowDownload ? _self.slowDownload : slowDownload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BikaInfoCopyWith<$Res> get bikaInfo {
  
  return $BikaInfoCopyWith<$Res>(_self.bikaInfo, (value) {
    return _then(_self.copyWith(bikaInfo: value));
  });
}
}


/// @nodoc
mixin _$BikaInfo {

 String get authorization; String get proxy;
/// Create a copy of BikaInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BikaInfoCopyWith<BikaInfo> get copyWith => _$BikaInfoCopyWithImpl<BikaInfo>(this as BikaInfo, _$identity);

  /// Serializes this BikaInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BikaInfo&&(identical(other.authorization, authorization) || other.authorization == authorization)&&(identical(other.proxy, proxy) || other.proxy == proxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorization,proxy);

@override
String toString() {
  return 'BikaInfo(authorization: $authorization, proxy: $proxy)';
}


}

/// @nodoc
abstract mixin class $BikaInfoCopyWith<$Res>  {
  factory $BikaInfoCopyWith(BikaInfo value, $Res Function(BikaInfo) _then) = _$BikaInfoCopyWithImpl;
@useResult
$Res call({
 String authorization, String proxy
});




}
/// @nodoc
class _$BikaInfoCopyWithImpl<$Res>
    implements $BikaInfoCopyWith<$Res> {
  _$BikaInfoCopyWithImpl(this._self, this._then);

  final BikaInfo _self;
  final $Res Function(BikaInfo) _then;

/// Create a copy of BikaInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authorization = null,Object? proxy = null,}) {
  return _then(_self.copyWith(
authorization: null == authorization ? _self.authorization : authorization // ignore: cast_nullable_to_non_nullable
as String,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _BikaInfo implements BikaInfo {
  const _BikaInfo({required this.authorization, required this.proxy});
  factory _BikaInfo.fromJson(Map<String, dynamic> json) => _$BikaInfoFromJson(json);

@override final  String authorization;
@override final  String proxy;

/// Create a copy of BikaInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BikaInfoCopyWith<_BikaInfo> get copyWith => __$BikaInfoCopyWithImpl<_BikaInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BikaInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BikaInfo&&(identical(other.authorization, authorization) || other.authorization == authorization)&&(identical(other.proxy, proxy) || other.proxy == proxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authorization,proxy);

@override
String toString() {
  return 'BikaInfo(authorization: $authorization, proxy: $proxy)';
}


}

/// @nodoc
abstract mixin class _$BikaInfoCopyWith<$Res> implements $BikaInfoCopyWith<$Res> {
  factory _$BikaInfoCopyWith(_BikaInfo value, $Res Function(_BikaInfo) _then) = __$BikaInfoCopyWithImpl;
@override @useResult
$Res call({
 String authorization, String proxy
});




}
/// @nodoc
class __$BikaInfoCopyWithImpl<$Res>
    implements _$BikaInfoCopyWith<$Res> {
  __$BikaInfoCopyWithImpl(this._self, this._then);

  final _BikaInfo _self;
  final $Res Function(_BikaInfo) _then;

/// Create a copy of BikaInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authorization = null,Object? proxy = null,}) {
  return _then(_BikaInfo(
authorization: null == authorization ? _self.authorization : authorization // ignore: cast_nullable_to_non_nullable
as String,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
