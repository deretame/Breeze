// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Leaderboard _$LeaderboardFromJson(Map<String, dynamic> json) {
  return _Leaderboard.fromJson(json);
}

/// @nodoc
mixin _$Leaderboard {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;

  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;

  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this Leaderboard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Leaderboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaderboardCopyWith<Leaderboard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardCopyWith<$Res> {
  factory $LeaderboardCopyWith(
          Leaderboard value, $Res Function(Leaderboard) then) =
      _$LeaderboardCopyWithImpl<$Res, Leaderboard>;

  @useResult
  $Res call(
      {@JsonKey(name: "code") int code,
      @JsonKey(name: "message") String message,
      @JsonKey(name: "data") Data data});

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$LeaderboardCopyWithImpl<$Res, $Val extends Leaderboard>
    implements $LeaderboardCopyWith<$Res> {
  _$LeaderboardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Leaderboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
    ) as $Val);
  }

  /// Create a copy of Leaderboard
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
abstract class _$$LeaderboardImplCopyWith<$Res>
    implements $LeaderboardCopyWith<$Res> {
  factory _$$LeaderboardImplCopyWith(
          _$LeaderboardImpl value, $Res Function(_$LeaderboardImpl) then) =
      __$$LeaderboardImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "code") int code,
      @JsonKey(name: "message") String message,
      @JsonKey(name: "data") Data data});

  @override
  $DataCopyWith<$Res> get data;
}

/// @nodoc
class __$$LeaderboardImplCopyWithImpl<$Res>
    extends _$LeaderboardCopyWithImpl<$Res, _$LeaderboardImpl>
    implements _$$LeaderboardImplCopyWith<$Res> {
  __$$LeaderboardImplCopyWithImpl(
      _$LeaderboardImpl _value, $Res Function(_$LeaderboardImpl) _then)
      : super(_value, _then);

  /// Create a copy of Leaderboard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(_$LeaderboardImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaderboardImpl implements _Leaderboard {
  const _$LeaderboardImpl(
      {@JsonKey(name: "code") required this.code,
      @JsonKey(name: "message") required this.message,
      @JsonKey(name: "data") required this.data});

  factory _$LeaderboardImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaderboardImplFromJson(json);

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
    return 'Leaderboard(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of Leaderboard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardImplCopyWith<_$LeaderboardImpl> get copyWith =>
      __$$LeaderboardImplCopyWithImpl<_$LeaderboardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaderboardImplToJson(
      this,
    );
  }
}

abstract class _Leaderboard implements Leaderboard {
  const factory _Leaderboard(
      {@JsonKey(name: "code") required final int code,
      @JsonKey(name: "message") required final String message,
      @JsonKey(name: "data") required final Data data}) = _$LeaderboardImpl;

  factory _Leaderboard.fromJson(Map<String, dynamic> json) =
      _$LeaderboardImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;

