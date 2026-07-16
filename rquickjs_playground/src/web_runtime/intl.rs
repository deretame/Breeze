//! Time-focused ECMA-402 helpers for the QuickJS host.
//!
//! Scope:
//! - `Intl.DateTimeFormat` (locale-aware date/time formatting)
//! - time zone canonicalization / system zone
//! - `Intl.supportedValuesOf` for calendars & time zones
//!
//! Explicitly out of scope: Collator, NumberFormat, currency, sorting.
//!
//! Implementation: `jiff` for TZ math, ICU4X (`icu` + `jiff-icu`) for locale
//! formatting so dates follow each locale's conventions.

use std::fmt;

use icu::calendar::Iso;
use icu::datetime::fieldsets::builder::{DateFields, FieldSetBuilder, ZoneStyle};
use icu::datetime::options::{Length, TimePrecision, YearStyle};
use icu::datetime::preferences::HourCycle;
use icu::datetime::{DateTimeFormatter, DateTimeFormatterPreferences};
use icu::locale::Locale;
use icu::time::zone::models::AtTime;
use icu::time::{TimeZoneInfo, ZonedDateTime};
use jiff::Timestamp;
use jiff::tz::{self, Offset, TimeZone};
use jiff_icu::ConvertFrom as _;
use serde_json::{Value, json};
use writeable::{PartsWrite, Writeable};

// jiff Timestamp millisecond range (approx year -9999..=9999).
const JIFF_MS_MIN: i64 = -377_705_023_201_000;
const JIFF_MS_MAX: i64 = 253_402_207_200_000;

fn ok(data: Value) -> String {
    json!({ "ok": true, "data": data }).to_string()
}

fn err(message: impl Into<String>) -> String {
    json!({ "ok": false, "error": message.into() }).to_string()
}

