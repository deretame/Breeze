import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { createTestStore } from '../test/testUtils';
import { breezeApi } from './breezeApi';

describe('breezeApi', () => {
  it('attaches the current bearer token to protected requests', async () => {
    const fetchMock = vi.fn(() =>
      Promise.resolve(
        new Response(JSON.stringify({ items: [] }), {
          headers: { 'content-type': 'application/json' },
        }),
      ),
    );
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    const result = await store.dispatch(
      breezeApi.endpoints.library.initiate('favorites'),
    );
    const request = fetchMock.mock.calls[0]?.[0];

    expect(result).toMatchObject({ data: { items: [] } });
    expect(request).toBeInstanceOf(Request);
    expect((request as Request).headers.get('authorization')).toBe('Bearer token-a');
  });

  it('clears an expired session after a protected request returns 401', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(JSON.stringify({ message: 'expired' }), {
            status: 401,
            headers: { 'content-type': 'application/json' },
          }),
        ),
      ),
    );
    const store = createTestStore();
    store.dispatch(
      setSession({
        token: 'expired-token',
        user: { id: 'user-a', username: 'reader' },
      }),
    );

    const result = await store.dispatch(
      breezeApi.endpoints.library.initiate('favorites'),
    );

    expect(result).toMatchObject({ error: { status: 401 } });
    expect(store.getState().auth).toEqual({ token: null, user: null });
  });
});
