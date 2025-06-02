// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_user_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmUserInfoJson {

@JsonKey(name: "uid") String get uid;@JsonKey(name: "username") String get username;@JsonKey(name: "email") String get email;@JsonKey(name: "emailverified") String get emailverified;@JsonKey(name: "photo") String get photo;@JsonKey(name: "fname") String get fname;@JsonKey(name: "gender") String get gender;@JsonKey(name: "message") dynamic get message;@JsonKey(name: "coin") int get coin;@JsonKey(name: "ipcountry") String get ipcountry;@JsonKey(name: "album_favorites") int get albumFavorites;@JsonKey(name: "s") String get s;@JsonKey(name: "level_name") String get levelName;@JsonKey(name: "level") int get level;@JsonKey(name: "nextLevelExp") int get nextLevelExp;@JsonKey(name: "exp") String get exp;@JsonKey(name: "expPercent") double get expPercent;@JsonKey(name: "badges") List<dynamic> get badges;@JsonKey(name: "album_favorites_max") int get albumFavoritesMax;@JsonKey(name: "ad_free") bool get adFree;@JsonKey(name: "ad_free_before") String get adFreeBefore;@JsonKey(name: "charge") String get charge;@JsonKey(name: "jar") String get jar;@JsonKey(name: "invitation_qrcode") String get invitationQrcode;@JsonKey(name: "invitation_url") String get invitationUrl;@JsonKey(name: "invited_cnt") String get invitedCnt;
/// Create a copy of JmUserInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmUserInfoJsonCopyWith<JmUserInfoJson> get copyWith => _$JmUserInfoJsonCopyWithImpl<JmUserInfoJson>(this as JmUserInfoJson, _$identity);

  /// Serializes this JmUserInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmUserInfoJson&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailverified, emailverified) || other.emailverified == emailverified)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.fname, fname) || other.fname == fname)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other.message, message)&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.ipcountry, ipcountry) || other.ipcountry == ipcountry)&&(identical(other.albumFavorites, albumFavorites) || other.albumFavorites == albumFavorites)&&(identical(other.s, s) || other.s == s)&&(identical(other.levelName, levelName) || other.levelName == levelName)&&(identical(other.level, level) || other.level == level)&&(identical(other.nextLevelExp, nextLevelExp) || other.nextLevelExp == nextLevelExp)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.expPercent, expPercent) || other.expPercent == expPercent)&&const DeepCollectionEquality().equals(other.badges, badges)&&(identical(other.albumFavoritesMax, albumFavoritesMax) || other.albumFavoritesMax == albumFavoritesMax)&&(identical(other.adFree, adFree) || other.adFree == adFree)&&(identical(other.adFreeBefore, adFreeBefore) || other.adFreeBefore == adFreeBefore)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.jar, jar) || other.jar == jar)&&(identical(other.invitationQrcode, invitationQrcode) || other.invitationQrcode == invitationQrcode)&&(identical(other.invitationUrl, invitationUrl) || other.invitationUrl == invitationUrl)&&(identical(other.invitedCnt, invitedCnt) || other.invitedCnt == invitedCnt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,username,email,emailverified,photo,fname,gender,const DeepCollectionEquality().hash(message),coin,ipcountry,albumFavorites,s,levelName,level,nextLevelExp,exp,expPercent,const DeepCollectionEquality().hash(badges),albumFavoritesMax,adFree,adFreeBefore,charge,jar,invitationQrcode,invitationUrl,invitedCnt]);

@override
String toString() {
  return 'JmUserInfoJson(uid: $uid, username: $username, email: $email, emailverified: $emailverified, photo: $photo, fname: $fname, gender: $gender, message: $message, coin: $coin, ipcountry: $ipcountry, albumFavorites: $albumFavorites, s: $s, levelName: $levelName, level: $level, nextLevelExp: $nextLevelExp, exp: $exp, expPercent: $expPercent, badges: $badges, albumFavoritesMax: $albumFavoritesMax, adFree: $adFree, adFreeBefore: $adFreeBefore, charge: $charge, jar: $jar, invitationQrcode: $invitationQrcode, invitationUrl: $invitationUrl, invitedCnt: $invitedCnt)';
}


}

