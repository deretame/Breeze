import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/plugin_home/plugin_home_bundle.dart';

void main() {
  group('PluginHomeBundle.fromResponse', () {
    test('parses scene tab and fills missing source', () {
      final bundle = PluginHomeBundle.fromResponse({
        'data': {
          'tabs': [
            {
              'id': 'ranking',
              'title': '排行榜',
              'scene': {
                'title': '排行榜',
                'body': {
                  'type': 'pluginPagedComicList',
                  'request': {'fnPath': 'getRankingData', 'extern': {}},
                },
                'filter': {'fnPath': 'getRankingFilterBundle'},
              },
            },
          ],
        },
      }, 'plugin-1');

      expect(bundle.tabs, hasLength(1));
      final tab = bundle.tabs.first;
      expect(tab.id, 'ranking');
      expect(tab.scene, isNotNull);
      expect(tab.scene!.from, 'plugin-1');
      expect(tab.scene!.body.request!.fnPath, 'getRankingData');
    });

    test('unwraps type-wrapped header actions for router', () {
      final bundle = PluginHomeBundle.fromResponse({
        'data': {
          'tabs': [
            {
              'id': 'hotSearch',
              'title': '热搜',
              'page': {
                'scheme': {'type': 'page'},
                'data': {'items': []},
              },
              'header': {
                'actions': [
                  {
                    'id': 'hotSearch',
                    'title': '热搜',
                    'action': {
                      'type': 'openPluginFunction',
                      'payload': {'id': 'hotSearch'},
                    },
                  },
                  {
                    'type': 'openSearch',
                    'payload': {'keyword': ''},
                  },
                ],
              },
            },
          ],
        },
      }, 'plugin-1');

      final tab = bundle.tabs.first;
      expect(tab.isPage, isTrue);
      expect(tab.headerActions, hasLength(2));
      expect(tab.headerActions[0]['type'], 'openPluginFunction');
      expect(tab.headerActions[1]['type'], 'openSearch');
    });

    test('falls back to tab index id and accepts pages key', () {
      final bundle = PluginHomeBundle.fromResponse({
        'data': {
          'pages': [
            {'title': '无名'},
          ],
        },
      }, 'plugin-1');

      expect(bundle.tabs, hasLength(1));
      expect(bundle.tabs.first.id, 'tab_0');
    });

    test('empty tabs yields empty bundle', () {
      final bundle = PluginHomeBundle.fromResponse({'data': {}}, 'plugin-1');
      expect(bundle.isEmpty, isTrue);
    });
  });
}
