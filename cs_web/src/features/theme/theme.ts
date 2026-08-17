import { createContext, useContext } from 'react';

export type ThemeMode = 'system' | 'light' | 'dark';

export type ThemeContextValue = {
  mode: ThemeMode;
  effectiveMode: Exclude<ThemeMode, 'system'>;
  setMode: (mode: ThemeMode) => void;
};

export const ThemeContext = createContext<ThemeContextValue>({
  mode: 'system',
  effectiveMode: 'dark',
  setMode: () => undefined,
});

export function useTheme() {
  return useContext(ThemeContext);
}
