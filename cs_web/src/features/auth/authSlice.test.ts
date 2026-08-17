import { describe, expect, it } from 'vitest';

import reducer, { clearSession, setSession } from './authSlice';

describe('authSlice', () => {
  it('persists and clears the browser session', () => {
    const session = { token: 'token-a', user: { id: 'user-a', username: 'reader' } };
    const withSession = reducer(undefined, setSession(session));

    expect(withSession).toEqual(session);
    expect(localStorage.getItem('breeze.cs.web.access-token')).toBe('token-a');
    expect(localStorage.getItem('breeze.cs.web.user')).toContain('reader');

    const cleared = reducer(withSession, clearSession());
    expect(cleared).toEqual({ token: null, user: null });
    expect(localStorage.getItem('breeze.cs.web.access-token')).toBeNull();
    expect(localStorage.getItem('breeze.cs.web.user')).toBeNull();
  });
});
