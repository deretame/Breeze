enum EventType {
  none,
  updateShield,
  updateSort,
  refresh,
  pageSkip,
  showInfo,
}

enum SortType { nullValue, dd, da, ld, vd }

class FavoriteEvent {
  EventType type;
  SortType sortType;
  int page;

  FavoriteEvent(this.type, this.sortType, this.page);
}

class HistoryEvent {
  EventType type;
  SortType sortType;

  HistoryEvent(this.type, this.sortType);
}

class DownloadEvent {
  EventType type;
  SortType sortType;

  DownloadEvent(this.type, this.sortType);
}

class TabViewEvent {
  int index;

  TabViewEvent(this.index);
}
