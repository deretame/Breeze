import {
  ArrowLeft,
  ArrowRight,
  BookOpen,
  Search as SearchIcon,
  SlidersHorizontal,
} from 'lucide-react';
import { FormEvent, useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { normalizeSearch } from '../lib/content';
import { usePluginsQuery, useSearchQuery } from '../services/breezeApi';
import { Button } from '../components/ui/button';
import { Card, CardContent } from '../components/ui/card';

export function SearchPage() {
  const user = useAppSelector((state) => state.auth.user);
  const [params, setParams] = useSearchParams();
  const queryKeyword = params.get('q') ?? '';
  const selectedPlugin = params.get('plugin') ?? '';
  const [keyword, setKeyword] = useState(queryKeyword);
  const { data: pluginData } = usePluginsQuery();
  const plugins = pluginData?.items.filter((plugin) => plugin.enabled) ?? [];
  const pluginId = selectedPlugin || plugins[0]?.plugin_id || '';
  const searchState = useSearchQuery(
    { pluginId, keyword: queryKeyword, page: 1 },
    { skip: !user || !pluginId || !queryKeyword.trim() },
  );
  const items = useMemo(
    () => normalizeSearch(searchState.data ?? {}),
    [searchState.data],
  );

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = new URLSearchParams(params);
    if (keyword.trim()) next.set('q', keyword.trim());
    else next.delete('q');
    if (pluginId) next.set('plugin', pluginId);
    setParams(next);
  }

  return (
    <div className="content-shell search-shell">
      <div className="page-heading">
        <div>
          <p className="eyebrow">DISCOVER</p>
          <h1>发现漫画</h1>
          <p className="lede">从服务端插件中搜索下一本想看的故事。</p>
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
      <Card className="search-controls">
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
              value={pluginId}
              onChange={(event) => {
                const next = new URLSearchParams(params);
                next.set('plugin', event.target.value);
                setParams(next);
              }}
            >
              {plugins.length === 0 ? (
                <option value="">暂无图源</option>
              ) : (
                plugins.map((plugin) => (
                  <option key={plugin.plugin_id} value={plugin.plugin_id}>
                    {plugin.plugin_id}
                  </option>
                ))
              )}
            </select>
            <Button type="submit" disabled={!user || !pluginId || !keyword.trim()}>
              <SearchIcon size={16} />
              搜索
            </Button>
          </form>
          <div className="search-filter-hint">
            <SlidersHorizontal size={14} /> 当前使用：<b>{pluginId || '未选择图源'}</b>
            <span>支持后续接入高级筛选</span>
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
      {searchState.isFetching && <div className="loading-line">正在搜索图源…</div>}
      {searchState.error && (
        <Card className="error-panel">
          <p>搜索失败，请检查插件配置或服务端日志。</p>
        </Card>
      )}
      {!searchState.isFetching &&
        queryKeyword &&
        items.length === 0 &&
        !searchState.error && (
          <Card className="empty-state large">
            <SearchIcon size={22} />
            <div>
              <b>没有找到结果</b>
              <p>换一个关键词，或尝试其他图源。</p>
            </div>
          </Card>
        )}
      <div className="comic-grid">
        {items.map((item) => (
          <Link
            className="comic-card"
            key={`${pluginId}:${item.id}`}
            to={`/comic/${encodeURIComponent(pluginId)}/${encodeURIComponent(item.id)}`}
          >
            <div className="comic-cover">
              {item.cover ? (
                <img src={item.cover} alt="" />
              ) : (
                <span>{item.title.slice(0, 1)}</span>
              )}
            </div>
            <div className="comic-card-body">
              <h3>{item.title}</h3>
              <p>{item.author}</p>
            </div>
            <ArrowRight className="comic-arrow" size={16} />
          </Link>
        ))}
      </div>
      {queryKeyword && items.length > 0 && (
        <div className="pagination">
          <Button variant="secondary" size="sm">
            <ArrowLeft size={15} />
            上一页
          </Button>
          <span>第 1 页</span>
          <Button variant="secondary" size="sm">
            下一页
            <ArrowRight size={15} />
          </Button>
        </div>
      )}
    </div>
  );
}
