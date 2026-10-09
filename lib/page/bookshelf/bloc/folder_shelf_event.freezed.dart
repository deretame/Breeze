// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_shelf_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FolderShelfEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent()';
}


}

/// @nodoc
class $FolderShelfEventCopyWith<$Res>  {
$FolderShelfEventCopyWith(FolderShelfEvent _, $Res Function(FolderShelfEvent) __);
}


/// Adds pattern-matching-related methods to [FolderShelfEvent].
extension FolderShelfEventPatterns on FolderShelfEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FolderShelfLoadRequested value)?  loadRequested,TResult Function( FolderShelfEnterFolder value)?  enterFolder,TResult Function( FolderShelfGoBack value)?  goBack,TResult Function( FolderShelfGoHome value)?  goHome,TResult Function( FolderShelfToggleSort value)?  toggleSort,TResult Function( FolderShelfCreateFolder value)?  createFolder,TResult Function( FolderShelfDeleteFolder value)?  deleteFolder,TResult Function( FolderShelfRenameFolder value)?  renameFolder,TResult Function( FolderShelfEnterSelectionMode value)?  enterSelectionMode,TResult Function( FolderShelfExitSelectionMode value)?  exitSelectionMode,TResult Function( FolderShelfToggleFolderSelection value)?  toggleFolderSelection,TResult Function( FolderShelfToggleComicSelection value)?  toggleComicSelection,TResult Function( FolderShelfSelectAll value)?  selectAll,TResult Function( FolderShelfMoveSelected value)?  moveSelected,TResult Function( FolderShelfCopySelected value)?  copySelected,TResult Function( FolderShelfDeleteSelected value)?  deleteSelected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FolderShelfLoadRequested() when loadRequested != null:
return loadRequested(_that);case FolderShelfEnterFolder() when enterFolder != null:
return enterFolder(_that);case FolderShelfGoBack() when goBack != null:
return goBack(_that);case FolderShelfGoHome() when goHome != null:
return goHome(_that);case FolderShelfToggleSort() when toggleSort != null:
return toggleSort(_that);case FolderShelfCreateFolder() when createFolder != null:
return createFolder(_that);case FolderShelfDeleteFolder() when deleteFolder != null:
return deleteFolder(_that);case FolderShelfRenameFolder() when renameFolder != null:
return renameFolder(_that);case FolderShelfEnterSelectionMode() when enterSelectionMode != null:
return enterSelectionMode(_that);case FolderShelfExitSelectionMode() when exitSelectionMode != null:
return exitSelectionMode(_that);case FolderShelfToggleFolderSelection() when toggleFolderSelection != null:
return toggleFolderSelection(_that);case FolderShelfToggleComicSelection() when toggleComicSelection != null:
return toggleComicSelection(_that);case FolderShelfSelectAll() when selectAll != null:
return selectAll(_that);case FolderShelfMoveSelected() when moveSelected != null:
return moveSelected(_that);case FolderShelfCopySelected() when copySelected != null:
return copySelected(_that);case FolderShelfDeleteSelected() when deleteSelected != null:
return deleteSelected(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FolderShelfLoadRequested value)  loadRequested,required TResult Function( FolderShelfEnterFolder value)  enterFolder,required TResult Function( FolderShelfGoBack value)  goBack,required TResult Function( FolderShelfGoHome value)  goHome,required TResult Function( FolderShelfToggleSort value)  toggleSort,required TResult Function( FolderShelfCreateFolder value)  createFolder,required TResult Function( FolderShelfDeleteFolder value)  deleteFolder,required TResult Function( FolderShelfRenameFolder value)  renameFolder,required TResult Function( FolderShelfEnterSelectionMode value)  enterSelectionMode,required TResult Function( FolderShelfExitSelectionMode value)  exitSelectionMode,required TResult Function( FolderShelfToggleFolderSelection value)  toggleFolderSelection,required TResult Function( FolderShelfToggleComicSelection value)  toggleComicSelection,required TResult Function( FolderShelfSelectAll value)  selectAll,required TResult Function( FolderShelfMoveSelected value)  moveSelected,required TResult Function( FolderShelfCopySelected value)  copySelected,required TResult Function( FolderShelfDeleteSelected value)  deleteSelected,}){
final _that = this;
switch (_that) {
case FolderShelfLoadRequested():
return loadRequested(_that);case FolderShelfEnterFolder():
return enterFolder(_that);case FolderShelfGoBack():
return goBack(_that);case FolderShelfGoHome():
return goHome(_that);case FolderShelfToggleSort():
return toggleSort(_that);case FolderShelfCreateFolder():
return createFolder(_that);case FolderShelfDeleteFolder():
return deleteFolder(_that);case FolderShelfRenameFolder():
return renameFolder(_that);case FolderShelfEnterSelectionMode():
return enterSelectionMode(_that);case FolderShelfExitSelectionMode():
return exitSelectionMode(_that);case FolderShelfToggleFolderSelection():
return toggleFolderSelection(_that);case FolderShelfToggleComicSelection():
return toggleComicSelection(_that);case FolderShelfSelectAll():
return selectAll(_that);case FolderShelfMoveSelected():
return moveSelected(_that);case FolderShelfCopySelected():
return copySelected(_that);case FolderShelfDeleteSelected():
return deleteSelected(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FolderShelfLoadRequested value)?  loadRequested,TResult? Function( FolderShelfEnterFolder value)?  enterFolder,TResult? Function( FolderShelfGoBack value)?  goBack,TResult? Function( FolderShelfGoHome value)?  goHome,TResult? Function( FolderShelfToggleSort value)?  toggleSort,TResult? Function( FolderShelfCreateFolder value)?  createFolder,TResult? Function( FolderShelfDeleteFolder value)?  deleteFolder,TResult? Function( FolderShelfRenameFolder value)?  renameFolder,TResult? Function( FolderShelfEnterSelectionMode value)?  enterSelectionMode,TResult? Function( FolderShelfExitSelectionMode value)?  exitSelectionMode,TResult? Function( FolderShelfToggleFolderSelection value)?  toggleFolderSelection,TResult? Function( FolderShelfToggleComicSelection value)?  toggleComicSelection,TResult? Function( FolderShelfSelectAll value)?  selectAll,TResult? Function( FolderShelfMoveSelected value)?  moveSelected,TResult? Function( FolderShelfCopySelected value)?  copySelected,TResult? Function( FolderShelfDeleteSelected value)?  deleteSelected,}){
final _that = this;
switch (_that) {
case FolderShelfLoadRequested() when loadRequested != null:
return loadRequested(_that);case FolderShelfEnterFolder() when enterFolder != null:
return enterFolder(_that);case FolderShelfGoBack() when goBack != null:
return goBack(_that);case FolderShelfGoHome() when goHome != null:
return goHome(_that);case FolderShelfToggleSort() when toggleSort != null:
return toggleSort(_that);case FolderShelfCreateFolder() when createFolder != null:
return createFolder(_that);case FolderShelfDeleteFolder() when deleteFolder != null:
return deleteFolder(_that);case FolderShelfRenameFolder() when renameFolder != null:
return renameFolder(_that);case FolderShelfEnterSelectionMode() when enterSelectionMode != null:
return enterSelectionMode(_that);case FolderShelfExitSelectionMode() when exitSelectionMode != null:
return exitSelectionMode(_that);case FolderShelfToggleFolderSelection() when toggleFolderSelection != null:
return toggleFolderSelection(_that);case FolderShelfToggleComicSelection() when toggleComicSelection != null:
return toggleComicSelection(_that);case FolderShelfSelectAll() when selectAll != null:
return selectAll(_that);case FolderShelfMoveSelected() when moveSelected != null:
return moveSelected(_that);case FolderShelfCopySelected() when copySelected != null:
return copySelected(_that);case FolderShelfDeleteSelected() when deleteSelected != null:
return deleteSelected(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SearchStatusState? search)?  loadRequested,TResult Function( String path)?  enterFolder,TResult Function()?  goBack,TResult Function()?  goHome,TResult Function()?  toggleSort,TResult Function( String name)?  createFolder,TResult Function( String path)?  deleteFolder,TResult Function( String path,  String newName)?  renameFolder,TResult Function()?  enterSelectionMode,TResult Function()?  exitSelectionMode,TResult Function( String path)?  toggleFolderSelection,TResult Function( String comicUniqueKey)?  toggleComicSelection,TResult Function()?  selectAll,TResult Function( Set<String> targetPaths,  Set<String>? sourceFolderPaths)?  moveSelected,TResult Function( Set<String> targetPaths)?  copySelected,TResult Function()?  deleteSelected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FolderShelfLoadRequested() when loadRequested != null:
return loadRequested(_that.search);case FolderShelfEnterFolder() when enterFolder != null:
return enterFolder(_that.path);case FolderShelfGoBack() when goBack != null:
return goBack();case FolderShelfGoHome() when goHome != null:
return goHome();case FolderShelfToggleSort() when toggleSort != null:
return toggleSort();case FolderShelfCreateFolder() when createFolder != null:
return createFolder(_that.name);case FolderShelfDeleteFolder() when deleteFolder != null:
return deleteFolder(_that.path);case FolderShelfRenameFolder() when renameFolder != null:
return renameFolder(_that.path,_that.newName);case FolderShelfEnterSelectionMode() when enterSelectionMode != null:
return enterSelectionMode();case FolderShelfExitSelectionMode() when exitSelectionMode != null:
return exitSelectionMode();case FolderShelfToggleFolderSelection() when toggleFolderSelection != null:
return toggleFolderSelection(_that.path);case FolderShelfToggleComicSelection() when toggleComicSelection != null:
return toggleComicSelection(_that.comicUniqueKey);case FolderShelfSelectAll() when selectAll != null:
return selectAll();case FolderShelfMoveSelected() when moveSelected != null:
return moveSelected(_that.targetPaths,_that.sourceFolderPaths);case FolderShelfCopySelected() when copySelected != null:
return copySelected(_that.targetPaths);case FolderShelfDeleteSelected() when deleteSelected != null:
return deleteSelected();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SearchStatusState? search)  loadRequested,required TResult Function( String path)  enterFolder,required TResult Function()  goBack,required TResult Function()  goHome,required TResult Function()  toggleSort,required TResult Function( String name)  createFolder,required TResult Function( String path)  deleteFolder,required TResult Function( String path,  String newName)  renameFolder,required TResult Function()  enterSelectionMode,required TResult Function()  exitSelectionMode,required TResult Function( String path)  toggleFolderSelection,required TResult Function( String comicUniqueKey)  toggleComicSelection,required TResult Function()  selectAll,required TResult Function( Set<String> targetPaths,  Set<String>? sourceFolderPaths)  moveSelected,required TResult Function( Set<String> targetPaths)  copySelected,required TResult Function()  deleteSelected,}) {final _that = this;
switch (_that) {
case FolderShelfLoadRequested():
return loadRequested(_that.search);case FolderShelfEnterFolder():
return enterFolder(_that.path);case FolderShelfGoBack():
return goBack();case FolderShelfGoHome():
return goHome();case FolderShelfToggleSort():
return toggleSort();case FolderShelfCreateFolder():
return createFolder(_that.name);case FolderShelfDeleteFolder():
return deleteFolder(_that.path);case FolderShelfRenameFolder():
return renameFolder(_that.path,_that.newName);case FolderShelfEnterSelectionMode():
return enterSelectionMode();case FolderShelfExitSelectionMode():
return exitSelectionMode();case FolderShelfToggleFolderSelection():
return toggleFolderSelection(_that.path);case FolderShelfToggleComicSelection():
return toggleComicSelection(_that.comicUniqueKey);case FolderShelfSelectAll():
return selectAll();case FolderShelfMoveSelected():
return moveSelected(_that.targetPaths,_that.sourceFolderPaths);case FolderShelfCopySelected():
return copySelected(_that.targetPaths);case FolderShelfDeleteSelected():
return deleteSelected();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SearchStatusState? search)?  loadRequested,TResult? Function( String path)?  enterFolder,TResult? Function()?  goBack,TResult? Function()?  goHome,TResult? Function()?  toggleSort,TResult? Function( String name)?  createFolder,TResult? Function( String path)?  deleteFolder,TResult? Function( String path,  String newName)?  renameFolder,TResult? Function()?  enterSelectionMode,TResult? Function()?  exitSelectionMode,TResult? Function( String path)?  toggleFolderSelection,TResult? Function( String comicUniqueKey)?  toggleComicSelection,TResult? Function()?  selectAll,TResult? Function( Set<String> targetPaths,  Set<String>? sourceFolderPaths)?  moveSelected,TResult? Function( Set<String> targetPaths)?  copySelected,TResult? Function()?  deleteSelected,}) {final _that = this;
switch (_that) {
case FolderShelfLoadRequested() when loadRequested != null:
return loadRequested(_that.search);case FolderShelfEnterFolder() when enterFolder != null:
return enterFolder(_that.path);case FolderShelfGoBack() when goBack != null:
return goBack();case FolderShelfGoHome() when goHome != null:
return goHome();case FolderShelfToggleSort() when toggleSort != null:
return toggleSort();case FolderShelfCreateFolder() when createFolder != null:
return createFolder(_that.name);case FolderShelfDeleteFolder() when deleteFolder != null:
return deleteFolder(_that.path);case FolderShelfRenameFolder() when renameFolder != null:
return renameFolder(_that.path,_that.newName);case FolderShelfEnterSelectionMode() when enterSelectionMode != null:
return enterSelectionMode();case FolderShelfExitSelectionMode() when exitSelectionMode != null:
return exitSelectionMode();case FolderShelfToggleFolderSelection() when toggleFolderSelection != null:
return toggleFolderSelection(_that.path);case FolderShelfToggleComicSelection() when toggleComicSelection != null:
return toggleComicSelection(_that.comicUniqueKey);case FolderShelfSelectAll() when selectAll != null:
return selectAll();case FolderShelfMoveSelected() when moveSelected != null:
return moveSelected(_that.targetPaths,_that.sourceFolderPaths);case FolderShelfCopySelected() when copySelected != null:
return copySelected(_that.targetPaths);case FolderShelfDeleteSelected() when deleteSelected != null:
return deleteSelected();case _:
  return null;

}
}

}