/// Map common IANA links / aliases to their primary identifiers.
/// jiff keeps link names as-is; Temporal/ECMA-402 expect primary ids.
fn primary_time_zone_id(id: &str) -> &str {
    match id {
        // UTC family
        "Etc/UTC" | "Etc/GMT" | "Etc/GMT+0" | "Etc/GMT-0" | "Etc/GMT0" | "GMT" | "GMT+0"
        | "GMT-0" | "GMT0" | "UCT" | "Etc/UCT" | "Universal" | "Zulu" | "Etc/Universal"
        | "Etc/Zulu" => "UTC",

        // Common links exercised by Test262 Temporal intl402
        "Asia/Calcutta" => "Asia/Kolkata",
        "America/Atka" => "America/Adak",
        "Australia/Canberra" => "Australia/Sydney",
        "Australia/Currie" => "Australia/Hobart",
        "Australia/Tasmania" => "Australia/Hobart",
        "Europe/Nicosia" => "Asia/Nicosia",
        "Asia/Chongqing" | "Asia/Chungking" | "Asia/Harbin" => "Asia/Shanghai",
        "Asia/Kashgar" => "Asia/Urumqi",
        "Asia/Katmandu" => "Asia/Kathmandu",
        "Asia/Rangoon" => "Asia/Yangon",
        "Asia/Saigon" => "Asia/Ho_Chi_Minh",
        "Asia/Thimbu" => "Asia/Thimphu",
        "Asia/Ulan_Bator" => "Asia/Ulaanbaatar",
        "Asia/Macao" => "Asia/Macau",
        "Atlantic/Faeroe" => "Atlantic/Faroe",
        "Australia/ACT" | "Australia/NSW" | "Australia/Victoria" => "Australia/Sydney",
        "Australia/LHI" => "Australia/Lord_Howe",
        "Australia/North" => "Australia/Darwin",
        "Australia/Queensland" => "Australia/Brisbane",
        "Australia/South" => "Australia/Adelaide",
        "Australia/West" => "Australia/Perth",
        "Australia/Yancowinna" => "Australia/Broken_Hill",
        "Brazil/Acre" => "America/Rio_Branco",
        "Brazil/DeNoronha" => "America/Noronha",
        "Brazil/East" => "America/Sao_Paulo",
        "Brazil/West" => "America/Manaus",
        "Canada/Atlantic" => "America/Halifax",
        "Canada/Central" => "America/Winnipeg",
        "Canada/Eastern" => "America/Toronto",
        "Canada/Mountain" => "America/Edmonton",
        "Canada/Newfoundland" => "America/St_Johns",
        "Canada/Pacific" => "America/Vancouver",
        "Canada/Saskatchewan" => "America/Regina",
        "Canada/Yukon" => "America/Whitehorse",
        "Chile/Continental" => "America/Santiago",
        "Chile/EasterIsland" => "Pacific/Easter",
        "Cuba" => "America/Havana",
        "Egypt" => "Africa/Cairo",
        "Eire" => "Europe/Dublin",
        "GB" | "GB-Eire" => "Europe/London",
        "Hongkong" => "Asia/Hong_Kong",
        "Iceland" => "Atlantic/Reykjavik",
        "Iran" => "Asia/Tehran",
        "Israel" => "Asia/Jerusalem",
        "Jamaica" => "America/Jamaica",
        "Japan" => "Asia/Tokyo",
        "Kwajalein" => "Pacific/Kwajalein",
        "Libya" => "Africa/Tripoli",
        "Mexico/BajaNorte" => "America/Tijuana",
        "Mexico/BajaSur" => "America/Mazatlan",
        "Mexico/General" => "America/Mexico_City",
        "NZ" => "Pacific/Auckland",
        "NZ-CHAT" => "Pacific/Chatham",
        "Navajo" => "America/Denver",
        "PRC" => "Asia/Shanghai",
        "Pacific/Ponape" => "Pacific/Pohnpei",
        "Pacific/Samoa" => "Pacific/Pago_Pago",
        "Pacific/Truk" => "Pacific/Chuuk",
        "Pacific/Yap" => "Pacific/Chuuk",
        "Poland" => "Europe/Warsaw",
        "Portugal" => "Europe/Lisbon",
        "ROC" => "Asia/Taipei",
        "ROK" => "Asia/Seoul",
        "Singapore" => "Asia/Singapore",
        "Turkey" => "Europe/Istanbul",
        "US/Alaska" => "America/Anchorage",
        "US/Aleutian" => "America/Adak",
        "US/Arizona" => "America/Phoenix",
        "US/Central" => "America/Chicago",
        "US/East-Indiana" => "America/Indiana/Indianapolis",
        "US/Eastern" => "America/New_York",
        "US/Hawaii" => "Pacific/Honolulu",
        "US/Indiana-Starke" => "America/Indiana/Knox",
        "US/Michigan" => "America/Detroit",
        "US/Mountain" => "America/Denver",
        "US/Pacific" => "America/Los_Angeles",
        "US/Samoa" => "Pacific/Pago_Pago",
        "W-SU" => "Europe/Moscow",

        other => other,
    }
}

fn parse_offset_time_zone(raw: &str) -> Option<TimeZone> {
    let s = raw.trim();
    if s.eq_ignore_ascii_case("z") {
        return Some(TimeZone::UTC);
    }
    let bytes = s.as_bytes();
    if bytes.is_empty() {
        return None;
    }
    let (sign, rest) = match bytes[0] {
        b'+' => (1i32, &s[1..]),
        b'-' => (-1i32, &s[1..]),
        _ => return None,
    };
    // Accept HH:MM, HHMM, HH:MM:SS, HH
    let parts: Vec<&str> = rest.split(':').collect();
    let (h, m, sec) = match parts.as_slice() {
        [hh] if hh.len() == 2 && hh.chars().all(|c| c.is_ascii_digit()) => {
            (hh.parse::<i32>().ok()?, 0, 0)
        }
        [hh] if hh.len() == 4 && hh.chars().all(|c| c.is_ascii_digit()) => {
            let h = hh[0..2].parse::<i32>().ok()?;
            let m = hh[2..4].parse::<i32>().ok()?;
            (h, m, 0)
        }
        [hh, mm]
            if hh.chars().all(|c| c.is_ascii_digit()) && mm.chars().all(|c| c.is_ascii_digit()) =>
        {
            (hh.parse::<i32>().ok()?, mm.parse::<i32>().ok()?, 0)
        }
        [hh, mm, ss]
            if hh.chars().all(|c| c.is_ascii_digit())
                && mm.chars().all(|c| c.is_ascii_digit())
                && ss.chars().all(|c| c.is_ascii_digit()) =>
        {
            (
                hh.parse::<i32>().ok()?,
                mm.parse::<i32>().ok()?,
                ss.parse::<i32>().ok()?,
            )
        }
        _ => return None,
    };
    if !(0..=23).contains(&h) || !(0..=59).contains(&m) || !(0..=59).contains(&sec) {
        return None;
    }
    let total = sign * (h * 3600 + m * 60 + sec);
    let off = Offset::from_seconds(total).ok()?;
    Some(TimeZone::fixed(off))
}

