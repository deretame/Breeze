// fetch 功能验收测试：Web API 层（URL/Headers/TextEncoder/AbortController）+ fetch
//
// 覆盖（v1 边界）：
//   - URL / URLSearchParams 解析与操作
//   - Headers 规范（大小写/合并/校验/迭代）
//   - TextEncoder / TextDecoder（UTF-8、代理对、BOM）
//   - AbortController / AbortSignal 事件与状态
//   - Request / Response 构造与 body 消费
//   - fetch 全链路（本地 HTTP 服务器 + 重定向 + 取消）
#include <gtest/gtest.h>
#include <log.hpp>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp>
#include <fetch/client.hpp>
#include "wpt_server.hpp"

#include <boost/asio/steady_timer.hpp>

#include <chrono>
#include <fstream>
#include <sstream>

using namespace qjs;

namespace {

struct FetchFixture : ::testing::Test {
    Runtime rt;
    fetch::Client client{}; // 先于 ctx 声明：析构逆序（ctx 先），
                                   // fetch 全局持有的 Client& 在 ctx 生命周期内有效
    Context ctx = rt.main_context();

    FetchFixture()
    {
        qjsbind::web::install_web_apis(ctx, client);
    }
};

// ---- URL ----
TEST_F(FetchFixture, UrlParseAndProperties)
{
    Value r = ctx.eval(
        "var u = new URL('/a/b?x=1&y=2#frag', 'http://example.com:8080/');"
        "u.href + '|' + u.protocol + '|' + u.host + '|' + u.port + '|' + u.pathname + '|' +"
        "u.search + '|' + u.hash + '|' + u.origin;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(),
              "http://example.com:8080/a/b?x=1&y=2#frag|http:|example.com:8080|8080|/a/b|"
              "?x=1&y=2|#frag|http://example.com:8080");
}

TEST_F(FetchFixture, UrlDefaultPort)
{
    EXPECT_EQ(ctx.eval("new URL('http://example.com:80/x').port").as<std::string>(), "");
    EXPECT_EQ(ctx.eval("new URL('https://example.com:443/x').port").as<std::string>(), "");
}

TEST_F(FetchFixture, UrlRelativeWithoutBase)
{
    Value r = ctx.eval("(() => { try { new URL('/x'); return 'no-error' } catch (e) { return e.name } })()");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(FetchFixture, UrlSearchParams)
{
    Value r = ctx.eval(
        "var p = new URLSearchParams('a=1&b=2&a=3');"
        "p.get('a') + '|' + p.getAll('a').join(',') + '|' + p.has('b') + '|' + p.toString();");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "1|1,3|true|a=1&b=2&a=3");
}

TEST_F(FetchFixture, UrlSearchParamsFromObject)
{
    EXPECT_EQ(ctx.eval("new URLSearchParams({x: 1, y: 'hello world'}).toString()")
                  .as<std::string>(),
              "x=1&y=hello+world");
}

// ---- Headers ----
TEST_F(FetchFixture, HeadersBasic)
{
    Value r = ctx.eval(
        "var h = new Headers();"
        "h.append('X-Test', 'a'); h.append('x-test', 'b'); h.set('Content-Type', 'text/plain');"
        "h.get('X-Test') + '|' + h.get('content-type') + '|' + h.has('X-TEST');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "a, b|text/plain|true");
}

TEST_F(FetchFixture, HeadersInvalidName)
{
    Value r = ctx.eval("(() => { try { new Headers({'bad name': 'x'}); return 'no' } catch (e) { return e.name } })()");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(FetchFixture, HeadersIteration)
{
    Value r = ctx.eval(
        "var h = new Headers({'b': '2', 'a': '1'});"
        "var keys = []; h.forEach((v, k) => keys.push(k)); keys.join(',');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "a,b");
}

// ---- TextEncoder / TextDecoder ----
TEST_F(FetchFixture, TextEncoderDecoder)
{
    Value r = ctx.eval(
        "var enc = new TextEncoder(); var dec = new TextDecoder();"
        "dec.decode(enc.encode('hello 世界')) + '|' + dec.decode(enc.encode('a\\uD800b'));");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "hello 世界|a\uFFFDb");
}

TEST_F(FetchFixture, TextDecoderBom)
{
    Value r = ctx.eval(
        "var bom = new Uint8Array([0xEF,0xBB,0xBF, 0x61]);"
        "new TextDecoder().decode(bom) + '|' + new TextDecoder({ignoreBOM: true}).decode(bom);");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "a|\uFEFFa");
}

// ---- AbortController ----
TEST_F(FetchFixture, AbortControllerBasic)
{
    Value r = ctx.eval(
        "var c = new AbortController(); var fired = false;"
        "c.signal.addEventListener('abort', () => { fired = true; });"
        "c.abort();"
        "c.signal.aborted + '|' + fired + '|' + c.signal.reason.name;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "true|true|AbortError");
}

TEST_F(FetchFixture, AbortSignalStaticAbort)
{
    Value r = ctx.eval("var s = AbortSignal.abort(); s.aborted + '|' + s.reason.name;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "true|AbortError");
}

// ---- Request / Response ----
TEST_F(FetchFixture, RequestConstruct)
{
    Value r = ctx.eval(
        "var req = new Request('http://example.com/x', {method: 'post', body: 'hello'});"
        "req.method + '|' + req.url + '|' + req.headers.get('content-type');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "POST|http://example.com/x|text/plain;charset=UTF-8");
}

TEST_F(FetchFixture, RequestGetWithBodyRejected)
{
    Value r = ctx.eval("(() => { try { new Request('http://x/', {body: 'b'}); return 'no' } catch (e) { return e.name } })()");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
}

TEST_F(FetchFixture, ResponseConstruct)
{
    Value r = ctx.eval(
        "var resp = new Response('hello', {status: 201, statusText: 'Created',"
        " headers: {'X-A': '1'}});"
        "resp.status + '|' + resp.statusText + '|' + resp.ok + '|' + resp.type;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "201|Created|true|default");
}

TEST_F(FetchFixture, ResponseConsume)
{
    Value r = ctx.eval(
        "var resp = new Response('{\"k\": 1}');"
        "resp.text().then(t => { globalThis.__t = t; return resp.json(); }).catch(e => {"
        " globalThis.__e = e.name; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__t").as<std::string>(), "{\"k\": 1}");
    // 第二次消费 body → TypeError
    EXPECT_EQ(ctx.eval("__e").as<std::string>(), "TypeError");
}

TEST_F(FetchFixture, ResponseErrorAndRedirect)
{
    Value r = ctx.eval(
        "Response.error().type + '|' + Response.redirect('http://x/y', 302).status + '|' +"
        "Response.redirect('http://x/y', 302).headers.get('location');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "error|302|http://x/y");
}

TEST_F(FetchFixture, HeaderMethodOverride)
{
    Value r = ctx.eval(
        "var r = new Request('https://site.example/');"
        "r.headers.append('x-http-method-override', 'GETTRACE');"
        "r.headers.get('x-http-method-override') + '|' + r.headers.has('x-http-method-override');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "GETTRACE|true");
}

TEST_F(FetchFixture, HeadersLiveIteration)
{
    // 活迭代器：迭代期间 delete/append 实时反映（wpt headers-basic 语义）
    Value r = ctx.eval(
        "var h = new Headers({'foo': '2', 'baz': '1', 'BAR': '0'});"
        "var k = []; for (const [n, v] of h) { k.push(n); h.delete('foo'); }"
        "k.join(',');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "bar,baz");
    r = ctx.eval(
        "var h = new Headers({'foo': '2', 'baz': '1', 'BAR': '0', 'quux': '3'});"
        "var k = []; for (const [n, v] of h) { k.push(n); if (n === 'baz') h.delete('bar'); }"
        "k.join(',');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "bar,baz,quux");
    r = ctx.eval(
        "var h = new Headers({'foo': '2', 'baz': '1', 'BAR': '0', 'quux': '3'});"
        "var k = []; for (const [n, v] of h) { k.push(n); if (n === 'baz') h.append('abc', '-1'); }"
        "k.join(',');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "bar,baz,baz,foo,quux");
    // 迭代器原型链 + next 描述符（wpt checkIteratorProperties）
    r = ctx.eval(
        "var it = new Headers({'a': '1'}).entries();"
        "var p = Object.getPrototypeOf(it);"
        "var d = Object.getOwnPropertyDescriptor(p, 'next');"
        "(Object.getPrototypeOf(p) === Object.getPrototypeOf(Object.getPrototypeOf([].values())))"
        " + '|' + d.enumerable + '|' + d.configurable + '|' + d.writable;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "true|true|true|true");
}

TEST_F(FetchFixture, RequestNonAsciiUrl)
{
    Value r = ctx.eval(
        "var r = new Request('http://x/y?z=1|x', {headers: {'X-Test': 'before-ß-after'}});"
        "r.url + '|' + r.headers.get('X-Test');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "http://x/y?z=1%7Cx|before-ß-after");
}

// 参照 Node(undici)：referer/cookie/origin 等用户自定义头可正常存储与发送
//（不做浏览器式 forbidden 过滤）；host/content-length 由运行时管理（忽略）。
TEST_F(FetchFixture, RequestRefererCustomHeader)
{
    Value r = ctx.eval(
        "var req = new Request('http://x/', {headers: {"
        "  'Referer': 'http://example.com/ref', 'Cookie': 'a=b',"
        "  'Origin': 'http://custom-origin.com', 'Host': 'evil.com',"
        "  'Content-Length': '999'"
        "}});"
        "['referer','cookie','origin','host','content-length'].map("
        "  n => req.headers.get(n)).join('|');");
    ASSERT_FALSE(r.is_exception());
    // 存储层不检查（Node Headers 语义）；host/content-length 在发送层忽略
    EXPECT_EQ(r.as<std::string>(),
              "http://example.com/ref|a=b|http://custom-origin.com|evil.com|999");
}

TEST_F(FetchFixture, RequestSurrogateUrl)
{
    ctx.eval("location = {href: 'http://x/url-encoding.html'}");
    Value r = ctx.eval(
        "var u1 = new URL('?\\uD83D', location.href).href;"
        "var r1 = new Request('?\\uD83D').url;"
        "u1 + '|' + r1;");
    if (r.is_exception()) {
        qjs::Value exc(ctx.raw(), JS_GetException(ctx.raw()));
        const char* s = JS_ToCString(ctx.raw(), exc.raw());
        QLOG_ERROR("EXC: {}", s ? s : "(null)");
        if (s)
            JS_FreeCString(ctx.raw(), s);
    }
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "http://x/url-encoding.html?%EF%BF%BD|http://x/url-encoding.html?%EF%BF%BD");
}

TEST_F(FetchFixture, FetchIntegrity)
{
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    // 正确摘要 → 成功（'hello world' 的 sha384 = /b2OdaZ/KfcBpOBAOF4uI5hjA+oQI5IRr5B/y7g1eLPkF8txzmRu/QgZ3YwIjeG9）
    Value r = ctx.eval(
        "fetch(base + '/echo-content.py', {method: 'POST', body: 'hello world',"
        " integrity: 'sha384-/b2OdaZ/KfcBpOBAOF4uI5hjA+oQI5IRr5B/y7g1eLPkF8txzmRu/QgZ3YwIjeG9'})"
        ".then(x => { globalThis.__ok = x.status; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<int>(), 200);
    // 错误摘要 → M3 消费末端校验：fetch resolve，text() reject TypeError
    //（设计文档 §4.5；v1 是 fetch 直接 reject）
    r = ctx.eval(
        "fetch(base + '/echo-content.py', {method: 'POST', body: 'hello world',"
        " integrity: 'sha384-' + 'A'.repeat(64)})"
        ".then(x => { globalThis.__bad = 'resolved:' + x.status; return x.text(); })"
        ".then(() => { globalThis.__bad += '|no'; },"
        "      e => { globalThis.__bad += '|' + e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__bad").as<std::string>(), "resolved:200|TypeError");
    // 204 null body + integrity → reject TypeError（wpt response-null-body 语义）
    r = ctx.eval(
        "fetch(base + '/status.py?code=204', {integrity: 'sha384-UT6f7WCFp32YJnp1is4l/ZYnOeQKpE8xjmdkLOwZ3nIP+tmT2aMRFQGJomjVf5cE'})"
        ".then(() => { globalThis.__n = 'no'; })"
        ".catch(e => { globalThis.__n = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__n").as<std::string>(), "TypeError");
    // 构造时非法元数据 → TypeError
    r = ctx.eval("new Request(base + '/echo-content.py', {integrity: 'bogus'});");
    EXPECT_TRUE(r.is_exception());
    r = ctx.eval("new Request(base + '/echo-content.py', {integrity: 'md5-abc'});");
    EXPECT_TRUE(r.is_exception());
    // 空串合法（不校验）
    r = ctx.eval("new Request(base + '/echo-content.py', {integrity: ''}).integrity;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "");
}

TEST_F(FetchFixture, FetchCompressed)
{
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    // 三种编码：解压后内容一致；X-Req-Accept-Encoding 证明拦截器自动加了协商头
    Value r = ctx.eval(
        "var __ae = null, __out = [];"
        "fetch(base + '/compress.py?code=gzip', {method: 'POST', body: 'hello world'})"
        ".then(x => { __ae = x.headers.get('X-Req-Accept-Encoding'); return x.text(); })"
        ".then(t => __out.push('gzip:' + t + ':ae=' + __ae));"
        "fetch(base + '/compress.py?code=deflate', {method: 'POST', body: 'hello deflate'})"
        ".then(x => x.text()).then(t => __out.push('deflate:' + t));"
        "fetch(base + '/compress.py?code=br', {method: 'POST', body: 'hello brotli'})"
        ".then(x => x.text()).then(t => __out.push('br:' + t));"
        "fetch(base + '/compress.py?code=gzip&corrupt=1', {method: 'POST', body: 'garbage'})"
        ".then(x => x.text()).then(t => __out.push('bad:' + t))"
        ".catch(e => __out.push('bad:' + e.name));"
        "globalThis.__out = __out; 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    // 并发请求的完成顺序不是契约（stdexec::task 与旧 basic_task 的调度语义
    // 不同，完成顺序可能变化）——排序后比较，顺序无关
    EXPECT_EQ(ctx.eval("__out.slice().sort().join(',')").as<std::string>(),
              "bad:TypeError,br:hello brotli,deflate:hello deflate,"
              "gzip:hello world:ae=gzip, deflate, br");
    // 解压 + SRI：摘要基于解压后内容（sha384('hello world') 通过 → 200 且 text 正常）
    r = ctx.eval(
        "fetch(base + '/compress.py?code=gzip', {method: 'POST', body: 'hello world',"
        " integrity: 'sha384-/b2OdaZ/KfcBpOBAOF4uI5hjA+oQI5IRr5B/y7g1eLPkF8txzmRu/QgZ3YwIjeG9'})"
        ".then(x => x.text()).then(t => { globalThis.__sri = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__sri").as<std::string>(), "hello world");
    // url-safe 变体 + 去 padding 的 integrity 同样通过（-_ → +/ 归一化）
    r = ctx.eval(
        "fetch(base + '/compress.py?code=gzip', {method: 'POST', body: 'hello world',"
        " integrity: 'sha384-_b2OdaZ_KfcBpOBAOF4uI5hjA-oQI5IRr5B_y7g1eLPkF8txzmRu_QgZ3YwIjeG9'})"
        ".then(x => x.text()).then(t => { globalThis.__sri2 = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__sri2").as<std::string>(), "hello world");
    // >64KiB body：压缩流跨多个 64KiB 块边界（gzip/deflate/br 三编码）
    r = ctx.eval(
        "var big = 'A'.repeat(70 * 1024);"
        "fetch(base + '/compress.py?code=gzip', {method: 'POST', body: big})"
        ".then(x => x.text()).then(t => { globalThis.__big = t.length; });"
        "fetch(base + '/compress.py?code=deflate', {method: 'POST', body: big})"
        ".then(x => x.text()).then(t => { globalThis.__bigd = t.length; });"
        "fetch(base + '/compress.py?code=br', {method: 'POST', body: big})"
        ".then(x => x.text()).then(t => { globalThis.__bigb = t.length; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__big + ',' + __bigd + ',' + __bigb").as<std::string>(),
              "71680,71680,71680");
    // trailing 字节：流尾垃圾应被忽略（三编码）
    r = ctx.eval(
        "fetch(base + '/compress.py?code=gzip&trailing=1', {method: 'POST', body: 'hi'})"
        ".then(x => x.text()).then(t => { globalThis.__tr = t; });"
        "fetch(base + '/compress.py?code=br&trailing=1', {method: 'POST', body: 'hi'})"
        ".then(x => x.text()).then(t => { globalThis.__trb = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__tr + ',' + __trb").as<std::string>(), "hi,hi");
}

TEST_F(FetchFixture, FetchDataUrl)
{
    Value r = ctx.eval(
        "var out = [];"
        "fetch('data:,response%27s%20body').then(x => {"
        " out.push(x.status + '|' + x.headers.get('content-type')); return x.text(); })"
        ".then(t => { out.push(t); });"
        "fetch('data:text/plain;base64,cmVzcG9uc2UncyBib2R5').then(x => {"
        " out.push(x.headers.get('content-type')); return x.text(); })"
        ".then(t => { out.push(t); });"
        "fetch('data:image/png;base64,AAAA').then(x => {"
        " out.push(x.headers.get('content-type')); return x.arrayBuffer(); })"
        ".then(b => { out.push(new Uint8Array(b).length); });"
        "fetch('data:notAdataUrl.com').then(() => { out.push('no'); })"
        ".catch(e => { out.push(e.name); });"
        "globalThis.__out = out; 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__out.join(',')").as<std::string>(),
              "200|text/plain;charset=US-ASCII,text/plain,image/png,TypeError,"
              "response's body,response's body,3");
}

TEST_F(FetchFixture, FetchDataUrlHead)
{
    Value r = ctx.eval(
        "fetch('data:,hello', {method: 'HEAD'}).then(x => {"
        " globalThis.__h = x.status + '|' + x.headers.get('content-type'); return x.text(); })"
        ".then(t => { globalThis.__h += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__h").as<std::string>(), "200|text/plain;charset=US-ASCII|");
}

TEST_F(FetchFixture, UrlSearchParamsLinkage)
{
    // SameObject：多次 getter 同一对象
    Value r = ctx.eval(
        "var u = new URL('http://x/a?b=1');"
        "u.searchParams === u.searchParams;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<bool>(), true);
    // params 修改 → URL.search 实时回写
    r = ctx.eval(
        "var u = new URL('http://x/a?b=1&c=2');"
        "var p = u.searchParams;"
        "p.append('d', 'x y'); p.set('b', '9'); p.delete('c'); p.sort();"
        "u.search + '|' + p.toString();");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "?b=9&d=x+y|b=9&d=x+y");
    // URL.search 修改 → 已缓存的 params 同步（live）
    r = ctx.eval(
        "var u = new URL('http://x/a?b=1');"
        "var p = u.searchParams;"
        "u.search = '?x=42&y=7';"
        "p.get('x') + '|' + p.get('b') + '|' + p.toString();");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "42|null|x=42&y=7");
    // href 整体重设 → 同步
    r = ctx.eval(
        "var u = new URL('http://x/a?b=1');"
        "var p = u.searchParams;"
        "u.href = 'http://x/z?q=9';"
        "p.get('q') + '|' + p.get('b');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "9|null");
    // 独立实例不联动（new URLSearchParams(url.searchParams) 是拷贝）
    r = ctx.eval(
        "var u = new URL('http://x/a?b=1');"
        "var p2 = new URLSearchParams(u.searchParams);"
        "p2.set('b', '2');"
        "u.search + '|' + p2.toString();");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "?b=1|b=2");
}

TEST_F(FetchFixture, BlobBasic)
{
    // 构造（string/ArrayBuffer/TypedArray/Blob parts）+ size/type + slice + text/arrayBuffer
    Value r = ctx.eval(
        "var b = new Blob(['hello ', new Uint8Array([0xE4, 0xB8, 0x96]), new ArrayBuffer(0)],"
        " {type: 'text/PLAIN;charset=utf-8'});"
        "b.size + '|' + b.type;");
    ASSERT_FALSE(r.is_exception());
    // 规范：Blob.type 保留 MIME 参数（参照 Node：小写 + trim，保留原始空白）
    EXPECT_EQ(r.as<std::string>(), "9|text/plain;charset=utf-8");
    r = ctx.eval(
        "var b = new Blob(['abcdef']);"
        "b.slice(1, 4).text().then(t => { globalThis.__sl = t; });"
        "b.slice(-3).text().then(t => { globalThis.__sl += '|' + t; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__sl").as<std::string>(), "bcd|def");
    r = ctx.eval(
        "var b = new Blob([new Uint8Array([1, 2, 3])]);"
        "b.arrayBuffer().then(ab => { globalThis.__ab = new Uint8Array(ab).length; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ab").as<int>(), 3);
    // BOM：text() 去 BOM
    r = ctx.eval(
        "var b = new Blob([new Uint8Array([0xEF, 0xBB, 0xBF, 0x61])]);"
        "b.text().then(t => { globalThis.__bom = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__bom").as<std::string>(), "a");
}

TEST_F(FetchFixture, BlobFile)
{
    Value r = ctx.eval(
        "var f = new File(['content'], 'a.txt', {type: 'text/plain', lastModified: 123});"
        "f.name + '|' + f.size + '|' + f.type + '|' + f.lastModified;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "a.txt|7|text/plain|123");
    // File 作为 fetch body（Content-Type 自动设置）
    r = ctx.eval(
        "var f = new File(['x'], 'b.bin', {type: 'application/octet-stream'});"
        "new Request('http://x/', {method: 'POST', body: f}).headers.get('content-type');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "application/octet-stream");
    // Blob 作为 Response 构造 body（Content-Type 自动）
    r = ctx.eval(
        "var b = new Blob(['{\"k\":1}'], {type: 'application/json'});"
        "new Response(b).headers.get('content-type');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "application/json");
}

TEST_F(FetchFixture, FormDataBasic)
{
    Value r = ctx.eval(
        "var fd = new FormData();"
        "fd.append('a', '1'); fd.append('a', '2'); fd.append('b', new Blob(['x'], {type: 'text/x'}));"
        "fd.set('a', '9');"
        "fd.has('a') + '|' + fd.get('a') + '|' + fd.getAll('a').join(',') + '|' + fd.has('b');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "true|9|9|true");
    r = ctx.eval(
        "var fd = new FormData();"
        "fd.append('k1', 'v1'); fd.append('k2', new File(['b2'], 'f2.txt', {type: 'text/plain'}));"
        "var out = []; for (const [k, v] of fd) { out.push(k + '=' + (typeof v === 'string' ? v : v.name)); }"
        "fd.delete('k1'); out.join(',') + '|' + fd.has('k1');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "k1=v1,k2=f2.txt|false");
    // multipart 编码：boundary + Content-Disposition + Content-Type
    r = ctx.eval(
        "var fd = new FormData();"
        "fd.append('n', 'v a'); fd.append('f', new File(['xy'], 'x.txt', {type: 'text/plain'}));"
        "var req = new Request('http://x/', {method: 'POST', body: fd});"
        "String(req.headers.get('content-type'));");
    ASSERT_FALSE(r.is_exception());
    QLOG_DEBUG("CT={}", r.as<std::string>());
    EXPECT_TRUE(r.as<std::string>().rfind("multipart/form-data; boundary=", 0) == 0);
}

TEST_F(FetchFixture, FormDataRoundTrip)
{
    // 空 FormData 往返
    Value r = ctx.eval(
        "new Response(new FormData()).formData().then(fd => {"
        " globalThis.__e = fd instanceof FormData; })"
        ".catch(e => { globalThis.__e = 'ERR:' + e.name + ':' + e.message; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("String(__e)").as<std::string>(), "true");
    // multipart 往返：string + File（type 保留）
    r = ctx.eval(
        "var fd = new FormData();"
        "fd.append('foo', 'bar');"
        "fd.append('file', new File(['{\"a\":1}'], 'j.json', {type: 'application/json'}));"
        "new Response(fd).formData().then(fd2 => {"
        " globalThis.__n = fd2.get('foo');"
        " var f = fd2.get('file');"
        " globalThis.__t = f.name + '|' + f.type + '|' + f.size;"
        " return f.text(); }).then(t => { globalThis.__b = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__n").as<std::string>(), "bar");
    EXPECT_EQ(ctx.eval("__t").as<std::string>(), "j.json|application/json|7");
    EXPECT_EQ(ctx.eval("__b").as<std::string>(), "{\"a\":1}");
    // 头名大小写不敏感（wpt formdata.any.js：小写 content-disposition 也能解析）
    r = ctx.eval(
        "var fd = new FormData();"
        "fd.append('foo', new Blob(['x'], {type: 'application/json'}));"
        "var r1 = new Response(fd);"
        "r1.formData().then(fd2 => {"
        " globalThis.__m = fd2.has('foo') + '|' + fd2.get('foo').type; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__m").as<std::string>(), "true|application/json");
}

// ---- P0 补齐：blob() / Response.json() / URL.parse() / AbortSignal.timeout/any ----
TEST_F(FetchFixture, P0BlobAndJson)
{
    // Request.blob() / Response.blob()：返回 Blob（bodyUsed 置位）
    Value r = ctx.eval(
        "var p = new Response('hello').blob().then(b => {"
        "  globalThis.__blob = b.size + '|' + b.type;"
        "  return b.text();"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__blob").as<std::string>(), "5|text/plain;charset=utf-8");
    // Response.json(data, init)：默认 application/json；init.headers 优先
    r = ctx.eval(
        "var a = new Response(JSON.stringify({k: 1}));"
        "var b = Response.json({k: 1});"
        "var c = Response.json({k: 1}, {status: 201, headers: {'content-type': 'application/problem+json'}});"
        "a.headers.get('content-type') + '|' + b.headers.get('content-type') + '|' + c.status + '|' +"
        "c.headers.get('content-type');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(),
              "text/plain;charset=UTF-8|application/json|201|application/problem+json");
    // Response.json body 内容 = JSON.stringify 结果
    r = ctx.eval(
        "Response.json({a: [1, 2]}).text().then(t => { globalThis.__jt = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__jt").as<std::string>(), "{\"a\":[1,2]}");
}

TEST_F(FetchFixture, P0UrlParse)
{
    Value r = ctx.eval(
        "String(URL.parse('http://x/y?z=1')) + '|' +"
        "String(URL.parse('/rel', 'http://base/')) + '|' +"
        "String(URL.parse('not a url')) + '|' +"
        "String(URL.parse('http://[bad')) + '|' +"
        "(URL.parse('http://x/') === null ? 'null' : 'ok');");
    ASSERT_FALSE(r.is_exception());
    // 合法 → 对象（String 转 href）；非法 → null（不抛）
    EXPECT_EQ(r.as<std::string>(), "http://x/y?z=1|http://base/rel|null|null|ok");
}

TEST_F(FetchFixture, P0AbortSignalTimeoutAny)
{
    // AbortSignal.timeout：到期后 aborted=true，reason=TimeoutError。
    // 定时器挂 io_ 注册表（不走 pending_，Node 语义：独立 timeout 不保持
    // run_to_completion），用 io.run_for 显式驱动触发。
    Value r = ctx.eval(
        "var sig = AbortSignal.timeout(20);"
        "globalThis.__timeout = 'pending';"
        "sig.addEventListener('abort', () => {"
        "  globalThis.__timeout = sig.aborted + '|' + sig.reason.name + '|' + sig.reason.message;"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    {
        auto& io = rt.io();
        boost::asio::steady_timer kick(io, std::chrono::milliseconds(60));
        kick.async_wait([](const boost::system::error_code&) {});
        io.run_for(std::chrono::milliseconds(60));
    }
    EXPECT_EQ(ctx.eval("__timeout").as<std::string>(),
              "true|TimeoutError|signal timed out");
    // 未到期前 aborted=false
    r = ctx.eval("var s2 = AbortSignal.timeout(100000); s2.aborted;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "false");
    // AbortSignal.any：任一 abort → 输出 abort（事件同步传播）；已 abort 输入 → 立即 abort
    r = ctx.eval(
        "var a = new AbortController(); var b = new AbortController();"
        "var any = AbortSignal.any([a.signal, b.signal]);"
        "globalThis.__any = 'pending';"
        "any.addEventListener('abort', () => { globalThis.__any = any.aborted + '|' + any.reason.name; });"
        "a.abort(); 'ok'");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(ctx.eval("__any").as<std::string>(), "true|AbortError");
    r = ctx.eval(
        "var c = new AbortController(); c.abort();"
        "AbortSignal.any([c.signal]).aborted;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "true");
}

// ---- 空 body 消费：bodyUsed 不置位；有 body 消费才置位（wpt consume-empty） ----
TEST_F(FetchFixture, ConsumeEmptyBodyBodyUsed)
{
    // 无 body：text()/arrayBuffer() 返回空结果且 bodyUsed 保持 false
    Value r = ctx.eval(
        "var req = new Request('http://x/', {method: 'POST'});"
        "var resp = new Response();"
        "globalThis.__cb = 'pending';"
        "Promise.all([req.text(), resp.text(), req.arrayBuffer(), resp.arrayBuffer(),"
        "             resp.json().catch(() => 'jerr'), req.json().catch(() => 'jerr')])"
        ".then(v => { globalThis.__cb ="
        "  (v[0] === '' && v[1] === '' && v[2].byteLength === 0 && v[3].byteLength === 0 &&"
        "   v[4] === 'jerr' && v[5] === 'jerr') + '|' + req.bodyUsed + '|' + resp.bodyUsed; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__cb").as<std::string>(), "true|false|false");
    // 有 body：消费后 bodyUsed 置位
    r = ctx.eval(
        "var req2 = new Request('http://x/', {method: 'POST', body: 'hi'});"
        "req2.text().then(() => { globalThis.__cb2 = req2.bodyUsed; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__cb2").as<std::string>(), "true");
    // 重复消费 → rejected promise（fetch 规范：text() 对已消费 body reject TypeError，非同步抛）
    r = ctx.eval(
        "var resp2 = new Response('x');"
        "resp2.text().then(() => {"
        "  resp2.text().then(() => { globalThis.__cb3 = 'no-reject'; },"
        "    e => { globalThis.__cb3 = e.name; });"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__cb3").as<std::string>(), "TypeError");
}

// ---- bytes()：返回 Uint8Array，内容一致，bodyUsed 置位 ----
TEST_F(FetchFixture, BodyBytes)
{
    Value r = ctx.eval(
        "var resp = new Response('hi');"
        "resp.bytes().then(u8 => {"
        "  globalThis.__by = (u8 instanceof Uint8Array) + '|' + u8.length + '|' +"
        "    new TextDecoder().decode(u8) + '|' + resp.bodyUsed;"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__by").as<std::string>(), "true|2|hi|true");
    // 空 body bytes() → 空 Uint8Array
    r = ctx.eval(
        "new Response().bytes().then(u8 => { globalThis.__by2 = u8.length; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__by2").as<int>(), 0);
}

// ---- formData()：urlencoded 分支 + 无 body 语义（wpt consume-empty/request-consume） ----
TEST_F(FetchFixture, FormDataUrlencoded)
{
    Value r = ctx.eval(
        "var resp = new Response('a=1&b=hello+world&empty=');"
        "resp.headers.set('content-type', 'application/x-www-form-urlencoded;charset=UTF-8');"
        "resp.formData().then(fd => {"
        "  globalThis.__fd = fd.get('a') + '|' + fd.get('b') + '|' + fd.get('empty');"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__fd").as<std::string>(), "1|hello world|");
    // 无 body + urlencoded content-type → 空 FormData（成功，bodyUsed 不置位）
    r = ctx.eval(
        "var req = new Request('http://x/', {method: 'POST',"
        "  headers: [['Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8']]});"
        "req.formData().then(fd => {"
        "  globalThis.__fd2 = (fd instanceof FormData) + '|' + fd.get('nope') + '|' + req.bodyUsed;"
        "}); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__fd2").as<std::string>(), "true|null|false");
    // 无 body + multipart content-type → TypeError（fetch 规范：bodyBytes null）
    r = ctx.eval(
        "var req2 = new Request('http://x/', {method: 'POST',"
        "  headers: [['Content-Type', 'multipart/form-data; boundary=\"boundary\"']]});"
        "req2.formData().then(() => { globalThis.__fd3 = 'ok'; },"
        "  e => { globalThis.__fd3 = e.name + '|' + req2.bodyUsed; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__fd3").as<std::string>(), "TypeError|false");
    // 无 body + 无 content-type → TypeError
    r = ctx.eval(
        "new Response().formData().then(() => { globalThis.__fd4 = 'ok'; },"
        "  e => { globalThis.__fd4 = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__fd4").as<std::string>(), "TypeError");
}

// ---- Blob.type 保留 MIME 参数 + multipart 全链路大小写不敏感（wpt formdata.any.js） ----
TEST_F(FetchFixture, BlobTypeKeepsParamsAndMultipartCaseInsensitive)
{
    // Blob 构造：type 保留参数（boundary），仅小写 + trim（参照 Node）
    Value r = ctx.eval(
        "var b = new Blob(['x'], {type: 'Multipart/Form-Data ;  boundary=\"AbC\"'});"
        "b.type;");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), "multipart/form-data ;  boundary=\"abc\"");
    // wpt formdata.any.js：multipart body 小写化后仍可解析回 FormData
    r = ctx.eval(R"JS(
(async () => {
  let formdata = new FormData();
  formdata.append('foo', new Blob([JSON.stringify({ bar: "baz" })], { type: "application/json" }));
  let blob = await new Response(formdata).blob();
  let body = await blob.text();
  blob = new Blob([body.toLowerCase()], { type: blob.type.toLowerCase() });
  let fd = await new Response(blob).formData();
  globalThis.__mci = fd.has('foo') + '|' + fd.get('foo').type;
})()
)JS");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__mci").as<std::string>(), "true|application/json");
    // 空 FormData：text() 输出 "--boundary--" 格式（HTML multipart 编码，wpt
    // response-form-data.html "Empty form data"）；formData() 解析回空表单
    r = ctx.eval(R"JS(
(async () => {
  const r1 = new Response(new FormData());
  const t = await r1.text();
  const start = t.startsWith('--');
  let boundary = t.substring(2).trim();
  const end = boundary.endsWith('--');
  const r2 = new Response(t);
  r2.headers.set('content-type', 'multipart/form-data; boundary=' + boundary.substring(0, boundary.length - 2));
  const fd = await r2.formData();
  globalThis.__efd = start + '|' + end + '|' + (fd instanceof FormData) + '|' + fd.get('x');
})()
)JS");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__efd").as<std::string>(), "true|true|true|null");
}

