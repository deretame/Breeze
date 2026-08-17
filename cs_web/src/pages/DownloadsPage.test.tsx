import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import { DownloadsPage } from './DownloadsPage';
import { createTestStore, renderWithStore } from '../test/testUtils';

describe('DownloadsPage', () => {
  it('shows a login prompt without a session', () => {
    renderWithStore(<DownloadsPage />, createTestStore());

    expect(screen.getByText('登录后查看下载任务')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /去登录/ })).toHaveAttribute(
      'href',
      '/login',
    );
  });

  it('renders task states and cancels an active task', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      if (url.includes('/cancel')) {
        return new Response(
          JSON.stringify({ task_id: 'task-running', status: 'cancelled' }),
          { headers: { 'content-type': 'application/json' } },
        );
      }
      return new Response(
        JSON.stringify({
          items: [
            {
              task_id: 'task-running',
              status: 'running',
              progress: 35,
              payload: { plugin_id: 'demo', comic_id: 'comic-1' },
            },
            {
              task_id: 'task-complete',
              status: 'completed',
              progress: 100,
              payload: { plugin_id: 'demo', comic_id: 'comic-2' },
            },
            {
              task_id: 'task-failed',
              status: 'failed',
              progress: 12,
              payload: { plugin_id: 'demo', comic_id: 'comic-3' },
            },
            {
              task_id: 'task-cancelled',
              status: 'cancelled',
              progress: 5,
              payload: { plugin_id: 'demo', comic_id: 'comic-4' },
            },
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
    renderWithStore(<DownloadsPage />, store);

    expect(await screen.findByText('comic-1')).toBeInTheDocument();
    expect(screen.getByText('demo · running')).toBeInTheDocument();
    expect(screen.getByText('demo · completed')).toBeInTheDocument();
    expect(screen.getByText('demo · failed')).toBeInTheDocument();
    expect(screen.getByText('demo · cancelled')).toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: '取消' })).toHaveLength(1);

    await user.click(screen.getByRole('button', { name: '取消' }));
    await waitFor(() => {
      expect(
        fetchMock.mock.calls.some(([input]) => {
          const url = input instanceof Request ? input.url : String(input);
          return url.includes('/downloads/tasks/task-running/cancel');
        }),
      ).toBe(true);
    });
  });
});
