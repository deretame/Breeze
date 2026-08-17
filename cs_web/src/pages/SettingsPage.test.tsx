import { screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import { SettingsPage } from './SettingsPage';
import { renderWithProviders } from '../test/testUtils';

describe('SettingsPage', () => {
  it('renders the health and capability values returned by the server', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL) => {
        const url = input instanceof Request ? input.url : String(input);
        if (url.endsWith('/health')) {
          return new Response(JSON.stringify({ status: 'ok' }), {
            headers: { 'content-type': 'application/json' },
          });
        }
        return new Response(
          JSON.stringify({
            browser_frontend: true,
            server_download: false,
            plugin_runtime: { quickjs: true, filesystem: false, cancellation: true },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }),
    );

    renderWithProviders(<SettingsPage />);

    expect(await screen.findByText('正常')).toBeInTheDocument();
    expect(screen.getByText('已开启')).toBeInTheDocument();
    expect(screen.getAllByText('未开启')).toHaveLength(2);
    expect(screen.getByRole('link', { name: /服务端地址/ })).toHaveAttribute(
      'href',
      '/',
    );
  });
});
