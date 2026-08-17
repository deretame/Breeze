import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { LibraryPage } from './LibraryPage';
import { createTestStore, renderWithStore } from '../test/testUtils';

describe('LibraryPage', () => {
  it('shows a login prompt without a session', () => {
    renderWithStore(<LibraryPage />, createTestStore());

    expect(screen.getByText('登录后查看你的书架')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /去登录/ })).toHaveAttribute(
      'href',
      '/login',
    );
  });

  it('renders favorites and reading history and supports refresh', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/plugins')) {
        return new Response(
          JSON.stringify({
            items: [{ plugin_id: 'demo', name: '示例图源', enabled: true }],
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      const body = url.includes('/favorites')
        ? {
            items: [
              {
                unique_key: 'demo:comic-1',
                source: 'demo',
                comic_id: 'comic-1',
                payload: {
                  title: '收藏的漫画',
                  cover: 'https://example.com/cover.jpg',
                },
              },
            ],
          }
        : {
            items: [
              {
                unique_key: 'demo:comic-1:chapter-1',
                source: 'demo',
                comic_id: 'comic-1',
                payload: { title: '最近读过', chapter_id: 'chapter-1' },
              },
            ],
          };
      return new Response(JSON.stringify(body), {
        headers: { 'content-type': 'application/json' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );
    const user = userEvent.setup();
    renderWithStore(<LibraryPage />, store);

    expect(await screen.findByText('收藏的漫画')).toBeInTheDocument();
    expect(screen.getByText('最近读过')).toBeInTheDocument();
    expect(screen.getByText('示例图源')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /收藏的漫画/ })).toHaveAttribute(
      'href',
      '/comic/demo/comic-1',
    );
    expect(screen.getByRole('link', { name: /最近读过/ })).toHaveAttribute(
      'href',
      '/reader/demo/comic-1/chapter-1',
    );

    const requestCount = fetchMock.mock.calls.length;
    await user.click(screen.getByRole('button', { name: /刷新/ }));
    expect(fetchMock.mock.calls.length).toBeGreaterThan(requestCount);
  });

  it('shows independent empty states for favorites and history', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(JSON.stringify({ items: [] }), {
            headers: { 'content-type': 'application/json' },
          }),
        ),
      ),
    );
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    renderWithStore(<LibraryPage />, store);

    expect(await screen.findByText('收藏夹还是空的')).toBeInTheDocument();
    expect(screen.getByText('还没有阅读记录')).toBeInTheDocument();
  });
});
