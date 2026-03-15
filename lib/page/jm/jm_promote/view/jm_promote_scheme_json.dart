const String jmPromotePageSchemeJson = '''
{
  "schemaVersion": "1.0.0",
  "statusViews": [
    {
      "status": "initial",
      "widget": "centerLoading"
    },
    {
      "status": "failure",
      "widget": "errorView",
      "errorTemplate": "{error}\\n加载失败，请重试。"
    },
    {
      "statuses": [
        "success",
        "loadingMore",
        "loadingMoreFailure"
      ],
      "widget": "contentScrollView"
    }
  ],
  "contentScrollView": {
    "type": "customScrollView",
    "slivers": [
      {
        "type": "promoteList"
      },
      {
        "type": "suggestionHeader",
        "visibleWhen": "hasSuggestions",
        "title": "最新上传"
      },
      {
        "type": "suggestionGrid",
        "visibleWhen": "hasSuggestions"
      },
      {
        "type": "loadingMoreIndicator",
        "visibleWhen": "isLoadingMore"
      },
      {
        "type": "loadingMoreRetry",
        "visibleWhen": "isLoadingMoreFailure"
      }
    ]
  }
}
''';
