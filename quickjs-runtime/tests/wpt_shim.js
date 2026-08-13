// wpt_shim.js —— testharness.js 最小兼容层（qjs wpt 运行器专用）
//
// 覆盖精选子集用到的 API：test / promise_test / async_test / setup / done /
// promise_rejects_js / assert_* 家族；注入 self/window/location。
// 结果收集到 globalThis.__wpt_results（运行器 eval 读取）。
(function () {
  'use strict';
  var results = { pass: 0, fail: 0, expected: 0, pending: 0, tests: [] };
  var doneCalled = false;

  // 已知 v1 限制（快照迭代器 vs 活迭代器、裸 %、data: URL、自定义迭代器）
  // 命中这些测试名的失败记为 expected，不计入 fail
  var expectedFailures = [
    // 自定义迭代器：new Headers(existing) 走实例 Symbol.iterator（fetch 规范细节）
    'Create headers with existing headers with custom iterator',
    // boost 严格 URL 语法：裸 % 被编码为 %25（安全特性，见 fetch_design.md）
    'Escaping produces double-percent',
    // 参照 Node(undici) 而非浏览器：referer/cookie/origin 等 forbidden 头用户
    // 自定义后正常发送（wpt 按浏览器语义期望不发送，登记为有意偏离）
    ' is a forbidden request header',
    // request-headers.any.js：forbidden 请求头/no-cors 过滤语义同上（有意偏离，不拦截）
    'Adding invalid request header',
    'Adding invalid no-cors request header',
    'Check that request constructor is filtering headers provided as init parameter',
    'Check that no-cors request constructor is filtering headers provided as init parameter',
    'Check that no-cors request constructor is filtering headers provided as part of request parameter',
    // consume-empty：空 FormData 的 text() 期望空串——但规范（HTML multipart
    // 编码）空表单序列化为 "--boundary--\r\n"（wpt 自带 FIXME 注明不确定，
    // response-form-data.html 的 "Empty form data" 与之矛盾）；按规范行为登记
    'Consume empty FormData ',
    // ---- v2 M2 范围外（设计文档：用户级 ReadableStream 构造 M5 细化）----
    // 用户级 new ReadableStream({start/pull}) 作 body 源
    'body source: stream',
    'with a stream on which',
    'with a stream holds',
    'ReadableStream body',
    // pipeTo/pipeThrough（v2 不实现）
    'pipeTo on Response body',
    'pipeThrough on Response body',
    // textStream 系列（2024 新增流式消费 API，v2 未实现）
    'textStream',
    // BYOB reader（{mode:'byob'}）
    'byob',
    'Reading with offset from Response stream',
    // GC 测试（依赖 /common/gc.js 与用户级流）
    'GC/CC should not abruptly close',
    // Object.prototype.then 注入测试（用户级流 + add_completion_callback）
    'via Object.prototype.then',
    // 用户流状态机测试（disturbed-6）
    'A non-closed stream on which',
    'A closed stream on which',
    'An errored stream on which',
    // duplex 选项的用户流场景（fetch spec 2024；v2 不支持用户级流 body）
    'duplex'
  ];
  function isExpectedFail(name) {
    return expectedFailures.some(function (p) { return String(name).indexOf(p) !== -1; });
  }

  function record(name, ok, detail) {
    results.tests.push({ name: String(name), ok: !!ok, detail: String(detail || '') });
    if (ok) results.pass++; else results.fail++;
  }
  function failTest(name, e) {
    // 已知 v1 限制 → 计 expected（不算 fail）
    if (isExpectedFail(name)) {
      results.expected++;
      return;
    }
    // quickjs 的 Error.stack 不含消息前缀：先记 String(e)（消息），再附栈
    var d = String(e);
    if (e && e.stack) d += '\n' + e.stack;
    record(name, false, d);
  }

  // ---- 环境注入 ----
  globalThis.self = globalThis;
  globalThis.window = globalThis;
  // location 由运行器在每个测试前经 __wpt_set_location 注入
  globalThis.location = { href: '', pathname: '/', toString: function () { return this.href; } };
  globalThis.__wpt_set_location = function (url) {
    var u = new URL(url);
    globalThis.location = {
      href: u.href, pathname: u.pathname, origin: u.origin, protocol: u.protocol,
      host: u.host, hostname: u.hostname, port: u.port, search: u.search, hash: u.hash,
      toString: function () { return u.href; }
    };
  };

  // ---- harness 基础 ----
  // wpt 语义：test() 回调的 this 是 test 对象（含 add_cleanup/step）
  function test(fn, name) {
    var t = {
      name: name,
      _cleanups: [],
      add_cleanup: function (f) { t._cleanups.push(f); },
      step: function (f) { try { f(t); } catch (e) { failTest(name, e); } }
    };
    try {
      fn.call(t);
      record(name, true, '');
    } catch (e) {
      failTest(name, e);
    }
    t._cleanups.forEach(function (f) {
      try {
        var r = f();
        if (r && typeof r.then === 'function') r.then(null, function () {});
      } catch (e) {}
    });
  }

  function async_test(name) {
    var t = {
      name: name, _done: false,
      step: function (fn) {
        try { fn(t); } catch (e) { failTest(name, e); }
      },
      done: function () {
        if (!t._done) { t._done = true; record(name, true, ''); }
      }
    };
    return t;
  }

  function promise_test(fn, name) {
    results.pending++;
    var cleanups = [];
    var t = {
      step: function (f) { try { f(); } catch (e) { failTest(name, e); } },
      add_cleanup: function (f) { cleanups.push(f); }
    };
    var p;
    try {
      p = fn(t);
    } catch (e) {
      failTest(name, e);
      results.pending--;
      return;
    }
    Promise.resolve(p).then(
      function () { record(name, true, ''); },
      function (e) { failTest(name, e); }
    ).then(function () {
      // 清理（t.add_cleanup 注册的；异步清理尽量驱动，失败不掩盖测试结果）
      cleanups.forEach(function (f) {
        try {
          var r = f();
          if (r && typeof r.then === 'function') r.then(null, function () {});
        } catch (e) {}
      });
      results.pending--;
    });
  }

  // wpt 签名：promise_rejects_js(test, constructor, promise)（第一个是 test 对象）
  function promise_rejects_js(test, ctor, promise) {
    return Promise.resolve(promise).then(
      function () { throw new Error('promise did not reject'); },
      function (e) {
        if (!(e instanceof ctor)) {
          throw new Error('promise rejected with wrong type: ' + String(e) +
                          ' (expected ' + String(ctor && ctor.name) + ')');
        }
      });
  }

  function setup(fn) {
    if (typeof fn === 'function') fn();
  }

  function done() { doneCalled = true; }

  // ---- assert 家族 ----
  function assert_equals(a, b, msg) {
    if (a !== b) throw new Error((msg ? msg + ': ' : '') + 'expected ' + fmt(b) + ' got ' + fmt(a));
  }
  function assert_not_equals(a, b, msg) {
    if (a === b) throw new Error((msg ? msg + ': ' : '') + 'expected different from ' + fmt(a));
  }
  function assert_true(v, msg) {
    if (!v) throw new Error((msg ? msg + ': ' : '') + 'expected true, got ' + fmt(v));
  }
  function assert_false(v, msg) {
    if (v) throw new Error((msg ? msg + ': ' : '') + 'expected false, got ' + fmt(v));
  }
  // 类数组比较（Array / TypedArray 等，wpt 的 assert_array_equals 语义：
  // 都有 length + 索引访问即可；嵌套数组递归）
  function assert_array_equals(a, b, msg) {
    if (!a || !b || typeof a.length !== 'number' || typeof b.length !== 'number')
      throw new Error((msg ? msg + ': ' : '') + 'not arrays');
    if (a.length !== b.length)
      throw new Error((msg ? msg + ': ' : '') + 'length mismatch: ' + a.length + ' vs ' + b.length);
    for (var i = 0; i < a.length; i++) {
      if (Array.isArray(a[i]) || Array.isArray(b[i])) {
        assert_array_equals(a[i], b[i], msg);
      } else if (a[i] !== b[i]) {
        throw new Error((msg ? msg + ': ' : '') + 'index ' + i + ': expected ' + fmt(b[i]) +
                        ' got ' + fmt(a[i]));
      }
    }
  }
  function assert_nested_array_equals(a, b, msg) {
    if (!Array.isArray(a) || !Array.isArray(b)) throw new Error('not arrays');
    if (a.length !== b.length)
      throw new Error((msg ? msg + ': ' : '') + 'length mismatch: ' + a.length + ' vs ' + b.length);
    for (var i = 0; i < a.length; i++) {
      if (Array.isArray(a[i]) || Array.isArray(b[i])) {
        assert_nested_array_equals(a[i], b[i], msg);
      } else if (a[i] !== b[i]) {
        throw new Error((msg ? msg + ': ' : '') + 'index ' + i + ': expected ' + fmt(b[i]) +
                        ' got ' + fmt(a[i]));
      }
    }
  }
  function assert_throws_js(ctor, fn, msg) {
    try {
      if (typeof fn === 'function') fn();
      else fn.call(undefined);
    } catch (e) {
      if (e instanceof ctor) return;
      throw new Error((msg ? msg + ': ' : '') + 'threw wrong type: ' + String(e) +
                      ' (expected ' + String(ctor && ctor.name) + ')');
    }
    throw new Error((msg ? msg + ': ' : '') + 'did not throw (expected ' + String(ctor && ctor.name) + ')');
  }
  function assert_unreached(msg) {
    throw new Error('unreached: ' + msg);
  }
  function fmt(v) {
    if (typeof v === 'string') return '"' + v + '"';
    if (v === null) return 'null';
    if (v === undefined) return 'undefined';
    if (Array.isArray(v)) return JSON.stringify(v);
    try { return String(v); } catch (e) { return '<unprintable>'; }
  }

  // ---- 导出 ----
  globalThis.test = test;
  globalThis.async_test = async_test;
  globalThis.promise_test = promise_test;
  globalThis.promise_rejects_js = promise_rejects_js;
  globalThis.setup = setup;
  globalThis.done = done;
  globalThis.assert_equals = assert_equals;
  globalThis.assert_not_equals = assert_not_equals;
  globalThis.assert_true = assert_true;
  globalThis.assert_false = assert_false;
  globalThis.assert_array_equals = assert_array_equals;
  globalThis.assert_nested_array_equals = assert_nested_array_equals;
  globalThis.assert_throws_js = assert_throws_js;
  globalThis.assert_unreached = assert_unreached;
  globalThis.__wpt_results = results;
  globalThis.__wpt_summary = function () {
    var s = results.pass + ' pass, ' + results.fail + ' fail' +
            (results.expected ? ', ' + results.expected + ' expected' : '') +
            (results.pending ? ', ' + results.pending + ' pending' : '');
    results.tests.forEach(function (t) {
      if (!t.ok) s += '\n  FAIL: ' + t.name + '\n    ' + t.detail;
    });
    return s;
  };
})();
