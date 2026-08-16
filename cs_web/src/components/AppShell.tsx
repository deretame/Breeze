import {
  BookOpen,
  Compass,
  Download,
  Home,
  Library,
  LogIn,
  LogOut,
  Settings2,
} from 'lucide-react';
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { useLogoutMutation } from '../services/breezeApi';
import { Button } from './ui/button';

const links = [
  { to: '/', label: '总览', icon: Home },
  { to: '/search', label: '发现漫画', icon: Compass },
  { to: '/library', label: '我的书架', icon: Library },
  { to: '/downloads', label: '下载任务', icon: Download },
];

export function AppShell() {
  const location = useLocation();
  const user = useAppSelector((state) => state.auth.user);
  const [logout, { isLoading: isLoggingOut }] = useLogoutMutation();
  const isReader = location.pathname.startsWith('/reader');

  return (
    <div className={isReader ? 'app-root reader-root' : 'app-root'}>
      <header className="topbar">
        <Link className="brand" to="/">
          <span className="brand-mark">
            <BookOpen size={18} strokeWidth={2.5} />
          </span>
          <span>Breeze</span>
        </Link>
        <div className="topbar-actions">
          {user ? (
            <>
              <span className="user-chip">
                <span className="user-dot" />
                {user.username}
              </span>
              <Button
                aria-label="退出登录"
                className="topbar-logout"
                variant="ghost"
                size="sm"
                disabled={isLoggingOut}
                onClick={() => void logout()}
              >
                <LogOut size={16} />
                <span>退出</span>
              </Button>
            </>
          ) : (
            <Link className="login-link" to="/login">
              <LogIn size={16} />
              登录
            </Link>
          )}
        </div>
      </header>

      <aside className="sidebar">
        <div className="sidebar-caption">工作区</div>
        <nav className="sidebar-nav" aria-label="主导航">
          {links.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              className={({ isActive }) => (isActive ? 'nav-item active' : 'nav-item')}
              end={to === '/'}
              to={to}
            >
              <Icon size={18} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div className="sidebar-caption">服务</div>
          <NavLink className="nav-item" to="/settings">
            <Settings2 size={18} />
            <span>连接设置</span>
          </NavLink>
          <div className="server-hint">
            <span className="status-pulse" />
            CS 服务在线时可用
          </div>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>

      <nav className="mobile-nav" aria-label="移动端导航">
        {links.slice(0, 4).map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            className={({ isActive }) =>
              isActive ? 'mobile-nav-item active' : 'mobile-nav-item'
            }
            end={to === '/'}
            to={to}
          >
            <Icon size={19} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
