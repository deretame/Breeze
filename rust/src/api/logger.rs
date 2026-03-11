use std::sync::{Mutex, OnceLock};
use std::time::Instant;
use tracing::{Event, Subscriber};
use tracing_subscriber::fmt::{FmtContext, FormatEvent, FormatFields, format::Writer};
use tracing_subscriber::registry::LookupSpan;

// 全局静态变量：用于记录上一条日志的打印时间
static LAST_LOG_TIME: OnceLock<Mutex<Instant>> = OnceLock::new();

pub struct BoxedFormatter {
    pub with_ansi: bool,
}

impl<S, N> FormatEvent<S, N> for BoxedFormatter
where
    S: Subscriber + for<'a> LookupSpan<'a>,
    N: for<'a> FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> std::fmt::Result {
        let meta = event.metadata();
        let file = meta.file().unwrap_or("unknown_file");
        let line = meta.line().unwrap_or(0);
        let target = meta.target();

        let now = chrono::Local::now().format("%H:%M:%S.%3f");
        let level = *meta.level();

        // 1. 获取颜色
        let (color_code, reset_code) = if self.with_ansi {
            match level {
                tracing::Level::ERROR => ("\x1b[31m", "\x1b[0m"),
                tracing::Level::WARN => ("\x1b[33m", "\x1b[0m"),
                tracing::Level::INFO => ("\x1b[32m", "\x1b[0m"),
                tracing::Level::DEBUG => ("\x1b[34m", "\x1b[0m"),
                tracing::Level::TRACE => ("\x1b[35m", "\x1b[0m"),
            }
        } else {
            ("", "")
        };

        // 2. 降级判断：如果是 Release 模式，或者是第三方库，则只打印基本单行信息
        let is_release_mode = !cfg!(debug_assertions);
        let is_third_party =
            !target.starts_with("windcore") && !target.starts_with("rquickjs_playground");

        if is_release_mode || is_third_party {
            write!(writer, "{}[{} {} {}] ", color_code, now, level, target)?;
            ctx.field_format().format_fields(writer.by_ref(), event)?;
            write!(writer, "{}", reset_code)?;
            return writeln!(writer);
        }

        // --- 下面的逻辑只有在 Debug 模式且是自己项目的日志时才会执行 ---

        // 3. 计算距离上一条日志的耗时
        let now_instant = Instant::now();
        let last_time_mutex = LAST_LOG_TIME.get_or_init(|| Mutex::new(now_instant));
        let mut last_time = last_time_mutex.lock().unwrap();
        let duration = now_instant.duration_since(*last_time);
        *last_time = now_instant; // 更新时间为当前时间

        let secs = duration.as_secs();
        let hours = secs / 3600;
        let mins = (secs % 3600) / 60;
        let secs_remainder = secs % 60;
        let micros = duration.subsec_micros();
        // 拼装时间显示格式：14:58:33.123 (+0:00:00.830022)
        let time_with_duration = format!(
            "{} (+{}:{:02}:{:02}.{:06})",
            now, hours, mins, secs_remainder, micros
        );

        // 4. 获取用于跳转的短文件名
        let file_name = std::path::Path::new(file)
            .file_name()
            .and_then(|name| name.to_str())
            .unwrap_or(file);

        // 5. 安全获取自适应宽度
        #[cfg(all(
            not(target_family = "wasm"),
            not(target_os = "android"),
            not(target_os = "ios")
        ))]
        let total_width = terminal_size::terminal_size()
            .map(|(w, _h)| w.0 as usize)
            .unwrap_or(104)
            .max(60);

        #[cfg(any(target_family = "wasm", target_os = "android", target_os = "ios"))]
        let total_width = 104;

        // 6. 动态生成横线
        let top_bottom_line = "─".repeat(total_width - 1);
        let separator_line = "┄".repeat(total_width - 1);

        // --- 开始打印边框 ---
        writeln!(writer, "{}┌{}{}", color_code, top_bottom_line, reset_code)?;

        // 拼装首行的左右两部分
        let left_part = format!(
            "│ #0   {}:{}:{}  {:<5} {}",
            file,
            line,
            line,
            level.as_str(),
            target
        );
        let right_part = format!("{}:{}", file_name, line);

        let left_len = left_part.chars().count();
        let right_len = right_part.chars().count();

        // 动态计算将右侧文件名推至边缘所需的空格数
        let spaces_count = if total_width > left_len + right_len {
            total_width - left_len - right_len
        } else {
            4
        };
        let spaces = " ".repeat(spaces_count);

        writeln!(
            writer,
            "{}{}{}{}{}",
            color_code, left_part, spaces, right_part, reset_code
        )?;

        // 打印中间信息（带耗时）
        writeln!(writer, "{}├{}{}", color_code, separator_line, reset_code)?;
        writeln!(
            writer,
            "{}│ {}{}",
            color_code, time_with_duration, reset_code
        )?;
        writeln!(writer, "{}├{}{}", color_code, separator_line, reset_code)?;

        // 打印实际日志内容
        write!(writer, "{}│ ", color_code)?;
        ctx.field_format().format_fields(writer.by_ref(), event)?;
        writeln!(writer, "{}", reset_code)?;

        // 打印底部边框
        writeln!(writer, "{}└{}{}", color_code, top_bottom_line, reset_code)
    }
}