  @override
  @JsonKey(name: "message")
  String get message;

  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of Leaderboard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaderboardImplCopyWith<_$LeaderboardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "comics")
  List<Comic> get comics => throw _privateConstructorUsedError;

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
  $Res call({@JsonKey(name: "comics") List<Comic> comics});
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
  $Res call({
    Object? comics = null,
  }) {
    return _then(_value.copyWith(
      comics: null == comics
          ? _value.comics
          : comics // ignore: cast_nullable_to_non_nullable
              as List<Comic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$$DataImplCopyWith(
          _$DataImpl value, $Res Function(_$DataImpl) then) =
      __$$DataImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({@JsonKey(name: "comics") List<Comic> comics});
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
  $Res call({
    Object? comics = null,
  }) {
    return _then(_$DataImpl(
      comics: null == comics
          ? _value._comics
          : comics // ignore: cast_nullable_to_non_nullable
              as List<Comic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "comics") required final List<Comic> comics})
      : _comics = comics;

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  final List<Comic> _comics;

  @override
  @JsonKey(name: "comics")
  List<Comic> get comics {
    if (_comics is EqualUnmodifiableListView) return _comics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comics);
  }

  @override
  String toString() {
    return 'Data(comics: $comics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            const DeepCollectionEquality().equals(other._comics, _comics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_comics));

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataImplToJson(
      this,
    );
  }
}

abstract class _Data implements Data {
  const factory _Data(
          {@JsonKey(name: "comics") required final List<Comic> comics}) =
      _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "comics")
  List<Comic> get comics;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Comic _$ComicFromJson(Map<String, dynamic> json) {
  return _Comic.fromJson(json);
}

/// @nodoc
mixin _$Comic {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;

  @JsonKey(name: "author")
  String get author => throw _privateConstructorUsedError;

  @JsonKey(name: "totalViews")
  int get totalViews => throw _privateConstructorUsedError;

  @JsonKey(name: "totalLikes")
  int get totalLikes => throw _privateConstructorUsedError;

  @JsonKey(name: "pagesCount")
  int get pagesCount => throw _privateConstructorUsedError;

  @JsonKey(name: "epsCount")
  int get epsCount => throw _privateConstructorUsedError;

  @JsonKey(name: "finished")
  bool get finished => throw _privateConstructorUsedError;

  @JsonKey(name: "categories")
  List<String> get categories => throw _privateConstructorUsedError;

  @JsonKey(name: "thumb")
  Thumb get thumb => throw _privateConstructorUsedError;

  @JsonKey(name: "viewsCount")
  int get viewsCount => throw _privateConstructorUsedError;

  @JsonKey(name: "leaderboardCount")
  int get leaderboardCount => throw _privateConstructorUsedError;

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComicCopyWith<Comic> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComicCopyWith<$Res> {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) then) =
      _$ComicCopyWithImpl<$Res, Comic>;

  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "title") String title,
      @JsonKey(name: "author") String author,
      @JsonKey(name: "totalViews") int totalViews,
      @JsonKey(name: "totalLikes") int totalLikes,
      @JsonKey(name: "pagesCount") int pagesCount,
      @JsonKey(name: "epsCount") int epsCount,
      @JsonKey(name: "finished") bool finished,
      @JsonKey(name: "categories") List<String> categories,
      @JsonKey(name: "thumb") Thumb thumb,
      @JsonKey(name: "viewsCount") int viewsCount,
      @JsonKey(name: "leaderboardCount") int leaderboardCount});

  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class _$ComicCopyWithImpl<$Res, $Val extends Comic>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? categories = null,
    Object? thumb = null,
    Object? viewsCount = null,
    Object? leaderboardCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      totalViews: null == totalViews
          ? _value.totalViews
          : totalViews // ignore: cast_nullable_to_non_nullable
              as int,
      totalLikes: null == totalLikes
          ? _value.totalLikes
          : totalLikes // ignore: cast_nullable_to_non_nullable
              as int,
      pagesCount: null == pagesCount
          ? _value.pagesCount
          : pagesCount // ignore: cast_nullable_to_non_nullable
              as int,
      epsCount: null == epsCount
          ? _value.epsCount
          : epsCount // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as Thumb,
      viewsCount: null == viewsCount
          ? _value.viewsCount
          : viewsCount // ignore: cast_nullable_to_non_nullable
              as int,
      leaderboardCount: null == leaderboardCount
          ? _value.leaderboardCount
          : leaderboardCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbCopyWith<$Res> get thumb {
    return $ThumbCopyWith<$Res>(_value.thumb, (value) {
      return _then(_value.copyWith(thumb: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ComicImplCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$$ComicImplCopyWith(
          _$ComicImpl value, $Res Function(_$ComicImpl) then) =
      __$$ComicImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "title") String title,
      @JsonKey(name: "author") String author,
      @JsonKey(name: "totalViews") int totalViews,
      @JsonKey(name: "totalLikes") int totalLikes,
      @JsonKey(name: "pagesCount") int pagesCount,
      @JsonKey(name: "epsCount") int epsCount,
      @JsonKey(name: "finished") bool finished,
      @JsonKey(name: "categories") List<String> categories,
      @JsonKey(name: "thumb") Thumb thumb,
      @JsonKey(name: "viewsCount") int viewsCount,
      @JsonKey(name: "leaderboardCount") int leaderboardCount});

  @override
  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class __$$ComicImplCopyWithImpl<$Res>
    extends _$ComicCopyWithImpl<$Res, _$ComicImpl>
    implements _$$ComicImplCopyWith<$Res> {
  __$$ComicImplCopyWithImpl(
      _$ComicImpl _value, $Res Function(_$ComicImpl) _then)
      : super(_value, _then);

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? categories = null,
    Object? thumb = null,
    Object? viewsCount = null,
    Object? leaderboardCount = null,
  }) {
    return _then(_$ComicImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      totalViews: null == totalViews
          ? _value.totalViews
          : totalViews // ignore: cast_nullable_to_non_nullable
              as int,
      totalLikes: null == totalLikes
          ? _value.totalLikes
          : totalLikes // ignore: cast_nullable_to_non_nullable
              as int,
      pagesCount: null == pagesCount
          ? _value.pagesCount
          : pagesCount // ignore: cast_nullable_to_non_nullable
              as int,
      epsCount: null == epsCount
          ? _value.epsCount
          : epsCount // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as Thumb,
      viewsCount: null == viewsCount
          ? _value.viewsCount
          : viewsCount // ignore: cast_nullable_to_non_nullable
              as int,
      leaderboardCount: null == leaderboardCount
          ? _value.leaderboardCount
          : leaderboardCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ComicImpl implements _Comic {
  const _$ComicImpl(
      {@JsonKey(name: "_id") required this.id,
      @JsonKey(name: "title") required this.title,
      @JsonKey(name: "author") required this.author,
      @JsonKey(name: "totalViews") required this.totalViews,
      @JsonKey(name: "totalLikes") required this.totalLikes,
      @JsonKey(name: "pagesCount") required this.pagesCount,
      @JsonKey(name: "epsCount") required this.epsCount,
      @JsonKey(name: "finished") required this.finished,
      @JsonKey(name: "categories") required final List<String> categories,
      @JsonKey(name: "thumb") required this.thumb,
      @JsonKey(name: "viewsCount") required this.viewsCount,
      @JsonKey(name: "leaderboardCount") required this.leaderboardCount})
      : _categories = categories;

  factory _$ComicImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComicImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "author")
  final String author;
  @override
  @JsonKey(name: "totalViews")
  final int totalViews;
  @override
  @JsonKey(name: "totalLikes")
  final int totalLikes;
  @override
  @JsonKey(name: "pagesCount")
  final int pagesCount;
  @override
  @JsonKey(name: "epsCount")
  final int epsCount;
  @override
  @JsonKey(name: "finished")
  final bool finished;
  final List<String> _categories;

  @override
  @JsonKey(name: "categories")
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  @JsonKey(name: "thumb")
  final Thumb thumb;
  @override
  @JsonKey(name: "viewsCount")
  final int viewsCount;
  @override
  @JsonKey(name: "leaderboardCount")
  final int leaderboardCount;

  @override
  String toString() {
    return 'Comic(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, viewsCount: $viewsCount, leaderboardCount: $leaderboardCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComicImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.totalViews, totalViews) ||
                other.totalViews == totalViews) &&
            (identical(other.totalLikes, totalLikes) ||
                other.totalLikes == totalLikes) &&
            (identical(other.pagesCount, pagesCount) ||
                other.pagesCount == pagesCount) &&
            (identical(other.epsCount, epsCount) ||
                other.epsCount == epsCount) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.leaderboardCount, leaderboardCount) ||
                other.leaderboardCount == leaderboardCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      author,
      totalViews,
      totalLikes,
      pagesCount,
      epsCount,
      finished,
      const DeepCollectionEquality().hash(_categories),
      thumb,
      viewsCount,
      leaderboardCount);

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComicImplCopyWith<_$ComicImpl> get copyWith =>
      __$$ComicImplCopyWithImpl<_$ComicImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComicImplToJson(
      this,
    );
  }
}

