import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { ComicPage } from './ComicPage';
import { createTestStore, renderWithStore } from '../test/testUtils';

describe('ComicPage', () => {
  it('renders details and sends favorite/download actions', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.includes('/detail')) {
        return new Response(
          JSON.stringify({
            data: {
              comic: {
                id: 'comic-1',
                title: '月光',
                author: '作者',
                description: '一部测试漫画',
                chapters: [
                  { id: 'chapter-1', title: '第一话', order: 1 },
                  { id: 'chapter-2', title: '第二话', order: 2 },
                ],
              },
            },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.includes('/library/favorites')) {
        return new Response(JSON.stringify({ unique_key: 'demo:comic-1' }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.includes('/downloads/tasks')) {
        return new Response(JSON.stringify({ task_id: 'task-1', status: 'queued' }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      return new Response('{}', { status: 404 });
    });
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );
    const user = userEvent.setup();
    renderWithStore(
      <Routes>
        <Route path="/comic/:pluginId/:comicId" element={<ComicPage />} />
      </Routes>,
      store,
      ['/comic/demo/comic-1'],
    );

    expect(await screen.findByRole('heading', { name: '月光' })).toBeInTheDocument();
    expect(screen.getByText('一部测试漫画')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /第一话/ })).toHaveAttribute(
      'href',
      '/reader/demo/comic-1/chapter-1',
    );

    await user.click(screen.getByRole('button', { name: '收藏' }));
    expect(await screen.findByRole('button', { name: '已收藏' })).toBeDisabled();

    await user.click(screen.getByRole('button', { name: '下载全部' }));
    expect(await screen.findByRole('button', { name: '已加入下载' })).toBeDisabled();

    const requests = fetchMock.mock.calls.map(([input]) =>
      input instanceof Request ? input.url : String(input),
    );
    expect(requests.some((url) => url.includes('/library/favorites'))).toBe(true);
    expect(requests.some((url) => url.includes('/downloads/tasks'))).toBe(true);
  });

  it('shows a login prompt when no browser session exists', () => {
    renderWithStore(
      <Routes>
        <Route path="/comic/:pluginId/:comicId" element={<ComicPage />} />
      </Routes>,
      createTestStore(),
      ['/comic/demo/comic-1'],
    );

    expect(screen.getByText('登录后查看漫画')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /去登录/ })).toHaveAttribute(
      'href',
      '/login',
    );
  });

  it('shows the detail error state when the plugin request fails', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() => Promise.resolve(new Response('{}', { status: 500 }))),
    );
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    renderWithStore(
      <Routes>
        <Route path="/comic/:pluginId/:comicId" element={<ComicPage />} />
      </Routes>,
      store,
      ['/comic/demo/comic-1'],
    );

    expect(
      await screen.findByText('漫画详情加载失败，请检查插件是否支持该作品。'),
    ).toBeInTheDocument();
  });
});
