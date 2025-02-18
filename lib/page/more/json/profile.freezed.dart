// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;

  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;

  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;

  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _value.copyWith(
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as int,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
            data:
                null == data
                    ? _value.data
                    : data // ignore: cast_nullable_to_non_nullable
                        as Data,
          )
          as $Val,
    );
  }

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataCopyWith<$Res> get data {
    return $DataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
    _$ProfileImpl value,
    $Res Function(_$ProfileImpl) then,
  ) = __$$ProfileImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  @override
  $DataCopyWith<$Res> get data;
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
    _$ProfileImpl _value,
    $Res Function(_$ProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _$ProfileImpl(
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as int,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        data:
            null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                    as Data,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl implements _Profile {
  const _$ProfileImpl({
    @JsonKey(name: "code") required this.code,
    @JsonKey(name: "message") required this.message,
    @JsonKey(name: "data") required this.data,
  });

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  @JsonKey(name: "code")
  final int code;
  @override
  @JsonKey(name: "message")
  final String message;
  @override
  @JsonKey(name: "data")
  final Data data;

  @override
  String toString() {
    return 'Profile(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(this);
  }
}

abstract class _Profile implements Profile {
  const factory _Profile({
    @JsonKey(name: "code") required final int code,
    @JsonKey(name: "message") required final String message,
    @JsonKey(name: "data") required final Data data,
  }) = _$ProfileImpl;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;

  @override
  @JsonKey(name: "message")
  String get message;

  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "user")
  User get user => throw _privateConstructorUsedError;

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataCopyWith<Data> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataCopyWith<$Res> {
  factory $DataCopyWith(Data value, $Res Function(Data) then) =
      _$DataCopyWithImpl<$Res, Data>;

  @useResult
  $Res call({@JsonKey(name: "user") User user});

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$DataCopyWithImpl<$Res, $Val extends Data>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? user = null}) {
    return _then(
      _value.copyWith(
            user:
                null == user
                    ? _value.user
                    : user // ignore: cast_nullable_to_non_nullable
                        as User,
          )
          as $Val,
    );
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$$DataImplCopyWith(
    _$DataImpl value,
    $Res Function(_$DataImpl) then,
  ) = __$$DataImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({@JsonKey(name: "user") User user});

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$DataImplCopyWithImpl<$Res>
    extends _$DataCopyWithImpl<$Res, _$DataImpl>
    implements _$$DataImplCopyWith<$Res> {
  __$$DataImplCopyWithImpl(_$DataImpl _value, $Res Function(_$DataImpl) _then)
    : super(_value, _then);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? user = null}) {
    return _then(
      _$DataImpl(
        user:
            null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                    as User,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "user") required this.user});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "user")
  final User user;

  @override
  String toString() {
    return 'Data(user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, user);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataImplToJson(this);
  }
}

