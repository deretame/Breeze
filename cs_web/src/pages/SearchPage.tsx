import { useWindowVirtualizer } from '@tanstack/react-virtual';
import {
  ArrowRight,
  BookOpen,
  LoaderCircle,
  Search as SearchIcon,
  SlidersHorizontal,
} from 'lucide-react';
import {
  type FormEvent,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { Link, useSearchParams } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { RemoteImage } from '../components/RemoteImage';
import { Button } from '../components/ui/button';
import { Card, CardContent } from '../components/ui/card';
import { normalizeSearchPage, type ComicCardData } from '../lib/content';
import {
  useLazySearchQuery,
  usePluginCatalogQuery,
  usePluginsQuery,
} from '../services/breezeApi';

type SearchItem = ComicCardData & {
  pluginId: string;
  sourceName: string;
};

const COLUMNS = 4;

function mergeItems(current: SearchItem[], incoming: SearchItem[]) {
  const items = new Map(current.map((item) => [`${item.pluginId}:${item.id}`, item]));
  for (const item of incoming) items.set(`${item.pluginId}:${item.id}`, item);
  return [...items.values()];
}

export function SearchPage() {
  const user = useAppSelector((state) => state.auth.user);
  const [params, setParams] = useSearchParams();
  const queryKeyword = params.get('q') ?? '';
  const selectedPlugin = params.get('plugin') || 'all';
  const [keyword, setKeyword] = useState(queryKeyword);
  const [items, setItems] = useState<SearchItem[]>([]);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(false);
  const [showSearchBar, setShowSearchBar] = useState(true);
  const requestId = useRef(0);
  const loadingRef = useRef(false);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const [scrollMargin, setScrollMargin] = useState(0);
  const [triggerSearch] = useLazySearchQuery();
  const { data: pluginData } = usePluginsQuery();
  const { data: catalogData } = usePluginCatalogQuery();
  const plugins = useMemo(
    () => pluginData?.items.filter((plugin) => plugin.enabled) ?? [],
    [pluginData?.items],
  );
  const catalogNames = useMemo(
    () =>
      new Map(
        (catalogData?.items ?? [])
          .filter((plugin) => plugin.manifest?.uuid && plugin.manifest.name)
          .map((plugin) => [plugin.manifest.uuid, plugin.manifest.name]),
      ),
    [catalogData?.items],
  );
  const pluginIds = useMemo(
    () =>
      selectedPlugin === 'all'
        ? plugins.map((plugin) => plugin.plugin_id)
        : plugins.some((plugin) => plugin.plugin_id === selectedPlugin)
          ? [selectedPlugin]
          : [],
    [plugins, selectedPlugin],
  );
  const pluginKey = pluginIds.join(',');
  const selectedPluginName =
    selectedPlugin === 'all'
      ? '全部图源'
      : plugins.find((plugin) => plugin.plugin_id === selectedPlugin)?.name?.trim() ||
        catalogNames.get(selectedPlugin) ||
        '当前图源';

  const loadPage = useCallback(
    async (nextPage: number, replace: boolean) => {
      if (!user || !queryKeyword.trim() || !pluginIds.length || loadingRef.current)
        return;
      const currentRequest = ++requestId.current;
      loadingRef.current = true;
      setIsLoading(true);
      setError(false);
      const results = await Promise.allSettled(
        pluginIds.map((pluginId) =>
          triggerSearch({
            pluginId,
            keyword: queryKeyword.trim(),
            page: nextPage,
          }).unwrap(),
        ),
      );
      if (currentRequest !== requestId.current) {
        loadingRef.current = false;
        setIsLoading(false);
        return;
      }
      const nextItems: SearchItem[] = [];
      let canLoadMore = false;
      let failedCount = 0;
      results.forEach((result, index) => {
        if (result.status === 'rejected') {
          failedCount += 1;
          return;
        }
        const normalized = normalizeSearchPage(result.value);
        canLoadMore ||= normalized.hasMore;
        normalized.items.forEach((item) => {
          nextItems.push({
            ...item,
            pluginId: pluginIds[index],
            sourceName:
              plugins
                .find((plugin) => plugin.plugin_id === pluginIds[index])
                ?.name?.trim() ||
              catalogNames.get(pluginIds[index]) ||
              '未命名图源',
          });
        });
      });
      setItems((current) =>
        replace ? mergeItems([], nextItems) : mergeItems(current, nextItems),
      );
      setPage(nextPage);
      setHasMore(canLoadMore);
      setError(results.length > 0 && failedCount === results.length);
      loadingRef.current = false;
      setIsLoading(false);
    },
    [catalogNames, pluginIds, plugins, queryKeyword, triggerSearch, user],
  );

  useEffect(() => {
    setKeyword(queryKeyword);
    setItems([]);
    setPage(0);
    setHasMore(false);
    setError(false);
    if (queryKeyword.trim() && pluginKey) void loadPage(1, true);
  }, [loadPage, pluginKey, queryKeyword]);

  useEffect(() => {
    const updateMargin = () => {
      if (listRef.current) setScrollMargin(listRef.current.offsetTop);
    };
    updateMargin();
    window.addEventListener('resize', updateMargin);
    return () => window.removeEventListener('resize', updateMargin);
  }, [items.length]);

  useEffect(() => {
    let lastScrollY = window.scrollY;
    const onScroll = () => {
      const nextScrollY = window.scrollY;
      if (nextScrollY < 80 || nextScrollY < lastScrollY - 8) setShowSearchBar(true);
      else if (nextScrollY > lastScrollY + 8) setShowSearchBar(false);
      lastScrollY = nextScrollY;
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    const node = sentinelRef.current;
    if (!node || !hasMore || typeof IntersectionObserver === 'undefined')
      return undefined;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting && !isLoading) void loadPage(page + 1, false);
      },
      { rootMargin: '520px 0px' },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [hasMore, isLoading, loadPage, page]);

  const rowVirtualizer = useWindowVirtualizer({
    count: Math.ceil(items.length / COLUMNS),
    estimateSize: () => 305,
    overscan: 4,
    scrollMargin,
  });
  const rowCount = Math.ceil(items.length / COLUMNS);
  const measuredRows = rowVirtualizer.getVirtualItems();
  const virtualRows = measuredRows.length
    ? measuredRows
    : Array.from({ length: rowCount }, (_, index) => ({
        index,
        key: `fallback-${index}`,
        start: index * 305,
      }));
  const listHeight = Math.max(
    rowVirtualizer.getTotalSize() + scrollMargin,
    rowCount * 305,
  );

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = new URLSearchParams(params);
    if (keyword.trim()) next.set('q', keyword.trim());
    else next.delete('q');
    next.set('plugin', selectedPlugin);
    next.delete('page');
    setParams(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function changePlugin(value: string) {
    const next = new URLSearchParams(params);
    next.set('plugin', value);
    next.delete('page');
    setParams(next);
  }

  return (
    <div className="content-shell search-shell">
      <div className="page-heading">
        <div>
          <p className="eyebrow">DISCOVER</p>
          <h1>发现漫画</h1>
          <p className="lede">从服务端插件中聚合搜索下一本想看的故事。</p>
        </div>
        <div className="heading-icon">
          <SearchIcon size={22} />
        </div>
      </div>
      {!user && (
        <Card className="notice-card">
          <BookOpen size={19} />
          <div>
            <b>登录后开始搜索</b>
            <p>插件请求需要经过服务端会话认证。</p>
          </div>
          <Link to="/login">
            <Button size="sm">
              去登录 <ArrowRight size={15} />
            </Button>
          </Link>
        </Card>
      )}
      <Card
        className={`
          search-controls
          ${showSearchBar ? '' : `search-controls-hidden`}
        `}
      >
        <CardContent>
          <form className="search-form" onSubmit={submit}>
            <div className="search-input-wrap">
              <SearchIcon size={18} />
              <input
                value={keyword}
                onChange={(event) => setKeyword(event.target.value)}
                placeholder="输入漫画名或关键词"
              />
            </div>
            <select
              aria-label="选择图源"
              value={selectedPlugin}
              onChange={(event) => changePlugin(event.target.value)}
            >
              <option value="all">全部图源（聚合搜索）</option>
              {plugins.map((plugin) => (
                <option key={plugin.plugin_id} value={plugin.plugin_id}>
                  {plugin.name?.trim() ||
                    catalogNames.get(plugin.plugin_id) ||
                    '未命名图源'}
                </option>
              ))}
            </select>
            <Button
              type="submit"
              disabled={!user || !pluginIds.length || !keyword.trim()}
            >
              <SearchIcon size={16} />
              搜索
            </Button>
          </form>
          <div className="search-filter-hint">
            <SlidersHorizontal size={14} /> 当前使用：<b>{selectedPluginName}</b>
            <span>向下滚动自动加载更多结果</span>
          </div>
        </CardContent>
      </Card>

      <div className="results-heading">
        <div>
          <span className="result-kicker">SEARCH RESULTS</span>
          <h2>{queryKeyword ? `“${queryKeyword}”的结果` : '开始一次搜索'}</h2>
        </div>
        {items.length > 0 && (
          <span className="result-count">{items.length} 个结果</span>
        )}
      </div>
      {isLoading && <div className="loading-line">正在聚合图源结果…</div>}
      {error && (
        <Card className="error-panel">
          <p>搜索失败，请检查插件配置或服务端日志。</p>
        </Card>
      )}
      {!isLoading && queryKeyword && items.length === 0 && !error && (
        <Card className="empty-state large">
          <SearchIcon size={22} />
          <div>
            <b>没有找到结果</b>
            <p>换一个关键词，或尝试其他图源。</p>
          </div>
        </Card>
      )}
      <div ref={listRef} className="search-virtual-list" style={{ height: listHeight }}>
        {virtualRows.map((virtualRow) => {
          const rowItems = items.slice(
            virtualRow.index * COLUMNS,
            virtualRow.index * COLUMNS + COLUMNS,
          );
          return (
            <div
              className="comic-grid search-virtual-row"
              data-testid="virtual-search-row"
              key={virtualRow.key}
              ref={rowVirtualizer.measureElement}
              data-index={virtualRow.index}
              style={{ transform: `translateY(${virtualRow.start - scrollMargin}px)` }}
            >
              {rowItems.map((item) => (
                <Link
                  className="comic-card"
                  key={`${item.pluginId}:${item.id}`}
                  to={`/comic/${encodeURIComponent(item.pluginId)}/${encodeURIComponent(item.id)}`}
                >
                  <div className="comic-cover">
                    {item.coverImage.url ? (
                      <RemoteImage
                        pluginId={item.pluginId}
                        page={item.coverImage}
                        alt={item.title}
                        className="comic-cover-image"
                        fallback={<span>{item.title.slice(0, 1)}</span>}
                      />
                    ) : (
                      <span>{item.title.slice(0, 1)}</span>
                    )}
                  </div>
                  <div className="comic-card-body">
                    <h3>{item.title}</h3>
                    <p>
                      {catalogNames.get(item.pluginId) ?? item.sourceName} ·{' '}
                      {item.author}
                    </p>
                  </div>
                  <ArrowRight className="comic-arrow" size={16} />
                </Link>
              ))}
            </div>
          );
        })}
      </div>
      <div ref={sentinelRef} className="search-load-more" aria-live="polite">
        {isLoading && items.length > 0 ? (
          <LoaderCircle className="spin" size={18} />
        ) : null}
        {!isLoading && hasMore ? '继续下滑加载更多' : null}
        {!isLoading && queryKeyword && !hasMore && items.length > 0
          ? '已经到底了'
          : null}
      </div>
    </div>
  );
}
