const fs = require('fs');
const https = require('https');
const path = require('path');

const input = fs.readFileSync(path.resolve(__dirname, 'i18n_strings.txt'), 'utf8');
const lines = input.split('\n').filter(l => l.includes('\t'));
const items = lines.map(l => {
  const idx = l.indexOf('\t');
  return { count: parseInt(l.slice(0, idx), 10), text: JSON.parse(l.slice(idx + 1)) };
});

function translate(text) {
  return new Promise((resolve, reject) => {
    const q = encodeURIComponent(text);
    const url = `https://api.mymemory.translated.net/get?q=${q}&langpair=zh-CN|en`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.responseStatus === 200 && json.responseData?.translatedText) {
            resolve(json.responseData.translatedText);
          } else {
            reject(new Error(json.responseDetails || JSON.stringify(json)));
          }
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

(async () => {
  const out = [];
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    process.stderr.write(`${i + 1}/${items.length}: ${it.text.slice(0, 40)}\n`);
    let en;
    try {
      en = await translate(it.text);
      await sleep(300);
    } catch (e) {
      process.stderr.write(`  ERROR: ${e.message}\n`);
      en = it.text;
    }
    out.push({ count: it.count, zh: it.text, en });
  }
  fs.writeFileSync(path.resolve(__dirname, 'i18n_translated.json'), JSON.stringify(out, null, 2));
  process.stderr.write('done\n');
})();
