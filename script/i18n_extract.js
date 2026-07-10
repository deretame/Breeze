const fs = require('fs');
const path = require('path');

const roots = [
  path.resolve(__dirname, '../rquickjs_playground/src'),
  path.resolve(__dirname, '../rust/src'),
];

function collectFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    const st = fs.statSync(full);
    if (st.isDirectory()) {
      collectFiles(full, out);
    } else if (full.endsWith('.rs')) {
      out.push(full);
    }
  }
  return out;
}

function stripRawStrings(text) {
  // Only mask raw strings with at least one # (r#"..."#) to avoid
  // matching the "r\" sequence inside normal strings like "error".
  return text.replace(/r(#+)"[\s\S]*?"\1/g, (m) => ' '.repeat(m.length));
}

function findChineseStrings(text) {
  const cleaned = stripRawStrings(text);
  const results = [];
  const re = /"((?:[^"\\]|\\.)*)"/g;
  let m;
  while ((m = re.exec(cleaned))) {
    const s = m[1];
    if (/[\u4e00-\u9fa5]/.test(s)) {
      results.push(s);
    }
  }
  return results;
}

const all = [];
for (const root of roots) {
  for (const file of collectFiles(root)) {
    const text = fs.readFileSync(file, 'utf8');
    const strings = findChineseStrings(text);
    for (const s of strings) {
      all.push({ file, s });
    }
  }
}

const counts = new Map();
for (const { s } of all) {
  counts.set(s, (counts.get(s) || 0) + 1);
}
const unique = [...counts.entries()].sort((a, b) => b[1] - a[1]);

console.log(`Total occurrences: ${all.length}`);
console.log(`Unique strings: ${unique.length}`);
for (const [s, c] of unique) {
  console.log(`${c}\t${JSON.stringify(s)}`);
}
