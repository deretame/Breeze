import { configureStore } from '@reduxjs/toolkit';

import authReducer from '../features/auth/authSlice';
import { breezeApi } from '../services/breezeApi';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    [breezeApi.reducerPath]: breezeApi.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(breezeApi.middleware),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