/// @nodoc


class FolderShelfLoadRequested implements FolderShelfEvent {
  const FolderShelfLoadRequested({this.search});
  

 final  SearchStatusState? search;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfLoadRequestedCopyWith<FolderShelfLoadRequested> get copyWith => _$FolderShelfLoadRequestedCopyWithImpl<FolderShelfLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfLoadRequested&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode {
    return Object.hash(runtimeType,search);
}

@override
String toString() {
    return 'FolderShelfEvent.loadRequested(search: $search)';
}


}

/// @nodoc
abstract mixin class $FolderShelfLoadRequestedCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfLoadRequestedCopyWith(FolderShelfLoadRequested value, $Res Function(FolderShelfLoadRequested) _then) = _$FolderShelfLoadRequestedCopyWithImpl;
@useResult
$Res call({
 SearchStatusState? search
});


$SearchStatusStateCopyWith<$Res>? get search;

}
/// @nodoc
class _$FolderShelfLoadRequestedCopyWithImpl<$Res>
    implements $FolderShelfLoadRequestedCopyWith<$Res> {
  _$FolderShelfLoadRequestedCopyWithImpl(this._self, this._then);

  final FolderShelfLoadRequested _self;
  final $Res Function(FolderShelfLoadRequested) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? search = freezed,}) {
  return _then(FolderShelfLoadRequested(
search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as SearchStatusState?,
  ));
}

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchStatusStateCopyWith<$Res>? get search {
    if (_self.search == null) {
    return null;
  }

  return $SearchStatusStateCopyWith<$Res>(_self.search!, (value) {
    return _then(_self.copyWith(search: value));
  });
}
}

