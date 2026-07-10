const fs = require('fs');
const path = require('path');

const roots = [
  { path: path.resolve(__dirname, '../rquickjs_playground/src'), prefix: 'crate::' },
  { path: path.resolve(__dirname, '../rust/src'), prefix: 'rquickjs_playground::' },
];

const tsvPath = path.resolve(__dirname, 'i18n_translations.tsv');
const i18nOut = path.resolve(__dirname, '../rquickjs_playground/src/i18n.rs');

function collectFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    const st = fs.statSync(full);
    if (st.isDirectory()) collectFiles(full, out);
    else if (full.endsWith('.rs') && !full.endsWith('i18n.rs')) out.push(full);
  }
  return out;
}

function rustLiteral(s) {
  return JSON.stringify(s);
}

function toPositionalTemplate(s) {
  let counter = 0;
  const nameToIdx = new Map();
  const placeholders = [];
  const t = s.replace(/\{\{|\}\}|\{([^}:]*)(?::[^}]*)?\}/g, (m, inner) => {
    if (m === '{{' || m === '}}') return m;
    const name = inner || '';
    let idx;
    if (name === '') {
      idx = counter++;
      placeholders.push({ name: '', pos: idx });
      return `{${idx}}`;
    }
    if (nameToIdx.has(name)) {
      idx = nameToIdx.get(name);
    } else {
      idx = counter++;
      nameToIdx.set(name, idx);
    }
    placeholders.push({ name, pos: idx });
    return `{${idx}}`;
  });
  return { template: t, placeholders };
}

// Read translations
const translations = [];
for (const line of fs.readFileSync(tsvPath, 'utf8').split(/\r?\n/)) {
  if (!line.trim()) continue;
  const idx = line.indexOf('\t');
  if (idx < 0) continue;
  const zh = line.slice(0, idx);
  const en = line.slice(idx + 1);
  const posZh = toPositionalTemplate(zh);
  const posEn = toPositionalTemplate(en);
  translations.push({ zh, en, key: posZh.template, enTemplate: posEn.template, placeholders: posZh.placeholders });
}

const zhMap = new Map(translations.map(t => [t.zh, t]));

