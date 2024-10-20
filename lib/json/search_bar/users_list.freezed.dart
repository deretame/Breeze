// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'users_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UsersList _$UsersListFromJson(Map<String, dynamic> json) {
  return _UsersList.fromJson(json);
}

/// @nodoc
mixin _$UsersList {
  @JsonKey(name: "users")
  List<User> get users => throw _privateConstructorUsedError;

  /// Serializes this UsersList to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UsersList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UsersListCopyWith<UsersList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UsersListCopyWith<$Res> {
  factory $UsersListCopyWith(UsersList value, $Res Function(UsersList) then) =
      _$UsersListCopyWithImpl<$Res, UsersList>;
  @useResult
  $Res call({@JsonKey(name: "users") List<User> users});
}

/// @nodoc
class _$UsersListCopyWithImpl<$Res, $Val extends UsersList>
    implements $UsersListCopyWith<$Res> {
  _$UsersListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UsersList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
  }) {
    return _then(_value.copyWith(
      users: null == users
          ? _value.users
          : users // ignore: cast_nullable_to_non_nullable
              as List<User>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UsersListImplCopyWith<$Res>
    implements $UsersListCopyWith<$Res> {
  factory _$$UsersListImplCopyWith(
          _$UsersListImpl value, $Res Function(_$UsersListImpl) then) =
      __$$UsersListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: "users") List<User> users});
}

/// @nodoc
class __$$UsersListImplCopyWithImpl<$Res>
    extends _$UsersListCopyWithImpl<$Res, _$UsersListImpl>
    implements _$$UsersListImplCopyWith<$Res> {
  __$$UsersListImplCopyWithImpl(
      _$UsersListImpl _value, $Res Function(_$UsersListImpl) _then)
      : super(_value, _then);

  /// Create a copy of UsersList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
  }) {
    return _then(_$UsersListImpl(
      users: null == users
          ? _value._users
          : users // ignore: cast_nullable_to_non_nullable
              as List<User>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UsersListImpl implements _UsersList {
  const _$UsersListImpl(
      {@JsonKey(name: "users") required final List<User> users})
      : _users = users;

  factory _$UsersListImpl.fromJson(Map<String, dynamic> json) =>
      _$$UsersListImplFromJson(json);

  final List<User> _users;
  @override
  @JsonKey(name: "users")
  List<User> get users {
    if (_users is EqualUnmodifiableListView) return _users;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_users);
  }

  @override
  String toString() {
    return 'UsersList(users: $users)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UsersListImpl &&
            const DeepCollectionEquality().equals(other._users, _users));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_users));

  /// Create a copy of UsersList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UsersListImplCopyWith<_$UsersListImpl> get copyWith =>
      __$$UsersListImplCopyWithImpl<_$UsersListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UsersListImplToJson(
      this,
    );
  }
}

abstract class _UsersList implements UsersList {
  const factory _UsersList(
          {@JsonKey(name: "users") required final List<User> users}) =
      _$UsersListImpl;

  factory _UsersList.fromJson(Map<String, dynamic> json) =
      _$UsersListImpl.fromJson;

  @override
  @JsonKey(name: "users")
  List<User> get users;

