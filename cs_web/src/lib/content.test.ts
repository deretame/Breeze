import { describe, expect, it } from 'vitest';

import { normalizeDetail, normalizeReaderPages, normalizeSearch } from './content';

describe('content normalizers', () => {
  it('normalizes the plugin comics search shape', () => {
    expect(
      normalizeSearch({
        data: {
          comics: [{ id: 'comic-1', name: '月光', artist: '作者' }],
        },
      }),
    ).toEqual([
      expect.objectContaining({
        id: 'comic-1',
        title: '月光',
        author: '作者',
      }),
    ]);
  });

  it('normalizes nested comic details and chapters', () => {
    expect(
      normalizeDetail({
        data: {
          comic: {
            id: 'comic-1',
            title: '月光',
            chapters: [{ id: 'chapter-1', title: '第一话', order: 2 }],
          },
        },
      }),
    ).toMatchObject({
      id: 'comic-1',
      title: '月光',
      chapters: [{ id: 'chapter-1', name: '第一话', order: 2 }],
    });
  });

  it('drops reader pages without an image URL', () => {
    expect(
      normalizeReaderPages({
        data: {
          chapter: {
            pages: [
              { id: '1', name: '1', url: 'https://example.com/1.jpg' },
              { id: '2', name: '2' },
            ],
          },
        },
      }),
    ).toEqual([
      {
        id: '1',
        name: '1',
        url: 'https://example.com/1.jpg',
        extern: {},
      },
    ]);
  });
});
