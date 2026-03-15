import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

String buildDownloadQjsRuntimeName({
  required String source,
  required String comicId,
}) {
  final sanitizedComicId = comicId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return 'download_${source}_$sanitizedComicId';
}

Future<void> initDownloadQjsRuntime({
  required String source,
  required String comicId,
}) async {
  final runtimeName = buildDownloadQjsRuntimeName(
    source: source,
    comicId: comicId,
  );

  final bundleKey = source == 'bika' ? 'bikaComic' : 'jmComic';
  final bundleName = source == 'bika' ? 'bikaComic' : 'jmComic';

  try {
    await initQjsRuntimeWithBundle(
      runtimeName: runtimeName,
      bundleName: bundleName,
      bundleJs: getJsBundle(name: bundleKey),
    );
  } catch (e) {
    logger.w('初始化下载专属 QJS 失败: $runtimeName', error: e);
    rethrow;
  }
}

Future<void> dropDownloadQjsRuntime({
  required String source,
  required String comicId,
}) async {
  final runtimeName = buildDownloadQjsRuntimeName(
    source: source,
    comicId: comicId,
  );

  try {
    await qjsDropRuntime(runtimeName: runtimeName);
  } catch (e) {
    logger.w('销毁下载专属 QJS 失败: $runtimeName', error: e);
  }
}