// ---- v2 M1：后端流式化（fetch resolve 提前；body 读干；中途 abort/失败）----
TEST_F(FetchFixture, M1FetchResolvesBeforeBody)
{
    // slow-response：响应头立即发出、body 延迟 200ms——fetch 在头部到达时即
    // resolve（v1 需等全量 body），text() 随后读干。
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    Value r = ctx.eval(
        "var t0 = Date.now();"
        "fetch(base + '/slow-response.py?delay=200&content=hello').then(x => {"
        " globalThis.__early = x.status + '|' + (Date.now() - t0 < 150);"
        " return x.text();"
        "}).then(t => { globalThis.__late = t + '|' + (Date.now() - t0 >= 180); });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    // resolve 早于 body 完成；text() 读干得到完整 body
    EXPECT_EQ(ctx.eval("__early").as<std::string>(), "200|true");
    EXPECT_EQ(ctx.eval("__late").as<std::string>(), "hello|true");
}

TEST_F(FetchFixture, M1FetchAbortDuringBody)
{
    // 慢响应：fetch resolve 后 abort → 挂起的读 reject AbortError（设计文档 §3.3）
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    Value r = ctx.eval(
        "var c = new AbortController();"
        "globalThis.__ab = 'pending';"
        "fetch(base + '/slow-response.py?delay=400&content=hello', {signal: c.signal})"
        ".then(x => { globalThis.__ab = 'resolved'; c.abort(); return x.text(); })"
        ".then(t => { globalThis.__ab += '|' + t; },"
        "      e => { globalThis.__ab += '|' + e.name; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ab").as<std::string>(), "resolved|AbortError");
}

