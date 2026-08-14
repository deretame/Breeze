const fs = require('fs');
const path = require('path');

const WPT_ROOT = path.join(__dirname, '..', 'wpt');

const TESTS = [
  "fetch/api/headers/headers-basic.any.js",
  "fetch/api/headers/headers-casing.any.js",
  "fetch/api/headers/headers-combine.any.js",
  "fetch/api/headers/headers-errors.any.js",
  "fetch/api/headers/headers-forbidden-override.any.js",
  "fetch/api/headers/headers-no-cors.any.js",
  "fetch/api/headers/headers-normalize.any.js",
  "fetch/api/headers/headers-record.any.js",
  "fetch/api/headers/headers-structure.any.js",
  "fetch/api/headers/header-setcookie.any.js",
  "fetch/api/headers/header-values-normalize.any.js",
  "fetch/api/request/request-structure.any.js",
  "fetch/api/request/request-bad-port.any.js",
  "fetch/api/request/forbidden-method.any.js",
  "fetch/api/request/request-init-002.any.js",
  "fetch/api/request/request-init-contenttype.any.js",
  "fetch/api/request/request-init-priority.any.js",
  "fetch/api/request/request-headers.any.js",
  "fetch/api/request/request-consume-empty.any.js",
  "fetch/api/response/response-error.any.js",
  "fetch/api/response/response-consume-empty.any.js",
  "fetch/api/response/response-init-001.any.js",
  "fetch/api/response/response-init-contenttype.any.js",
  "fetch/api/response/response-static-error.any.js",
  "fetch/api/response/response-static-json.any.js",
  "fetch/api/response/response-static-redirect.any.js",
  "fetch/api/request/request-constructor-init-body-override.any.js",
  "fetch/api/body/formdata.any.js",
  "fetch/api/body/mime-type.any.js",
  "fetch/api/basic/response-null-body.any.js",
  "fetch/api/basic/header-value-combining.any.js",
  "fetch/api/basic/header-value-null-byte.any.js",
  "fetch/api/basic/historical.any.js",
  "fetch/api/basic/request-head.any.js",
  "fetch/api/basic/request-headers-nonascii.any.js",
  "fetch/api/basic/request-headers-case.any.js",
  "fetch/api/abort/request.any.js",
];

function readWptFile(relative) {
  return fs.readFileSync(path.join(WPT_ROOT, relative), 'utf8');
}

function resolveMetaScript(testDir, line) {
  const trimmed = line.trim();
  const prefix = "// META: script=";
  if (!trimmed.startsWith(prefix)) return null;
  const script = trimmed.slice(prefix.length).trim();
  if (script.startsWith('/')) {
    return readWptFile(script.slice(1));
  }
  return fs.readFileSync(path.join(testDir, script), 'utf8');
}

function injectLoopVars(source) {
  const re = /for\s*\(\s*([A-Za-z_$][A-Za-z0-9_$]*)\s+(of|in)\s+/g;
  const vars = new Set();
  let m;
  while ((m = re.exec(source)) !== null) {
    vars.add(m[1]);
  }
  if (vars.size === 0) return source;
  const declarations = Array.from(vars).sort().join(', ');
  return `var ${declarations};\n${source}`;
}

function buildPayload(testRelative) {
  const testPath = path.join(WPT_ROOT, testRelative);
  const testDir = path.dirname(testPath);
  let testSource = fs.readFileSync(testPath, 'utf8');
  testSource = injectLoopVars(testSource);

  const parts = [];

  parts.push(`
    "use strict";
    var __wpt_results__ = null;
    if (typeof self === "undefined") { globalThis.self = globalThis; }
    if (!globalThis.GLOBAL) {
      globalThis.GLOBAL = {
        isWindow: () => false,
        isWorker: () => false,
        isShadowRealm: () => false,
      };
    }
  `);

  parts.push(readWptFile('resources/testharness.js'));

  parts.push(`
    (function() {
      const results = [];
      let resolvePromise = null;
      globalThis.__wpt_results__ = new Promise(function(resolve) {
        resolvePromise = resolve;
      });
      function sanitize(s) {
        if (s == null) return null;
        return String(s).replace(/[\uD800-\uDFFF]/g, c => "\\\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4));
      }
      add_result_callback(function(test) {
        results.push({
          status: test.status,
          name: sanitize(test.name),
          message: sanitize(test.message),
          stack: sanitize(test.stack)
        });
      });
      add_completion_callback(function(tests, harness_status) {
        resolvePromise({
          harness: {
            status: harness_status.status,
            message: sanitize(harness_status.message),
            stack: sanitize(harness_status.stack)
          },
          tests: results
        });
      });
    })();
  `);

  for (const line of testSource.split('\n')) {
    const resolved = resolveMetaScript(testDir, line);
    if (resolved) parts.push(resolved);
  }
  parts.push(testSource);

  return parts.join('\n');
}

async function runTest(testRelative) {
  const payload = buildPayload(testRelative);
  try {
    // Eval in a function to avoid strict-mode from leaking to outer scope;
    // testharness.js itself detects environment based on globalThis/self.
    const run = new Function(payload + '\n return globalThis.__wpt_results__;');
    const result = await run();
    return result;
  } catch (err) {
    return { harness: { status: 2, message: String(err.message || err), stack: String(err.stack || '') }, tests: [] };
  }
}

async function main() {
  let total = 0;
  let passed = 0;
  let failed = 0;
  let harnessErrors = 0;
  const byFile = [];

  for (const file of TESTS) {
    const result = await runTest(file);
    const harnessOk = result.harness.status === 0;
    if (!harnessOk) harnessErrors++;

    let filePassed = 0;
    let fileFailed = 0;
    for (const test of result.tests) {
      total++;
      if (test.status === 0) {
        passed++;
        filePassed++;
      } else {
        failed++;
        fileFailed++;
      }
    }
    byFile.push({ file, passed: filePassed, failed: fileFailed, harnessOk });
  }

  console.log('\n========== Node.js WPT fetch summary ==========');
  console.log(`Total test assertions: ${total}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log(`Harness errors: ${harnessErrors}`);
  console.log(`Pass rate: ${total > 0 ? ((passed / total) * 100).toFixed(1) : 'N/A'}%`);
  console.log('\nPer file:');
  for (const { file, passed: p, failed: f, harnessOk } of byFile) {
    console.log(`  ${file}: passed=${p} failed=${f} harness_ok=${harnessOk}`);
  }
  console.log('=======================================\n');
}

main().catch(console.error);