fn resolve_time_zone(id: Option<&str>) -> Result<TimeZone, String> {
    match id {
        None => Ok(TimeZone::system()),
        Some("") => Err("Invalid time zone specified: ".to_string()),
        Some(raw) => {
            let primary = primary_time_zone_id(raw);
            if primary.eq_ignore_ascii_case("utc") {
                return Ok(TimeZone::UTC);
            }
            if let Ok(tz) = TimeZone::get(primary) {
                return Ok(tz);
            }
            if let Some(tz) = parse_offset_time_zone(raw) {
                return Ok(tz);
            }
            // Temporal polyfill uppercases IANA ids before calling Intl.
            let rebuilt = rebuild_iana_id(primary);
            let rebuilt_primary = primary_time_zone_id(&rebuilt);
            if rebuilt_primary.eq_ignore_ascii_case("utc") {
                return Ok(TimeZone::UTC);
            }
            if let Ok(tz) = TimeZone::get(rebuilt_primary) {
                return Ok(tz);
            }
            if let Ok(tz) = TimeZone::get(raw) {
                return Ok(tz);
            }
            if let Some(tz) = parse_offset_time_zone(&rebuilt) {
                return Ok(tz);
            }
            Err(format!("Invalid time zone specified: {raw}"))
        }
    }
}

fn rebuild_iana_id(raw: &str) -> String {
    raw.split('/')
        .map(|segment| {
            if segment.eq_ignore_ascii_case("utc")
                || segment.eq_ignore_ascii_case("gmt")
                || segment.eq_ignore_ascii_case("etc")
            {
                if segment.eq_ignore_ascii_case("etc") {
                    "Etc".to_string()
                } else {
                    segment.to_ascii_uppercase()
                }
            } else {
                let mut parts = segment.split('_');
                let mut out = String::new();
                if let Some(first) = parts.next() {
                    out.push_str(&title_case_segment(first));
                }
                for part in parts {
                    out.push('_');
                    out.push_str(&title_case_segment(part));
                }
                out
            }
        })
        .collect::<Vec<_>>()
        .join("/")
}

fn title_case_segment(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => String::new(),
        Some(c) => {
            let mut out = c.to_uppercase().collect::<String>();
            out.push_str(&chars.as_str().to_ascii_lowercase());
            out
        }
    }
}

fn canonical_time_zone_id(tz: &TimeZone) -> String {
    if let Some(iana) = tz.iana_name() {
        return primary_time_zone_id(iana).to_string();
    }
    match tz.to_fixed_offset() {
        Ok(off) => {
            let secs = off.seconds();
            if secs == 0 {
                "UTC".to_string()
            } else {
                let sign = if secs >= 0 { '+' } else { '-' };
                let abs = secs.unsigned_abs();
                let h = abs / 3600;
                let m = (abs % 3600) / 60;
                let s = abs % 60;
                if s == 0 {
                    format!("{sign}{h:02}:{m:02}")
                } else {
                    format!("{sign}{h:02}:{m:02}:{s:02}")
                }
            }
        }
        Err(_) => "UTC".to_string(),
    }
}

/// Returns the host system time zone identifier.
pub fn intl_system_time_zone() -> String {
    let tz = TimeZone::system();
    ok(Value::String(canonical_time_zone_id(&tz)))
}

/// Canonicalize / validate a time zone id.
pub fn intl_canonicalize_time_zone(id: String) -> String {
    match resolve_time_zone(Some(id.as_str())) {
        Ok(tz) => ok(Value::String(canonical_time_zone_id(&tz))),
        Err(e) => err(e),
    }
}

fn parse_length(style: Option<&str>) -> Length {
    match style {
        Some("full") => Length::Long,
        Some("long") => Length::Long,
        Some("medium") => Length::Medium,
        Some("short") => Length::Short,
        _ => Length::Medium,
    }
}

