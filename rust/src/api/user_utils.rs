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

            init_subscriber(
                tracing_subscriber::registry().with(filter).with(
                    fmt::layer()
                        .with_writer(writer)
                        .event_format(BoxedFormatter { with_ansi: false }),
                ),
                "Android",
            );

            tracing::info!("Tracing initialized (Android)");
            return;
        }

        #[cfg(any(target_os = "ios", target_os = "macos"))]
        {
            init_subscriber(
                tracing_subscriber::registry()
                    .with(filter)
                    .with(fmt::layer().event_format(BoxedFormatter { with_ansi: true })),
                "iOS/macOS",
            );
            tracing::info!("Tracing initialized (iOS/macOS)");
            return;
        }

        #[cfg(target_family = "wasm")]
        {
            init_subscriber(
                tracing_subscriber::registry()
                    .with(filter)
                    .with(fmt::layer().event_format(BoxedFormatter { with_ansi: false })),
                "WASM",
            );
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
            init_subscriber(
                tracing_subscriber::registry()
                    .with(filter)
                    .with(fmt::layer().event_format(BoxedFormatter { with_ansi: true })),
                "Desktop",
            );
            tracing::info!("Tracing initialized (Desktop)");
        }
    });
}

fn init_subscriber<S>(subscriber: S, platform: &str)
where
    S: tracing::Subscriber + Send + Sync + 'static,
{
    use tracing_log::{AsLog, LogTracer};

    tracing::dispatcher::set_global_default(subscriber.into())
        .unwrap_or_else(|_| panic!("Failed to initialize tracing subscriber ({platform})"));

    // html5ever / selectors emit a huge amount of DEBUG records through the `log`
    // crate. `tracing-log` forwards those records as tracing events whose
    // metadata target is "log", so `EnvFilter` cannot suppress them by crate
    // name. Drop them at the LogTracer level instead.
    LogTracer::builder()
        .with_max_level(tracing::metadata::LevelFilter::current().as_log())
        .ignore_crate("html5ever")
        .ignore_crate("selectors")
        .init()
        .unwrap_or_else(|_| panic!("Failed to initialize log tracer ({platform})"));
}

fn default_log_level(enabled: bool) -> String {
    if enabled {
        "debug,hyper_util=warn,reqwest=warn,h2=warn".to_string()
    } else {
        "warn".to_string()
    }
}
