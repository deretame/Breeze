const fs = require('fs');
const path = require('path');
const han = /[\u4e00-\u9fff]/;
const targets = [
  'lib/page/about',
  'lib/page/old_page',
  'lib/page/plugin_function',
  'lib/page/change_log_page.dart',
  'lib/page/webview_page.dart',
  'lib/page/login_page.dart',
  'lib/page/image_crop.dart',
  'lib/page/font_setting',
  'lib/page/discover',
  'lib/widgets',
  'lib/util',
  'lib/service',
];

function walk(dir) {
  const res = [];
  if (!fs.existsSync(dir)) return res;
  const st = fs.statSync(dir);
  if (st.isFile()) {
    if (dir.endsWith('.dart')) res.push(dir);
    return res;
  }
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) res.push(...walk(p));
    else if (p.endsWith('.dart')) res.push(p);
  }
  return res;
}

const files = new Set();
for (const t of targets) walk(t).forEach((f) => files.add(f));
for (const f of [...files].sort()) {
  const lines = fs.readFileSync(f, 'utf8').split(/\r?\n/);
  lines.forEach((line, i) => {
    const re = /r?("(?:\\.|[^"\\])*"|'+(?:\\.|[^'\\])*'+)/g;
    let m;
    while ((m = re.exec(line)) !== null) {
      const s = m[1];
      if (han.test(s)) {
        console.log(`${f}:${i + 1}:${line.trim()}`);
        break;
      }
    }
  });
}