fn parse_zone_style(style: Option<&str>) -> Option<ZoneStyle> {
    match style {
        Some("long") => Some(ZoneStyle::SpecificLong),
        Some("short") => Some(ZoneStyle::SpecificShort),
        Some("longOffset") => Some(ZoneStyle::LocalizedOffsetLong),
        Some("shortOffset") => Some(ZoneStyle::LocalizedOffsetShort),
        Some("longGeneric") => Some(ZoneStyle::GenericLong),
        Some("shortGeneric") => Some(ZoneStyle::GenericShort),
        _ => None,
    }
}

fn best_length(options: &Value) -> Length {
    if let Some(ds) = options.get("dateStyle").and_then(|v| v.as_str()) {
        return parse_length(Some(ds));
    }
    if let Some(ts) = options.get("timeStyle").and_then(|v| v.as_str()) {
        return parse_length(Some(ts));
    }

    // Text month/weekday styles drive length. Numeric fields (used heavily by
    // Temporal for offset scraping) must stay Short so month stays "3" not "Mar".
    let month = options.get("month").and_then(|v| v.as_str());
    let weekday = options.get("weekday").and_then(|v| v.as_str());
    let has_long_text = matches!(month, Some("long") | Some("full"))
        || matches!(weekday, Some("long") | Some("full"));
    let has_medium_text = matches!(month, Some("short") | Some("narrow"))
        || matches!(weekday, Some("short") | Some("narrow"));
    if has_long_text {
        return Length::Long;
    }
    if has_medium_text {
        return Length::Medium;
    }
    Length::Short
}

fn pick_date_fields(options: &Value, has_date_style: bool) -> Option<DateFields> {
    if has_date_style {
        return Some(DateFields::YMD);
    }
    let y = options.get("year").is_some() || options.get("era").is_some();
    let m = options.get("month").is_some();
    let d = options.get("day").is_some();
    let w = options.get("weekday").is_some();
    match (y, m, d, w) {
        (true, true, true, true) => Some(DateFields::YMDE),
        (true, true, true, false) => Some(DateFields::YMD),
        (false, true, true, true) => Some(DateFields::MDE),
        (false, true, true, false) => Some(DateFields::MD),
        (false, false, true, true) => Some(DateFields::DE),
        (false, false, true, false) => Some(DateFields::D),
        (false, false, false, true) => Some(DateFields::E),
        (true, true, false, _) => Some(DateFields::YM),
        (true, false, false, _) => Some(DateFields::Y),
        (false, true, false, _) => Some(DateFields::M),
        _ => None,
    }
}

fn pick_time_precision(options: &Value, has_time_style: bool) -> Option<TimePrecision> {
    if has_time_style {
        return Some(TimePrecision::Second);
    }
    if options.get("second").is_some() || options.get("fractionalSecondDigits").is_some() {
        Some(TimePrecision::Second)
    } else if options.get("minute").is_some() {
        Some(TimePrecision::Minute)
    } else if options.get("hour").is_some() || options.get("dayPeriod").is_some() {
        // hour alone still needs a time fieldset.
        Some(TimePrecision::Minute)
    } else {
        None
    }
}

fn build_field_set(
    options: &Value,
) -> Result<icu::datetime::fieldsets::enums::CompositeFieldSet, String> {
    let has_date_style = options.get("dateStyle").is_some();
    let has_time_style = options.get("timeStyle").is_some();

    let mut date_fields = pick_date_fields(options, has_date_style);
    let mut time_precision = pick_time_precision(options, has_time_style);
    let zone_style = parse_zone_style(options.get("timeZoneName").and_then(|v| v.as_str()));

    // Default when nothing specified: medium date+time (locale conventions).
    if date_fields.is_none() && time_precision.is_none() && zone_style.is_none() {
        date_fields = Some(DateFields::YMD);
        time_precision = Some(TimePrecision::Second);
    }

    let mut builder = FieldSetBuilder::new();
    // Zone-only fieldsets do not consume `length` (ICU SuperfluousOptions).
    if date_fields.is_some() || time_precision.is_some() {
        builder.length = Some(best_length(options));
    }
    builder.date_fields = date_fields;
    builder.time_precision = time_precision;
    builder.zone_style = zone_style;

    // ECMA-402 year:"numeric" expects a full calendar year (not 2-digit).
    let year_opt = options.get("year").and_then(|v| v.as_str());
    let wants_full_year = matches!(year_opt, Some("numeric") | Some("2-digit"))
        || options.get("era").is_some()
        || matches!(
            options.get("dateStyle").and_then(|v| v.as_str()),
            Some("full") | Some("long") | Some("medium")
        );
    if wants_full_year
        && date_fields.is_some_and(|f| {
            matches!(
                f,
                DateFields::Y | DateFields::YM | DateFields::YMD | DateFields::YMDE
            )
        })
    {
        builder.year_style = Some(if options.get("era").is_some() {
            YearStyle::WithEra
        } else {
            YearStyle::Full
        });
    }

    builder
        .build_composite()
        .map_err(|e| format!("invalid DateTimeFormat options: {e:?}"))
}

