pub fn setup_default_user_utils() {
    setup_backtrace();
}

fn setup_backtrace() {
    if std::env::var("RUST_BACKTRACE").is_err_and(|e| e == std::env::VarError::NotPresent) {
        unsafe { std::env::set_var("RUST_BACKTRACE", "1") };
    } else {
        tracing::debug!("Skip setup RUST_BACKTRACE because there is already environment variable");
    }
}

pub(crate) fn setup_log_to_console(enabled: bool) {
    static INIT: std::sync::Once = std::sync::Once::new();
    INIT.call_once(|| {
        if !enabled {
            return;
        }
        #[allow(unused_imports)]
        use tracing_subscriber::{EnvFilter, fmt, prelude::*};

        use crate::api::logger::BoxedFormatter;

        let filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| EnvFilter::new(default_log_level(enabled)));

        #[cfg(target_os = "android")]
        {
            use tracing_logcat::{LogcatMakeWriter, LogcatTag};

            let writer = LogcatMakeWriter::new(LogcatTag::Fixed("windcore".to_owned()))
                .expect("Failed to initialize logcat writer");

            tracing_subscriber::registry()
                .with(filter)
                .with(
                    fmt::layer()
                        .with_writer(writer)
                        .event_format(BoxedFormatter { with_ansi: false }),
                )
                .try_init()
                .expect("Failed to initialize tracing subscriber (Android)");

            tracing::info!("Tracing initialized (Android)");
            return;
        }

        #[cfg(any(target_os = "ios", target_os = "macos"))]
        {
            tracing_subscriber::registry()
                .with(filter)
                .with(fmt::layer().event_format(BoxedFormatter { with_ansi: true }))
                .try_init()
                .expect("Failed to initialize tracing subscriber (iOS/macOS)");
            tracing::info!("Tracing initialized (iOS/macOS)");
            return;
        }

        #[cfg(target_family = "wasm")]
        {
            tracing_subscriber::registry()
                .with(filter)
                .with(fmt::layer().event_format(BoxedFormatter { with_ansi: false }))
                .try_init()
                .expect("Failed to initialize tracing subscriber (WASM)");
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
            tracing_subscriber::registry()
                .with(filter)
                .with(fmt::layer().event_format(BoxedFormatter { with_ansi: true }))
                .try_init()
                .expect("Failed to initialize tracing subscriber (Desktop)");
            tracing::info!("Tracing initialized (Desktop)");
        }
    });
}

fn default_log_level(enabled: bool) -> String {
    if enabled {
        "debug,hyper_util=warn,reqwest=warn,h2=warn".to_string()
    } else {
        "warn".to_string()
    }
}
