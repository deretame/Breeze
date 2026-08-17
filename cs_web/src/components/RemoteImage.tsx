import type { ReactNode } from 'react';
import { useEffect, useState } from 'react';

import { useAppSelector } from '../app/hooks';
import type { ImageData, ReaderPageData } from '../lib/content';

type RemoteImageProps = {
  pluginId: string;
  page: ImageData | ReaderPageData;
  className?: string;
  alt?: string;
  fallback?: ReactNode;
};

export function RemoteImage({
  pluginId,
  page,
  className,
  alt,
  fallback,
}: RemoteImageProps) {
  const token = useAppSelector((state) => state.auth.token);
  const [src, setSrc] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);
  const { extern, name, url } = page;

  useEffect(() => {
    let active = true;
    let objectUrl: string | null = null;
    const controller = new AbortController();
    setSrc(null);
    setFailed(false);
    void fetch(`/api/v1/plugins/${encodeURIComponent(pluginId)}/invoke-bytes`, {
      method: 'POST',
      headers: {
        accept: 'application/octet-stream',
        'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      signal: controller.signal,
      body: JSON.stringify({
        function: 'fetchImageBytes',
        args: [{ url, timeoutMs: 30000, extern }],
      }),
    })
      .then(async (response) => {
        if (!response.ok) throw new Error(`图片请求失败 (${response.status})`);
        return response.blob();
      })
      .then((blob) => {
        if (!active) return;
        objectUrl = URL.createObjectURL(blob);
        setSrc(objectUrl);
      })
      .catch(() => {
        if (active && !controller.signal.aborted) setFailed(true);
      });

    return () => {
      active = false;
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [extern, pluginId, token, url]);

  if (failed) {
    return fallback ?? <div className="reader-image-fallback">图片加载失败</div>;
  }
  if (!src) {
    return (
      fallback ?? <div className="reader-image-skeleton" aria-label="图片加载中" />
    );
  }
  return (
    <img
      className={className}
      src={src}
      alt={alt ?? name}
      decoding="async"
      loading="lazy"
    />
  );
}
