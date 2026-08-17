import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { ReaderPage } from './ReaderPage';
import { createTestStore, renderWithStore } from '../test/testUtils';

function renderReader(store: ReturnType<typeof createTestStore>) {
  return renderWithStore(
    <Routes>
      <Route path="/reader/:pluginId/:comicId/:chapterId" element={<ReaderPage />} />
    </Routes>,
    store,
    ['/reader/demo/comic-1/chapter-1'],
  );
}

describe('ReaderPage', () => {
  it('loads pages, records history and toggles immersive mode', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.includes('/read')) {
        return new Response(
          JSON.stringify({
            data: {
              chapter: {
                pages: [
                  { id: 'page-1', name: '第一页', url: 'https://example.com/1.jpg' },
                ],
              },
            },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.includes('/invoke-bytes')) {
        return {
          ok: true,
          blob: async () => new Blob(['image']),
        } as Response;
      }
      return new Response(JSON.stringify({ unique_key: 'demo:comic-1:chapter-1' }), {
        headers: { 'content-type': 'application/json' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:reader-page');
    vi.spyOn(URL, 'revokeObjectURL');
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );
    const user = userEvent.setup();
    const { container } = renderReader(store);

    expect(await screen.findByText('第 1 话')).toBeInTheDocument();
    expect(screen.getByText(/1 页/)).toBeInTheDocument();
    await waitFor(() => {
      expect(
        fetchMock.mock.calls.some(([input]) => {
          const url = input instanceof Request ? input.url : String(input);
          return url.includes('/library/history');
        }),
      ).toBe(true);
    });

    await user.click(screen.getByRole('button', { name: '最大化阅读' }));
    expect(container.querySelector('.reader-page')).toHaveClass('immersive');
    expect(await screen.findByRole('img', { name: '第一页' })).toHaveAttribute(
      'src',
      'blob:reader-page',
    );
  });

  it('shows the chapter error state when the read request fails', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() => Promise.resolve(new Response('{}', { status: 500 }))),
    );
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    renderReader(store);

    expect(await screen.findByText('这一章暂时打不开')).toBeInTheDocument();
    expect(screen.getByText('返回漫画详情')).toBeInTheDocument();
  });

  it('shows a login prompt without a session', () => {
    renderReader(createTestStore());

    expect(screen.getByText('登录后开始阅读')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /去登录/ })).toHaveAttribute(
      'href',
      '/login',
    );
  });

  it('shows the empty chapter state when no pages are returned', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(JSON.stringify({ data: { chapter: { pages: [] } } }), {
            headers: { 'content-type': 'application/json' },
          }),
        ),
      ),
    );
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    renderReader(store);

    expect(await screen.findByText('章节没有图片')).toBeInTheDocument();
  });
});
