import { useEffect, useState } from 'react';
import { Link, Route, Routes } from 'react-router-dom';

type HealthResponse = {
  status: string;
  service: string;
  version: string;
  db_schema_version: number;
  web_frontend: boolean;
  server_download: boolean;
};

function App() {
  return (
    <Routes>
      <Route path="*" element={<HomePage />} />
    </Routes>
  );
}

function HomePage() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    fetch('/api/v1/health')
      .then(async (response) => {
        if (!response.ok) {
          throw new Error(`服务端返回 HTTP ${response.status}`);
        }
        return (await response.json()) as HealthResponse;
      })
      .then((value) => {
        if (active) {
          setHealth(value);
        }
      })
      .catch((reason: unknown) => {
        if (active) {
          setError(reason instanceof Error ? reason.message : '无法连接服务端');
        }
      });

    return () => {
      active = false;
    };
  }, []);

  return (
    <main className="page-shell">
      <header className="hero">
        <p className="eyebrow">Breeze CS</p>
        <h1>漫画阅读服务已准备好</h1>
        <p className="subtitle">
          这是独立浏览器前端的基础入口，后续会在这里加入漫画搜索、详情和阅读器。
        </p>
      </header>

      <section className="status-card" aria-live="polite">
        <div>
          <span className="status-label">服务端状态</span>
          <strong>{health ? '已连接' : error ? '连接失败' : '连接中…'}</strong>
        </div>
        {health && (
          <dl>
            <div>
              <dt>版本</dt>
              <dd>{health.version}</dd>
            </div>
            <div>
              <dt>SQLite Schema</dt>
              <dd>{health.db_schema_version}</dd>
            </div>
            <div>
              <dt>服务端下载</dt>
              <dd>{health.server_download ? '已开启' : '未开启'}</dd>
            </div>
          </dl>
        )}
        {error && <p className="error-message">{error}</p>}
      </section>

      <nav className="next-links" aria-label="功能入口">
        <Link to="/reader">阅读器占位入口</Link>
        <Link to="/library">书架占位入口</Link>
      </nav>
    </main>
  );
}

export default App;
