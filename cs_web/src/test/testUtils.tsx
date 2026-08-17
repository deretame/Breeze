import type { ReactElement } from 'react';
import { render, type RenderOptions } from '@testing-library/react';
import { configureStore } from '@reduxjs/toolkit';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';

import authReducer from '../features/auth/authSlice';
import { breezeApi } from '../services/breezeApi';

export function createTestStore() {
  return configureStore({
    reducer: {
      auth: authReducer,
      [breezeApi.reducerPath]: breezeApi.reducer,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(breezeApi.middleware),
  });
}

export function renderWithProviders(
  element: ReactElement,
  initialEntries: string[] = ['/'],
  options?: Omit<RenderOptions, 'wrapper'>,
) {
  const store = createTestStore();
  return renderWithStore(element, store, initialEntries, options);
}

export function renderWithStore(
  element: ReactElement,
  store: ReturnType<typeof createTestStore>,
  initialEntries: string[] = ['/'],
  options?: Omit<RenderOptions, 'wrapper'>,
) {
  const result = render(
    <Provider store={store}>
      <MemoryRouter initialEntries={initialEntries}>{element}</MemoryRouter>
    </Provider>,
    options,
  );
  return { ...result, store };
}