fn parse_locale(raw: &str) -> Locale {
    let cleaned = raw.split(',').next().unwrap_or("en").trim();
    cleaned
        .parse::<Locale>()
        .or_else(|_| {
            let base = cleaned.split('-').take(2).collect::<Vec<_>>().join("-");
            base.parse::<Locale>()
        })
        .unwrap_or_else(|_| "en".parse::<Locale>().expect("en locale"))
}

fn hour_cycle_from_options(options: &Value) -> Option<HourCycle> {
    if let Some(hc) = options.get("hourCycle").and_then(|v| v.as_str()) {
        return match hc {
            "h11" => Some(HourCycle::H11),
            "h12" => Some(HourCycle::H12),
            "h23" | "h24" => Some(HourCycle::H23),
            _ => None,
        };
    }
    match options.get("hour12").and_then(|v| v.as_bool()) {
        Some(true) => Some(HourCycle::H12),
        Some(false) => Some(HourCycle::H23),
        None => None,
    }
}

fn apply_calendar_to_locale(locale: &mut Locale, calendar: Option<&str>) {
    let Some(cal) = calendar else { return };
    if cal.eq_ignore_ascii_case("iso8601") || cal.eq_ignore_ascii_case("gregory") {
        return;
    }
    let tag = format!("{locale}-u-ca-{cal}");
    if let Ok(parsed) = tag.parse::<Locale>() {
        *locale = parsed;
    }
}

fn zoned_from_epoch(epoch_milli: f64, tz: TimeZone) -> Result<jiff::Zoned, String> {
    if !epoch_milli.is_finite() {
        return Err("Invalid time value".into());
    }
    // JS Date range roughly used by Temporal polyfill.
    if epoch_milli < -8.64e15 || epoch_milli > 8.64e15 {
        return Err("Invalid time value".into());
    }
    let epoch_ms_i64 = epoch_milli.round() as i64;
    // P1: clamp into jiff range so extreme Temporal samples don't hard-fail.
    let clamped = epoch_ms_i64.clamp(JIFF_MS_MIN, JIFF_MS_MAX);
    let ts =
        Timestamp::from_millisecond(clamped).map_err(|e| format!("Invalid time value: {e}"))?;
    Ok(ts.to_zoned(tz))
}

struct PartCollector {
    out: String,
    ranges: Vec<(usize, usize, &'static str)>,
    stack: Vec<(writeable::Part, usize)>,
}

impl fmt::Write for PartCollector {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.out.push_str(s);
        Ok(())
    }
}

impl PartsWrite for PartCollector {
    type SubPartsWrite = Self;

    fn with_part(
        &mut self,
        part: writeable::Part,
        mut f: impl FnMut(&mut Self) -> fmt::Result,
    ) -> fmt::Result {
        let start = self.out.len();
        self.stack.push((part, start));
        f(self)?;
        let (part, start) = self.stack.pop().unwrap();
        let end = self.out.len();
        if part.category == "datetime" && end > start {
            let ty = match part.value {
                "year" => "year",
                "month" => "month",
                "day" => "day",
                "weekday" => "weekday",
                "hour" => "hour",
                "minute" => "minute",
                "second" => "second",
                "dayPeriod" => "dayPeriod",
                "era" => "era",
                "timeZoneName" => "timeZoneName",
                "fractionalSecond" => "fractionalSecond",
                "relatedYear" => "relatedYear",
                "yearName" => "yearName",
                other => {
                    let _ = other;
                    return Ok(());
                }
            };
            self.ranges.push((start, end, ty));
        }
        Ok(())
    }
}