TEST_F(FetchFixture, M1FetchBodyReadError)
{
    // 谎报 content-length：头后连接即断 → 读 body 中途失败 → 消费 reject TypeError
    //（fetch 已 resolve；v1 是 fetch 直接 reject）
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    Value r = ctx.eval(
        "fetch(base + '/bad-length.py?length=100&content=hello')"
        ".then(x => { globalThis.__bl = 'resolved:' + x.status; return x.text(); })"
        ".then(t => { globalThis.__bl += '|' + t; },"
        "      e => { globalThis.__bl += '|' + e.name; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    const std::string out = ctx.eval("__bl").as<std::string>();
    EXPECT_TRUE(out.rfind("resolved:200|", 0) == 0) << out;
    EXPECT_EQ(out, "resolved:200|TypeError") << out;
}

// ---- v2 M2：ReadableStream 绑定（body getter/reader/tee/abort 语义）----
TEST_F(FetchFixture, M2BodyStreamBasics)
{
    // body getter 返回流；locked/bodyUsed/getReader/read 基本语义
    Value r = ctx.eval(
        "var resp = new Response('hello');"
        "globalThis.__bs = String(resp.body.constructor.name) + '|' + resp.body.locked + '|' + resp.bodyUsed;"
        "var reader = resp.body.getReader();"
        "globalThis.__bs += '|' + resp.body.locked + '|' + resp.bodyUsed;"
        "reader.read().then(function(x) {"
        "  var td = new TextDecoder();"
        "  globalThis.__bs += '|' + x.done + '|' + td.decode(x.value);"
        "  return reader.read();"
        "}).then(function(x) { globalThis.__bs += '|' + x.done + '|' + resp.bodyUsed; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__bs").as<std::string>(),
              "ReadableStream|false|false|true|false|false|hello|true|true");
}

