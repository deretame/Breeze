import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';

import { AppShell } from './AppShell';
import { setSession } from '../features/auth/authSlice';
import {
  createTestStore,
  renderWithStore,
  renderWithProviders,
} from '../test/testUtils';

describe('AppShell', () => {
  it('shows the live server status and primary navigation', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(JSON.stringify({ status: 'ok', db_schema_version: 3 }), {
            headers: { 'content-type': 'application/json' },
          }),
        ),
      ),
    );

    renderWithProviders(<AppShell />);

    expect(await screen.findByText('CS 服务在线')).toBeInTheDocument();
    expect(screen.getAllByRole('link', { name: /发现漫画/ })[0]).toHaveAttribute(
      'href',
      '/search',
    );
    expect(screen.getByRole('link', { name: /连接设置/ })).toHaveAttribute(
      'href',
      '/settings',
    );
  });

  it('logs out and clears the persisted session', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/logout')) {
        return new Response(JSON.stringify({ logged_out: true }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      return new Response(JSON.stringify({ status: 'ok' }), {
        headers: { 'content-type': 'application/json' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );
    const user = userEvent.setup();
    renderWithStore(<AppShell />, store);

    await user.click(await screen.findByRole('button', { name: '退出登录' }));
    await waitFor(() => expect(store.getState().auth.token).toBeNull());
    expect(
      fetchMock.mock.calls.some(([input]) => {
        const url = input instanceof Request ? input.url : String(input);
        return url.endsWith('/logout');
      }),
    ).toBe(true);
  });
});
