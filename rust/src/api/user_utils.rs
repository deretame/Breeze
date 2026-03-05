pub fn setup_default_user_utils() {
    setup_log_to_console();
    setup_backtrace();
}

fn setup_backtrace() {
    if std::env::var("RUST_BACKTRACE").is_err_and(|e| e == std::env::VarError::NotPresent) {
        unsafe { std::env::set_var("RUST_BACKTRACE", "1") };
    } else {
        log::debug!("Skip setup RUST_BACKTRACE because there is already environment variable");
    }
}

fn setup_log_to_console() {
    #[cfg(target_os = "android")]
    {
        let _ = android_logger::init_once(
            android_logger::Config::default()
                .with_tag("frb_user")
                .with_max_level(default_log_level()),
        );
        return;
    }

    #[cfg(any(target_os = "ios", target_os = "macos"))]
    {
        let _ = oslog::OsLogger::new("frb_user")
            .level_filter(default_log_level())
            .init();
        return;
    }

    #[cfg(target_family = "wasm")]
    {
        let _ = crate::misc::web_utils::WebConsoleLogger::init();
        return;
    }

    #[cfg(all(
        not(target_family = "wasm"),
        not(target_os = "android"),
        not(target_os = "ios"),
        not(target_os = "macos")
    ))]
    let mut builder = env_logger::Builder::from_default_env();

    #[cfg(all(
        not(target_family = "wasm"),
        not(target_os = "android"),
        not(target_os = "ios"),
        not(target_os = "macos")
    ))]
    if std::env::var("RUST_LOG").is_err_and(|e| e == std::env::VarError::NotPresent) {
        builder.filter_level(default_log_level());
    }

    #[cfg(all(
        not(target_family = "wasm"),
        not(target_os = "android"),
        not(target_os = "ios"),
        not(target_os = "macos")
    ))]
    {
        if !cfg!(debug_assertions) {
            builder
                .format_timestamp(None)
                .format_module_path(false)
                .format_target(false);
        }
        let _ = builder.try_init();
    }
}

fn default_log_level() -> log::LevelFilter {
    if cfg!(debug_assertions) {
        log::LevelFilter::Debug
    } else {
        log::LevelFilter::Warn
    }
}