TEST_F(FetchFixture, M2BodyLockedConsume)
{
    // getReader 后消费方法 reject TypeError；reader GC 后流仍锁定（wpt 语义）
    Value r = ctx.eval(
        "var resp = new Response('x');"
        "resp.body.getReader();" // 返回值丢弃（reader 可被 GC）
        "var threw = false;"
        "resp.blob().then(function() { globalThis.__lc = 'resolved'; },"
        "                  function(e) { globalThis.__lc = e.name; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__lc").as<std::string>(), "TypeError");
}

TEST_F(FetchFixture, M2CloneTee)
{
    // clone：tee 共享底层，两侧独立读；disturbed 检查
    Value r = ctx.eval(
        "var resp = new Response('hello');"
        "var c = resp.clone();"
        "Promise.all([resp.text(), c.text()]).then(function(ts) {"
        "  globalThis.__ct = ts[0] + '|' + ts[1];"
        "}, function(e) { globalThis.__ct = 'rej:' + e.name; });"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ct").as<std::string>(), "hello|hello");
}

TEST_F(FetchFixture, M2FetchResponseStream)
{
    // fetch 响应 body 流式读取（慢响应：read 挂起后数据到达）
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("var base = '" + base + "';");
    Value r = ctx.eval(
        "fetch(base + '/slow-response.py?delay=150&content=streamed').then(function(resp) {"
        "  var reader = resp.body.getReader();"
        "  var chunks = [];"
        "  function pump() {"
        "    return reader.read().then(function(x) {"
        "      if (x.done) { globalThis.__fs = chunks.join('|') + '|used=' + resp.bodyUsed; return; }"
        "      chunks.push(new TextDecoder().decode(x.value));"
        "      return pump();"
        "    });"
        "  }"
        "  return pump();"
        "});"
        "'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__fs").as<std::string>(), "streamed|used=true");
}

} // namespace
