import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/widgets/comic_simplify_entry/detail_columns.dart';

void main() {
  test('detailColumnCount maps width to 1-4 columns', () {
    expect(detailColumnCount(300), 1);
    expect(detailColumnCount(340), 1);
    expect(detailColumnCount(690), 2);
    expect(detailColumnCount(1040), 3);
    expect(detailColumnCount(1390), 4);
    expect(detailColumnCount(5000), 4);
  });

  test('detailColumnItemCount covers every item exactly once', () {
    for (final total in [0, 1, 2, 3, 5, 7, 8, 100, 101]) {
      for (var columns = 1; columns <= 4; columns++) {
        var covered = 0;
        int? prev;
        for (var c = 0; c < columns; c++) {
          final count = detailColumnItemCount(total, columns, c);
          covered += count;
          if (prev != null) {
            // 交错分列：前面的列行数 >= 后面的列，至多多 1 行。
            expect(count, lessThanOrEqualTo(prev));
            expect(prev - count, lessThanOrEqualTo(1));
          }
          prev = count;
          for (var row = 0; row < count; row++) {
            expect(row * columns + c, lessThan(total));
          }
        }
        expect(covered, total);
      }
    }
  });
}
