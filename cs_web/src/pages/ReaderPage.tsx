import {
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Maximize2,
  Menu,
  Moon,
  PanelLeft,
  Settings2,
  X,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { RemoteImage } from '../components/RemoteImage';
import { Button } from '../components/ui/button';
import { Card } from '../components/ui/card';
import { normalizeReaderSnapshot } from '../lib/content';
import { useReadQuery, useSaveLibraryMutation } from '../services/breezeApi';

export function ReaderPage() {
  const { pluginId = '', comicId = '', chapterId = '' } = useParams();
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const [immersive, setImmersive] = useState(false);
  const [hideSidebar, setHideSidebar] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [progress, setProgress] = useState(0);
  const [saveLibrary] = useSaveLibraryMutation();
  const savedRef = useRef<string | null>(null);
  const readState = useReadQuery(
    { pluginId, comicId, chapterId },
    { skip: !user || !pluginId || !comicId || !chapterId },
  );
  const snapshot = useMemo(
    () => normalizeReaderSnapshot(readState.data ?? {}),
    [readState.data],
  );
  const currentIndex = Math.max(
    snapshot.chapters.findIndex(
      (chapter) =>
        chapter.id === chapterId ||
        chapter.requestId === chapterId ||
        chapter.logicalKey === chapterId ||
        chapter.storageChapterId === chapterId,
    ),
    0,
  );
  const previousChapter = snapshot.chapters[currentIndex - 1];
  const nextChapter = snapshot.chapters[currentIndex + 1];

  useEffect(() => {
    const updateProgress = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(
        maxScroll > 0 ? Math.min(100, (window.scrollY / maxScroll) * 100) : 0,
      );
    };
    updateProgress();
    window.addEventListener('scroll', updateProgress, { passive: true });
    window.addEventListener('resize', updateProgress);
    return () => {
      window.removeEventListener('scroll', updateProgress);
      window.removeEventListener('resize', updateProgress);
    };
  }, [snapshot.pages.length]);

  useEffect(() => {
    document.documentElement.classList.toggle(
      'reader-sidebar-hidden',
      hideSidebar || immersive,
    );
    return () => document.documentElement.classList.remove('reader-sidebar-hidden');
  }, [hideSidebar, immersive]);

  useEffect(() => {
    const chapterMatchesRequest = [
      snapshot.chapter.id,
      snapshot.chapter.requestId,
      snapshot.chapter.logicalKey,
      snapshot.chapter.storageChapterId,
    ].includes(chapterId);
    const chapterReady =
      !readState.isFetching &&
      (chapterMatchesRequest || snapshot.chapters.length === 1);
    if (
      !user ||
      !snapshot.pages.length ||
      !chapterReady ||
      savedRef.current === chapterId
    )
      return;
    savedRef.current = chapterId;
    void saveLibrary({
      kind: 'history',
      record: {
        unique_key: `${pluginId}:${comicId}:${chapterId}`,
        source: pluginId,
        comic_id: comicId,
        payload: {
          chapter_id: chapterId,
          chapter_name: snapshot.chapter.name,
          comic_title: snapshot.comicTitle,
          title: snapshot.comicTitle,
          cover: snapshot.comicCover,
          page: 0,
        },
      },
    });
  }, [chapterId, comicId, pluginId, readState.isFetching, saveLibrary, snapshot, user]);

  async function toggleImmersive() {
    const next = !immersive;
    setImmersive(next);
    try {
      if (next && !document.fullscreenElement)
        await document.documentElement.requestFullscreen?.();
      if (!next && document.fullscreenElement) await document.exitFullscreen?.();
    } catch {
      // Browsers may reject fullscreen without a user gesture; CSS immersive mode still works.
    }
  }

  function openChapter(id: string | undefined) {
    if (!id) return;
    navigate(
      `/reader/${encodeURIComponent(pluginId)}/${encodeURIComponent(comicId)}/${encodeURIComponent(id)}`,
    );
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

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
          <span>
            {readState.isFetching ? '正在准备阅读器…' : snapshot.chapter.name}
          </span>
          <small>
            {snapshot.comicTitle} ·{' '}
            {snapshot.pages.length ? `${snapshot.pages.length} 页` : 'Breeze Reader'}
          </small>
        </div>
        <div className="reader-actions">
          <Button
            variant="ghost"
            size="sm"
            aria-label="阅读设置"
            aria-expanded={settingsOpen}
            onClick={() => setSettingsOpen((value) => !value)}
          >
            <Settings2 size={17} />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label={immersive ? '退出最大化' : '最大化阅读'}
            onClick={() => void toggleImmersive()}
          >
            <Maximize2 size={17} />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label={hideSidebar ? '显示侧边栏' : '隐藏侧边栏'}
            aria-pressed={hideSidebar}
            onClick={() => setHideSidebar((value) => !value)}
          >
            {hideSidebar ? <Menu size={17} /> : <PanelLeft size={17} />}
          </Button>
        </div>
        {settingsOpen && (
          <Card className="reader-settings-panel">
            <div>
              <b>阅读设置</b>
              <button
                aria-label="关闭阅读设置"
                onClick={() => setSettingsOpen(false)}
                type="button"
              >
                <X size={15} />
              </button>
            </div>
            <p>当前为连续阅读模式，图片会按需加载。</p>
            <button type="button" onClick={() => setHideSidebar((value) => !value)}>
              {hideSidebar ? '显示侧边栏' : '隐藏侧边栏'}
            </button>
          </Card>
        )}
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
      {!readState.isFetching && !readState.error && snapshot.pages.length > 0 && (
        <main className="reader-canvas">
          <div className="reader-page-column">
            {snapshot.pages.map((page, index) => (
              <figure className="reader-page-item" key={`${page.id}:${index}`}>
                <RemoteImage pluginId={pluginId} page={page} alt={page.name} />
                <figcaption>{String(index + 1).padStart(2, '0')}</figcaption>
              </figure>
            ))}
          </div>
        </main>
      )}
      {!readState.isFetching && !readState.error && snapshot.pages.length === 0 && (
        <div className="reader-error">
          <Menu size={22} />
          <h2>章节没有图片</h2>
          <p>服务端返回了空章节，请尝试重新选择章节。</p>
        </div>
      )}
      <div className="reader-bottom-controls">
        <Button
          variant="secondary"
          size="sm"
          disabled={!previousChapter}
          onClick={() => openChapter(previousChapter?.id)}
          title={previousChapter?.name}
        >
          <ChevronLeft size={16} />
          {previousChapter?.name ?? '上一话'}
        </Button>
        <span aria-label={`阅读进度 ${Math.round(progress)}%`}>
          <span className="reader-progress" style={{ width: `${progress}%` }} />
        </span>
        <Button
          variant="secondary"
          size="sm"
          disabled={!nextChapter}
          onClick={() => openChapter(nextChapter?.id)}
          title={nextChapter?.name}
        >
          {nextChapter?.name ?? '下一话'}
          <ChevronRight size={16} />
        </Button>
      </div>
    </div>
  );
}
