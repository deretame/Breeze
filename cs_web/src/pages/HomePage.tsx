import {
  ArrowUpRight,
  BookMarked,
  CheckCircle2,
  Cloud,
  Database,
  Download,
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
  useInstallCatalogPluginMutation,
  usePluginCatalogQuery,
  usePluginsQuery,
} from '../services/breezeApi';

export function HomePage() {
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const { data: health, isError: healthError } = useHealthQuery();
  const { data: capabilities } = useCapabilitiesQuery();
  const { data: pluginData, isLoading: pluginsLoading } = usePluginsQuery();
  const {
    data: catalogData,
    isError: catalogError,
    isLoading: catalogLoading,
  } = usePluginCatalogQuery();
  const [installCatalogPlugin] = useInstallCatalogPluginMutation();
  const [keyword, setKeyword] = useState('');
  const [installingPluginId, setInstallingPluginId] = useState<string | null>(null);
  const [installMessage, setInstallMessage] = useState('');
  const plugins = pluginData?.items.filter((plugin) => plugin.enabled) ?? [];
  const catalog = catalogData?.items ?? [];
  const catalogNames = new Map(
    catalog
      .filter((item) => item.manifest?.uuid && item.manifest.name)
      .map((item) => [item.manifest.uuid, item.manifest.name]),
  );
  const pluginManagementEnabled = capabilities?.plugin_management ?? true;

  function submitSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (keyword.trim()) navigate(`/search?q=${encodeURIComponent(keyword.trim())}`);
  }

  async function installCatalogEntry(pluginId: string) {
    if (!user || installingPluginId) return;
    setInstallingPluginId(pluginId);
    setInstallMessage('');
    try {
      await installCatalogPlugin({ pluginId }).unwrap();
      setInstallMessage('插件已安装到服务端，可以开始搜索。');
    } catch {
      setInstallMessage('插件安装失败，请检查服务端插件安装权限和网络日志。');
    } finally {
      setInstallingPluginId(null);
    }
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
                  <b>
                    {plugin.name?.trim() ||
                      catalogNames.get(plugin.plugin_id) ||
                      '未命名图源'}
                  </b>
                  <small>版本 {plugin.version}</small>
                </span>
                <ArrowUpRight size={16} />
              </Link>
            ))}
          </div>
        )}
      </section>

      <section className="section-block">
        <div className="section-heading">
          <div>
            <p className="eyebrow">PLUGIN STORE</p>
            <h2>真实插件源</h2>
          </div>
          {catalogData?.source && (
            <a
              className="text-link"
              href={catalogData.source}
              target="_blank"
              rel="noreferrer"
            >
              查看目录 <ArrowUpRight size={15} />
            </a>
          )}
        </div>
        {catalogLoading ? (
          <div className="loading-line">正在读取真实插件目录…</div>
        ) : catalogError ? (
          <Card className="error-panel">
            <p>真实插件目录暂时不可用，请检查服务端网络配置。</p>
          </Card>
        ) : catalog.length === 0 ? (
          <Card className="empty-state">
            <Sparkles size={20} />
            <div>
              <b>插件目录为空</b>
              <p>服务端暂时没有从本体插件源读取到可安装插件。</p>
            </div>
          </Card>
        ) : (
          <div className="plugin-grid">
            {catalog.map((item) => {
              const manifest = item.manifest;
              const installed = plugins.find(
                (plugin) => plugin.plugin_id === manifest.uuid,
              );
              const title = manifest.name.trim() || item.repo;
              return (
                <article
                  className="plugin-card plugin-catalog-card"
                  key={manifest.uuid}
                >
                  <span className="plugin-avatar">
                    {manifest.iconUrl ? (
                      <img src={manifest.iconUrl} alt="" loading="lazy" />
                    ) : (
                      title.slice(0, 1).toUpperCase()
                    )}
                  </span>
                  <span className="plugin-catalog-content">
                    <b>{title}</b>
                    <small>
                      {installed
                        ? `已安装 ${installed.version}`
                        : `版本 ${manifest.version}`}
                    </small>
                    <p>{manifest.describe || item.repo}</p>
                  </span>
                  <Button
                    size="sm"
                    variant={installed ? 'secondary' : 'primary'}
                    disabled={
                      !user || !pluginManagementEnabled || installingPluginId !== null
                    }
                    onClick={() => void installCatalogEntry(manifest.uuid)}
                  >
                    <Download size={14} />
                    {!user
                      ? '登录安装'
                      : !pluginManagementEnabled
                        ? '服务端未开启'
                        : installed
                          ? '更新'
                          : '安装'}
                  </Button>
                </article>
              );
            })}
          </div>
        )}
        {installMessage && <p className="settings-note">{installMessage}</p>}
      </section>
    </div>
  );
}
