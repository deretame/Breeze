export type ComicCardData = {
  id: string;
  title: string;
  cover: string;
  author: string;
  description: string;
  raw: Record<string, unknown>;
};

export type ChapterData = {
  id: string;
  name: string;
  order: number;
};

export type ReaderPageData = {
  id: string;
  name: string;
  url: string;
  extern: Record<string, unknown>;
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

function firstText(record: Record<string, unknown>, keys: string[], fallback = '') {
  for (const key of keys) {
    const value = text(record[key]);
    if (value.trim()) return value;
  }
  return fallback;
}

export function normalizeSearch(response: Record<string, unknown>): ComicCardData[] {
  const data = asRecord(response.data);
  const items = asList(data.items ?? response.items ?? data.list ?? response.list);
  return items.map((value, index) => {
    const item = asRecord(value);
    const id = firstText(item, ['id', 'comicId', 'comic_id'], `item-${index + 1}`);
    return {
      id,
      title: firstText(item, ['title', 'name', 'comicName'], `未命名漫画 ${index + 1}`),
      cover: firstText(item, ['cover', 'coverUrl', 'thumbnail', 'url']),
      author: firstText(item, ['author', 'artist', '作者'], '未知作者'),
      description: firstText(item, ['description', 'desc', '简介']),
      raw: item,
    };
  });
}

export function normalizeDetail(response: Record<string, unknown>) {
  const data = asRecord(response.data);
  const normal = asRecord(data.normal ?? response.normal);
  const info = asRecord(
    normal.comicInfo ?? normal.comic ?? data.comic ?? response.comic,
  );
  const chaptersValue =
    normal.eps ?? normal.chapters ?? data.chapters ?? response.chapters;
  const chapters = asList(chaptersValue).map((value, index) => {
    const chapter = asRecord(value);
    return {
      id: firstText(chapter, ['id', 'chapterId', 'chapter_id'], String(index + 1)),
      name: firstText(chapter, ['name', 'title', 'epName'], `第 ${index + 1} 话`),
      order: Number(chapter.order ?? index),
    } satisfies ChapterData;
  });
  return {
    id: firstText(info, ['id', 'comicId'], text(response.comicId)),
    title: firstText(info, ['title', 'name'], '未命名漫画'),
    cover: firstText(info, ['cover', 'coverUrl', 'thumbnail']),
    author: firstText(info, ['author', 'artist'], '未知作者'),
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
      return {
        id: firstText(page, ['id'], String(index + 1)),
        name: firstText(page, ['name', 'originalName'], `第 ${index + 1} 页`),
        url: firstText(page, ['url', 'fileServer', 'path']),
        extern: asRecord(page.extern),
      } satisfies ReaderPageData;
    })
    .filter((page) => page.url.length > 0);
}
