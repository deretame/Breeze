import eslint from '@eslint/js';
import betterTailwindcss from 'eslint-plugin-better-tailwindcss';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist'] },
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2022,
      globals: globals.browser,
    },
    plugins: {
      'better-tailwindcss': betterTailwindcss,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    settings: {
      'better-tailwindcss': {
        cwd: import.meta.dirname,
        detectComponentClasses: true,
        entryPoint: 'src/styles.css',
      },
    },
    rules: {
      ...betterTailwindcss.configs.recommended.rules,
      // Prettier owns line wrapping; keeping both rules enabled causes them to
      // continuously rewrite the same className expressions in opposite ways.
      'better-tailwindcss/enforce-consistent-line-wrapping': 'off',
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
);
