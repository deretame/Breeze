import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it } from 'vitest';

import { ThemeProvider } from './ThemeProvider';
import { useTheme } from './theme';

function ThemeProbe() {
  const { effectiveMode, mode, setMode } = useTheme();
  return (
    <>
      <output data-testid="theme-mode">{mode}</output>
      <output data-testid="effective-theme">{effectiveMode}</output>
      <button onClick={() => setMode('light')} type="button">
        浅色
      </button>
      <button onClick={() => setMode('system')} type="button">
        系统
      </button>
    </>
  );
}

describe('ThemeProvider', () => {
  it('defaults to the system appearance and applies explicit theme changes', async () => {
    const user = userEvent.setup();
    render(
      <ThemeProvider>
        <ThemeProbe />
      </ThemeProvider>,
    );

    expect(screen.getByTestId('theme-mode')).toHaveTextContent('system');
    await waitFor(() => expect(document.documentElement.dataset.theme).toBe('dark'));

    await user.click(screen.getByRole('button', { name: '浅色' }));
    expect(screen.getByTestId('effective-theme')).toHaveTextContent('light');
    expect(document.documentElement.dataset.theme).toBe('light');
    expect(localStorage.getItem('breeze.cs.web.theme')).toBe('light');

    await user.click(screen.getByRole('button', { name: '系统' }));
    expect(screen.getByTestId('theme-mode')).toHaveTextContent('system');
  });
});
