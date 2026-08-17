import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { createTestStore } from '../test/testUtils';
import { breezeApi } from './breezeApi';

function requestFromCall(call: unknown[] | undefined) {
  const input = call?.[0];
  expect(input).toBeInstanceOf(Request);
  return input as Request;
}

function findRequest(calls: unknown[][], method: string, path: string) {
  const call = [...calls].reverse().find(([input]) => {
    const request = input as Request;
    return request.method === method && request.url.includes(path);
  });
  expect(call).toBeDefined();
  return requestFromCall(call);
}

async function requestBody(request: Request) {
  return request.method === 'GET' ? undefined : request.clone().json();
}

describe('breezeApi endpoint contracts', () => {
  it('covers every query and mutation request shape', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/health')) {
        return new Response(JSON.stringify({ status: 'ok' }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.endsWith('/capabilities')) {
        return new Response(JSON.stringify({ browser_frontend: true }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.endsWith('/plugins/catalog')) {
        return new Response(
          JSON.stringify({
            source: 'https://api.windy-78.site/plugin-list',
            items: [],
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/plugins/catalog/install')) {
        return new Response(
          JSON.stringify({
            plugin_id: 'demo',
            version: '1.0.0',
            enabled: true,
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/plugins')) {
        return new Response(JSON.stringify({ items: [] }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.endsWith('/auth/login') || url.endsWith('/auth/register')) {
        return new Response(
          JSON.stringify({
            access_token: 'token-a',
            expires_at: '2099-01-01T00:00:00Z',
            user: { id: 'user-a', username: 'reader' },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/auth/logout')) {
        return new Response(JSON.stringify({ logged_out: true }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.includes('/downloads/tasks/')) {
        return new Response(
          JSON.stringify({ task_id: 'task-1', status: 'cancelled' }),
          {
            headers: { 'content-type': 'application/json' },
          },
        );
      }
      if (url.endsWith('/downloads/tasks')) {
        return new Response(JSON.stringify({ items: [] }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.includes('/library/')) {
        return new Response(JSON.stringify({ items: [] }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      return new Response(JSON.stringify({ data: {} }), {
        headers: { 'content-type': 'application/json' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    await store.dispatch(breezeApi.endpoints.health.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1))).toMatchObject({
      method: 'GET',
      url: expect.stringContaining('/health'),
    });
    await store.dispatch(breezeApi.endpoints.capabilities.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain('/capabilities');
    await store.dispatch(breezeApi.endpoints.plugins.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain('/plugins');
    await store.dispatch(breezeApi.endpoints.pluginCatalog.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/plugins/catalog',
    );

    await store
      .dispatch(
        breezeApi.endpoints.login.initiate({
          username: 'reader',
          password: 'password123',
        }),
      )
      .unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1))).toMatchObject({
      method: 'POST',
      url: expect.stringContaining('/auth/login'),
    });
    expect(await requestBody(requestFromCall(fetchMock.mock.calls.at(-1)))).toEqual({
      username: 'reader',
      password: 'password123',
    });
    await store
      .dispatch(
        breezeApi.endpoints.register.initiate({
          username: 'new-reader',
          password: 'password123',
        }),
      )
      .unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/auth/register',
    );
    await store
      .dispatch(breezeApi.endpoints.installCatalogPlugin.initiate({ pluginId: 'demo' }))
      .unwrap();
    const installCatalogRequest = findRequest(
      fetchMock.mock.calls,
      'POST',
      '/plugins/catalog/install',
    );
    expect(await requestBody(installCatalogRequest)).toEqual({
      plugin_id: 'demo',
    });

    await store
      .dispatch(
        breezeApi.endpoints.search.initiate({
          pluginId: 'demo/source',
          keyword: '月光',
          page: 2,
        }),
      )
      .unwrap();
    expect(await requestBody(requestFromCall(fetchMock.mock.calls.at(-1)))).toEqual({
      core: { keyword: '月光', page: 2 },
      extern: {},
    });
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/plugins/demo%2Fsource/search',
    );

    await store
      .dispatch(
        breezeApi.endpoints.detail.initiate({ pluginId: 'demo', comicId: 'comic/1' }),
      )
      .unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/comic/comic%2F1/detail',
    );
    expect(await requestBody(requestFromCall(fetchMock.mock.calls.at(-1)))).toEqual({
      core: {},
      extern: {},
    });

    await store
      .dispatch(
        breezeApi.endpoints.read.initiate({
          pluginId: 'demo',
          comicId: 'comic-1',
          chapterId: 'chapter/1',
        }),
      )
      .unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/comic/comic-1/read',
    );
    expect(await requestBody(requestFromCall(fetchMock.mock.calls.at(-1)))).toEqual({
      core: { chapterId: 'chapter/1' },
      extern: {},
    });

    await store.dispatch(breezeApi.endpoints.library.initiate('favorites')).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/library/favorites',
    );
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).method).toBe('GET');
    await store
      .dispatch(
        breezeApi.endpoints.saveLibrary.initiate({
          kind: 'favorites',
          record: { unique_key: 'demo:comic-1', comic_id: 'comic-1' },
        }),
      )
      .unwrap();
    const saveLibraryRequest = findRequest(
      fetchMock.mock.calls,
      'POST',
      '/library/favorites',
    );
    expect(await requestBody(saveLibraryRequest)).toEqual({
      unique_key: 'demo:comic-1',
      comic_id: 'comic-1',
    });

    await store.dispatch(breezeApi.endpoints.downloads.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1)).url).toContain(
      '/downloads/tasks',
    );
    await store
      .dispatch(
        breezeApi.endpoints.createDownload.initiate({
          plugin_id: 'demo',
          comic_id: 'comic-1',
          chapter_ids: ['chapter-1'],
        }),
      )
      .unwrap();
    const createDownloadRequest = findRequest(
      fetchMock.mock.calls,
      'POST',
      '/downloads/tasks',
    );
    expect(await requestBody(createDownloadRequest)).toEqual({
      plugin_id: 'demo',
      comic_id: 'comic-1',
      chapter_ids: ['chapter-1'],
    });
    await store
      .dispatch(breezeApi.endpoints.cancelDownload.initiate('task/1'))
      .unwrap();
    const cancelDownloadRequest = findRequest(
      fetchMock.mock.calls,
      'POST',
      '/downloads/tasks/task%2F1/cancel',
    );
    expect(cancelDownloadRequest.url).toContain('/downloads/tasks/task%2F1/cancel');

    await store.dispatch(breezeApi.endpoints.logout.initiate()).unwrap();
    expect(requestFromCall(fetchMock.mock.calls.at(-1))).toMatchObject({
      method: 'POST',
      url: expect.stringContaining('/auth/logout'),
    });
    expect(store.getState().auth.token).toBeNull();
  });
});