abstract class _Comic implements Comic {
  const factory _Comic(
      {@JsonKey(name: "_id") required final String id,
      @JsonKey(name: "title") required final String title,
      @JsonKey(name: "author") required final String author,
      @JsonKey(name: "totalViews") required final int totalViews,
      @JsonKey(name: "totalLikes") required final int totalLikes,
      @JsonKey(name: "pagesCount") required final int pagesCount,
      @JsonKey(name: "epsCount") required final int epsCount,
      @JsonKey(name: "finished") required final bool finished,
      @JsonKey(name: "categories") required final List<String> categories,
      @JsonKey(name: "thumb") required final Thumb thumb,
      @JsonKey(name: "viewsCount") required final int viewsCount,
      @JsonKey(name: "leaderboardCount")
      required final int leaderboardCount}) = _$ComicImpl;

  factory _Comic.fromJson(Map<String, dynamic> json) = _$ComicImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "title")
  String get title;

  @override
  @JsonKey(name: "author")
  String get author;

  @override
  @JsonKey(name: "totalViews")
  int get totalViews;

  @override
  @JsonKey(name: "totalLikes")
  int get totalLikes;

  @override
  @JsonKey(name: "pagesCount")
  int get pagesCount;

  @override
  @JsonKey(name: "epsCount")
  int get epsCount;

  @override
  @JsonKey(name: "finished")
  bool get finished;

  @override
  @JsonKey(name: "categories")
  List<String> get categories;

  @override
  @JsonKey(name: "thumb")
  Thumb get thumb;

  @override
  @JsonKey(name: "viewsCount")
  int get viewsCount;

  @override
  @JsonKey(name: "leaderboardCount")
  int get leaderboardCount;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComicImplCopyWith<_$ComicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Thumb _$ThumbFromJson(Map<String, dynamic> json) {
  return _Thumb.fromJson(json);
}

