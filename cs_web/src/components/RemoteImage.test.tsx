import { screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import { setSession } from '../features/auth/authSlice';
import type { ReaderPageData } from '../lib/content';
import { RemoteImage } from './RemoteImage';
import { renderWithProviders } from '../test/testUtils';

const page: ReaderPageData = {
  id: 'page-1',
  name: '第一页',
  url: 'https://example.com/page-1.jpg',
  extern: {},
};

describe('RemoteImage', () => {
  it('loads an authenticated image and revokes its object URL', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      blob: async () => new Blob(['image']),
    } as Response);
    const createObjectUrl = vi
      .spyOn(URL, 'createObjectURL')
      .mockReturnValue('blob:breeze-page');
    const revokeObjectUrl = vi.spyOn(URL, 'revokeObjectURL');
    vi.stubGlobal('fetch', fetchMock);
    const { store, unmount } = renderWithProviders(
      <RemoteImage pluginId="demo" page={page} />,
    );
    store.dispatch(
      setSession({ token: 'token-a', user: { id: 'user-a', username: 'reader' } }),
    );

    const image = await screen.findByRole('img', { name: '第一页' });
    expect(image).toHaveAttribute('src', 'blob:breeze-page');
    expect(image).toHaveAttribute('loading', 'lazy');
    expect(image).toHaveAttribute('decoding', 'async');
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/v1/plugins/demo/invoke-bytes',
      expect.objectContaining({
        signal: expect.any(AbortSignal),
        body: expect.stringContaining('page-1.jpg'),
      }),
    );
    expect(createObjectUrl).toHaveBeenCalled();

    unmount();
    expect(revokeObjectUrl).toHaveBeenCalledWith('blob:breeze-page');
  });

  it('shows a fallback when the image request fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network down')));

    renderWithProviders(<RemoteImage pluginId="demo" page={page} />);

    expect(await screen.findByText('图片加载失败')).toBeInTheDocument();
  });
});
