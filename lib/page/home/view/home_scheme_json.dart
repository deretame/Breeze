const String homePageSchemeJson = '''
{
  "schemaVersion": "1.0.0",
  "modes": {
    "bika": {
      "comicChoice": 1,
      "title": "哔咔漫画",
      "body": { "listKey": "bika_list" },
      "sections": [
        { "type": "bikaKeyword" },
        { "type": "bikaCategory" }
      ],
      "fab": {
        "enabled": true,
        "icon": "compare_arrows"
      }
    },
    "jm": {
      "comicChoice": 2,
      "title": "禁漫首页",
      "body": { "listKey": "jm_promote" },
      "sections": [
        { "type": "jmPromote" }
      ],
      "fab": {
        "enabled": true,
        "icon": "compare_arrows"
      }
    }
  }
}
''';
