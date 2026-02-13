import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ExportType {
  @JsonValue('zip')
  zip,
  @JsonValue('folder')
  folder,
}

@JsonEnum()
enum From {
  @JsonValue('bika')
  bika,
  @JsonValue('jm')
  jm,
  @JsonValue('unknown')
  unknown,
}

@JsonEnum()
enum ComicEntryType {
  @JsonValue('normal')
  normal,
  @JsonValue('favorite')
  favorite,
  @JsonValue('history')
  history,
  @JsonValue('download')
  download,
  @JsonValue('historyAndDownload')
  historyAndDownload,
}

@JsonEnum()
enum LoginStatus {
  @JsonValue('login')
  login,
  @JsonValue('loggingIn')
  loggingIn,
  @JsonValue('logout')
  logout,
}

@JsonEnum()
enum PictureType {
  @JsonValue('comic')
  comic,
  @JsonValue('cover')
  cover,
  @JsonValue('creator')
  creator,
  @JsonValue('favourite')
  favourite,
  @JsonValue('user')
  user,
  @JsonValue('category')
  category,
  @JsonValue('avatar')
  avatar,
  @JsonValue('unknown')
  unknown,
}
