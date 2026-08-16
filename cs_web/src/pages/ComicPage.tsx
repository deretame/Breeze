import {
  ArrowLeft,
  BookOpen,
  CalendarDays,
  CloudDownload,
  Heart,
  Play,
  UserRound,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { Button } from '../components/ui/button';
import { Card } from '../components/ui/card';
import { normalizeDetail } from '../lib/content';
import {
  useCreateDownloadMutation,
  useDetailQuery,
  useSaveLibraryMutation,
} from '../services/breezeApi';

export function ComicPage() {
  const { pluginId = '', comicId = '' } = useParams();
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const [saved, setSaved] = useState(false);
  const [downloaded, setDownloaded] = useState(false);
  const detailState = useDetailQuery(
    { pluginId, comicId },
    { skip: !user || !pluginId || !comicId },
  );
  const [saveLibrary, saveState] = useSaveLibraryMutation();
  const [createDownload, downloadState] = useCreateDownloadMutation();
  const comic = useMemo(
    () => normalizeDetail(detailState.data ?? {}),
    [detailState.data],
  );

  async function saveFavorite() {
    if (!user) return;
    await saveLibrary({
      kind: 'favorites',
      record: {
        unique_key: `${pluginId}:${comicId}`,
        source: pluginId,
        comic_id: comicId,
        payload: { title: comic.title, cover: comic.cover, author: comic.author },
      },
    });
    setSaved(true);
  }

  async function downloadAll() {
    if (!comic.chapters.length) return;
    try {
      await createDownload({
        plugin_id: pluginId,
        comic_id: comicId,
        chapter_ids: comic.chapters.map((chapter) => chapter.id),
      }).unwrap();
      setDownloaded(true);
    } catch {
      // RTK Query exposes the request error below without an unhandled rejection.
    }
  }

  if (!user) {
    return (
      <div className="content-shell">
        <Card className="empty-state large">
          <BookOpen size={22} />
          <div>
            <b>登录后查看漫画</b>
            <p>漫画详情和阅读请求需要服务端会话。</p>
          </div>
          <Link to="/login">
            <Button>去登录</Button>
          </Link>
        </Card>
      </div>
    );
  }

  return (
    <div className="content-shell comic-detail-shell">
      <button className="back-button" onClick={() => navigate(-1)} type="button">
        <ArrowLeft size={16} />
        返回搜索结果
      </button>
      {detailState.isFetching && <div className="loading-line">正在加载漫画详情…</div>}
      {detailState.error && (
        <Card className="error-panel">
          <p>漫画详情加载失败，请检查插件是否支持该作品。</p>
        </Card>
      )}
      {!detailState.isFetching && !detailState.error && (
        <>
          <section className="comic-hero">
            <div className="detail-cover">
              {comic.cover ? (
                <img src={comic.cover} alt="" />
              ) : (
                <span>{comic.title.slice(0, 1)}</span>
              )}
            </div>
            <div className="detail-copy">
              <p className="eyebrow">{pluginId} / COMIC DETAIL</p>
              <h1>{comic.title}</h1>
              <p className="detail-description">{comic.description}</p>
              <div className="detail-meta">
                <span>
                  <UserRound size={15} />
                  {comic.author}
                </span>
                <span>
                  <BookOpen size={15} />
                  {comic.chapters.length} 话
                </span>
                <span>
                  <CalendarDays size={15} />
                  服务端图源
                </span>
              </div>
              <div className="detail-actions">
                <Button
                  onClick={() =>
                    comic.chapters[0] &&
                    navigate(
                      `/reader/${encodeURIComponent(pluginId)}/${encodeURIComponent(comicId)}/${encodeURIComponent(comic.chapters[0].id)}`,
                    )
                  }
                  disabled={comic.chapters.length === 0}
                >
                  <Play size={16} />
                  开始阅读
                </Button>
                <Button
                  variant="secondary"
                  onClick={() => void saveFavorite()}
                  disabled={saveState.isLoading || saved}
                >
                  <Heart size={16} fill={saved ? 'currentColor' : 'none'} />
                  {saved ? '已收藏' : '收藏'}
                </Button>
                <Button
                  variant="secondary"
                  onClick={() => void downloadAll()}
                  disabled={downloadState.isLoading || downloaded}
                >
                  <CloudDownload size={16} />
                  {downloaded ? '已加入下载' : '下载全部'}
                </Button>
              </div>
              {downloadState.error && (
                <p className="inline-error">服务端下载未开启或任务创建失败。</p>
              )}
            </div>
          </section>
          <section className="chapter-section">
            <div className="section-heading">
              <div>
                <p className="eyebrow">CHAPTERS</p>
                <h2>章节目录</h2>
              </div>
              <span className="chapter-count">{comic.chapters.length} 话</span>
            </div>
            <Card className="chapter-card">
              <div className="chapter-list">
                {comic.chapters.map((chapter, index) => (
                  <Link
                    className="chapter-row"
                    key={chapter.id}
                    to={`/reader/${encodeURIComponent(pluginId)}/${encodeURIComponent(comicId)}/${encodeURIComponent(chapter.id)}`}
                  >
                    <span className="chapter-index">
                      {String(index + 1).padStart(2, '0')}
                    </span>
                    <span className="chapter-name">{chapter.name}</span>
                    <span className="chapter-order">
                      {chapter.order > 0 ? `#${chapter.order}` : ''}
                    </span>
                    <ArrowLeft className="chapter-arrow" size={15} />
                  </Link>
                ))}
              </div>
            </Card>
          </section>
        </>
      )}
    </div>
  );
}
