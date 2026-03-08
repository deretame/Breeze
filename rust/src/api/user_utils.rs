use std::sync::OnceLock;

use tracing::debug;
use tracing_subscriber::EnvFilter;

static TRACING_INIT: OnceLock<()> = OnceLock::new();

pub fn setup_default_user_utils() {
    setup_tracing();
    setup_backtrace();
}

fn setup_backtrace() {
    if std::env::var("RUST_BACKTRACE").is_err_and(|e| e == std::env::VarError::NotPresent) {
        unsafe { std::env::set_var("RUST_BACKTRACE", "1") };
    } else {
        debug!("skip setup RUST_BACKTRACE because it already exists");
    }
}

fn setup_tracing() {
    if TRACING_INIT.get().is_some() {
        return;
    }

    let _ = tracing_log::LogTracer::init();

    let env_filter = match EnvFilter::try_from_default_env() {
        Ok(filter) => filter,
        Err(_) => EnvFilter::new(default_log_level_directive()),
    };

    let subscriber = tracing_subscriber::fmt()
        .with_env_filter(env_filter)
        .with_file(true)
        .with_line_number(true)
        .with_target(true)
        .with_thread_names(true)
        .with_ansi(cfg!(debug_assertions));

    if subscriber.try_init().is_ok() {
        let _ = TRACING_INIT.set(());
    }
}

fn default_log_level_directive() -> &'static str {
    if cfg!(debug_assertions) {
        "debug"
    } else {
        "warn"
    }
}
