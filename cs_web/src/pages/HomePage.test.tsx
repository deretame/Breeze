import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useLocation } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { HomePage } from './HomePage';
import { createTestStore, renderWithStore } from '../test/testUtils';

function LocationProbe() {
  const location = useLocation();
  return <output data-testid="location">{location.pathname + location.search}</output>;
}

describe('HomePage', () => {
  it('renders server capabilities, enabled plugins and navigates to search', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.endsWith('/health')) {
        return new Response(JSON.stringify({ status: 'ok', db_schema_version: 3 }), {
          headers: { 'content-type': 'application/json' },
        });
      }
      if (url.endsWith('/capabilities')) {
        return new Response(
          JSON.stringify({
            server_download: true,
            browser_frontend: true,
            plugin_runtime: { quickjs: true, filesystem: false, cancellation: true },
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/plugins/catalog')) {
        return new Response(
          JSON.stringify({
            source: 'https://api.windy-78.site/plugin-list',
            items: [
              {
                repo: 'deretame/demo-plugin',
                manifest: {
                  uuid: 'remote-demo',
                  name: '真实插件源示例',
                  version: '1.2.0',
                  describe: '来自本体插件目录',
                  iconUrl: '',
                  home: '',
                  npmName: 'demo-plugin',
                  updateUrl: '',
                  creator: { name: 'Breeze', describe: '' },
                },
              },
            ],
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      if (url.endsWith('/plugins/catalog/install')) {
        return new Response(
          JSON.stringify({
            plugin_id: 'remote-demo',
            version: '1.2.0',
            enabled: true,
          }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      return new Response(
        JSON.stringify({
          items: [
            {
              plugin_id: 'demo',
              name: '本地示例图源',
              version: '1.0.0',
              enabled: true,
            },
            { plugin_id: 'disabled', version: '1.0.0', enabled: false },
          ],
        }),
        { headers: { 'content-type': 'application/json' } },
      );
    });
    vi.stubGlobal('fetch', fetchMock);
    const store = createTestStore();
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );
    const user = userEvent.setup();
    renderWithStore(
      <>
        <HomePage />
        <LocationProbe />
      </>,
      store,
    );

    expect(await screen.findByText('本地示例图源')).toBeInTheDocument();
    expect(screen.queryByText('disabled')).not.toBeInTheDocument();
    expect(screen.getByText('SQLite schema')).toBeInTheDocument();
    expect(screen.getByText('已开启')).toBeInTheDocument();
    expect(await screen.findByText('真实插件源示例')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: '安装' }));
    expect(
      await screen.findByText('插件已安装到服务端，可以开始搜索。'),
    ).toBeInTheDocument();

    await user.type(screen.getByRole('textbox', { name: '搜索漫画' }), '月光');
    await user.click(screen.getByRole('button', { name: '开始搜索' }));
    expect(screen.getByTestId('location')).toHaveTextContent(
      '/search?q=%E6%9C%88%E5%85%89',
    );
  });

  it('shows the offline and empty-plugin states when the server is unavailable', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    renderWithStore(<HomePage />, createTestStore());

    expect(await screen.findByText('离线')).toBeInTheDocument();
    expect(await screen.findByText('还没有可用图源')).toBeInTheDocument();
  });
});
