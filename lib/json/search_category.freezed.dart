// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SearchCategory _$SearchCategoryFromJson(Map<String, dynamic> json) {
  return _SearchCategory.fromJson(json);
}

/// @nodoc
mixin _$SearchCategory {
  @JsonKey(name: "categories")
  List<Category> get categories => throw _privateConstructorUsedError;

  /// Serializes this SearchCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchCategoryCopyWith<SearchCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchCategoryCopyWith<$Res> {
  factory $SearchCategoryCopyWith(
          SearchCategory value, $Res Function(SearchCategory) then) =
      _$SearchCategoryCopyWithImpl<$Res, SearchCategory>;

  @useResult
  $Res call({@JsonKey(name: "categories") List<Category> categories});
}

/// @nodoc
class _$SearchCategoryCopyWithImpl<$Res, $Val extends SearchCategory>
    implements $SearchCategoryCopyWith<$Res> {
  _$SearchCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
  }) {
    return _then(_value.copyWith(
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<Category>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchCategoryImplCopyWith<$Res>
    implements $SearchCategoryCopyWith<$Res> {
  factory _$$SearchCategoryImplCopyWith(_$SearchCategoryImpl value,
          $Res Function(_$SearchCategoryImpl) then) =
      __$$SearchCategoryImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({@JsonKey(name: "categories") List<Category> categories});
}

/// @nodoc
class __$$SearchCategoryImplCopyWithImpl<$Res>
    extends _$SearchCategoryCopyWithImpl<$Res, _$SearchCategoryImpl>
    implements _$$SearchCategoryImplCopyWith<$Res> {
  __$$SearchCategoryImplCopyWithImpl(
      _$SearchCategoryImpl _value, $Res Function(_$SearchCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
  }) {
    return _then(_$SearchCategoryImpl(
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<Category>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchCategoryImpl implements _SearchCategory {
  const _$SearchCategoryImpl(
      {@JsonKey(name: "categories") required final List<Category> categories})
      : _categories = categories;

  factory _$SearchCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchCategoryImplFromJson(json);

  final List<Category> _categories;

  @override
  @JsonKey(name: "categories")
  List<Category> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  String toString() {
    return 'SearchCategory(categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchCategoryImpl &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_categories));

  /// Create a copy of SearchCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchCategoryImplCopyWith<_$SearchCategoryImpl> get copyWith =>
      __$$SearchCategoryImplCopyWithImpl<_$SearchCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchCategoryImplToJson(
      this,
    );
  }
}

abstract class _SearchCategory implements SearchCategory {
  const factory _SearchCategory(
      {@JsonKey(name: "categories")
      required final List<Category> categories}) = _$SearchCategoryImpl;

  factory _SearchCategory.fromJson(Map<String, dynamic> json) =
      _$SearchCategoryImpl.fromJson;

  @override
  @JsonKey(name: "categories")
  List<Category> get categories;

  /// Create a copy of SearchCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchCategoryImplCopyWith<_$SearchCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;

  @JsonKey(name: "thumb")
  Thumb get thumb => throw _privateConstructorUsedError;

  @JsonKey(name: "isWeb")
  bool? get isWeb => throw _privateConstructorUsedError;

  @JsonKey(name: "active")
  bool? get active => throw _privateConstructorUsedError;

  @JsonKey(name: "link")
  String? get link => throw _privateConstructorUsedError;

  @JsonKey(name: "_id")
  String? get id => throw _privateConstructorUsedError;

  @JsonKey(name: "description")
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;

  @useResult
  $Res call(
      {@JsonKey(name: "title") String title,
      @JsonKey(name: "thumb") Thumb thumb,
      @JsonKey(name: "isWeb") bool? isWeb,
      @JsonKey(name: "active") bool? active,
      @JsonKey(name: "link") String? link,
      @JsonKey(name: "_id") String? id,
      @JsonKey(name: "description") String? description});

  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? thumb = null,
    Object? isWeb = freezed,
    Object? active = freezed,
    Object? link = freezed,
    Object? id = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as Thumb,
      isWeb: freezed == isWeb
          ? _value.isWeb
          : isWeb // ignore: cast_nullable_to_non_nullable
              as bool?,
      active: freezed == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Category
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
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
          _$CategoryImpl value, $Res Function(_$CategoryImpl) then) =
      __$$CategoryImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "title") String title,
      @JsonKey(name: "thumb") Thumb thumb,
      @JsonKey(name: "isWeb") bool? isWeb,
      @JsonKey(name: "active") bool? active,
      @JsonKey(name: "link") String? link,
      @JsonKey(name: "_id") String? id,
      @JsonKey(name: "description") String? description});

  @override
  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
      _$CategoryImpl _value, $Res Function(_$CategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? thumb = null,
    Object? isWeb = freezed,
    Object? active = freezed,
    Object? link = freezed,
    Object? id = freezed,
    Object? description = freezed,
  }) {
    return _then(_$CategoryImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      thumb: null == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as Thumb,
      isWeb: freezed == isWeb
          ? _value.isWeb
          : isWeb // ignore: cast_nullable_to_non_nullable
              as bool?,
      active: freezed == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl implements _Category {
  const _$CategoryImpl(
      {@JsonKey(name: "title") required this.title,
      @JsonKey(name: "thumb") required this.thumb,
      @JsonKey(name: "isWeb") this.isWeb,
      @JsonKey(name: "active") this.active,
      @JsonKey(name: "link") this.link,
      @JsonKey(name: "_id") this.id,
      @JsonKey(name: "description") this.description});

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "thumb")
  final Thumb thumb;
  @override
  @JsonKey(name: "isWeb")
  final bool? isWeb;
  @override
  @JsonKey(name: "active")
  final bool? active;
  @override
  @JsonKey(name: "link")
  final String? link;
  @override
  @JsonKey(name: "_id")
  final String? id;
  @override
  @JsonKey(name: "description")
  final String? description;

  @override
  String toString() {
    return 'Category(title: $title, thumb: $thumb, isWeb: $isWeb, active: $active, link: $link, id: $id, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.isWeb, isWeb) || other.isWeb == isWeb) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, title, thumb, isWeb, active, link, id, description);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(
      this,
    );
  }
}

abstract class _Category implements Category {
  const factory _Category(
          {@JsonKey(name: "title") required final String title,
          @JsonKey(name: "thumb") required final Thumb thumb,
          @JsonKey(name: "isWeb") final bool? isWeb,
          @JsonKey(name: "active") final bool? active,
          @JsonKey(name: "link") final String? link,
          @JsonKey(name: "_id") final String? id,
          @JsonKey(name: "description") final String? description}) =
      _$CategoryImpl;

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  @JsonKey(name: "title")
  String get title;

  @override
  @JsonKey(name: "thumb")
  Thumb get thumb;

  @override
  @JsonKey(name: "isWeb")
  bool? get isWeb;

  @override
  @JsonKey(name: "active")
  bool? get active;

  @override
  @JsonKey(name: "link")
  String? get link;

  @override
  @JsonKey(name: "_id")
  String? get id;

  @override
  @JsonKey(name: "description")
  String? get description;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Thumb _$ThumbFromJson(Map<String, dynamic> json) {
  return _Thumb.fromJson(json);
}

/// @nodoc
mixin _$Thumb {
  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;

  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;

  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

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
      {@JsonKey(name: "originalName") String originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
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
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_value.copyWith(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$ThumbImplCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$$ThumbImplCopyWith(
          _$ThumbImpl value, $Res Function(_$ThumbImpl) then) =
      __$$ThumbImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "originalName") String originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
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
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_$ThumbImpl(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$ThumbImpl implements _Thumb {
  const _$ThumbImpl(
      {@JsonKey(name: "originalName") required this.originalName,
      @JsonKey(name: "path") required this.path,
      @JsonKey(name: "fileServer") required this.fileServer});

  factory _$ThumbImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbImplFromJson(json);

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
    return 'Thumb(originalName: $originalName, path: $path, fileServer: $fileServer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbImpl &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalName, path, fileServer);

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
          {@JsonKey(name: "originalName") required final String originalName,
          @JsonKey(name: "path") required final String path,
          @JsonKey(name: "fileServer") required final String fileServer}) =
      _$ThumbImpl;

  factory _Thumb.fromJson(Map<String, dynamic> json) = _$ThumbImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

  @override
  @JsonKey(name: "path")
  String get path;

  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
