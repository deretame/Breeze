import { Link } from 'react-router-dom';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../components/ui/card';
import { useTheme, type ThemeMode } from '../features/theme/theme';
import { useCapabilitiesQuery, useHealthQuery } from '../services/breezeApi';

export function SettingsPage() {
  const { data: health } = useHealthQuery();
  const { data: capabilities } = useCapabilitiesQuery();
  const { mode, effectiveMode, setMode } = useTheme();
  return (
    <div className="content-shell">
      <div className="page-heading">
        <div>
          <p className="eyebrow">CONNECTION</p>
          <h1>连接设置</h1>
          <p className="lede">独立浏览器前端与 Breeze CS 服务端共用同一套 API。</p>
        </div>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>服务端能力</CardTitle>
          <CardDescription>当前连接返回的协议能力。</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="settings-list">
            <div className="settings-control-row">
              <span>界面主题</span>
              <select
                aria-label="界面主题"
                value={mode}
                onChange={(event) => setMode(event.target.value as ThemeMode)}
              >
                <option value="system">跟随系统</option>
                <option value="light">浅色模式</option>
                <option value="dark">深色模式</option>
              </select>
            </div>
            <div>
              <span>当前外观</span>
              <b>{effectiveMode === 'light' ? '浅色' : '深色'}</b>
            </div>
            <div>
              <span>服务状态</span>
              <b>{health?.status === 'ok' ? '正常' : '未连接'}</b>
            </div>
            <div>
              <span>协议版本</span>
              <b>{capabilities ? 'v1' : '—'}</b>
            </div>
            <div>
              <span>浏览器前端</span>
              <b>{capabilities?.browser_frontend ? '已开启' : '—'}</b>
            </div>
            <div>
              <span>服务端下载</span>
              <b>{capabilities?.server_download ? '已开启' : '未开启'}</b>
            </div>
            <div>
              <span>插件安装管理</span>
              <b>{capabilities?.plugin_management ? '已开启' : '未开启'}</b>
            </div>
          </div>
          <Link className="settings-note" to="/">
            服务端地址由当前页面来源决定，部署时可直接访问同源 API。
          </Link>
        </CardContent>
      </Card>
    </div>
  );
}