/// @nodoc
abstract mixin class $JmUserInfoJsonCopyWith<$Res>  {
  factory $JmUserInfoJsonCopyWith(JmUserInfoJson value, $Res Function(JmUserInfoJson) _then) = _$JmUserInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "uid") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "email") String email,@JsonKey(name: "emailverified") String emailverified,@JsonKey(name: "photo") String photo,@JsonKey(name: "fname") String fname,@JsonKey(name: "gender") String gender,@JsonKey(name: "message") dynamic message,@JsonKey(name: "coin") int coin,@JsonKey(name: "ipcountry") String ipcountry,@JsonKey(name: "album_favorites") int albumFavorites,@JsonKey(name: "s") String s,@JsonKey(name: "level_name") String levelName,@JsonKey(name: "level") int level,@JsonKey(name: "nextLevelExp") int nextLevelExp,@JsonKey(name: "exp") String exp,@JsonKey(name: "expPercent") double expPercent,@JsonKey(name: "badges") List<dynamic> badges,@JsonKey(name: "album_favorites_max") int albumFavoritesMax,@JsonKey(name: "ad_free") bool adFree,@JsonKey(name: "ad_free_before") String adFreeBefore,@JsonKey(name: "charge") String charge,@JsonKey(name: "jar") String jar,@JsonKey(name: "invitation_qrcode") String invitationQrcode,@JsonKey(name: "invitation_url") String invitationUrl,@JsonKey(name: "invited_cnt") String invitedCnt
});




}
/// @nodoc
class _$JmUserInfoJsonCopyWithImpl<$Res>
    implements $JmUserInfoJsonCopyWith<$Res> {
  _$JmUserInfoJsonCopyWithImpl(this._self, this._then);

  final JmUserInfoJson _self;
  final $Res Function(JmUserInfoJson) _then;

/// Create a copy of JmUserInfoJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? username = null,Object? email = null,Object? emailverified = null,Object? photo = null,Object? fname = null,Object? gender = null,Object? message = freezed,Object? coin = null,Object? ipcountry = null,Object? albumFavorites = null,Object? s = null,Object? levelName = null,Object? level = null,Object? nextLevelExp = null,Object? exp = null,Object? expPercent = null,Object? badges = null,Object? albumFavoritesMax = null,Object? adFree = null,Object? adFreeBefore = null,Object? charge = null,Object? jar = null,Object? invitationQrcode = null,Object? invitationUrl = null,Object? invitedCnt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailverified: null == emailverified ? _self.emailverified : emailverified // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,fname: null == fname ? _self.fname : fname // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as dynamic,coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as int,ipcountry: null == ipcountry ? _self.ipcountry : ipcountry // ignore: cast_nullable_to_non_nullable
as String,albumFavorites: null == albumFavorites ? _self.albumFavorites : albumFavorites // ignore: cast_nullable_to_non_nullable
as int,s: null == s ? _self.s : s // ignore: cast_nullable_to_non_nullable
as String,levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,nextLevelExp: null == nextLevelExp ? _self.nextLevelExp : nextLevelExp // ignore: cast_nullable_to_non_nullable
as int,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as String,expPercent: null == expPercent ? _self.expPercent : expPercent // ignore: cast_nullable_to_non_nullable
as double,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<dynamic>,albumFavoritesMax: null == albumFavoritesMax ? _self.albumFavoritesMax : albumFavoritesMax // ignore: cast_nullable_to_non_nullable
as int,adFree: null == adFree ? _self.adFree : adFree // ignore: cast_nullable_to_non_nullable
as bool,adFreeBefore: null == adFreeBefore ? _self.adFreeBefore : adFreeBefore // ignore: cast_nullable_to_non_nullable
as String,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as String,jar: null == jar ? _self.jar : jar // ignore: cast_nullable_to_non_nullable
as String,invitationQrcode: null == invitationQrcode ? _self.invitationQrcode : invitationQrcode // ignore: cast_nullable_to_non_nullable
as String,invitationUrl: null == invitationUrl ? _self.invitationUrl : invitationUrl // ignore: cast_nullable_to_non_nullable
as String,invitedCnt: null == invitedCnt ? _self.invitedCnt : invitedCnt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _JmUserInfoJson implements JmUserInfoJson {
  const _JmUserInfoJson({@JsonKey(name: "uid") required this.uid, @JsonKey(name: "username") required this.username, @JsonKey(name: "email") required this.email, @JsonKey(name: "emailverified") required this.emailverified, @JsonKey(name: "photo") required this.photo, @JsonKey(name: "fname") required this.fname, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "message") required this.message, @JsonKey(name: "coin") required this.coin, @JsonKey(name: "ipcountry") required this.ipcountry, @JsonKey(name: "album_favorites") required this.albumFavorites, @JsonKey(name: "s") required this.s, @JsonKey(name: "level_name") required this.levelName, @JsonKey(name: "level") required this.level, @JsonKey(name: "nextLevelExp") required this.nextLevelExp, @JsonKey(name: "exp") required this.exp, @JsonKey(name: "expPercent") required this.expPercent, @JsonKey(name: "badges") required final  List<dynamic> badges, @JsonKey(name: "album_favorites_max") required this.albumFavoritesMax, @JsonKey(name: "ad_free") required this.adFree, @JsonKey(name: "ad_free_before") required this.adFreeBefore, @JsonKey(name: "charge") required this.charge, @JsonKey(name: "jar") required this.jar, @JsonKey(name: "invitation_qrcode") required this.invitationQrcode, @JsonKey(name: "invitation_url") required this.invitationUrl, @JsonKey(name: "invited_cnt") required this.invitedCnt}): _badges = badges;
  factory _JmUserInfoJson.fromJson(Map<String, dynamic> json) => _$JmUserInfoJsonFromJson(json);

@override@JsonKey(name: "uid") final  String uid;
@override@JsonKey(name: "username") final  String username;
@override@JsonKey(name: "email") final  String email;
@override@JsonKey(name: "emailverified") final  String emailverified;
@override@JsonKey(name: "photo") final  String photo;
@override@JsonKey(name: "fname") final  String fname;
@override@JsonKey(name: "gender") final  String gender;
@override@JsonKey(name: "message") final  dynamic message;
@override@JsonKey(name: "coin") final  int coin;
@override@JsonKey(name: "ipcountry") final  String ipcountry;
@override@JsonKey(name: "album_favorites") final  int albumFavorites;
@override@JsonKey(name: "s") final  String s;
@override@JsonKey(name: "level_name") final  String levelName;
@override@JsonKey(name: "level") final  int level;
@override@JsonKey(name: "nextLevelExp") final  int nextLevelExp;
@override@JsonKey(name: "exp") final  String exp;
@override@JsonKey(name: "expPercent") final  double expPercent;
 final  List<dynamic> _badges;
@override@JsonKey(name: "badges") List<dynamic> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

@override@JsonKey(name: "album_favorites_max") final  int albumFavoritesMax;
@override@JsonKey(name: "ad_free") final  bool adFree;
@override@JsonKey(name: "ad_free_before") final  String adFreeBefore;
@override@JsonKey(name: "charge") final  String charge;
@override@JsonKey(name: "jar") final  String jar;
@override@JsonKey(name: "invitation_qrcode") final  String invitationQrcode;
@override@JsonKey(name: "invitation_url") final  String invitationUrl;
@override@JsonKey(name: "invited_cnt") final  String invitedCnt;

/// Create a copy of JmUserInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmUserInfoJsonCopyWith<_JmUserInfoJson> get copyWith => __$JmUserInfoJsonCopyWithImpl<_JmUserInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmUserInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmUserInfoJson&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailverified, emailverified) || other.emailverified == emailverified)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.fname, fname) || other.fname == fname)&&(identical(other.gender, gender) || other.gender == gender)&&const DeepCollectionEquality().equals(other.message, message)&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.ipcountry, ipcountry) || other.ipcountry == ipcountry)&&(identical(other.albumFavorites, albumFavorites) || other.albumFavorites == albumFavorites)&&(identical(other.s, s) || other.s == s)&&(identical(other.levelName, levelName) || other.levelName == levelName)&&(identical(other.level, level) || other.level == level)&&(identical(other.nextLevelExp, nextLevelExp) || other.nextLevelExp == nextLevelExp)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.expPercent, expPercent) || other.expPercent == expPercent)&&const DeepCollectionEquality().equals(other._badges, _badges)&&(identical(other.albumFavoritesMax, albumFavoritesMax) || other.albumFavoritesMax == albumFavoritesMax)&&(identical(other.adFree, adFree) || other.adFree == adFree)&&(identical(other.adFreeBefore, adFreeBefore) || other.adFreeBefore == adFreeBefore)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.jar, jar) || other.jar == jar)&&(identical(other.invitationQrcode, invitationQrcode) || other.invitationQrcode == invitationQrcode)&&(identical(other.invitationUrl, invitationUrl) || other.invitationUrl == invitationUrl)&&(identical(other.invitedCnt, invitedCnt) || other.invitedCnt == invitedCnt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,username,email,emailverified,photo,fname,gender,const DeepCollectionEquality().hash(message),coin,ipcountry,albumFavorites,s,levelName,level,nextLevelExp,exp,expPercent,const DeepCollectionEquality().hash(_badges),albumFavoritesMax,adFree,adFreeBefore,charge,jar,invitationQrcode,invitationUrl,invitedCnt]);

@override
String toString() {
  return 'JmUserInfoJson(uid: $uid, username: $username, email: $email, emailverified: $emailverified, photo: $photo, fname: $fname, gender: $gender, message: $message, coin: $coin, ipcountry: $ipcountry, albumFavorites: $albumFavorites, s: $s, levelName: $levelName, level: $level, nextLevelExp: $nextLevelExp, exp: $exp, expPercent: $expPercent, badges: $badges, albumFavoritesMax: $albumFavoritesMax, adFree: $adFree, adFreeBefore: $adFreeBefore, charge: $charge, jar: $jar, invitationQrcode: $invitationQrcode, invitationUrl: $invitationUrl, invitedCnt: $invitedCnt)';
}


}

