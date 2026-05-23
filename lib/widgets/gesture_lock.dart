import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<List<int>?> showGesturePasswordSetupDialog(
  BuildContext context, {
  required String title,
  required String confirmTitle,
}) {
  return showDialog<List<int>>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _GesturePasswordSetupDialog(title: title, confirmTitle: confirmTitle),
  );
}

Future<GestureUnlockResult?> showGestureUnlockDialog(
  BuildContext context, {
  required String expectedHash,
  String title = '手势解锁',
  String hint = '请绘制手势密码',
  bool showForgotPassword = false,
}) {
  return showDialog<GestureUnlockResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _GestureUnlockDialog(
      expectedHash: expectedHash,
      title: title,
      hint: hint,
      showForgotPassword: showForgotPassword,
    ),
  );
}

String hashGesturePattern(List<int> pattern) {
  return sha256.convert(utf8.encode(pattern.join('-'))).toString();
}

String hashPinCode(String pin) {
  return sha256.convert(utf8.encode('pin:$pin')).toString();
}

Future<String?> showPinCodeSetupDialog(
  BuildContext context, {
  required String title,
  required String confirmTitle,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _PinCodeSetupDialog(title: title, confirmTitle: confirmTitle),
  );
}

Future<bool?> showPinVerifyDialog(
  BuildContext context, {
  required String expectedHash,
  String title = '输入 PIN',
  String hint = '请输入重置 PIN',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _PinVerifyDialog(expectedHash: expectedHash, title: title, hint: hint),
  );
}

enum GestureUnlockResult { success, forgotPassword }

class AppGesturePatternBoard extends StatefulWidget {
  const AppGesturePatternBoard({super.key, required this.onCompleted});

  final ValueChanged<List<int>> onCompleted;

  @override
  State<AppGesturePatternBoard> createState() => _AppGesturePatternBoardState();
}

class _AppGesturePatternBoardState extends State<AppGesturePatternBoard> {
  final GlobalKey _boardKey = GlobalKey();
  final List<int> _selected = <int>[];
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanStart: (details) {
        _selected.clear();
        _dragging = true;
        _trySelect(details.localPosition);
        setState(() {});
      },
      onPanUpdate: (details) {
        if (!_dragging) {
          return;
        }
        _trySelect(details.localPosition);
        setState(() {});
      },
      onPanEnd: (_) => _finish(),
      onPanCancel: _finish,
      child: RepaintBoundary(
        key: _boardKey,
        child: SizedBox(
          width: 240,
          height: 240,
          child: CustomPaint(
            painter: _GesturePatternPainter(
              selected: List<int>.from(_selected),
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _trySelect(Offset position) {
    final size =
        (_boardKey.currentContext?.findRenderObject() as RenderBox?)?.size;
    if (size == null) {
      return;
    }
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;
    final col = (position.dx / cellWidth).floor();
    final row = (position.dy / cellHeight).floor();
    if (col < 0 || col > 2 || row < 0 || row > 2) {
      return;
    }
    final index = row * 3 + col;
    if (_selected.contains(index)) {
      return;
    }
    _selected.add(index);
  }

  void _finish() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final result = List<int>.from(_selected);
    _selected.clear();
    setState(() {});
    if (result.isNotEmpty) {
      widget.onCompleted(result);
    }
  }
}

class _GesturePasswordSetupDialog extends StatefulWidget {
  const _GesturePasswordSetupDialog({
    required this.title,
    required this.confirmTitle,
  });

  final String title;
  final String confirmTitle;

  @override
  State<_GesturePasswordSetupDialog> createState() =>
      _GesturePasswordSetupDialogState();
}

class _GesturePasswordSetupDialogState
    extends State<_GesturePasswordSetupDialog> {
  List<int>? _firstPattern;
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    final title = _firstPattern == null ? widget.title : widget.confirmTitle;
    final hint = _firstPattern == null ? '请连接至少 4 个点' : '请再次绘制相同手势';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            AppGesturePatternBoard(onCompleted: _handleCompleted),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                _errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  void _handleCompleted(List<int> pattern) {
    if (pattern.length < 4) {
      setState(() {
        _errorText = '至少连接 4 个点';
      });
      return;
    }

    if (_firstPattern == null) {
      setState(() {
        _firstPattern = pattern;
        _errorText = '';
      });
      return;
    }

    if (listEquals(_firstPattern, pattern)) {
      Navigator.pop(context, pattern);
      return;
    }

    setState(() {
      _firstPattern = null;
      _errorText = '两次手势不一致，请重新设置';
    });
  }
}

class _GestureUnlockDialog extends StatefulWidget {
  const _GestureUnlockDialog({
    required this.expectedHash,
    required this.title,
    required this.hint,
    required this.showForgotPassword,
  });

  final String expectedHash;
  final String title;
  final String hint;
  final bool showForgotPassword;

  @override
  State<_GestureUnlockDialog> createState() => _GestureUnlockDialogState();
}

class _GestureUnlockDialogState extends State<_GestureUnlockDialog> {
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.hint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            AppGesturePatternBoard(onCompleted: _handleCompleted),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                _errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.showForgotPassword)
          TextButton(
            onPressed: () {
              Navigator.pop(context, GestureUnlockResult.forgotPassword);
            },
            child: const Text('忘记密码'),
          ),
      ],
    );
  }

  void _handleCompleted(List<int> pattern) {
    if (hashGesturePattern(pattern) == widget.expectedHash) {
      Navigator.pop(context, GestureUnlockResult.success);
      return;
    }
    setState(() {
      _errorText = '手势密码不正确，请重试';
    });
  }
}