function buildI18nRs() {
  const header = `//! 错误消息多语言支持
//! Multi-language error message support.

use std::collections::HashMap;
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::LazyLock;

/// 支持的错误消息语言
/// Supported error-message languages.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorMessageLang {
    /// 中文 / Chinese
    Zh,
    /// 英文 / English
    En,
}

const LANG_ZH: u8 = 0;
const LANG_EN: u8 = 1;

/// 当前语言，默认中文
/// Current language, defaults to Chinese.
static CURRENT_LANG: AtomicU8 = AtomicU8::new(LANG_ZH);

/// 中文消息表（key 为消息模板本身）
/// Chinese message table (keys are the message templates themselves).
static ZH_MESSAGES: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut m = HashMap::new();
    insert_messages(&mut m);
    m
});

/// 英文消息表
/// English message table.
static EN_MESSAGES: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut m = HashMap::new();
    insert_messages_en(&mut m);
    m
});

/// 设置错误消息语言
/// Set error-message language.
///
/// \`lang\` 支持 \`"zh"\` 或 \`"en"\`，其它值会被忽略。
/// \`lang\` accepts \`"zh"\` or \`"en"\`; other values are ignored.
/// 返回是否识别成功 / Returns whether the language was recognized.
pub fn set_error_message_language(lang: &str) -> bool {
    let code = match lang {
        "zh" => LANG_ZH,
        "en" => LANG_EN,
        _ => return false,
    };
    CURRENT_LANG.store(code, Ordering::Relaxed);
    true
}

/// 获取当前错误消息语言
/// Get the current error-message language.
pub fn current_error_message_language() -> ErrorMessageLang {
    match CURRENT_LANG.load(Ordering::Relaxed) {
        LANG_EN => ErrorMessageLang::En,
        _ => ErrorMessageLang::Zh,
    }
}

/// 根据 key 读取当前语言的静态消息
/// Read the static message for the current language by key.
///
/// 如果 key 不存在则返回 key 本身，避免崩溃。
/// If the key is missing, returns the key itself to avoid panics.
pub fn t(key: &str) -> &'static str {
    let map = match current_error_message_language() {
        ErrorMessageLang::En => &*EN_MESSAGES,
        ErrorMessageLang::Zh => &*ZH_MESSAGES,
    };
    map.get(key).copied().unwrap_or(key)
}

/// 按位置参数拼接消息模板
/// Format a message template with positional arguments.
///
/// 模板使用 \`{0}\`、\`{1}\` 等占位符。
/// Templates use \`{0}\`, \`{1}\`, etc. placeholders.
pub fn format_message(key: &str, args: &[&dyn std::fmt::Display]) -> String {
    let mut s = t(key).to_string();
    for (i, arg) in args.iter().enumerate() {
        let placeholder = format!("{{{}}}", i);
        s = s.replace(&placeholder, &format!("{}", arg));
    }
    s
}

fn insert_messages(m: &mut HashMap<&'static str, &'static str>) {
`;
  const mid = `}

fn insert_messages_en(m: &mut HashMap<&'static str, &'static str>) {
`;
  const footer = `}

/// 无参数消息宏（返回 &str）
/// Macro for parameterless messages (returns &str).
#[macro_export]
macro_rules! i18n {
    ($key:expr) => {
        $crate::i18n::t($key)
    };
}

/// 带位置参数拼接的消息宏（返回 String）
/// Macro for messages with positional arguments (returns String).
#[macro_export]
macro_rules! i18n_fmt {
    ($key:expr $(, $arg:expr)* $(,)?) => {{
        let args: &[&dyn std::fmt::Display] = &[$(&$arg),*];
        $crate::i18n::format_message($key, args)
    }};
}
`;
  const zhLines = translations.map(t => `    m.insert(${rustLiteral(t.key)}, ${rustLiteral(t.key)});`).join('\n');
  const enLines = translations.map(t => `    m.insert(${rustLiteral(t.key)}, ${rustLiteral(t.enTemplate)});`).join('\n');
  return header + zhLines + '\n' + mid + enLines + '\n' + footer;
}

fs.writeFileSync(i18nOut, buildI18nRs());
console.log(`Generated ${i18nOut} with ${translations.length} entries.`);

// Source replacement
const rawStringRe = /r(#+)"[\s\S]*?"\1/g;
const lineCommentRe = /\/\/.*$/gm;
const blockCommentRe = /\/\*[\s\S]*?\*\//g;

function maskRegions(text, regex) {
  return text.replace(regex, m => ' '.repeat(m.length));
}

function findStringLiterals(text) {
  const masked = maskRegions(maskRegions(maskRegions(text, rawStringRe), lineCommentRe), blockCommentRe);
  const re = /"((?:[^"\\]|\\.)*)"/g;
  const out = [];
  let m;
  while ((m = re.exec(masked))) {
    const start = m.index;
    const end = m.index + m[0].length;
    if (/[\u4e00-\u9fa5]/.test(m[1])) {
      out.push({ start, end, value: m[1] });
    }
  }
  return out;
}

