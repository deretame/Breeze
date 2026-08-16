import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

export type AuthUser = {
  id: string;
  username: string;
};

type AuthState = {
  token: string | null;
  user: AuthUser | null;
};

const TOKEN_KEY = 'breeze.cs.web.access-token';
const USER_KEY = 'breeze.cs.web.user';

function readInitialState(): AuthState {
  try {
    const token = localStorage.getItem(TOKEN_KEY);
    const rawUser = localStorage.getItem(USER_KEY);
    const user = rawUser ? (JSON.parse(rawUser) as AuthUser) : null;
    return { token, user };
  } catch {
    return { token: null, user: null };
  }
}

const authSlice = createSlice({
  name: 'auth',
  initialState: readInitialState(),
  reducers: {
    setSession: (state, action: PayloadAction<{ token: string; user: AuthUser }>) => {
      state.token = action.payload.token;
      state.user = action.payload.user;
      localStorage.setItem(TOKEN_KEY, action.payload.token);
      localStorage.setItem(USER_KEY, JSON.stringify(action.payload.user));
    },
    clearSession: (state) => {
      state.token = null;
      state.user = null;
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
    },
  },
});

export const { setSession, clearSession } = authSlice.actions;
export default authSlice.reducer;