  /// Create a copy of UsersList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UsersListImplCopyWith<_$UsersListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: "gender")
  Gender get gender => throw _privateConstructorUsedError;
  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: "slogan")
  String? get slogan => throw _privateConstructorUsedError;
  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: "verified")
  bool get verified => throw _privateConstructorUsedError;
  @JsonKey(name: "exp")
  int get exp => throw _privateConstructorUsedError;
  @JsonKey(name: "level")
  int get level => throw _privateConstructorUsedError;
  @JsonKey(name: "characters")
  List<String> get characters => throw _privateConstructorUsedError;
  @JsonKey(name: "role")
  Role get role => throw _privateConstructorUsedError;
  @JsonKey(name: "avatar")
  Avatar get avatar => throw _privateConstructorUsedError;
  @JsonKey(name: "comicsUploaded")
  int get comicsUploaded => throw _privateConstructorUsedError;
  @JsonKey(name: "character")
  String? get character => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "gender") Gender gender,
      @JsonKey(name: "name") String name,
      @JsonKey(name: "slogan") String? slogan,
      @JsonKey(name: "title") String title,
      @JsonKey(name: "verified") bool verified,
      @JsonKey(name: "exp") int exp,
      @JsonKey(name: "level") int level,
      @JsonKey(name: "characters") List<String> characters,
      @JsonKey(name: "role") Role role,
      @JsonKey(name: "avatar") Avatar avatar,
      @JsonKey(name: "comicsUploaded") int comicsUploaded,
      @JsonKey(name: "character") String? character});

  $AvatarCopyWith<$Res> get avatar;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? slogan = freezed,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? avatar = null,
    Object? comicsUploaded = null,
    Object? character = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slogan: freezed == slogan
          ? _value.slogan
          : slogan // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      verified: null == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      exp: null == exp
          ? _value.exp
          : exp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as Role,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as Avatar,
      comicsUploaded: null == comicsUploaded
          ? _value.comicsUploaded
          : comicsUploaded // ignore: cast_nullable_to_non_nullable
              as int,
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AvatarCopyWith<$Res> get avatar {
    return $AvatarCopyWith<$Res>(_value.avatar, (value) {
      return _then(_value.copyWith(avatar: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "gender") Gender gender,
      @JsonKey(name: "name") String name,
      @JsonKey(name: "slogan") String? slogan,
      @JsonKey(name: "title") String title,
      @JsonKey(name: "verified") bool verified,
      @JsonKey(name: "exp") int exp,
      @JsonKey(name: "level") int level,
      @JsonKey(name: "characters") List<String> characters,
      @JsonKey(name: "role") Role role,
      @JsonKey(name: "avatar") Avatar avatar,
      @JsonKey(name: "comicsUploaded") int comicsUploaded,
      @JsonKey(name: "character") String? character});

  @override
  $AvatarCopyWith<$Res> get avatar;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? slogan = freezed,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? avatar = null,
    Object? comicsUploaded = null,
    Object? character = freezed,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slogan: freezed == slogan
          ? _value.slogan
          : slogan // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      verified: null == verified
          ? _value.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      exp: null == exp
          ? _value.exp
          : exp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as Role,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as Avatar,
      comicsUploaded: null == comicsUploaded
          ? _value.comicsUploaded
          : comicsUploaded // ignore: cast_nullable_to_non_nullable
              as int,
      character: freezed == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {@JsonKey(name: "_id") required this.id,
      @JsonKey(name: "gender") required this.gender,
      @JsonKey(name: "name") required this.name,
      @JsonKey(name: "slogan") this.slogan,
      @JsonKey(name: "title") required this.title,
      @JsonKey(name: "verified") required this.verified,
      @JsonKey(name: "exp") required this.exp,
      @JsonKey(name: "level") required this.level,
      @JsonKey(name: "characters") required final List<String> characters,
      @JsonKey(name: "role") required this.role,
      @JsonKey(name: "avatar") required this.avatar,
      @JsonKey(name: "comicsUploaded") required this.comicsUploaded,
      @JsonKey(name: "character") this.character})
      : _characters = characters;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "gender")
  final Gender gender;
  @override
  @JsonKey(name: "name")
  final String name;
  @override
  @JsonKey(name: "slogan")
  final String? slogan;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "verified")
  final bool verified;
  @override
  @JsonKey(name: "exp")
  final int exp;
  @override
  @JsonKey(name: "level")
  final int level;
  final List<String> _characters;
  @override
  @JsonKey(name: "characters")
  List<String> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  @override
  @JsonKey(name: "role")
  final Role role;
  @override
  @JsonKey(name: "avatar")
  final Avatar avatar;
  @override
  @JsonKey(name: "comicsUploaded")
  final int comicsUploaded;
  @override
  @JsonKey(name: "character")
  final String? character;

  @override
  String toString() {
    return 'User(id: $id, gender: $gender, name: $name, slogan: $slogan, title: $title, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, comicsUploaded: $comicsUploaded, character: $character)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slogan, slogan) || other.slogan == slogan) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.exp, exp) || other.exp == exp) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.comicsUploaded, comicsUploaded) ||
                other.comicsUploaded == comicsUploaded) &&
            (identical(other.character, character) ||
                other.character == character));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      gender,
      name,
      slogan,
      title,
      verified,
      exp,
      level,
      const DeepCollectionEquality().hash(_characters),
      role,
      avatar,
      comicsUploaded,
      character);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {@JsonKey(name: "_id") required final String id,
      @JsonKey(name: "gender") required final Gender gender,
      @JsonKey(name: "name") required final String name,
      @JsonKey(name: "slogan") final String? slogan,
      @JsonKey(name: "title") required final String title,
      @JsonKey(name: "verified") required final bool verified,
      @JsonKey(name: "exp") required final int exp,
      @JsonKey(name: "level") required final int level,
      @JsonKey(name: "characters") required final List<String> characters,
      @JsonKey(name: "role") required final Role role,
      @JsonKey(name: "avatar") required final Avatar avatar,
      @JsonKey(name: "comicsUploaded") required final int comicsUploaded,
      @JsonKey(name: "character") final String? character}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;
  @override
  @JsonKey(name: "gender")
  Gender get gender;
  @override
  @JsonKey(name: "name")
  String get name;
  @override
  @JsonKey(name: "slogan")
  String? get slogan;
  @override
  @JsonKey(name: "title")
  String get title;
  @override
  @JsonKey(name: "verified")
  bool get verified;
  @override
  @JsonKey(name: "exp")
  int get exp;
  @override
  @JsonKey(name: "level")
  int get level;
  @override
  @JsonKey(name: "characters")
  List<String> get characters;
  @override
  @JsonKey(name: "role")
  Role get role;
  @override
  @JsonKey(name: "avatar")
  Avatar get avatar;
  @override
  @JsonKey(name: "comicsUploaded")
  int get comicsUploaded;
  @override
  @JsonKey(name: "character")
  String? get character;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Avatar _$AvatarFromJson(Map<String, dynamic> json) {
  return _Avatar.fromJson(json);
}

