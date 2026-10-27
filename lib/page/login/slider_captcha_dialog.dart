import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/main.dart';

/// 拼图滑块题目（插件 createFnPath 返回）。
class SliderChallenge {
  const SliderChallenge({
    required this.token,
    required this.bg,
    required this.piece,
    required this.pieceY,
    required this.imageW,
    required this.imageH,
    required this.pieceSize,
  });

  final String token;
  final Uint8List bg;
  final Uint8List piece;

  /// 拼块在底图坐标系下的垂直位置（逻辑像素）。
  final double pieceY;

  /// 底图逻辑尺寸（网页端固定 320x180）。
  final double imageW;
  final double imageH;

  /// 拼块边长（逻辑像素，服务端下发 s）。
  final double pieceSize;

  static Uint8List _decodeImage(dynamic value) {
    var raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) throw StateError('empty slider image');
    final comma = raw.indexOf(',');
    if (comma >= 0 && raw.substring(0, comma).contains('base64')) {
      raw = raw.substring(comma + 1);
    }
    final bytes = base64Decode(raw.replaceAll(RegExp(r'\s'), ''));
    if (bytes.isEmpty) throw StateError('empty slider image');
    return bytes;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory SliderChallenge.fromMap(Map<String, dynamic> map) {
    final token = map['token']?.toString().trim() ?? '';
    if (token.isEmpty) throw StateError('missing slider token');
    final imageW = _asDouble(map['w'], 320);
    final imageH = _asDouble(map['h'], 180);
    if (imageW <= 0 || imageH <= 0) throw StateError('bad slider size');
    return SliderChallenge(
      token: token,
      bg: _decodeImage(map['bg']),
      piece: _decodeImage(map['piece']),
      pieceY: _asDouble(map['y'], 0),
      imageW: imageW,
      imageH: imageH,
      pieceSize: _asDouble(map['s'], 52),
    );
  }
}

/// 拖动轨迹点：`[t, x, y]`（相对毫秒，底图坐标系位移，纵向位移）。
typedef SliderTrackPoint = List<num>;

/// 生成拟人拖动轨迹（首点固定 `[0,0,0]`，与网页端 slider-captcha.js 一致）。
/// 供单测/无手势场景使用；真实拖动由 [_SliderCaptchaDialogState] 逐点记录。
List<SliderTrackPoint> buildSliderTrack({
  required double targetX,
  required int durationMs,
  int? seed,
}) {
  final track = <SliderTrackPoint>[
    [0, 0, 0],
  ];
  var state = seed ?? 0x2F6E2B1;
  double nextRandom() {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state / 0x7fffffff;
  }

  var elapsed = 0;
  while (true) {
    elapsed += 10 + (nextRandom() * 22).round();
    final p = (elapsed / durationMs).clamp(0.0, 1.0);
    // easeInOutQuad：加速起步、减速到位，和人手拖动一致。
    final ease = p < 0.5 ? 2 * p * p : 1 - ((-2 * p + 2) * (-2 * p + 2)) / 2;
    final x = (ease * targetX * 10).round() / 10;
    final y = (600 + nextRandom() * 8).round();
    track.add([elapsed, x, y]);
    if (p >= 1) break;
  }
  return track;
}

/// 纯 Flutter 拼图滑块弹窗：取题 → 拖拼块 → 调插件 verify，成功返回一次性 pass。
/// 无 WebView；轨迹格式与网页端 `slider-captcha.js` 一致（`[t,x,y][]`）。
///
/// 网络层可注入（widget test 用 fake 覆盖拖动→verify→pop 全交互）；
/// 缺省走插件 `createFnPath`/`verifyFnPath`。
class SliderCaptchaDialog extends StatefulWidget {
  const SliderCaptchaDialog({
    super.key,
    required this.from,
    required this.createFnPath,
    required this.verifyFnPath,
    this.createChallenge,
    this.verifyChallenge,
    this.refreshText = '',
    this.values = const <String, dynamic>{},
  });

  final String from;
  final String createFnPath;
  final String verifyFnPath;

  /// 换题按钮文案（插件 slider.refreshText），空时用默认文案。
  final String refreshText;

  /// 取题时透传的当前表单值（账号绑定的站用它取题；不绑定的站忽略）。
  /// 缺省走插件时经 `core.values` 发给 createFnPath。
  final Map<String, dynamic> values;

  /// 取题：返回插件 create 原始 map（含 token/bg/piece/y/w/h/s）。
  final Future<Map<String, dynamic>> Function()? createChallenge;

