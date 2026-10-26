import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/login/slider_captcha_dialog.dart';

// 真实编码的小图桩（fake 取题用；手写 base64 会解码失败）。
const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAPklEQVQ4EaXBAQEAAAgCIP1/h382IiiWh2J5KJaHYnkolodieSiWh2J5KJaHYnkolodieSiWh2J5KJaHYnk45eYxwRHD/aMAAAAASUVORK5CYII=';
const _tinyJpegBase64 =
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA0JCgsKCA0LCgsODg0PEyAVExISEyccHhcgLikxMC4pLSwzOko+MzZGNywtQFdBRkxOUlNSMj5aYVpQYEpRUk//2wBDAQ4ODhMREyYVFSZPNS01T09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0//wAARCAAkAEADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDrKKKKACiiigAoorzygD0OivPK7vTv+Qba/wDXFP5CgCxRRRQAUUUUAFeeV6HVf7BZf8+dv/36X/CgDhK7vTv+Qba/9cU/kKPsFl/z52//AH6X/Cp1VUUKoCqBgADAAoAWiiigAooooAKKKKACiiigD//Z';

Map<String, dynamic> _fakeChallenge({String token = 'tok123'}) {
  return {
    'token': token,
    'bg': 'data:image/jpeg;base64,$_tinyJpegBase64',
    'piece': 'data:image/png;base64,$_tinyPngBase64',
    'y': 42,
    'w': 320,
    'h': 180,
    's': 52,
  };
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  String token = 'tok123',
  Future<String> Function({
    required String token,
    required double x,
    required List<SliderTrackPoint> track,
  })? verifyChallenge,
  List<Map<String, dynamic>>? seenCalls,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SliderCaptchaDialog(
          from: 'test',
          createFnPath: 'create',
          verifyFnPath: 'verify',
          createChallenge: () async => _fakeChallenge(token: token),
          verifyChallenge:
              verifyChallenge ??
              ({
                required String token,
                required double x,
                required List<SliderTrackPoint> track,
              }) async {
                seenCalls?.add({'token': token, 'x': x, 'track': track});
                return 'pass-xyz';
              },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
  });
  tearDown(() => LocaleSettings.useDeviceLocale());

  group('SliderCaptchaDialog', () {
    testWidgets('取题后显示拼图与滑杆', (tester) async {
      await _pumpDialog(tester);
      expect(find.text('请完成拼图验证'), findsOneWidget);
      expect(find.text('按住滑块，拖动完成拼图'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('拖动滑杆后 verify 并返回 pass', (tester) async {
      final seenCalls = <Map<String, dynamic>>[];
      String? popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  popped = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => SliderCaptchaDialog(
                      from: 'test',
                      createFnPath: 'create',
                      verifyFnPath: 'verify',
                      createChallenge: () async => _fakeChallenge(),
                      verifyChallenge: ({
                        required String token,
                        required double x,
                        required List<SliderTrackPoint> track,
                      }) async {
                        seenCalls.add({
                          'token': token,
                          'x': x,
                          'track': track,
                        });
                        return 'pass-xyz';
                      },
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // knob 是滑杆上唯一的 ➜ 文本。
      final knob = find.text('➜');
      expect(knob, findsOneWidget);
      await tester.drag(knob, const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(seenCalls, hasLength(1));
      final call = seenCalls.single;
      expect(call['token'], 'tok123');
      // 拖 120 显示像素，显示宽按屏宽算：x 应为正数且小于底图宽。
      expect(call['x'] as double, greaterThan(0));
      expect(call['x'] as double, lessThan(320));
      // 轨迹首点固定 [0,0,0]，至少 3 点。
      final track = call['track'] as List;
      expect(track.length, greaterThanOrEqualTo(3));
      expect(track.first, [0, 0, 0]);
      // verify 成功后 dialog 关闭并返回 pass。
      expect(popped, 'pass-xyz');
      expect(find.text('请完成拼图验证'), findsNothing);
    });

    testWidgets('verify 失败自动换新题', (tester) async {
      var calls = 0;
      await _pumpDialog(
        tester,
        verifyChallenge: ({
          required String token,
          required double x,
          required List<SliderTrackPoint> track,
        }) async {
          calls++;
          throw StateError('驗證失敗,請重試');
        },
      );
      await tester.drag(find.text('➜'), const Offset(120, 0));
      await tester.pumpAndSettle();
      // 失败后换题：dialog 不关闭，仍可再次拖动。
      expect(calls, 1);
      expect(find.text('请完成拼图验证'), findsOneWidget);
      expect(find.text('➜'), findsOneWidget);
    });
  });
}
