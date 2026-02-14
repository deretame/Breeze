use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;

/// 启动一个命名管道监听器，等待外部进程（如安装器）发送关闭信号。
/// 当收到信号时，通过 StreamSink 向 Dart 侧发送 `true`。
/// 仅在 Windows 上有效，其他平台不做任何操作。
#[frb]
pub fn start_shutdown_listener(sink: StreamSink<bool>) -> anyhow::Result<()> {
    #[cfg(target_os = "windows")]
    {
        use tokio::net::windows::named_pipe::ServerOptions;

        std::thread::spawn(move || {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();
            rt.block_on(async {
                loop {
                    let pipe_name = r"\\.\pipe\zephyr_shutdown_signal";

                    let server = ServerOptions::new()
                        .first_pipe_instance(true)
                        .create(pipe_name);

                    if let Ok(server) = server {
                        // 等待客户端连接
                        if server.connect().await.is_ok() {
                            // 收到连接，发送退出信号给 Dart
                            let _ = sink.add(true);
                            break;
                        }
                    } else {
                        // 管道创建失败（可能已存在），休眠后重试
                        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
                    }
                }
            });
        });
    }

    // 非 Windows 平台不做任何操作，避免编译警告
    #[cfg(not(target_os = "windows"))]
    let _ = sink;

    Ok(())
}
