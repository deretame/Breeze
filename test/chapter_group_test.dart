import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/comic_info/method/chapter_group.dart';

void main() {
  test('顶层 groupTitle 去空白，缺省为空=不分组', () {
    expect(resolveChapterGroupTitle(groupTitle: '连载'), '连载');
    expect(resolveChapterGroupTitle(groupTitle: ' 单行本 '), '单行本');
    expect(resolveChapterGroupTitle(), '');
  });

  test('展示标题只 strip 本组前缀', () {
    expect(
      chapterDisplayName(name: '连载—第1话', groupTitle: '连载'),
      '第1话',
    );
    // 别的组的前缀不动。
    expect(
      chapterDisplayName(name: '单行本—第1卷', groupTitle: '连载'),
      '单行本—第1卷',
    );
    // 半角 - 不是分隔符，不动。
    expect(
      chapterDisplayName(name: '连载-第1话', groupTitle: '连载'),
      '连载-第1话',
    );
    expect(chapterDisplayName(name: '第1话', groupTitle: ''), '第1话');
  });

  test('带组消歧义标题：有组补组、无组原样、已有前缀不重复', () {
    expect(chapterQualifiedName(name: '3卷', groupTitle: '单行本'), '单行本—3卷');
    expect(
      chapterQualifiedName(name: '单行本—3卷', groupTitle: '单行本'),
      '单行本—3卷',
    );
    expect(chapterQualifiedName(name: '第1话', groupTitle: ''), '第1话');
  });

  test('空组显示未分组文案', () {
    expect(chapterGroupDisplayTitle('', '未分组'), '未分组');
    expect(chapterGroupDisplayTitle('连载', '未分组'), '连载');
  });

  test('分组保持元素顺序且组按首次出现排序', () {
    final groups = groupChaptersByTitle<String>(
      const ['a1', 'b1', 'a2', 'c1', 'b2'],
      (item) => item[0],
    );
    expect(groups.map((g) => g.title), ['a', 'b', 'c']);
    expect(groups[0].items, ['a1', 'a2']);
    expect(groups[1].items, ['b1', 'b2']);
    expect(groups[2].items, ['c1']);
  });

  test('空标题自成一组（调用方显示未分组）', () {
    final groups = groupChaptersByTitle<String>(const ['x', 'y'], (_) => '');
    expect(groups.length, 1);
    expect(groups.single.title, '');
    expect(groups.single.items, ['x', 'y']);
  });
}