/// @nodoc


class FolderShelfEnterFolder implements FolderShelfEvent {
  const FolderShelfEnterFolder(this.path);
  

 final  String path;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfEnterFolderCopyWith<FolderShelfEnterFolder> get copyWith => _$FolderShelfEnterFolderCopyWithImpl<FolderShelfEnterFolder>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfEnterFolder&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'FolderShelfEvent.enterFolder(path: $path)';
}


}

/// @nodoc
abstract mixin class $FolderShelfEnterFolderCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfEnterFolderCopyWith(FolderShelfEnterFolder value, $Res Function(FolderShelfEnterFolder) _then) = _$FolderShelfEnterFolderCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$FolderShelfEnterFolderCopyWithImpl<$Res>
    implements $FolderShelfEnterFolderCopyWith<$Res> {
  _$FolderShelfEnterFolderCopyWithImpl(this._self, this._then);

  final FolderShelfEnterFolder _self;
  final $Res Function(FolderShelfEnterFolder) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(FolderShelfEnterFolder(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfGoBack implements FolderShelfEvent {
  const FolderShelfGoBack();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfGoBack);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.goBack()';
}


}




/// @nodoc


class FolderShelfGoHome implements FolderShelfEvent {
  const FolderShelfGoHome();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfGoHome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.goHome()';
}


}




