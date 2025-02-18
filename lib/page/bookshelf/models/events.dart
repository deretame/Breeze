enum EventType { none, updateShield, updateSort, refresh, pageSkip, showInfo }

enum SortType { nullValue, dd, da, ld, vd }

class FavoriteEvent {
  EventType type;
  SortType sortType;
  int page;

  FavoriteEvent(this.type, this.sortType, this.page);
}

class HistoryEvent {
  EventType type;

  HistoryEvent(this.type);
}

class DownloadEvent {
  EventType type;

  DownloadEvent(this.type);
}

class TabViewEvent {
  int index;

  TabViewEvent(this.index);
}

class ChangeSortValueEvent {
  String value;

  ChangeSortValueEvent(this.value);
}