  /// 验题：入参 token/x/track（见 [SliderTrackPoint]），返回 pass。
  final Future<String> Function({
    required String token,
    required double x,
    required List<SliderTrackPoint> track,
  })?
  verifyChallenge;

  /// 弹出拼图对话框，验证通过返回 `pass`，用户取消返回 null。
  static Future<String?> show(
    BuildContext context, {
    required String from,
    required String createFnPath,
    required String verifyFnPath,
    String refreshText = '',
    Map<String, dynamic> values = const <String, dynamic>{},
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SliderCaptchaDialog(
        from: from,
        createFnPath: createFnPath,
        verifyFnPath: verifyFnPath,
        refreshText: refreshText,
        values: values,
      ),
    );
  }

  @override
  State<SliderCaptchaDialog> createState() => _SliderCaptchaDialogState();
}

enum _SliderPhase { loading, ready, verifying, failed }

class _SliderCaptchaDialogState extends State<SliderCaptchaDialog> {
  static const double _knobWidth = 52;
  static const double _barHeight = 40;

  SliderChallenge? _challenge;
  _SliderPhase _phase = _SliderPhase.loading;
  String _error = '';

  // 拖动状态（显示像素）。
  double _knobDx = 0;
  bool _dragging = false;
  double _dragStartX = 0;
  int _dragStartT = 0;
  final List<SliderTrackPoint> _track = [];
  double _lastClientY = 0;

  Future<void> _load({bool first = false}) {
    if (!first && _phase == _SliderPhase.loading) return Future.value();
    setState(() {
      _phase = _SliderPhase.loading;
      _error = '';
      _knobDx = 0;
      _track.clear();
    });
    return _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    try {
      final Map<String, dynamic> result;
      if (widget.createChallenge != null) {
        result = await widget.createChallenge!();
      } else {
        result = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: widget.createFnPath,
          core: {...widget.values, 'values': widget.values},
          extern: const <String, dynamic>{},
        );
      }
      if (!mounted) return;
      setState(() {
        _challenge = SliderChallenge.fromMap(result);
        _phase = _SliderPhase.ready;
        _knobDx = 0;
        _track.clear();
      });
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      setState(() {
        _phase = _SliderPhase.failed;
        _error = normalizeSearchErrorMessage(e);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  /// 内容区实际渲染宽度（bg 图实测，替代屏宽公式预估）。
  /// AlertDialog content 有 24px 内边距，直接按屏宽算会在窄屏下偏大，
  /// 导致拼块显示位置与上报 x 系统性偏大约 8%。
  /// 注意：content 包在 IntrinsicWidth 里，LayoutBuilder 会直接抛异常，
  /// 这里用 GlobalKey 在 build 后测 bg 图实际尺寸。
  final GlobalKey _imageKey = GlobalKey();
  double? _renderWidth;

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      final w = box?.hasSize == true ? box!.size.width : 0.0;
      if (w > 0 && (_renderWidth == null || (_renderWidth! - w).abs() > 0.5)) {
        setState(() {
          _renderWidth = w;
        });
      }
    });
  }

  double get _displayWidth {
    final measured = _renderWidth;
    if (measured != null && measured > 0) return measured;
    final query = MediaQuery.maybeOf(context);
    final screenWidth = query?.size.width ?? 360;
    // 实测值就绪前回退屏宽公式（与网页端一致：min(320, max(240, 屏宽-60))）。
    final target = (screenWidth - 60 - 48).clamp(240.0, 320.0);
    return target;
  }

  double get _scale {
    final challenge = _challenge;
    if (challenge == null) return 1;
    return _displayWidth / challenge.imageW;
  }

  double get _maxMove {
    final challenge = _challenge;
    if (challenge == null) return 0;
    return _displayWidth - challenge.pieceSize * _scale;
  }

