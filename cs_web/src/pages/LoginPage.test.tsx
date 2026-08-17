import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';

import { LoginPage } from './LoginPage';
import { renderWithProviders } from '../test/testUtils';

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

describe('LoginPage', () => {
  it('submits credentials and persists the returned session', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        jsonResponse({
          access_token: 'token-a',
          expires_at: '2099-01-01T00:00:00Z',
          user: { id: 'user-a', username: 'reader' },
        }),
      ),
    );
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.type(screen.getByPlaceholderText('输入用户名'), 'reader');
    await user.type(screen.getByPlaceholderText('至少 8 个字符'), 'password123');
    await user.click(screen.getByRole('button', { name: /登录/ }));

    await waitFor(() => {
      expect(localStorage.getItem('breeze.cs.web.access-token')).toBe('token-a');
    });
    expect(localStorage.getItem('breeze.cs.web.user')).toContain('reader');
  });

  it('renders the server error for invalid credentials', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(jsonResponse({ message: '用户名或密码错误' }, 401)),
    );
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.type(screen.getByPlaceholderText('输入用户名'), 'reader');
    await user.type(screen.getByPlaceholderText('至少 8 个字符'), 'bad-password');
    await user.click(screen.getByRole('button', { name: /登录/ }));

    expect(await screen.findByText('用户名或密码错误')).toBeInTheDocument();
  });

  it('switches to registration mode and submits a new account', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        jsonResponse({
          access_token: 'registered-token',
          expires_at: '2099-01-01T00:00:00Z',
          user: { id: 'user-new', username: 'new-reader' },
        }),
      ),
    );
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.click(screen.getByRole('button', { name: /还没有账号/ }));
    expect(screen.getByRole('heading', { name: '创建你的账号' })).toBeInTheDocument();
    await user.type(screen.getByPlaceholderText('输入用户名'), 'new-reader');
    await user.type(screen.getByPlaceholderText('至少 8 个字符'), 'password123');
    await user.click(screen.getByRole('button', { name: /创建账号/ }));

    await waitFor(() => {
      expect(localStorage.getItem('breeze.cs.web.access-token')).toBe(
        'registered-token',
      );
    });
  });
});
