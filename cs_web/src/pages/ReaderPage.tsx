import {
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Maximize2,
  Menu,
  Moon,
  PanelLeft,
  Settings2,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { RemoteImage } from '../components/RemoteImage';
import { Button } from '../components/ui/button';
import { Card } from '../components/ui/card';
import { normalizeReaderPages } from '../lib/content';
import { useReadQuery, useSaveLibraryMutation } from '../services/breezeApi';

export function ReaderPage() {
  const { pluginId = '', comicId = '', chapterId = '' } = useParams();
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const [immersive, setImmersive] = useState(false);
  const [saveLibrary] = useSaveLibraryMutation();
  const savedRef = useRef(false);
  const readState = useReadQuery(
    { pluginId, comicId, chapterId },
    { skip: !user || !pluginId || !comicId || !chapterId },
  );
  const pages = useMemo(
    () => normalizeReaderPages(readState.data ?? {}),
    [readState.data],
  );

  useEffect(() => {
    if (!user || !pages.length || savedRef.current) return;
    savedRef.current = true;
    void saveLibrary({
      kind: 'history',
      record: {
        unique_key: `${pluginId}:${comicId}:${chapterId}`,
        source: pluginId,
        comic_id: comicId,
        payload: {
          chapter_id: chapterId,
          title: readState.data?.title ?? comicId,
          page: 0,
        },
      },
    });
  }, [chapterId, comicId, pages.length, pluginId, readState.data, saveLibrary, user]);

  if (!user) {
    return (
      <div className="reader-empty">
        <Card className="empty-state large">
          <b>登录后开始阅读</b>
          <Link to="/login">
            <Button>去登录</Button>
          </Link>
        </Card>
      </div>
    );
  }

  return (
    <div className={immersive ? 'reader-page immersive' : 'reader-page'}>
      <header className="reader-toolbar">
        <button className="reader-back" onClick={() => navigate(-1)} type="button">
          <ArrowLeft size={17} />
          <span>退出阅读</span>
        </button>
        <div className="reader-title">
          <span>{readState.isFetching ? '正在准备阅读器…' : `第 ${chapterId} 话`}</span>
          <small>{pages.length ? `${pages.length} 页` : 'Breeze Reader'}</small>
        </div>
        <div className="reader-actions">
          <Button variant="ghost" size="sm" aria-label="阅读设置">
            <Settings2 size={17} />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label="切换沉浸模式"
            onClick={() => setImmersive((value) => !value)}
          >
            <Maximize2 size={17} />
          </Button>
          <Button variant="ghost" size="sm" aria-label="打开章节目录">
            <PanelLeft size={17} />
          </Button>
        </div>
      </header>
      {readState.isFetching && (
        <div className="reader-loading">
          <div className="reader-spinner" />
          <p>正在从服务端加载章节图片…</p>
        </div>
      )}
      {readState.error && (
        <div className="reader-error">
          <Moon size={22} />
          <h2>这一章暂时打不开</h2>
          <p>插件没有返回可阅读的页面，稍后再试或返回上一页。</p>
          <Button variant="secondary" onClick={() => navigate(-1)}>
            返回漫画详情
          </Button>
        </div>
      )}
      {!readState.isFetching && !readState.error && pages.length > 0 && (
        <main className="reader-canvas">
          <div className="reader-page-column">
            {pages.map((page, index) => (
              <figure className="reader-page-item" key={`${page.id}:${index}`}>
                <RemoteImage pluginId={pluginId} page={page} alt={page.name} />
                <figcaption>{String(index + 1).padStart(2, '0')}</figcaption>
              </figure>
            ))}
          </div>
        </main>
      )}
      {!readState.isFetching && !readState.error && pages.length === 0 && (
        <div className="reader-error">
          <Menu size={22} />
          <h2>章节没有图片</h2>
          <p>服务端返回了空章节，请尝试重新选择章节。</p>
        </div>
      )}
      <div className="reader-bottom-controls">
        <Button variant="secondary" size="sm">
          <ChevronLeft size={16} />
          上一话
        </Button>
        <span>
          <span className="reader-progress" style={{ width: '12%' }} />
        </span>
        <Button variant="secondary" size="sm">
          下一话
          <ChevronRight size={16} />
        </Button>
      </div>
    </div>
  );
}
