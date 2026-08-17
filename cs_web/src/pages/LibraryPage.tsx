import {
  ArrowRight,
  BookMarked,
  Clock3,
  Heart,
  History,
  Library as LibraryIcon,
  RefreshCw,
} from 'lucide-react';
import { Link } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { RemoteImage } from '../components/RemoteImage';
import { Button } from '../components/ui/button';
import { Card, CardContent } from '../components/ui/card';
import { normalizeImage } from '../lib/content';
import {
  useLibraryQuery,
  usePluginCatalogQuery,
  usePluginsQuery,
} from '../services/breezeApi';

export function LibraryPage() {
  const user = useAppSelector((state) => state.auth.user);
  const favorites = useLibraryQuery('favorites', { skip: !user });
  const history = useLibraryQuery('history', { skip: !user });
  const { data: catalogData } = usePluginCatalogQuery();
  const { data: pluginData } = usePluginsQuery();
  const favoriteItems = favorites.data?.items ?? [];
  const historyItems = history.data?.items ?? [];
  const sourceNames = new Map(
    (catalogData?.items ?? [])
      .filter((item) => item.manifest?.uuid && item.manifest.name)
      .map((item) => [item.manifest.uuid, item.manifest.name]),
  );
  for (const plugin of pluginData?.items ?? []) {
    if (plugin.name?.trim()) sourceNames.set(plugin.plugin_id, plugin.name.trim());
  }

  if (!user) {
    return (
      <div className="content-shell">
        <Card className="empty-state large">
          <LibraryIcon size={24} />
          <div>
            <b>登录后查看你的书架</b>
            <p>收藏、历史和追更会安全保存在 Breeze 服务端。</p>
          </div>
          <Link to="/login">
            <Button>去登录</Button>
          </Link>
        </Card>
      </div>
    );
  }

  return (
    <div className="content-shell">
      <div className="page-heading">
        <div>
          <p className="eyebrow">YOUR LIBRARY</p>
          <h1>我的书架</h1>
          <p className="lede">在这里继续昨天停下的故事。</p>
        </div>
        <div className="heading-icon violet-icon">
          <BookMarked size={22} />
        </div>
      </div>
      <section className="library-stats">
        <Card>
          <CardContent className="card-content">
            <Heart size={18} />
            <strong>{favoriteItems.length}</strong>
            <span>收藏漫画</span>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="card-content">
            <History size={18} />
            <strong>{historyItems.length}</strong>
            <span>阅读记录</span>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="card-content">
            <Clock3 size={18} />
            <strong>同步中</strong>
            <span>跨设备状态</span>
          </CardContent>
        </Card>
      </section>
      <section className="section-block">
        <div className="section-heading">
          <div>
            <p className="eyebrow">FAVORITES</p>
            <h2>收藏</h2>
          </div>
          <Button variant="ghost" size="sm" onClick={() => void favorites.refetch()}>
            <RefreshCw size={15} />
            刷新
          </Button>
        </div>
        {favoriteItems.length === 0 ? (
          <Card className="empty-state">
            <Heart size={19} />
            <div>
              <b>收藏夹还是空的</b>
              <p>在漫画详情页点击收藏，作品会出现在这里。</p>
            </div>
          </Card>
        ) : (
          <div className="library-list">
            {favoriteItems.map((item) => {
              const payload = item.payload;
              const cover = normalizeImage(payload.cover);
              const sourceName = sourceNames.get(item.source) ?? '未命名图源';
              return (
                <Link
                  className="library-row"
                  key={item.unique_key}
                  to={`/comic/${encodeURIComponent(item.source)}/${encodeURIComponent(item.comic_id)}`}
                >
                  <div className="library-thumb">
                    {cover.url ? (
                      <RemoteImage
                        pluginId={item.source}
                        page={cover}
                        alt={String(payload.title ?? '漫画封面')}
                        className="library-cover-image"
                        fallback={
                          <span>{String(payload.title ?? '漫').slice(0, 1)}</span>
                        }
                      />
                    ) : (
                      <span>{String(payload.title ?? '漫').slice(0, 1)}</span>
                    )}
                  </div>
                  <div>
                    <b>{String(payload.title ?? item.comic_id)}</b>
                    <small>{sourceName}</small>
                  </div>
                  <ArrowRight size={17} />
                </Link>
              );
            })}
          </div>
        )}
      </section>
      <section className="section-block">
        <div className="section-heading">
          <div>
            <p className="eyebrow">RECENTLY READ</p>
            <h2>最近阅读</h2>
          </div>
        </div>
        {historyItems.length === 0 ? (
          <Card className="empty-state">
            <History size={19} />
            <div>
              <b>还没有阅读记录</b>
              <p>打开一本漫画后，你的进度会自动同步。</p>
            </div>
          </Card>
        ) : (
          <div className="history-list">
            {historyItems.map((item) => (
              <Link
                className="history-row"
                key={item.unique_key}
                to={`/reader/${encodeURIComponent(item.source)}/${encodeURIComponent(item.comic_id)}/${encodeURIComponent(String(item.payload.chapter_id ?? ''))}`}
              >
                <span className="history-dot" />
                <div>
                  <b>
                    {String(
                      item.payload.title ?? item.payload.comic_title ?? item.comic_id,
                    )}
                  </b>
                  <small>
                    {String(
                      item.payload.chapter_name ?? item.payload.chapter_id ?? '—',
                    )}{' '}
                    · {sourceNames.get(item.source) ?? '未命名图源'}
                  </small>
                </div>
                <ArrowRight size={16} />
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
