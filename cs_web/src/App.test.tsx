import { screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import App from './App';
import { renderWithProviders } from './test/testUtils';

describe('App routes', () => {
  it('redirects unknown paths to the home page', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              items: [],
              browser_frontend: true,
              server_download: false,
              plugin_runtime: { quickjs: true, filesystem: false, cancellation: true },
            }),
            { headers: { 'content-type': 'application/json' } },
          ),
        ),
      ),
    );

    renderWithProviders(<App />, ['/not-a-real-page']);

    expect(await screen.findByText('你好，读者。')).toBeInTheDocument();
  });

  it('renders the public login route without requesting protected data', () => {
    const fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);

    renderWithProviders(<App />, ['/login']);

    expect(screen.getByRole('heading', { name: '欢迎回来' })).toBeInTheDocument();
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