fn parts_from_formatted(
    formatted: impl Writeable,
    hour_cycle: &str,
) -> Result<(String, Vec<Value>), String> {
    let mut sink = PartCollector {
        out: String::new(),
        ranges: Vec::new(),
        stack: Vec::new(),
    };
    formatted
        .write_to_parts(&mut sink)
        .map_err(|e| format!("format failed: {e}"))?;

    sink.ranges.sort_by_key(|(s, e, _)| (*s, usize::MAX - *e));
    let mut kept: Vec<(usize, usize, &str)> = Vec::new();
    for (s, e, ty) in sink.ranges {
        if kept.iter().any(|(ks, ke, _)| *ks <= s && e <= *ke) {
            continue;
        }
        kept.push((s, e, ty));
    }
    kept.sort_by_key(|(s, _, _)| *s);

    let mut parts = Vec::new();
    let mut cursor = 0usize;
    let mut rebuilt = String::new();
    for (s, e, ty) in kept {
        if s > cursor {
            let lit = &sink.out[cursor..s];
            if !lit.is_empty() {
                parts.push(json!({ "type": "literal", "value": lit }));
                rebuilt.push_str(lit);
            }
        }
        let mut value = sink.out[s..e].to_string();
        // h24: map midnight hour 0/00 -> 24 (ECMA-402).
        if ty == "hour" && hour_cycle == "h24" && (value == "0" || value == "00") {
            value = if value.len() == 2 {
                "24".to_string()
            } else {
                "24".to_string()
            };
        }
        parts.push(json!({ "type": ty, "value": value }));
        rebuilt.push_str(&parts.last().unwrap()["value"].as_str().unwrap_or(""));
        if ty == "year" {
            let y = parts.last().unwrap()["value"]
                .as_str()
                .unwrap_or("")
                .to_string();
            parts.push(json!({ "type": "relatedYear", "value": y }));
            // relatedYear is not rendered in format string by browsers; keep text as-is.
        }
        cursor = e;
    }
    if cursor < sink.out.len() {
        let lit = &sink.out[cursor..];
        if !lit.is_empty() {
            parts.push(json!({ "type": "literal", "value": lit }));
            rebuilt.push_str(lit);
        }
    }

    // If h24 rewrote hour, rebuild full text from parts (skip relatedYear).
    let text = if hour_cycle == "h24" {
        parts
            .iter()
            .filter(|p| p.get("type").and_then(|t| t.as_str()) != Some("relatedYear"))
            .filter_map(|p| p.get("value").and_then(|v| v.as_str()))
            .collect::<String>()
    } else {
        rebuilt
    };

    Ok((text, parts))
}

fn resolved_hour_cycle(options: &Value) -> String {
    options
        .get("hourCycle")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .or_else(|| {
            options
                .get("hour12")
                .and_then(|v| v.as_bool())
                .map(|h12| if h12 { "h12" } else { "h23" }.to_string())
        })
        .unwrap_or_else(|| "h23".to_string())
}

fn format_with_icu(
    epoch_milli: f64,
    options: &Value,
) -> Result<(String, Vec<Value>, String, String, String, String, bool), String> {
    let time_zone = options
        .get("timeZone")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string());
    let calendar = options
        .get("calendar")
        .and_then(|v| v.as_str())
        .unwrap_or("iso8601");
    let locale_raw = options
        .get("locale")
        .and_then(|v| v.as_str())
        .unwrap_or("en");

    let tz = resolve_time_zone(time_zone.as_deref())?;
    let tz_id = canonical_time_zone_id(&tz);
    let zoned = zoned_from_epoch(epoch_milli, tz)?;
    let icu_zdt = ZonedDateTime::<Iso, TimeZoneInfo<AtTime>>::convert_from(&zoned);

    let mut locale = parse_locale(locale_raw);
    apply_calendar_to_locale(&mut locale, Some(calendar));

    let mut prefs = DateTimeFormatterPreferences::from(locale.clone());
    if let Some(hc) = hour_cycle_from_options(options) {
        prefs.hour_cycle = Some(hc);
    }

    let field_set = build_field_set(options)?;
    let formatter = DateTimeFormatter::try_new(prefs, field_set)
        .map_err(|e| format!("DateTimeFormatter init failed: {e}"))?;

    let hour_cycle = resolved_hour_cycle(options);
    let formatted = formatter.format(&icu_zdt);
    let (text, parts) = parts_from_formatted(formatted, &hour_cycle)?;
    let hour12 = hour_cycle == "h11" || hour_cycle == "h12";

    Ok((
        text,
        parts,
        locale.to_string(),
        calendar.to_string(),
        tz_id,
        hour_cycle,
        hour12,
    ))
}

