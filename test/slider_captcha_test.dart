import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/login/slider_captcha_dialog.dart';

void main() {
  group('SliderChallenge.fromMap', () {
    test('解析 dataURL 图片与逻辑尺寸', () {
      final bgBytes = base64Encode(List<int>.filled(16, 7));
      final pieceBytes = base64Encode(List<int>.filled(8, 3));
      final challenge = SliderChallenge.fromMap({
        'token': 'abc123',
        'bg': 'data:image/jpeg;base64,$bgBytes',
        'piece': 'data:image/png;base64,$pieceBytes',
        'y': 42,
        'w': 320,
        'h': 180,
        's': 52,
      });
      expect(challenge.token, 'abc123');
      expect(challenge.bg, base64Decode(bgBytes));
      expect(challenge.piece, base64Decode(pieceBytes));
      expect(challenge.pieceY, 42);
      expect(challenge.imageW, 320);
      expect(challenge.imageH, 180);
      expect(challenge.pieceSize, 52);
    });

    test('兼容裸 base64（无 dataURL 前缀）', () {
      final bgBytes = base64Encode(List<int>.filled(16, 7));
      final challenge = SliderChallenge.fromMap({
        'token': 't',
        'bg': bgBytes,
        'piece': base64Encode(List<int>.filled(8, 3)),
        'y': '24',
        'w': '320',
        'h': '180',
        's': '52',
      });
      expect(challenge.bg, base64Decode(bgBytes));
      expect(challenge.pieceY, 24);
    });

    test('缺 token 时抛错', () {
      expect(
        () => SliderChallenge.fromMap({
          'bg': base64Encode([1, 2]),
          'piece': base64Encode([3]),
        }),
        throwsStateError,
      );
    });
  });

  group('buildSliderTrack', () {
    test('首点固定 [0,0,0]，终点 x 等于目标', () {
      final track = buildSliderTrack(targetX: 257, durationMs: 600);
      expect(track.first, [0, 0, 0]);
      expect(track.length, greaterThan(3));
      final last = track.last;
      expect(last[1], 257);
      // 时间单调递增。
      for (var i = 1; i < track.length; i++) {
        expect(track[i][0], greaterThan(track[i - 1][0]));
      }
      // x 单调不减（easeInOut 无回退）。
      for (var i = 1; i < track.length; i++) {
        expect(track[i][1], greaterThanOrEqualTo(track[i - 1][1]));
      }
    });

    test('同一种子结果稳定', () {
      final a = buildSliderTrack(targetX: 100, durationMs: 500, seed: 7);
      final b = buildSliderTrack(targetX: 100, durationMs: 500, seed: 7);
      expect(a, b);
    });
  });
}
