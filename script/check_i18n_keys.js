const fs = require('fs');
const path = require('path');

function glob(dir, pat) {
  const out = [];
  function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const full = path.join(d, e.name);
      if (e.isDirectory()) walk(full);
      else if (pat.test(e.name)) out.push(full);
    }
  }
  walk(dir);
  return out;
}

function unescapeRustKey(raw) {
  return JSON.parse('"' + raw.replace(/\\"/g, '"').replace(/\\n/g, '\\n').replace(/\\t/g, '\\t').replace(/\\\\/g, '\\') + '"');
}

const i18n = fs.readFileSync('rquickjs_playground/src/i18n.rs', 'utf8');
const enMatch = i18n.match(/fn insert_messages_en\([^)]*\)\s*\{([\s\S]*?)\n\}/);
const enKeys = new Set();
if (enMatch) {
  const re = /m\.insert\(\s*"((?:[^"\\]|\\.)*)"/g;
  let r;
  while ((r = re.exec(enMatch[1])) !== null) {
    enKeys.add(unescapeRustKey(r[1]));
  }
}

const zhMatch = i18n.match(/fn insert_messages\([^)]*\)\s*\{([\s\S]*?)\n\}/);
const zhKeys = new Set();
if (zhMatch) {
  const re = /m\.insert\(\s*"((?:[^"\\]|\\.)*)"/g;
  let r;
  while ((r = re.exec(zhMatch[1])) !== null) {
    zhKeys.add(unescapeRustKey(r[1]));
  }
}

const used = new Map();
function count(k) {
  used.set(k, (used.get(k) || 0) + 1);
}

for (const dir of ['rquickjs_playground/src', 'rust/src']) {
  for (const f of glob(dir, /\.rs$/)) {
    const txt = fs.readFileSync(f, 'utf8');
    for (const mac of ['i18n!', 'i18n_fmt!']) {
      for (const prefix of ['crate::', 'rquickjs_playground::']) {
        const pattern = prefix.replace(/::/g, '\\\\::') + mac.replace(/!/g, '\\!') + '\\("((?:[^"\\\\]|\\\\.)*)"';
        const re = new RegExp(pattern, 'g');
        let m;
        while ((m = re.exec(txt)) !== null) {
          count(unescapeRustKey(m[1]));
        }
      }
    }
  }
}

console.log('ZH keys:', zhKeys.size);
console.log('EN keys:', enKeys.size);
console.log('Used keys:', used.size);

const missingZh = [];
const missingEn = [];
for (const k of used.keys()) {
  if (!zhKeys.has(k)) missingZh.push(k);
  if (!enKeys.has(k)) missingEn.push(k);
}
if (missingZh.length) {
  console.log('\nMissing ZH translations:', missingZh.length);
  for (const k of missingZh.sort()) console.log('  ', k);
}
if (missingEn.length) {
  console.log('\nMissing EN translations:', missingEn.length);
  for (const k of missingEn.sort()) console.log('  ', k);
}
const extraEn = [...enKeys].filter(k => !used.has(k));
if (extraEn.length) {
  console.log('\nExtra EN keys not used:', extraEn.length);
  for (const k of extraEn.sort()) console.log('  ', k);
}