/// @nodoc


class FolderShelfToggleSort implements FolderShelfEvent {
  const FolderShelfToggleSort();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfToggleSort);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.toggleSort()';
}


}




/// @nodoc


class FolderShelfCreateFolder implements FolderShelfEvent {
  const FolderShelfCreateFolder(this.name);
  

 final  String name;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfCreateFolderCopyWith<FolderShelfCreateFolder> get copyWith => _$FolderShelfCreateFolderCopyWithImpl<FolderShelfCreateFolder>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfCreateFolder&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name);
}

@override
String toString() {
    return 'FolderShelfEvent.createFolder(name: $name)';
}


}

/// @nodoc
abstract mixin class $FolderShelfCreateFolderCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfCreateFolderCopyWith(FolderShelfCreateFolder value, $Res Function(FolderShelfCreateFolder) _then) = _$FolderShelfCreateFolderCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$FolderShelfCreateFolderCopyWithImpl<$Res>
    implements $FolderShelfCreateFolderCopyWith<$Res> {
  _$FolderShelfCreateFolderCopyWithImpl(this._self, this._then);

  final FolderShelfCreateFolder _self;
  final $Res Function(FolderShelfCreateFolder) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(FolderShelfCreateFolder(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfDeleteFolder implements FolderShelfEvent {
  const FolderShelfDeleteFolder(this.path);
  

 final  String path;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfDeleteFolderCopyWith<FolderShelfDeleteFolder> get copyWith => _$FolderShelfDeleteFolderCopyWithImpl<FolderShelfDeleteFolder>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfDeleteFolder&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'FolderShelfEvent.deleteFolder(path: $path)';
}


}

/// @nodoc
abstract mixin class $FolderShelfDeleteFolderCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfDeleteFolderCopyWith(FolderShelfDeleteFolder value, $Res Function(FolderShelfDeleteFolder) _then) = _$FolderShelfDeleteFolderCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$FolderShelfDeleteFolderCopyWithImpl<$Res>
    implements $FolderShelfDeleteFolderCopyWith<$Res> {
  _$FolderShelfDeleteFolderCopyWithImpl(this._self, this._then);

  final FolderShelfDeleteFolder _self;
  final $Res Function(FolderShelfDeleteFolder) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(FolderShelfDeleteFolder(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfRenameFolder implements FolderShelfEvent {
  const FolderShelfRenameFolder(this.path, this.newName);
  

 final  String path;
 final  String newName;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfRenameFolderCopyWith<FolderShelfRenameFolder> get copyWith => _$FolderShelfRenameFolderCopyWithImpl<FolderShelfRenameFolder>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfRenameFolder&&(identical(other.path, path) || other.path == path)&&(identical(other.newName, newName) || other.newName == newName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,newName);
}

@override
String toString() {
    return 'FolderShelfEvent.renameFolder(path: $path, newName: $newName)';
}


}

/// @nodoc
abstract mixin class $FolderShelfRenameFolderCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfRenameFolderCopyWith(FolderShelfRenameFolder value, $Res Function(FolderShelfRenameFolder) _then) = _$FolderShelfRenameFolderCopyWithImpl;
@useResult
$Res call({
 String path, String newName
});




}
/// @nodoc
class _$FolderShelfRenameFolderCopyWithImpl<$Res>
    implements $FolderShelfRenameFolderCopyWith<$Res> {
  _$FolderShelfRenameFolderCopyWithImpl(this._self, this._then);

  final FolderShelfRenameFolder _self;
  final $Res Function(FolderShelfRenameFolder) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? newName = null,}) {
  return _then(FolderShelfRenameFolder(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,null == newName ? _self.newName : newName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfEnterSelectionMode implements FolderShelfEvent {
  const FolderShelfEnterSelectionMode();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfEnterSelectionMode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.enterSelectionMode()';
}


}




/// @nodoc


class FolderShelfExitSelectionMode implements FolderShelfEvent {
  const FolderShelfExitSelectionMode();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfExitSelectionMode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.exitSelectionMode()';
}


}




/// @nodoc


class FolderShelfToggleFolderSelection implements FolderShelfEvent {
  const FolderShelfToggleFolderSelection(this.path);
  

 final  String path;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfToggleFolderSelectionCopyWith<FolderShelfToggleFolderSelection> get copyWith => _$FolderShelfToggleFolderSelectionCopyWithImpl<FolderShelfToggleFolderSelection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfToggleFolderSelection&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'FolderShelfEvent.toggleFolderSelection(path: $path)';
}


}

/// @nodoc
abstract mixin class $FolderShelfToggleFolderSelectionCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfToggleFolderSelectionCopyWith(FolderShelfToggleFolderSelection value, $Res Function(FolderShelfToggleFolderSelection) _then) = _$FolderShelfToggleFolderSelectionCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$FolderShelfToggleFolderSelectionCopyWithImpl<$Res>
    implements $FolderShelfToggleFolderSelectionCopyWith<$Res> {
  _$FolderShelfToggleFolderSelectionCopyWithImpl(this._self, this._then);

  final FolderShelfToggleFolderSelection _self;
  final $Res Function(FolderShelfToggleFolderSelection) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(FolderShelfToggleFolderSelection(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfToggleComicSelection implements FolderShelfEvent {
  const FolderShelfToggleComicSelection(this.comicUniqueKey);
  

 final  String comicUniqueKey;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfToggleComicSelectionCopyWith<FolderShelfToggleComicSelection> get copyWith => _$FolderShelfToggleComicSelectionCopyWithImpl<FolderShelfToggleComicSelection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfToggleComicSelection&&(identical(other.comicUniqueKey, comicUniqueKey) || other.comicUniqueKey == comicUniqueKey));
}


@override
int get hashCode {
    return Object.hash(runtimeType,comicUniqueKey);
}

@override
String toString() {
    return 'FolderShelfEvent.toggleComicSelection(comicUniqueKey: $comicUniqueKey)';
}


}

/// @nodoc
abstract mixin class $FolderShelfToggleComicSelectionCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfToggleComicSelectionCopyWith(FolderShelfToggleComicSelection value, $Res Function(FolderShelfToggleComicSelection) _then) = _$FolderShelfToggleComicSelectionCopyWithImpl;
@useResult
$Res call({
 String comicUniqueKey
});




}
/// @nodoc
class _$FolderShelfToggleComicSelectionCopyWithImpl<$Res>
    implements $FolderShelfToggleComicSelectionCopyWith<$Res> {
  _$FolderShelfToggleComicSelectionCopyWithImpl(this._self, this._then);

  final FolderShelfToggleComicSelection _self;
  final $Res Function(FolderShelfToggleComicSelection) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comicUniqueKey = null,}) {
  return _then(FolderShelfToggleComicSelection(
null == comicUniqueKey ? _self.comicUniqueKey : comicUniqueKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FolderShelfSelectAll implements FolderShelfEvent {
  const FolderShelfSelectAll();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfSelectAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.selectAll()';
}


}




/// @nodoc


class FolderShelfMoveSelected implements FolderShelfEvent {
  const FolderShelfMoveSelected( Set<String> targetPaths, { Set<String>? sourceFolderPaths}): _targetPaths = targetPaths,_sourceFolderPaths = sourceFolderPaths;
  

 final  Set<String> _targetPaths;
 Set<String> get targetPaths {
  if (_targetPaths is EqualUnmodifiableSetView) return _targetPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_targetPaths);
}

 final  Set<String>? _sourceFolderPaths;
 Set<String>? get sourceFolderPaths {
  final value = _sourceFolderPaths;
  if (value == null) return null;
  if (_sourceFolderPaths is EqualUnmodifiableSetView) return _sourceFolderPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}


/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfMoveSelectedCopyWith<FolderShelfMoveSelected> get copyWith => _$FolderShelfMoveSelectedCopyWithImpl<FolderShelfMoveSelected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfMoveSelected&&const DeepCollectionEquality().equals(other.targetPaths, _targetPaths)&&const DeepCollectionEquality().equals(other.sourceFolderPaths, _sourceFolderPaths));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_targetPaths),const DeepCollectionEquality().hash(_sourceFolderPaths));
}

