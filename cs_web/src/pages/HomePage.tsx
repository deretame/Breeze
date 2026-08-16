import {
  ArrowUpRight,
  BookMarked,
  CheckCircle2,
  Cloud,
  Database,
  Library,
  Search,
  Sparkles,
  WifiOff,
} from 'lucide-react';
import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { Button } from '../components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../components/ui/card';
import {
  useCapabilitiesQuery,
  useHealthQuery,
  usePluginsQuery,
} from '../services/breezeApi';

export function HomePage() {
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const { data: health, isError: healthError } = useHealthQuery();
  const { data: capabilities } = useCapabilitiesQuery();
  const { data: pluginData, isLoading: pluginsLoading } = usePluginsQuery();
  const [keyword, setKeyword] = useState('');
  const plugins = pluginData?.items.filter((plugin) => plugin.enabled) ?? [];

  function submitSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (keyword.trim()) navigate(`/search?q=${encodeURIComponent(keyword.trim())}`);
  }

  return (
    <div className="content-shell home-shell">
      <section className="welcome-row">
        <div>
          <p className="eyebrow">BREEZE CS / OVERVIEW</p>
          <h1>你好，{user?.username ?? '读者'}。</h1>
          <p className="lede">把今天想看的故事，交给你的书架。</p>
        </div>
        <div className="welcome-orbit">
          <Sparkles size={22} />
          <span />
        </div>
      </section>

      <form className="hero-search" onSubmit={submitSearch}>
        <Search size={21} />
        <input
          value={keyword}
          onChange={(event) => setKeyword(event.target.value)}
          placeholder="搜索漫画、作者或关键词…"
          aria-label="搜索漫画"
        />
        <Button type="submit">开始搜索</Button>
      </form>

      <section className="dashboard-grid">
        <Card className="status-panel">
          <CardHeader className="status-panel-header">
            <div>
              <CardTitle>服务端状态</CardTitle>
              <CardDescription>当前 Breeze CS 连接情况</CardDescription>
            </div>
            <span className={healthError ? 'status-badge offline' : 'status-badge'}>
              {healthError ? <WifiOff size={14} /> : <span className="status-pulse" />}
              {healthError ? '离线' : health ? '在线' : '连接中'}
            </span>
          </CardHeader>
          <CardContent>
            <div className="metric-grid">
              <div className="metric">
                <Database size={17} />
                <span>SQLite schema</span>
                <strong>{health?.db_schema_version ?? '—'}</strong>
              </div>
              <div className="metric">
                <Cloud size={17} />
                <span>服务端下载</span>
                <strong>{capabilities?.server_download ? '已开启' : '未开启'}</strong>
              </div>
              <div className="metric">
                <Library size={17} />
                <span>插件运行时</span>
                <strong>
                  {capabilities?.plugin_runtime.quickjs ? 'QuickJS' : '—'}
                </strong>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="quick-card">
          <CardHeader>
            <CardTitle>从这里开始</CardTitle>
            <CardDescription>常用入口都在手边。</CardDescription>
          </CardHeader>
          <CardContent className="quick-actions">
            <Link to="/search" className="quick-action">
              <span className="quick-action-icon teal">
                <Search size={17} />
              </span>
              <span>
                <b>发现漫画</b>
                <small>探索已安装图源</small>
              </span>
              <ArrowUpRight size={16} />
            </Link>
            <Link to="/library" className="quick-action">
              <span className="quick-action-icon violet">
                <BookMarked size={17} />
              </span>
              <span>
                <b>打开书架</b>
                <small>查看收藏与阅读历史</small>
              </span>
              <ArrowUpRight size={16} />
            </Link>
          </CardContent>
        </Card>
      </section>

      <section className="section-block">
        <div className="section-heading">
          <div>
            <p className="eyebrow">SOURCE CATALOG</p>
            <h2>已安装图源</h2>
          </div>
          <Link className="text-link" to="/search">
            全部图源 <ArrowUpRight size={15} />
          </Link>
        </div>
        {pluginsLoading ? (
          <div className="loading-line">正在读取图源…</div>
        ) : plugins.length === 0 ? (
          <Card className="empty-state">
            <Sparkles size={20} />
            <div>
              <b>还没有可用图源</b>
              <p>请在服务端安装插件，安装后刷新这里即可开始搜索。</p>
            </div>
            <CheckCircle2 className="empty-check" size={18} />
          </Card>
        ) : (
          <div className="plugin-grid">
            {plugins.map((plugin) => (
              <Link
                className="plugin-card"
                key={plugin.plugin_id}
                to={`/search?plugin=${encodeURIComponent(plugin.plugin_id)}`}
              >
                <span className="plugin-avatar">
                  {plugin.plugin_id.slice(0, 1).toUpperCase()}
                </span>
                <span>
                  <b>{plugin.plugin_id}</b>
                  <small>版本 {plugin.version}</small>
                </span>
                <ArrowUpRight size={16} />
              </Link>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
