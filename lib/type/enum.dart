import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum RealSrResolutionThreshold {
  @JsonValue('p540')
  p540,
  @JsonValue('p720')
  p720,
  @JsonValue('p1080')
  p1080,
  @JsonValue('p1440')
  p1440,
  @JsonValue('p2160')
  p2160;

  int get maxWidth => switch (this) {
    p540 => 540,
    p720 => 720,
    p1080 => 1080,
    p1440 => 1440,
    p2160 => 2160,
  };

  String get label => switch (this) {
    p540 => '< 540p',
    p720 => '< 720p',
    p1080 => '< 1080p',
    p1440 => '< 1440p',
    p2160 => '< 2160p',
  };
}

@JsonEnum()
enum RealSrNoiseLevel {
  @JsonValue('conservative')
  conservative(-1),
  @JsonValue('noDenoise')
  noDenoise(0),
  @JsonValue('denoise1x')
  denoise1x(1),
  @JsonValue('denoise2x')
  denoise2x(2),
  @JsonValue('denoise3x')
  denoise3x(3);

  final int value;

  const RealSrNoiseLevel(this.value);

  String get label => switch (this) {
    conservative => '保守',
    noDenoise => '无降噪',
    denoise1x => '降噪 1x',
    denoise2x => '降噪 2x',
    denoise3x => '降噪 3x',
  };
}

@JsonEnum()
enum ExportType {
  @JsonValue('zip')
  zip,
  @JsonValue('folder')
  folder,
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
  @JsonValue('page')
  page,
  @JsonValue('unknown')
  unknown,
}