@override
String toString() {
    return 'FolderShelfEvent.moveSelected(targetPaths: $targetPaths, sourceFolderPaths: $sourceFolderPaths)';
}


}

/// @nodoc
abstract mixin class $FolderShelfMoveSelectedCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfMoveSelectedCopyWith(FolderShelfMoveSelected value, $Res Function(FolderShelfMoveSelected) _then) = _$FolderShelfMoveSelectedCopyWithImpl;
@useResult
$Res call({
 Set<String> targetPaths, Set<String>? sourceFolderPaths
});




}
/// @nodoc
class _$FolderShelfMoveSelectedCopyWithImpl<$Res>
    implements $FolderShelfMoveSelectedCopyWith<$Res> {
  _$FolderShelfMoveSelectedCopyWithImpl(this._self, this._then);

  final FolderShelfMoveSelected _self;
  final $Res Function(FolderShelfMoveSelected) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? targetPaths = null,Object? sourceFolderPaths = freezed,}) {
  return _then(FolderShelfMoveSelected(
null == targetPaths ? _self._targetPaths : targetPaths // ignore: cast_nullable_to_non_nullable
as Set<String>,sourceFolderPaths: freezed == sourceFolderPaths ? _self._sourceFolderPaths : sourceFolderPaths // ignore: cast_nullable_to_non_nullable
as Set<String>?,
  ));
}


}