/// @nodoc
abstract mixin class _$JmUserInfoJsonCopyWith<$Res> implements $JmUserInfoJsonCopyWith<$Res> {
  factory _$JmUserInfoJsonCopyWith(_JmUserInfoJson value, $Res Function(_JmUserInfoJson) _then) = __$JmUserInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "uid") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "email") String email,@JsonKey(name: "emailverified") String emailverified,@JsonKey(name: "photo") String photo,@JsonKey(name: "fname") String fname,@JsonKey(name: "gender") String gender,@JsonKey(name: "message") dynamic message,@JsonKey(name: "coin") int coin,@JsonKey(name: "ipcountry") String ipcountry,@JsonKey(name: "album_favorites") int albumFavorites,@JsonKey(name: "s") String s,@JsonKey(name: "level_name") String levelName,@JsonKey(name: "level") int level,@JsonKey(name: "nextLevelExp") int nextLevelExp,@JsonKey(name: "exp") String exp,@JsonKey(name: "expPercent") double expPercent,@JsonKey(name: "badges") List<dynamic> badges,@JsonKey(name: "album_favorites_max") int albumFavoritesMax,@JsonKey(name: "ad_free") bool adFree,@JsonKey(name: "ad_free_before") String adFreeBefore,@JsonKey(name: "charge") String charge,@JsonKey(name: "jar") String jar,@JsonKey(name: "invitation_qrcode") String invitationQrcode,@JsonKey(name: "invitation_url") String invitationUrl,@JsonKey(name: "invited_cnt") String invitedCnt
});




}
/// @nodoc
class __$JmUserInfoJsonCopyWithImpl<$Res>
    implements _$JmUserInfoJsonCopyWith<$Res> {
  __$JmUserInfoJsonCopyWithImpl(this._self, this._then);

  final _JmUserInfoJson _self;
  final $Res Function(_JmUserInfoJson) _then;

/// Create a copy of JmUserInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? username = null,Object? email = null,Object? emailverified = null,Object? photo = null,Object? fname = null,Object? gender = null,Object? message = freezed,Object? coin = null,Object? ipcountry = null,Object? albumFavorites = null,Object? s = null,Object? levelName = null,Object? level = null,Object? nextLevelExp = null,Object? exp = null,Object? expPercent = null,Object? badges = null,Object? albumFavoritesMax = null,Object? adFree = null,Object? adFreeBefore = null,Object? charge = null,Object? jar = null,Object? invitationQrcode = null,Object? invitationUrl = null,Object? invitedCnt = null,}) {
  return _then(_JmUserInfoJson(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailverified: null == emailverified ? _self.emailverified : emailverified // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,fname: null == fname ? _self.fname : fname // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as dynamic,coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as int,ipcountry: null == ipcountry ? _self.ipcountry : ipcountry // ignore: cast_nullable_to_non_nullable
as String,albumFavorites: null == albumFavorites ? _self.albumFavorites : albumFavorites // ignore: cast_nullable_to_non_nullable
as int,s: null == s ? _self.s : s // ignore: cast_nullable_to_non_nullable
as String,levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,nextLevelExp: null == nextLevelExp ? _self.nextLevelExp : nextLevelExp // ignore: cast_nullable_to_non_nullable
as int,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as String,expPercent: null == expPercent ? _self.expPercent : expPercent // ignore: cast_nullable_to_non_nullable
as double,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<dynamic>,albumFavoritesMax: null == albumFavoritesMax ? _self.albumFavoritesMax : albumFavoritesMax // ignore: cast_nullable_to_non_nullable
as int,adFree: null == adFree ? _self.adFree : adFree // ignore: cast_nullable_to_non_nullable
as bool,adFreeBefore: null == adFreeBefore ? _self.adFreeBefore : adFreeBefore // ignore: cast_nullable_to_non_nullable
as String,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as String,jar: null == jar ? _self.jar : jar // ignore: cast_nullable_to_non_nullable
as String,invitationQrcode: null == invitationQrcode ? _self.invitationQrcode : invitationQrcode // ignore: cast_nullable_to_non_nullable
as String,invitationUrl: null == invitationUrl ? _self.invitationUrl : invitationUrl // ignore: cast_nullable_to_non_nullable
as String,invitedCnt: null == invitedCnt ? _self.invitedCnt : invitedCnt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