/// @nodoc
mixin _$Thumb {
  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;

  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;

  /// Serializes this Thumb to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThumbCopyWith<Thumb> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThumbCopyWith<$Res> {
  factory $ThumbCopyWith(Thumb value, $Res Function(Thumb) then) =
      _$ThumbCopyWithImpl<$Res, Thumb>;

  @useResult
  $Res call(
      {@JsonKey(name: "fileServer") String fileServer,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "originalName") String originalName});
}

/// @nodoc
class _$ThumbCopyWithImpl<$Res, $Val extends Thumb>
    implements $ThumbCopyWith<$Res> {
  _$ThumbCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileServer = null,
    Object? path = null,
    Object? originalName = null,
  }) {
    return _then(_value.copyWith(
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThumbImplCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$$ThumbImplCopyWith(
          _$ThumbImpl value, $Res Function(_$ThumbImpl) then) =
      __$$ThumbImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "fileServer") String fileServer,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "originalName") String originalName});
}

/// @nodoc
class __$$ThumbImplCopyWithImpl<$Res>
    extends _$ThumbCopyWithImpl<$Res, _$ThumbImpl>
    implements _$$ThumbImplCopyWith<$Res> {
  __$$ThumbImplCopyWithImpl(
      _$ThumbImpl _value, $Res Function(_$ThumbImpl) _then)
      : super(_value, _then);

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileServer = null,
    Object? path = null,
    Object? originalName = null,
  }) {
    return _then(_$ThumbImpl(
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThumbImpl implements _Thumb {
  const _$ThumbImpl(
      {@JsonKey(name: "fileServer") required this.fileServer,
      @JsonKey(name: "path") required this.path,
      @JsonKey(name: "originalName") required this.originalName});

  factory _$ThumbImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbImplFromJson(json);

  @override
  @JsonKey(name: "fileServer")
  final String fileServer;
  @override
  @JsonKey(name: "path")
  final String path;
  @override
  @JsonKey(name: "originalName")
  final String originalName;

  @override
  String toString() {
    return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbImpl &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fileServer, path, originalName);

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      __$$ThumbImplCopyWithImpl<_$ThumbImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThumbImplToJson(
      this,
    );
  }
}

abstract class _Thumb implements Thumb {
  const factory _Thumb(
          {@JsonKey(name: "fileServer") required final String fileServer,
          @JsonKey(name: "path") required final String path,
          @JsonKey(name: "originalName") required final String originalName}) =
      _$ThumbImpl;

  factory _Thumb.fromJson(Map<String, dynamic> json) = _$ThumbImpl.fromJson;

  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  @override
  @JsonKey(name: "path")
  String get path;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
