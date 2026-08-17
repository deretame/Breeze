export type ImageData = {
  id: string;
  name: string;
  url: string;
  extern: Record<string, unknown>;
};

export type ComicCardData = {
  id: string;
  title: string;
  cover: string;
  coverImage: ImageData;
  author: string;
  description: string;
  raw: Record<string, unknown>;
};

export type ChapterData = {
  id: string;
  requestId: string;
  logicalKey: string;
  storageChapterId: string;
  name: string;
  order: number;
};

export type ReaderPageData = {
  id: string;
  name: string;
  url: string;
  extern: Record<string, unknown>;
};

export type ReaderSnapshotData = {
  comicTitle: string;
  comicCover: ImageData;
  chapter: ChapterData;
  chapters: ChapterData[];
  pages: ReaderPageData[];
};

export function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function asList(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function text(value: unknown, fallback = '') {
  return typeof value === 'string' || typeof value === 'number'
    ? String(value)
    : fallback;
}

function displayText(value: unknown): string {
  const direct = text(value).trim();
  if (direct) return direct;
  if (Array.isArray(value)) {
    return value
      .map((item) => displayText(item))
      .filter(Boolean)
      .join(', ');
  }
  if (!value || typeof value !== 'object') return '';
  const record = asRecord(value);
  for (const key of ['name', 'title', 'label', 'value', 'text']) {
    const candidate = displayText(record[key]);
    if (candidate) return candidate;
  }
  return '';
}

function firstText(record: Record<string, unknown>, keys: string[], fallback = '') {
  for (const key of keys) {
    const value = displayText(record[key]);
    if (value.trim()) return value;
  }
  return fallback;
}

export function normalizeImage(value: unknown): ImageData {
  if (typeof value === 'string') {
    return { id: '', name: '', url: value, extern: {} };
  }
  const record = asRecord(value);
  return {
    id: firstText(record, ['id']),
    name: firstText(record, ['name', 'originalName']),
    url: firstText(record, ['url', 'fileServer', 'src', 'path']),
    extern: asRecord(record.extern),
  };
}

function firstImage(record: Record<string, unknown>, keys: string[]): ImageData {
  for (const key of keys) {
    const image = normalizeImage(record[key]);
    if (image.url) return image;
  }
  return normalizeImage('');
}

function normalizeChapter(value: unknown, index: number): ChapterData {
  const chapter = asRecord(value);
  const id = firstText(
    chapter,
    ['id', 'chapterId', 'chapter_id', 'requestId', 'logicalKey', 'storageChapterId'],
    String(index + 1),
  );
  return {
    id,
    requestId: firstText(chapter, ['requestId', 'request_id'], id),
    logicalKey: firstText(chapter, ['logicalKey', 'logical_key'], id),
    storageChapterId: firstText(
      chapter,
      ['storageChapterId', 'storage_chapter_id'],
      id,
    ),
    name: firstText(chapter, ['name', 'title', 'epName'], `第 ${index + 1} 话`),
    order: Number(chapter.order ?? index + 1) || index + 1,
  };
}

export function normalizeSearchPage(response: Record<string, unknown>) {
  const data = asRecord(response.data);
  const items = asList(
    data.items ??
      data.comics ??
      data.results ??
      response.items ??
      response.comics ??
      response.results ??
      data.list ??
      response.list,
  );
  const normalizedItems = items.map((value, index) => {
    const item = asRecord(value);
    const id = firstText(item, ['id', 'comicId', 'comic_id'], `item-${index + 1}`);
    const coverImage = firstImage(item, [
      'cover',
      'coverImage',
      'image',
      'thumbnail',
      'url',
    ]);
    return {
      id,
      title: firstText(item, ['title', 'name', 'comicName'], `未命名漫画 ${index + 1}`),
      cover: coverImage.url,
      coverImage,
      author: firstText(item, ['author', 'artist', 'creator', '作者'], '未知作者'),
      description: firstText(item, ['description', 'desc', '简介']),
      raw: item,
    } satisfies ComicCardData;
  });
  const paging = asRecord(data.paging ?? response.paging);
  const currentPage = Number(paging.page ?? 1) || 1;
  const pages = Number(paging.pages ?? 0) || 0;
  const hasReachedMax =
    paging.hasReachedMax === true ||
    paging.has_reached_max === true ||
    (pages > 0 && currentPage >= pages);
  return {
    items: normalizedItems,
    hasMore: !hasReachedMax && normalizedItems.length > 0,
  };
}

export function normalizeSearch(response: Record<string, unknown>): ComicCardData[] {
  return normalizeSearchPage(response).items;
}

export function normalizeDetail(response: Record<string, unknown>) {
  const data = asRecord(response.data);
  const normal = asRecord(data.normal ?? response.normal);
  const info = asRecord(
    normal.comicInfo ?? normal.comic ?? data.comic ?? response.comic,
  );
  const chaptersValue =
    normal.eps ??
    normal.chapters ??
    info.chapters ??
    data.chapters ??
    response.chapters;
  const chapters = asList(chaptersValue).map(normalizeChapter);
  const coverImage = firstImage(info, ['cover', 'coverImage', 'image', 'thumbnail']);
  return {
    id: firstText(info, ['id', 'comicId'], text(response.comicId)),
    title: firstText(info, ['title', 'name'], '未命名漫画'),
    cover: coverImage.url,
    coverImage,
    author: firstText(info, ['author', 'artist', 'creator'], '未知作者'),
    description: firstText(info, ['description', 'desc', '简介'], '暂无简介'),
    chapters,
  };
}

export function normalizeReaderPages(
  response: Record<string, unknown>,
): ReaderPageData[] {
  const data = asRecord(response.data);
  const chapter = asRecord(data.chapter ?? response.chapter);
  const pages = asList(chapter.pages ?? chapter.docs ?? data.pages ?? response.pages);
  return pages
    .map((value, index) => {
      const page = asRecord(value);
      const image = normalizeImage(value);
      return {
        id: firstText(page, ['id'], image.id || String(index + 1)),
        name: firstText(
          page,
          ['name', 'originalName'],
          image.name || `第 ${index + 1} 页`,
        ),
        url: image.url,
        extern: image.extern,
      } satisfies ReaderPageData;
    })
    .filter((page) => page.url.length > 0);
}

export function normalizeReaderSnapshot(
  response: Record<string, unknown>,
): ReaderSnapshotData {
  const data = asRecord(response.data);
  const comic = asRecord(data.comic ?? response.comic);
  const chapter = normalizeChapter(data.chapter ?? response.chapter, 0);
  const chapters = asList(data.chapters ?? response.chapters).map(normalizeChapter);
  const normalizedChapters = chapters.length ? chapters : [chapter];
  return {
    comicTitle: firstText(comic, ['title', 'name'], '未命名漫画'),
    comicCover: firstImage(comic, ['cover', 'coverImage', 'image']),
    chapter,
    chapters: normalizedChapters,
    pages: normalizeReaderPages(response),
  };
}
