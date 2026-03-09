pub fn setup_default_user_utils() {
    setup_log_to_console();
    setup_backtrace();
}

fn setup_backtrace() {
    if std::env::var("RUST_BACKTRACE").is_err_and(|e| e == std::env::VarError::NotPresent) {
        unsafe { std::env::set_var("RUST_BACKTRACE", "1") };
    } else {
        tracing::debug!("Skip setup RUST_BACKTRACE because there is already environment variable");
    }
}

fn setup_log_to_console() {
    static INIT: std::sync::Once = std::sync::Once::new();
    INIT.call_once(|| {
        #[cfg(debug_assertions)]
        {
            #[allow(unused_imports)]
            use tracing_subscriber::{EnvFilter, fmt, prelude::*};

            let filter = EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new(default_log_level()));

            #[cfg(target_os = "android")]
            {
                use tracing_logcat::{LogcatMakeWriter, LogcatTag};

                let writer = LogcatMakeWriter::new(LogcatTag::Fixed("windcore".to_owned()))
                    .expect("Failed to initialize logcat writer");

                let _ = tracing_subscriber::registry()
                    .with(filter)
                    .with(
                        fmt::layer()
                            .with_writer(writer)
                            .with_ansi(false)
                            .with_target(true)
                            .with_line_number(true)
                            .with_thread_ids(true)
                            .with_file(true)
                            .with_thread_names(true),
                    )
                    .try_init();

                tracing::info!("Tracing initialized (Android)");
                return;
            }

            #[cfg(any(target_os = "ios", target_os = "macos"))]
            {
                let _ = tracing_subscriber::registry()
                    .with(filter)
                    .with(
                        fmt::layer()
                            .with_target(true)
                            .with_line_number(true)
                            .with_thread_ids(true)
                            .with_file(true)
                            .with_thread_names(true),
                    )
                    .try_init();
                tracing::info!("Tracing initialized (iOS/macOS)");
                return;
            }

            #[cfg(target_family = "wasm")]
            {
                let _ = tracing_subscriber::registry()
                    .with(filter)
                    .with(
                        fmt::layer()
                            .with_target(true)
                            .with_line_number(true)
                            .with_thread_ids(false)
                            .with_file(true)
                            .with_thread_names(false),
                    )
                    .try_init();
                tracing::info!("Tracing initialized (WASM)");
                return;
            }

            #[cfg(all(
                not(target_family = "wasm"),
                not(target_os = "android"),
                not(target_os = "ios"),
                not(target_os = "macos")
            ))]
            {
                let _ = tracing_subscriber::registry()
                    .with(filter)
                    .with(
                        fmt::layer()
                            .with_target(true)
                            .with_line_number(true)
                            .with_thread_ids(true)
                            .with_file(true)
                            .with_thread_names(true),
                    )
                    .try_init();
                tracing::info!("Tracing initialized (Desktop)");
            }
        }
    });
}

fn default_log_level() -> String {
    if cfg!(debug_assertions) {
        "debug".to_string()
    } else {
        "warn".to_string()
    }
}
