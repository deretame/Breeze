enum EventType { none, updateShield, updateSort, refresh, pageSkip, showInfo }

enum SortType { nullValue, dd, da, ld, vd }

class BookShelfEvent {}

class FavoriteEvent {
  EventType type;
  SortType sortType;
  int page;

  FavoriteEvent(this.type, this.sortType, this.page);
}

class HistoryEvent {
  EventType type;
  bool clean;

  HistoryEvent(this.type, this.clean);
}

class DownloadEvent {
  EventType type;
  bool clean;

  DownloadEvent(this.type, this.clean);
}

class JmFavoriteEvent {
  EventType type;

  JmFavoriteEvent(this.type);
}

class JmCloudFavoriteEvent {
  EventType type;

  JmCloudFavoriteEvent(this.type);
}

class TabViewEvent {
  int index;

  TabViewEvent(this.index);
}

class ChangeSortValueEvent {
  String value;

  ChangeSortValueEvent(this.value);
}
