import type { PropsWithChildren } from 'react';
import { useEffect, useMemo, useState } from 'react';

const THEME_KEY = 'breeze.cs.web.theme';
import { ThemeContext, type ThemeMode } from './theme';

function readMode(): ThemeMode {
  try {
    const value = localStorage.getItem(THEME_KEY);
    return value === 'light' || value === 'dark' ? value : 'system';
  } catch {
    return 'system';
  }
}

function systemMode(): Exclude<ThemeMode, 'system'> {
  return typeof window !== 'undefined' &&
    window.matchMedia?.('(prefers-color-scheme: light)').matches
    ? 'light'
    : 'dark';
}

export function ThemeProvider({ children }: PropsWithChildren) {
  const [mode, setModeState] = useState<ThemeMode>(readMode);
  const [systemTheme, setSystemTheme] =
    useState<Exclude<ThemeMode, 'system'>>(systemMode);
  const effectiveMode = mode === 'system' ? systemTheme : mode;

  useEffect(() => {
    const media = window.matchMedia?.('(prefers-color-scheme: light)');
    if (!media) return undefined;
    const update = () => setSystemTheme(media.matches ? 'light' : 'dark');
    update();
    media.addEventListener?.('change', update);
    return () => media.removeEventListener?.('change', update);
  }, []);

  useEffect(() => {
    document.documentElement.dataset.theme = effectiveMode;
    document.documentElement.style.colorScheme = effectiveMode;
  }, [effectiveMode]);

  const value = useMemo(
    () => ({
      mode,
      effectiveMode,
      setMode: (nextMode: ThemeMode) => {
        setModeState(nextMode);
        localStorage.setItem(THEME_KEY, nextMode);
      },
    }),
    [effectiveMode, mode],
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}