class _PinCodeSetupDialog extends StatefulWidget {
  const _PinCodeSetupDialog({required this.title, required this.confirmTitle});

  final String title;
  final String confirmTitle;

  @override
  State<_PinCodeSetupDialog> createState() => _PinCodeSetupDialogState();
}

class _PinCodeSetupDialogState extends State<_PinCodeSetupDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _errorText = '';
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '重置 PIN',
                hintText: '至少 4 位数字',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.confirmTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "PIN 可用于重置手势密码，遗忘手势密码与 PIN 后将无法进入软件，请妥善保管 Pin",
              softWrap: true,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                _errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }

  void _submit() {
    final pin = _controller.text.trim();
    final confirmPin = _confirmController.text.trim();
    if (!RegExp(r'^\d{4,}$').hasMatch(pin)) {
      setState(() {
        _errorText = 'PIN 需至少 4 位数字';
      });
      return;
    }
    if (pin != confirmPin) {
      setState(() {
        _errorText = '两次输入的 PIN 不一致';
      });
      return;
    }
    Navigator.pop(context, pin);
  }
}

class _PinVerifyDialog extends StatefulWidget {
  const _PinVerifyDialog({
    required this.expectedHash,
    required this.title,
    required this.hint,
  });

  final String expectedHash;
  final String title;
  final String hint;

  @override
  State<_PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<_PinVerifyDialog> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.hint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'PIN',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                _errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (hashPinCode(pin) == widget.expectedHash) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _errorText = 'PIN 不正确，请重试';
    });
  }
}

class _GesturePatternPainter extends CustomPainter {
  const _GesturePatternPainter({
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<int> selected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final points = _buildPoints(size);
    final linePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < selected.length; i++) {
      canvas.drawLine(points[selected[i - 1]], points[selected[i]], linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      final isSelected = selected.contains(i);
      final fillPaint = Paint()
        ..color = isSelected
            ? activeColor.withValues(alpha: 0.18)
            : Colors.transparent
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = isSelected ? activeColor : inactiveColor
        ..strokeWidth = isSelected ? 3 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(points[i], 18, fillPaint);
      canvas.drawCircle(points[i], 18, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GesturePatternPainter oldDelegate) {
    return !listEquals(oldDelegate.selected, selected) ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }

  List<Offset> _buildPoints(Size size) {
    final stepX = size.width / 3;
    final stepY = size.height / 3;
    return List<Offset>.generate(9, (index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(stepX * (col + 0.5), stepY * (row + 0.5));
    });
  }
}
