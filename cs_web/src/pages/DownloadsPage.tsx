import {
  AlertCircle,
  CheckCircle2,
  CloudDownload,
  LoaderCircle,
  XCircle,
} from 'lucide-react';
import { Link } from 'react-router-dom';

import { useAppSelector } from '../app/hooks';
import { Button } from '../components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../components/ui/card';
import { useCancelDownloadMutation, useDownloadsQuery } from '../services/breezeApi';

function statusIcon(status: string) {
  if (status === 'completed') return <CheckCircle2 size={18} />;
  if (status === 'failed') return <AlertCircle size={18} />;
  if (status === 'cancelled') return <XCircle size={18} />;
  return <LoaderCircle className="spin" size={18} />;
}

export function DownloadsPage() {
  const user = useAppSelector((state) => state.auth.user);
  const state = useDownloadsQuery(undefined, {
    skip: !user,
    pollingInterval: user ? 5000 : 0,
  });
  const [cancel] = useCancelDownloadMutation();
  const items = state.data?.items ?? [];

  if (!user)
    return (
      <div className="content-shell">
        <Card className="empty-state large">
          <CloudDownload size={24} />
          <div>
            <b>登录后查看下载任务</b>
            <p>服务端下载任务和进度会跨设备保留。</p>
          </div>
          <Link to="/login">
            <Button>去登录</Button>
          </Link>
        </Card>
      </div>
    );

  return (
    <div className="content-shell downloads-shell">
      <div className="page-heading">
        <div>
          <p className="eyebrow">REMOTE DOWNLOADS</p>
          <h1>下载任务</h1>
          <p className="lede">服务端下载开启后，任务会在这里持续运行。</p>
        </div>
        <div className="heading-icon">
          <CloudDownload size={22} />
        </div>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>任务队列</CardTitle>
          <CardDescription>
            {items.length ? `${items.length} 个任务` : '当前没有任务'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {items.length === 0 ? (
            <div className="empty-inline">
              <CloudDownload size={20} />
              <span>从漫画详情页选择章节后创建服务端下载。</span>
            </div>
          ) : (
            <div className="download-list">
              {items.map((item) => {
                const payload = item.payload;
                const canCancel = !['completed', 'failed', 'cancelled'].includes(
                  item.status,
                );
                return (
                  <div className="download-row" key={item.task_id}>
                    <span className={`download-status ${item.status}`}>
                      {statusIcon(item.status)}
                    </span>
                    <div className="download-info">
                      <b>{String(payload.comic_id ?? '未命名漫画')}</b>
                      <small>
                        {String(payload.plugin_id ?? '未知图源')} · {item.status}
                      </small>
                      <div className="progress-track">
                        <span style={{ width: `${item.progress}%` }} />
                      </div>
                    </div>
                    <strong className="download-percent">{item.progress}%</strong>
                    {canCancel && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => void cancel(item.task_id)}
                      >
                        取消
                      </Button>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