function findMatchingParen(text, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < text.length; i++) {
    const c = text[i];
    if (c === '(') depth++;
    else if (c === ')') {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function extractFormatArgs(inner) {
  return inner.replace(/^\s*,?\s*/, '').trim();
}

function buildArgs(t, explicitArgs) {
  const explicit = explicitArgs ? explicitArgs.split(',').map(s => s.trim()).filter(Boolean) : [];
  const args = [];
  let explicitIdx = 0;
  for (const ph of t.placeholders) {
    if (ph.name === '') {
      args.push(explicit[explicitIdx++] ?? '');
    } else {
      args.push(ph.name);
    }
  }
  return args;
}

function makeI18nFmtCall(prefix, t, explicitArgs) {
  const args = buildArgs(t, explicitArgs);
  const argStr = args.length ? ', ' + args.join(', ') : '';
  return `${prefix}i18n_fmt!(${rustLiteral(t.key)}${argStr})`;
}

function processFile(file, prefix) {
  let text = fs.readFileSync(file, 'utf8');
  const literals = findStringLiterals(text);
  if (literals.length === 0) return;

  const repls = [];
  for (const lit of literals) {
    const t = zhMap.get(lit.value);
    if (!t) {
      console.warn(`No translation for ${JSON.stringify(lit.value)} in ${file}`);
      continue;
    }
    const ctx = findEnclosingContext(text, lit.start);
    if (ctx && ctx.macroName) {
      const explicitArgs = extractFormatArgs(ctx.afterString);
      const call = makeI18nFmtCall(prefix, t, explicitArgs);
      const macroStartIdx = text.lastIndexOf(ctx.macroName, ctx.openIdx);
      let repl;
      if (ctx.macroName === 'format') repl = call;
      else if (ctx.macroName === 'anyhow') repl = `anyhow!(${call})`;
      else if (ctx.macroName === 'bail') repl = `bail!(${call})`;
      else if (ctx.macroName === 'panic') repl = `panic!("{}", ${call})`;
      else if (ctx.macroName.startsWith('tracing::')) {
        const level = ctx.macroName.slice('tracing::'.length);
        repl = `tracing::${level}!("{}", ${call})`;
      } else {
        repl = call;
      }
      repls.push({ start: macroStartIdx, end: ctx.closeIdx + 1, repl });
    } else if (ctx && ctx.type === 'expect') {
      repls.push({ start: ctx.openIdx, end: ctx.closeIdx + 1, repl: `.expect(&${prefix}i18n_fmt!(${rustLiteral(t.key)}))` });
    } else if (ctx && ctx.type === 'context') {
      repls.push({ start: ctx.openIdx, end: ctx.closeIdx + 1, repl: `.context(${prefix}i18n_fmt!(${rustLiteral(t.key)}))` });
    } else if (ctx && ctx.type === 'throw_message') {
      repls.push({ start: ctx.openIdx, end: ctx.closeIdx + 1, repl: `throw_message(${prefix}i18n!(${rustLiteral(t.key)}))` });
    } else {
      repls.push({ start: lit.start, end: lit.end, repl: `${prefix}i18n_fmt!(${rustLiteral(t.key)})` });
    }
  }

  repls.sort((a, b) => a.start - b.start);
  const merged = [];
  for (const r of repls) {
    const last = merged[merged.length - 1];
    if (last && r.start < last.end) continue;
    merged.push(r);
  }

  merged.sort((a, b) => b.start - a.start);
  for (const r of merged) {
    text = text.slice(0, r.start) + r.repl + text.slice(r.end);
  }

  fs.writeFileSync(file, text);
  console.log(`Updated ${file} (${literals.length} literals, ${merged.length} replacements)`);
}

function findEnclosingContext(text, strStart) {
  let depth = 0;
  for (let i = strStart - 1; i >= 0; i--) {
    const c = text[i];
    if (c === ')') depth++;
    else if (c === '(') {
      if (depth > 0) { depth--; continue; }
      const before = text.slice(0, i);
      const closeIdx = findMatchingParen(text, i);
      if (closeIdx < 0) continue;
      const afterString = text.slice(strStart + 1 + text.slice(strStart).indexOf('"', 1), closeIdx);
      if (/format!\s*$/.test(before)) return { openIdx: i, closeIdx, macroName: 'format', afterString };
      if (/anyhow!\s*$/.test(before)) return { openIdx: i, closeIdx, macroName: 'anyhow', afterString };
      if (/bail!\s*$/.test(before)) return { openIdx: i, closeIdx, macroName: 'bail', afterString };
      if (/panic!\s*$/.test(before)) return { openIdx: i, closeIdx, macroName: 'panic', afterString };
      const tracingM = before.match(/tracing::(\w+)!\s*$/);
      if (tracingM) return { openIdx: i, closeIdx, macroName: `tracing::${tracingM[1]}`, afterString };
      if (before.endsWith('.expect')) return { openIdx: i - 7, closeIdx, type: 'expect' };
      if (before.endsWith('.context')) return { openIdx: i - 8, closeIdx, type: 'context' };
      if (before.endsWith('throw_message')) return { openIdx: i - 13, closeIdx, type: 'throw_message' };
    }
  }
  return null;
}

for (const root of roots) {
  for (const file of collectFiles(root.path)) {
    processFile(file, root.prefix);
  }
}

console.log('Done');
