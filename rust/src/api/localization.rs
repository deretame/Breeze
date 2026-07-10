//! 系统本地化信息获取（locale / timezone）。
//! System localization info (locale / timezone).

use anyhow::{Context, Result};
use chrono::Local;
use flutter_rust_bridge::frb;
use icu_locale::{Locale, LocaleCanonicalizer, langid};

/// 获取系统首选语言，返回统一的 BCP-47 字符串（等价于 Web 的 `navigator.language`）。
/// Get the system's most preferred language as a unified BCP-47 string.
/// Equivalent to `navigator.language` on the web.
///
/// 先用 ICU4X 做规范化和常见别名处理，再按本项目惯例对中文做简化：
/// - `zh-Hans-CN` / `zh-Hans` / `zh-CN` / `zh` → `zh-CN`
/// - `zh-Hant-TW` / `zh-Hant` / `zh-TW` → `zh-TW`
/// - `zh-Hant-HK` / `zh-HK` → `zh-HK`
///
/// 其他 locale 按 ICU4X 规范化输出，如 `en-US`、`de-DE`、`ja-JP`。
#[frb(sync)]
pub fn get_system_language() -> Result<String> {
    let raw = sys_locale::get_locale().context("failed to get system locale")?;
    normalize_locale(&raw)
}

/// 获取系统按优先级排序的语言列表（等价于 Web 的 `navigator.languages`）。
/// Get the system's preferred languages in descending order of preference.
/// Equivalent to `navigator.languages` on the web.
#[frb(sync)]
pub fn get_system_languages() -> Result<Vec<String>> {
    let raw_locales: Vec<String> = sys_locale::get_locales().collect();

    let mut seen = std::collections::HashSet::new();
    let mut languages = Vec::new();
    for raw in raw_locales {
        if let Ok(tag) = normalize_locale(&raw) {
            if seen.insert(tag.clone()) {
                languages.push(tag);
            }
        }
    }

    if languages.is_empty() {
        languages.push("en-US".to_string());
    }

    Ok(languages)
}

fn normalize_locale(raw: &str) -> Result<String> {
    // sys-locale / libc 返回的 locale 可能带下划线或编码后缀，例如 `zh_CN.UTF-8`。
    let cleaned = raw.replace('_', "-");
    let cleaned = cleaned
        .split_once('.')
        .map(|(tag, _)| tag)
        .unwrap_or(&cleaned);

    let mut locale: Locale = cleaned
        .parse()
        .with_context(|| format!("failed to parse locale: {raw}"))?;

    // ICU4X 规范化：处理大小写、常见别名等。
    let canonicalizer = LocaleCanonicalizer::new_extended();
    canonicalizer.canonicalize(&mut locale);

    // 本项目惯例：简化中文 locale。
    if locale.id.language == langid!("zh").language {
        let script = locale.id.script.map(|s| s.as_str().to_string());
        let region = locale.id.region.map(|r| r.as_str().to_string());

        let simplified = match (script.as_deref(), region.as_deref()) {
            (Some("Hans"), Some("CN")) => "zh-CN",
            (Some("Hant"), Some("TW")) => "zh-TW",
            (Some("Hant"), Some("HK")) => "zh-HK",
            (Some("Hans"), None) => "zh-CN",
            (Some("Hant"), None) => "zh-TW",
            (None, None) => "zh-CN",
            _ => return Ok(locale.id.to_string()),
        };
        return Ok(simplified.to_string());
    }

    Ok(locale.id.to_string())
}

/// 获取系统时区 IANA 名称，如 `Asia/Shanghai`。
/// Get the system timezone IANA name, e.g. `Asia/Shanghai`.
#[frb(sync)]
pub fn get_system_timezone() -> Result<String> {
    let raw = iana_time_zone::get_timezone().context("failed to get system timezone")?;
    Ok(canonicalize_iana_id(&raw).unwrap_or_else(|| raw))
}

fn canonicalize_iana_id(raw: &str) -> Option<String> {
    use icu_time::zone::iana::IanaParserExtended;
    let parsed = IanaParserExtended::new().parse(raw);
    if parsed.time_zone.is_unknown() {
        None
    } else {
        Some(parsed.canonical.to_string())
    }
}

/// 获取系统时区相对于 UTC 的偏移，格式为 `+HH:MM` / `-HH:MM`。
/// Get the system timezone offset from UTC as `+HH:MM` / `-HH:MM`.
#[frb(sync)]
pub fn get_system_timezone_offset() -> Result<String> {
    // 优先用 tz-rs 计算当前本地时区偏移（Unix 平台）。
    #[cfg(unix)]
    if let Ok(offset) = timezone_offset_via_tz_rs() {
        return Ok(format_offset_seconds(offset));
    }

    // 回退到 chrono。
    let offset = Local::now().offset().local_minus_utc();
    Ok(format_offset_seconds(offset))
}

#[cfg(unix)]
fn timezone_offset_via_tz_rs() -> Result<i32> {
    let tz = tz::TimeZone::local().context("failed to get local timezone via tz-rs")?;
    let local_time_type = tz
        .find_current_local_time_type()
        .context("failed to find current local time type")?;
    Ok(local_time_type.ut_offset())
}

fn format_offset_seconds(seconds: i32) -> String {
    let sign = if seconds < 0 { '-' } else { '+' };
    let abs = seconds.abs();
    let hours = abs / 3600;
    let minutes = (abs % 3600) / 60;
    format!("{sign}{:02}:{:02}", hours, minutes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_chinese_locales() {
        assert_eq!(normalize_locale("zh-Hans-CN").unwrap(), "zh-CN");
        assert_eq!(normalize_locale("zh-Hans").unwrap(), "zh-CN");
        assert_eq!(normalize_locale("zh-CN").unwrap(), "zh-CN");
        assert_eq!(normalize_locale("zh-Hant-TW").unwrap(), "zh-TW");
        assert_eq!(normalize_locale("zh-Hant").unwrap(), "zh-TW");
        assert_eq!(normalize_locale("zh-Hant-HK").unwrap(), "zh-HK");
        assert_eq!(normalize_locale("zh-HK").unwrap(), "zh-HK");
        assert_eq!(normalize_locale("zh").unwrap(), "zh-CN");
        assert_eq!(normalize_locale("zh_CN.UTF-8").unwrap(), "zh-CN");
    }

    #[test]
    fn normalize_other_locales() {
        assert_eq!(normalize_locale("en-US").unwrap(), "en-US");
        assert_eq!(normalize_locale("de_DE").unwrap(), "de-DE");
        assert_eq!(normalize_locale("ja-JP").unwrap(), "ja-JP");
    }

    #[test]
    fn canonicalize_timezone_ids() {
        assert_eq!(
            canonicalize_iana_id("Asia/Calcutta"),
            Some("Asia/Kolkata".to_string())
        );
        assert_eq!(
            canonicalize_iana_id("Asia/Shanghai"),
            Some("Asia/Shanghai".to_string())
        );
        assert_eq!(canonicalize_iana_id("Mars/Phobos"), None);
    }

    #[test]
    fn format_offsets() {
        assert_eq!(format_offset_seconds(28800), "+08:00");
        assert_eq!(format_offset_seconds(-28800), "-08:00");
        assert_eq!(format_offset_seconds(0), "+00:00");
        assert_eq!(format_offset_seconds(330 * 60), "+05:30");
    }
}