/// @nodoc


class FolderShelfCopySelected implements FolderShelfEvent {
  const FolderShelfCopySelected( Set<String> targetPaths): _targetPaths = targetPaths;
  

 final  Set<String> _targetPaths;
 Set<String> get targetPaths {
  if (_targetPaths is EqualUnmodifiableSetView) return _targetPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_targetPaths);
}


/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShelfCopySelectedCopyWith<FolderShelfCopySelected> get copyWith => _$FolderShelfCopySelectedCopyWithImpl<FolderShelfCopySelected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfCopySelected&&const DeepCollectionEquality().equals(other.targetPaths, _targetPaths));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_targetPaths));
}

@override
String toString() {
    return 'FolderShelfEvent.copySelected(targetPaths: $targetPaths)';
}


}

/// @nodoc
abstract mixin class $FolderShelfCopySelectedCopyWith<$Res> implements $FolderShelfEventCopyWith<$Res> {
  factory $FolderShelfCopySelectedCopyWith(FolderShelfCopySelected value, $Res Function(FolderShelfCopySelected) _then) = _$FolderShelfCopySelectedCopyWithImpl;
@useResult
$Res call({
 Set<String> targetPaths
});




}
/// @nodoc
class _$FolderShelfCopySelectedCopyWithImpl<$Res>
    implements $FolderShelfCopySelectedCopyWith<$Res> {
  _$FolderShelfCopySelectedCopyWithImpl(this._self, this._then);

  final FolderShelfCopySelected _self;
  final $Res Function(FolderShelfCopySelected) _then;

/// Create a copy of FolderShelfEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? targetPaths = null,}) {
  return _then(FolderShelfCopySelected(
null == targetPaths ? _self._targetPaths : targetPaths // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class FolderShelfDeleteSelected implements FolderShelfEvent {
  const FolderShelfDeleteSelected();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShelfDeleteSelected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'FolderShelfEvent.deleteSelected()';
}


}




// dart format on