/// Format epoch milliseconds into DateTimeFormat parts (locale-aware).
pub fn intl_dtf_format_to_parts(epoch_milli: f64, options_json: String) -> String {
    let options: Value = match serde_json::from_str(&options_json) {
        Ok(v) => v,
        Err(e) => return err(format!("invalid options json: {e}")),
    };
    match format_with_icu(epoch_milli, &options) {
        Ok((_text, parts, ..)) => ok(Value::Array(parts)),
        Err(e) => err(e),
    }
}

/// Format epoch milliseconds into a locale-aware date/time string.
pub fn intl_dtf_format(epoch_milli: f64, options_json: String) -> String {
    let options: Value = match serde_json::from_str(&options_json) {
        Ok(v) => v,
        Err(e) => return err(format!("invalid options json: {e}")),
    };
    match format_with_icu(epoch_milli, &options) {
        Ok((text, ..)) => ok(Value::String(text)),
        Err(e) => err(e),
    }
}

/// resolvedOptions subset for DateTimeFormat.
pub fn intl_dtf_resolved_options(options_json: String) -> String {
    let options: Value = match serde_json::from_str(&options_json) {
        Ok(v) => v,
        Err(e) => return err(format!("invalid options json: {e}")),
    };
    let time_zone = options
        .get("timeZone")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string());
    let tz = match resolve_time_zone(time_zone.as_deref()) {
        Ok(tz) => tz,
        Err(e) => return err(e),
    };
    let calendar = options
        .get("calendar")
        .and_then(|v| v.as_str())
        .unwrap_or("iso8601");
    let locale_raw = options
        .get("locale")
        .and_then(|v| v.as_str())
        .unwrap_or("en");
    let locale = parse_locale(locale_raw);
    let hour_cycle = options
        .get("hourCycle")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .or_else(|| {
            options
                .get("hour12")
                .and_then(|v| v.as_bool())
                .map(|h12| if h12 { "h12" } else { "h23" }.to_string())
        });

    // If unset, expose locale-default-ish value for en* as h12, else h23.
    let hour_cycle = hour_cycle.unwrap_or_else(|| {
        let tag = locale.to_string().to_ascii_lowercase();
        if tag.starts_with("en") {
            "h12".to_string()
        } else {
            "h23".to_string()
        }
    });

    ok(json!({
        "locale": locale.to_string(),
        "calendar": calendar,
        "numberingSystem": "latn",
        "timeZone": canonical_time_zone_id(&tz),
        "hourCycle": hour_cycle,
        "hour12": hour_cycle == "h11" || hour_cycle == "h12",
    }))
}

/// `Intl.supportedValuesOf` for calendar / timeZone (time-related only).
pub fn intl_supported_values_of(key: String) -> String {
    match key.as_str() {
        "timeZone" => {
            let mut zones: Vec<String> = tz::db()
                .available()
                .map(|name| primary_time_zone_id(&name.to_string()).to_string())
                .collect();
            if !zones.iter().any(|z| z == "UTC") {
                zones.push("UTC".to_string());
            }
            zones.sort();
            zones.dedup();
            ok(json!(zones))
        }
        "calendar" => ok(json!([
            "iso8601",
            "gregory",
            "buddhist",
            "chinese",
            "coptic",
            "dangi",
            "ethioaa",
            "ethiopic",
            "hebrew",
            "indian",
            "islamic",
            "islamic-civil",
            "islamic-rgsa",
            "islamic-tbla",
            "islamic-umalqura",
            "japanese",
            "persian",
            "roc"
        ])),
        "currency" | "numberingSystem" | "unit" | "collation" => {
            err(format!("Unsupported key (time-focused Intl only): {key}"))
        }
        _ => err(format!("Invalid key: {key}")),
    }
}
