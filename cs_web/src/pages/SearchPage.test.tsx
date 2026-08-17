import { screen, waitFor } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { SearchPage } from './SearchPage';
import { renderWithProviders } from '../test/testUtils';

describe('SearchPage', () => {
  it('aggregates enabled plugin results and labels their source', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/plugins/catalog')) {
        return new Response(
          JSON.stringify({
            items: [
              { manifest: { uuid: 'demo-a', name: '示例图源 A' } },
              { manifest: { uuid: 'demo-b', name: '示例图源 B' } },
            ],
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/plugins')) {
        return new Response(
          JSON.stringify({
            items: [
              { plugin_id: 'demo-a', version: '1.0.0', enabled: true },
              { plugin_id: 'demo-b', version: '1.0.0', enabled: true },
            ],
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.includes('/search')) {
        const requestBody =
          input instanceof Request ? await input.clone().json() : init?.body;
        const body =
          typeof requestBody === 'string'
            ? (JSON.parse(requestBody) as { core: { page: number } })
            : (requestBody as { core: { page: number } });
        return new Response(
          JSON.stringify({
            data: {
              paging: { page: body.core.page, pages: 1, hasReachedMax: true },
              comics: [
                {
                  id: `${url.includes('demo-a') ? 'a' : 'b'}-${body.core.page}`,
                  title: `${url.includes('demo-a') ? '月光 A' : '月光 B'}`,
                },
              ],
            },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      return new Response('{}', { status: 404 });
    });
    vi.stubGlobal('fetch', fetchMock);
    const { store } = renderWithProviders(<SearchPage />, ['/search?q=月光']);
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    expect(await screen.findByRole('heading', { name: '月光 A' })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: '月光 B' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /月光 A/ })).toBeInTheDocument();
    expect(screen.getAllByText(/示例图源 [AB]/).length).toBeGreaterThanOrEqual(2);
    expect(
      fetchMock.mock.calls.filter(([input]) => {
        const url = input instanceof Request ? input.url : String(input);
        return url.includes('/search');
      }),
    ).toHaveLength(2);
  });

  it('asks anonymous readers to log in and keeps search disabled', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              items: [{ plugin_id: 'demo', version: '1.0.0', enabled: true }],
            }),
            { headers: { 'content-type': 'application/json' } },
          ),
        ),
      ),
    );

    renderWithProviders(<SearchPage />, ['/search']);

    expect(await screen.findByText('登录后开始搜索')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: '搜索' })).toBeDisabled();
  });

  it('renders the error state for a failed search request', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/plugins')) {
        return new Response(
          JSON.stringify({ items: [{ plugin_id: 'demo', enabled: true }] }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      return new Response('{}', { status: 500 });
    });
    vi.stubGlobal('fetch', fetchMock);
    const { store } = renderWithProviders(<SearchPage />, [
      '/search?q=月光&plugin=demo',
    ]);
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    expect(
      await screen.findByText('搜索失败，请检查插件配置或服务端日志。'),
    ).toBeInTheDocument();
  });

  it('renders the empty state when the plugin returns no comics', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/plugins')) {
        return new Response(
          JSON.stringify({ items: [{ plugin_id: 'demo', enabled: true }] }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      return new Response(JSON.stringify({ data: { comics: [] } }), {
        headers: { 'content-type': 'application/json' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const { store } = renderWithProviders(<SearchPage />, [
      '/search?q=不存在&plugin=demo',
    ]);
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    await waitFor(() =>
      expect(
        fetchMock.mock.calls.some((call) => {
          const request = call[0];
          const url = request instanceof Request ? request.url : String(request);
          return url.includes('/search');
        }),
      ).toBe(true),
    );
    expect(await screen.findByText('没有找到结果')).toBeInTheDocument();
  });
});