/// @nodoc
mixin _$Avatar {
  @JsonKey(name: "originalName")
  OriginalName get originalName => throw _privateConstructorUsedError;
  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;
  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  /// Serializes this Avatar to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AvatarCopyWith<Avatar> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AvatarCopyWith<$Res> {
  factory $AvatarCopyWith(Avatar value, $Res Function(Avatar) then) =
      _$AvatarCopyWithImpl<$Res, Avatar>;
  @useResult
  $Res call(
      {@JsonKey(name: "originalName") OriginalName originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
}

/// @nodoc
class _$AvatarCopyWithImpl<$Res, $Val extends Avatar>
    implements $AvatarCopyWith<$Res> {
  _$AvatarCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_value.copyWith(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as OriginalName,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AvatarImplCopyWith<$Res> implements $AvatarCopyWith<$Res> {
  factory _$$AvatarImplCopyWith(
          _$AvatarImpl value, $Res Function(_$AvatarImpl) then) =
      __$$AvatarImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: "originalName") OriginalName originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
}

/// @nodoc
class __$$AvatarImplCopyWithImpl<$Res>
    extends _$AvatarCopyWithImpl<$Res, _$AvatarImpl>
    implements _$$AvatarImplCopyWith<$Res> {
  __$$AvatarImplCopyWithImpl(
      _$AvatarImpl _value, $Res Function(_$AvatarImpl) _then)
      : super(_value, _then);

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_$AvatarImpl(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as OriginalName,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AvatarImpl implements _Avatar {
  const _$AvatarImpl(
      {@JsonKey(name: "originalName") required this.originalName,
      @JsonKey(name: "path") required this.path,
      @JsonKey(name: "fileServer") required this.fileServer});

  factory _$AvatarImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvatarImplFromJson(json);

  @override
  @JsonKey(name: "originalName")
  final OriginalName originalName;
  @override
  @JsonKey(name: "path")
  final String path;
  @override
  @JsonKey(name: "fileServer")
  final String fileServer;

  @override
  String toString() {
    return 'Avatar(originalName: $originalName, path: $path, fileServer: $fileServer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AvatarImpl &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalName, path, fileServer);

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AvatarImplCopyWith<_$AvatarImpl> get copyWith =>
      __$$AvatarImplCopyWithImpl<_$AvatarImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AvatarImplToJson(
      this,
    );
  }
}

abstract class _Avatar implements Avatar {
  const factory _Avatar(
      {@JsonKey(name: "originalName") required final OriginalName originalName,
      @JsonKey(name: "path") required final String path,
      @JsonKey(name: "fileServer")
      required final String fileServer}) = _$AvatarImpl;

  factory _Avatar.fromJson(Map<String, dynamic> json) = _$AvatarImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  OriginalName get originalName;
  @override
  @JsonKey(name: "path")
  String get path;
  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AvatarImplCopyWith<_$AvatarImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