  void _onDragStart(DragStartDetails details) {
    if (_phase != _SliderPhase.ready || _challenge == null) return;
    setState(() {
      _dragging = true;
      _dragStartX = details.globalPosition.dx;
      _dragStartT = DateTime.now().millisecondsSinceEpoch;
      _lastClientY = details.globalPosition.dy;
      _track
        ..clear()
        ..add([0, 0, 0]);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _phase != _SliderPhase.ready) return;
    final dx = (details.globalPosition.dx - _dragStartX).clamp(0.0, _maxMove);
    final elapsed = DateTime.now().millisecondsSinceEpoch - _dragStartT;
    _lastClientY = details.globalPosition.dy;
    // 网页端记的是底图坐标系位移（dx/k）与 clientY。
    final logicX = (dx / _scale * 10).round() / 10;
    setState(() {
      _knobDx = dx;
      _track.add([elapsed, logicX, _lastClientY.round()]);
      if (_track.length > 500) _track.removeAt(1);
    });
  }

  Future<void> _onDragEnd() async {
    if (!_dragging) return;
    setState(() => _dragging = false);
    if (_phase != _SliderPhase.ready || _challenge == null) return;
    if (_track.length < 3) {
      setState(() => _knobDx = 0);
      return;
    }
    final challenge = _challenge!;
    // 与网页端一致：x 为底图坐标系 knob 位移，保留 1 位小数。
    final x = (_knobDx / _scale * 10).round() / 10;
    setState(() => _phase = _SliderPhase.verifying);
    try {
      final String pass;
      if (widget.verifyChallenge != null) {
        pass = await widget.verifyChallenge!(
          token: challenge.token,
          x: x,
          track: _track.map((p) => [p[0], p[1], p[2]]).toList(),
        );
      } else {
        final result = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: widget.verifyFnPath,
          core: {
            'token': challenge.token,
            'x': x,
            'track': _track.map((p) => [p[0], p[1], p[2]]).toList(),
          },
          extern: const <String, dynamic>{},
        );
        pass = result['pass']?.toString().trim() ?? '';
      }
      if (pass.trim().isEmpty) throw StateError(t.login.sliderFailed);
      if (!mounted) return;
      Navigator.of(context).pop(pass);
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      // 一次一题：失败即换新题（旧 token 已作废）。
      setState(() {
        _phase = _SliderPhase.loading;
        _error = '';
        _knobDx = 0;
        _track.clear();
      });
      await _loadChallenge();
      if (mounted && _phase == _SliderPhase.failed) {
        // 取题也失败时保留错误展示。
        return;
      }
      if (mounted) {
        setState(() => _error = normalizeSearchErrorMessage(e));
        if (_phase == _SliderPhase.ready) {
          // 新题已就绪，仅提示上次失败原因。
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(t.login.sliderFailed)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = _displayWidth;
    final challenge = _challenge;
    final height = challenge == null
        ? width * 180 / 320
        : width * challenge.imageH / challenge.imageW;
    // content 不定宽：占满 dialog 可用宽；bg 图挂 key 实测回写 _renderWidth，
    // 下一帧起拼图/滑杆/上报 x 全按实测缩放算。首帧 width 用屏宽公式回退。
    _scheduleMeasure();
    return AlertDialog(
      title: Text(t.login.sliderTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImage(width, height),
          const SizedBox(height: 10),
          _buildBar(),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _phase == _SliderPhase.verifying
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed:
              (_phase == _SliderPhase.loading ||
                  _phase == _SliderPhase.verifying)
              ? null
              : () => _load(),
          child: Text(
            widget.refreshText.trim().isNotEmpty
                ? widget.refreshText.trim()
                : t.login.retry,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(double width, double height) {
    final challenge = _challenge;
    // 宽不定死：跟 content 可用宽走（实测值），窄屏 dialog 内边距压缩时不错位。
    if (_phase == _SliderPhase.loading || challenge == null) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Center(child: Text(t.login.sliderLoading)),
      );
    }
    if (_phase == _SliderPhase.failed && _error.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Center(child: Text(t.login.sliderLoadFailed)),
      );
    }
    final pieceDisplay = challenge.pieceSize * _scale;
    return Container(
      key: _imageKey,
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.memory(
            challenge.bg,
            width: width,
            height: height,
            fit: BoxFit.fill,
          ),
          Positioned(
            left: _knobDx,
            top: challenge.pieceY * _scale,
            child: Image.memory(
              challenge.piece,
              width: pieceDisplay,
              height: pieceDisplay,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar() {
    final busy =
        _phase == _SliderPhase.loading || _phase == _SliderPhase.verifying;
    final ready = _phase == _SliderPhase.ready && !busy;
    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _knobDx + _knobWidth / 2,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: Text(
              busy ? t.login.sliderVerifying : t.login.sliderHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            left: _knobDx,
            top: 0,
            child: GestureDetector(
              onHorizontalDragStart: ready ? _onDragStart : null,
              onHorizontalDragUpdate: ready ? _onDragUpdate : null,
              onHorizontalDragEnd: ready ? (_) => _onDragEnd() : null,
              onHorizontalDragCancel: ready ? () => _onDragEnd() : null,
              child: Container(
                width: _knobWidth,
                height: _barHeight,
                decoration: BoxDecoration(
                  color: _phase == _SliderPhase.verifying
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: _phase == _SliderPhase.verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '➜',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