abstract class _Data implements Data {
  const factory _Data({@JsonKey(name: "user") required final User user}) =
      _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "user")
  User get user;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "birthday")
  DateTime get birthday => throw _privateConstructorUsedError;

  @JsonKey(name: "email")
  String get email => throw _privateConstructorUsedError;

  @JsonKey(name: "gender")
  String get gender => throw _privateConstructorUsedError;

  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;

  @JsonKey(name: "slogan")
  String get slogan => throw _privateConstructorUsedError;

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

  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;

  @JsonKey(name: "avatar")
  Avatar get avatar => throw _privateConstructorUsedError;

  @JsonKey(name: "isPunched")
  bool get isPunched => throw _privateConstructorUsedError;

  @JsonKey(name: "character")
  String get character => throw _privateConstructorUsedError;

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
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "birthday") DateTime birthday,
    @JsonKey(name: "email") String email,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "slogan") String slogan,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<String> characters,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "avatar") Avatar avatar,
    @JsonKey(name: "isPunched") bool isPunched,
    @JsonKey(name: "character") String character,
  });

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
    Object? birthday = null,
    Object? email = null,
    Object? gender = null,
    Object? name = null,
    Object? slogan = null,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? createdAt = null,
    Object? avatar = null,
    Object? isPunched = null,
    Object? character = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            birthday:
                null == birthday
                    ? _value.birthday
                    : birthday // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            email:
                null == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String,
            gender:
                null == gender
                    ? _value.gender
                    : gender // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            slogan:
                null == slogan
                    ? _value.slogan
                    : slogan // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            verified:
                null == verified
                    ? _value.verified
                    : verified // ignore: cast_nullable_to_non_nullable
                        as bool,
            exp:
                null == exp
                    ? _value.exp
                    : exp // ignore: cast_nullable_to_non_nullable
                        as int,
            level:
                null == level
                    ? _value.level
                    : level // ignore: cast_nullable_to_non_nullable
                        as int,
            characters:
                null == characters
                    ? _value.characters
                    : characters // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            avatar:
                null == avatar
                    ? _value.avatar
                    : avatar // ignore: cast_nullable_to_non_nullable
                        as Avatar,
            isPunched:
                null == isPunched
                    ? _value.isPunched
                    : isPunched // ignore: cast_nullable_to_non_nullable
                        as bool,
            character:
                null == character
                    ? _value.character
                    : character // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
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
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "birthday") DateTime birthday,
    @JsonKey(name: "email") String email,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "slogan") String slogan,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<String> characters,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "avatar") Avatar avatar,
    @JsonKey(name: "isPunched") bool isPunched,
    @JsonKey(name: "character") String character,
  });

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
    Object? birthday = null,
    Object? email = null,
    Object? gender = null,
    Object? name = null,
    Object? slogan = null,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? createdAt = null,
    Object? avatar = null,
    Object? isPunched = null,
    Object? character = null,
  }) {
    return _then(
      _$UserImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        birthday:
            null == birthday
                ? _value.birthday
                : birthday // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        email:
            null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String,
        gender:
            null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        slogan:
            null == slogan
                ? _value.slogan
                : slogan // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        verified:
            null == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                    as bool,
        exp:
            null == exp
                ? _value.exp
                : exp // ignore: cast_nullable_to_non_nullable
                    as int,
        level:
            null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                    as int,
        characters:
            null == characters
                ? _value._characters
                : characters // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        avatar:
            null == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                    as Avatar,
        isPunched:
            null == isPunched
                ? _value.isPunched
                : isPunched // ignore: cast_nullable_to_non_nullable
                    as bool,
        character:
            null == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl({
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "birthday") required this.birthday,
    @JsonKey(name: "email") required this.email,
    @JsonKey(name: "gender") required this.gender,
    @JsonKey(name: "name") required this.name,
    @JsonKey(name: "slogan") required this.slogan,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "verified") required this.verified,
    @JsonKey(name: "exp") required this.exp,
    @JsonKey(name: "level") required this.level,
    @JsonKey(name: "characters") required final List<String> characters,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "avatar") required this.avatar,
    @JsonKey(name: "isPunched") required this.isPunched,
    @JsonKey(name: "character") required this.character,
  }) : _characters = characters;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "birthday")
  final DateTime birthday;
  @override
  @JsonKey(name: "email")
  final String email;
  @override
  @JsonKey(name: "gender")
  final String gender;
  @override
  @JsonKey(name: "name")
  final String name;
  @override
  @JsonKey(name: "slogan")
  final String slogan;
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
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "avatar")
  final Avatar avatar;
  @override
  @JsonKey(name: "isPunched")
  final bool isPunched;
  @override
  @JsonKey(name: "character")
  final String character;

  @override
  String toString() {
    return 'User(id: $id, birthday: $birthday, email: $email, gender: $gender, name: $name, slogan: $slogan, title: $title, verified: $verified, exp: $exp, level: $level, characters: $characters, createdAt: $createdAt, avatar: $avatar, isPunched: $isPunched, character: $character)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.birthday, birthday) ||
                other.birthday == birthday) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slogan, slogan) || other.slogan == slogan) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.exp, exp) || other.exp == exp) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(
              other._characters,
              _characters,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.isPunched, isPunched) ||
                other.isPunched == isPunched) &&
            (identical(other.character, character) ||
                other.character == character));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    birthday,
    email,
    gender,
    name,
    slogan,
    title,
    verified,
    exp,
    level,
    const DeepCollectionEquality().hash(_characters),
    createdAt,
    avatar,
    isPunched,
    character,
  );

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "birthday") required final DateTime birthday,
    @JsonKey(name: "email") required final String email,
    @JsonKey(name: "gender") required final String gender,
    @JsonKey(name: "name") required final String name,
    @JsonKey(name: "slogan") required final String slogan,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "verified") required final bool verified,
    @JsonKey(name: "exp") required final int exp,
    @JsonKey(name: "level") required final int level,
    @JsonKey(name: "characters") required final List<String> characters,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "avatar") required final Avatar avatar,
    @JsonKey(name: "isPunched") required final bool isPunched,
    @JsonKey(name: "character") required final String character,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "birthday")
  DateTime get birthday;

  @override
  @JsonKey(name: "email")
  String get email;

  @override
  @JsonKey(name: "gender")
  String get gender;

  @override
  @JsonKey(name: "name")
  String get name;

  @override
  @JsonKey(name: "slogan")
  String get slogan;

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
  @JsonKey(name: "created_at")
  DateTime get createdAt;

  @override
  @JsonKey(name: "avatar")
  Avatar get avatar;

  @override
  @JsonKey(name: "isPunched")
  bool get isPunched;

  @override
  @JsonKey(name: "character")
  String get character;

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
  String get originalName => throw _privateConstructorUsedError;

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
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
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
    return _then(
      _value.copyWith(
            originalName:
                null == originalName
                    ? _value.originalName
                    : originalName // ignore: cast_nullable_to_non_nullable
                        as String,
            path:
                null == path
                    ? _value.path
                    : path // ignore: cast_nullable_to_non_nullable
                        as String,
            fileServer:
                null == fileServer
                    ? _value.fileServer
                    : fileServer // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AvatarImplCopyWith<$Res> implements $AvatarCopyWith<$Res> {
  factory _$$AvatarImplCopyWith(
    _$AvatarImpl value,
    $Res Function(_$AvatarImpl) then,
  ) = __$$AvatarImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
}

/// @nodoc
class __$$AvatarImplCopyWithImpl<$Res>
    extends _$AvatarCopyWithImpl<$Res, _$AvatarImpl>
    implements _$$AvatarImplCopyWith<$Res> {
  __$$AvatarImplCopyWithImpl(
    _$AvatarImpl _value,
    $Res Function(_$AvatarImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(
      _$AvatarImpl(
        originalName:
            null == originalName
                ? _value.originalName
                : originalName // ignore: cast_nullable_to_non_nullable
                    as String,
        path:
            null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                    as String,
        fileServer:
            null == fileServer
                ? _value.fileServer
                : fileServer // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AvatarImpl implements _Avatar {
  const _$AvatarImpl({
    @JsonKey(name: "originalName") required this.originalName,
    @JsonKey(name: "path") required this.path,
    @JsonKey(name: "fileServer") required this.fileServer,
  });

  factory _$AvatarImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvatarImplFromJson(json);

  @override
  @JsonKey(name: "originalName")
  final String originalName;
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
    return _$$AvatarImplToJson(this);
  }
}

abstract class _Avatar implements Avatar {
  const factory _Avatar({
    @JsonKey(name: "originalName") required final String originalName,
    @JsonKey(name: "path") required final String path,
    @JsonKey(name: "fileServer") required final String fileServer,
  }) = _$AvatarImpl;

  factory _Avatar.fromJson(Map<String, dynamic> json) = _$AvatarImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

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
