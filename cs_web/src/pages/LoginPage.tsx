import {
  ArrowRight,
  BookOpen,
  CheckCircle2,
  LockKeyhole,
  UserRound,
} from 'lucide-react';
import { FormEvent, useEffect, useState } from 'react';
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
import { useLoginMutation, useRegisterMutation } from '../services/breezeApi';

function errorMessage(error: unknown) {
  if (error && typeof error === 'object' && 'data' in error) {
    const data = (error as { data?: { message?: string } }).data;
    if (data?.message) return data.message;
  }
  return '请求失败，请检查服务端是否已经启动。';
}

export function LoginPage() {
  const navigate = useNavigate();
  const user = useAppSelector((state) => state.auth.user);
  const [registerMode, setRegisterMode] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [login, loginState] = useLoginMutation();
  const [register, registerState] = useRegisterMutation();
  const requestState = registerMode ? registerState : loginState;

  useEffect(() => {
    if (user) navigate('/', { replace: true });
  }, [navigate, user]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      if (registerMode) {
        await register({ username, password }).unwrap();
      } else {
        await login({ username, password }).unwrap();
      }
      navigate('/', { replace: true });
    } catch {
      // The mutation state renders the server's structured error below.
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-glow auth-glow-one" />
      <div className="auth-glow auth-glow-two" />
      <div className="auth-layout">
        <section className="auth-pitch">
          <Link className="brand auth-brand" to="/">
            <span className="brand-mark">
              <BookOpen size={18} />
            </span>
            Breeze
          </Link>
          <p className="eyebrow">BREEZE CS</p>
          <h1>
            把书架带到
            <br />
            <em>每一块屏幕。</em>
          </h1>
          <p className="auth-pitch-copy">
            连接你的 Breeze 服务端，在桌面、手机和浏览器之间继续阅读。
          </p>
          <div className="auth-benefits">
            <span>
              <CheckCircle2 size={16} />
              收藏和历史跨设备同步
            </span>
            <span>
              <CheckCircle2 size={16} />
              插件在服务端安全运行
            </span>
          </div>
        </section>

        <Card className="auth-card">
          <CardHeader>
            <div className="auth-icon">
              <LockKeyhole size={20} />
            </div>
            <CardTitle>{registerMode ? '创建你的账号' : '欢迎回来'}</CardTitle>
            <CardDescription>
              {registerMode
                ? '注册后即可连接当前 Breeze 服务。'
                : '登录到 Breeze CS，继续你的阅读。'}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form className="auth-form" onSubmit={submit}>
              <label>
                用户名
                <span className="input-wrap">
                  <UserRound size={17} />
                  <input
                    required
                    minLength={3}
                    maxLength={64}
                    value={username}
                    onChange={(event) => setUsername(event.target.value)}
                    placeholder="输入用户名"
                  />
                </span>
              </label>
              <label>
                密码
                <span className="input-wrap">
                  <LockKeyhole size={17} />
                  <input
                    required
                    minLength={8}
                    maxLength={256}
                    type="password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    placeholder="至少 8 个字符"
                  />
                </span>
              </label>
              {requestState.error && (
                <p className="form-error">{errorMessage(requestState.error)}</p>
              )}
              <Button
                className="auth-submit"
                size="lg"
                type="submit"
                disabled={requestState.isLoading}
              >
                {requestState.isLoading
                  ? '连接中…'
                  : registerMode
                    ? '创建账号'
                    : '登录'}
                <ArrowRight size={17} />
              </Button>
            </form>
            <button
              className="auth-switch"
              onClick={() => setRegisterMode((value) => !value)}
              type="button"
            >
              {registerMode ? '已有账号？返回登录' : '还没有账号？创建一个'}
            </button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
