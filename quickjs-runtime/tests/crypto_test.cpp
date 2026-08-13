// crypto_test.cpp —— Breeze 风格 crypto API 集成测试（对齐 kit types/crypto.d.ts）
//
// 覆盖：
//   - 标准向量互操作：sha256/md5/sha1/sha512、HMAC（RFC 4231）、PBKDF2
//     （RFC 7914/6070）、AES-128-CBC/AES-128-GCM（node crypto 生成向量）
//   - 流式 createHash/createHmac：多次 update、输入编码（hex/base64）、
//     digest 默认 Buffer、二进制输入
//   - AES：CBC/ECB 往返与 PKCS7 padding、GCM tag 拼接与认证失败、B64 变体
//   - 异步 API（Promise）：md5/sha*/hmacSha*/aes*（stdexec 协程 + 后台线程池）
//   - 真异步验证：pbkdf2 高迭代计算期间 setTimeout 按时触发（不阻塞事件循环）
//   - randomBytes/randomUUID、timingSafeEqual、pbkdf2 callback（异步）
//   - 错误路径：非法算法/密钥长度/IV 长度/iterations 上限/hex/非二进制对象
#include <chrono>
#include <string>
#include <thread>

#include <gtest/gtest.h>
#include <qjsbind/blob_store.hpp>
#include <qjsbind/polyfill/crypto.hpp>
#include <qjsbind/polyfill/runtime_api.hpp>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp> // install_timers（AsyncDoesNotBlockLoop 用 setTimeout）

using namespace qjs;

namespace {

// fixture：runtime_api（Buffer/bytesToBase64/uuidv4）+ timers + crypto
struct CryptoFixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    CryptoFixture()
    {
        dyn::install_blob_store(ctx);     // runtime_api.js 引用的既有能力
        install_runtime_api(ctx);         // Buffer / bytesToBase64 / uuidv4
        qjsbind::web::install_timers(ctx); // setTimeout（真异步验证用）
        install_crypto(ctx);              // crypto / hostCrypto / nodeCryptoCompat
        // 测试辅助：__settle（Promise 结算到全局槽，reject 置 __crypto_err）
        ctx.eval("globalThis.__settle = (p) => {"
                 "  globalThis.__crypto_r = undefined;"
                 "  globalThis.__crypto_err = false;"
                 "  globalThis.__crypto_err_msg = '';"
                 "  Promise.resolve(p).then(v => { globalThis.__crypto_r = v; },"
                 "                     e => { globalThis.__crypto_err = true;"
                 "                            globalThis.__crypto_err_msg = String(e && e.message || e); });"
                 "};");
    }

    Value eval_ok(const std::string& code)
    {
        Value r = ctx.eval(code);
        if (r.is_exception()) {
            JSValue e = JS_GetException(ctx.raw());
            auto s = Context(ctx.raw()).js_string(e);
            QLOG_ERROR("[crypto_test] eval failed: {} | code: {}", s ? *s : "(null)", code);
            JS_FreeValue(ctx.raw(), e);
        }
        EXPECT_FALSE(r.is_exception());
        return r;
    }

    // 驱动事件循环结算 microtask（__settle 已注册）
    void pump() { rt.run_to_completion(); }

    // 反复 pump 直到条件成立（后台线程结算 post 回 JS 线程，需多轮等待）
    void pump_until(const std::string& cond_expr, int max_tries = 100)
    {
        for (int i = 0; i < max_tries; ++i) {
            rt.run_to_completion();
            if (eval_ok(cond_expr).as<bool>())
                return;
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        FAIL() << "pump_until 超时: " << cond_expr;
    }

    // 单层 Promise：__settle(expr) → pump → serialize(__crypto_r)
    std::string eval_async(const std::string& expr, const std::string& serialize)
    {
        eval_ok("__settle(" + expr + ");");
        pump();
        EXPECT_FALSE(eval_ok("globalThis.__crypto_err === true;").as<bool>())
            << "异步求值 reject: " << expr << " | err: "
            << eval_ok("globalThis.__crypto_err_msg;").as<std::string>();
        return eval_ok("(" + serialize + ");").as<std::string>();
    }
};

// ================= 标准向量互操作 =================

TEST_F(CryptoFixture, HashVectors)
{
    EXPECT_EQ(eval_ok("crypto.createHash('sha256').update('abc').digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_ok("crypto.createHash('md5').update('abc').digest('hex');")
                  .as<std::string>(),
              "900150983cd24fb0d6963f7d28e17f72");
    EXPECT_EQ(eval_ok("crypto.createHash('sha1').update('abc').digest('hex');")
                  .as<std::string>(),
              "a9993e364706816aba3e25717850c26c9cd0d89d");
    EXPECT_EQ(eval_ok("crypto.createHash('sha512').update('abc').digest('hex');")
                  .as<std::string>(),
              "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2"
              "192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f");
    EXPECT_EQ(eval_ok("crypto.createHash('sha-256').update('abc').digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}

TEST_F(CryptoFixture, HexEncodeNative)
{
    // __crypto_hex_encode 直接路径（原生 boost hex_lower）：空/边界/高字节/NUL
    EXPECT_EQ(eval_ok("__crypto_hex_encode(new Uint8Array([]));").as<std::string>(), "");
    EXPECT_EQ(eval_ok("__crypto_hex_encode(new Uint8Array([0,1,15,16,255]));").as<std::string>(),
              "00010f10ff");
    EXPECT_EQ(eval_ok("__crypto_hex_encode(new Uint8Array([0xAB,0xCD,0xEF]));").as<std::string>(),
              "abcdef");
    EXPECT_EQ(eval_ok("__crypto_hex_encode(new Uint8Array([0x80,0x81,0xfe,0xff,0]));").as<std::string>(),
              "8081feff00");
    // 端到端：crypto.js 的 hexEncode → 原生 __crypto_hex_encode（digest('hex') 路径）
    EXPECT_EQ(eval_ok("crypto.createHash('sha256').update('abc').digest('hex');").as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}

TEST_F(CryptoFixture, HexDecodeNative)
{
    // __crypto_hex_decode 直接路径（原生 boost unhex）：小写/大写/空
    EXPECT_EQ(eval_ok("(() => { const d = __crypto_hex_decode('616263'); return Array.from(d).join(','); })();")
                  .as<std::string>(), "97,98,99");
    EXPECT_EQ(eval_ok("(() => { const d = __crypto_hex_decode('ABCDEF'); return Array.from(d).join(','); })();")
                  .as<std::string>(), "171,205,239");
    EXPECT_EQ(eval_ok("(() => { const d = __crypto_hex_decode(''); return d.length; })();").as<int>(), 0);
    // 奇长度 / 非法字符 → JS TypeError（原生 throw_type_error，instanceof 正确）
    EXPECT_TRUE(eval_ok("(() => { try { __crypto_hex_decode('abc'); return false; }"
                        "catch (e) { return e instanceof TypeError; } })();").as<bool>());
    EXPECT_TRUE(eval_ok("(() => { try { __crypto_hex_decode('0g'); return false; }"
                        "catch (e) { return e instanceof TypeError; } })();").as<bool>());
    // 端到端：update('616263', 'hex') 走 JS hexDecode → 原生 __crypto_hex_decode
    EXPECT_EQ(eval_ok("crypto.createHash('sha256').update('616263', 'hex').digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}

TEST_F(CryptoFixture, HashStreaming)
{
    EXPECT_EQ(eval_ok(
                  "const h = crypto.createHash('sha256');"
                  "h.update('a').update('b').update('c');"
                  "h.digest('hex');").as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_ok(
                  "crypto.createHash('sha256').update('616263', 'hex').digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_ok(
                  "crypto.createHash('sha256').update('YWJj', 'base64').digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_ok(
                  "const d = crypto.createHash('sha256').update('abc').digest();"
                  "Buffer.isBuffer(d) && d.toString('hex');").as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_ok(
                  "crypto.createHash('sha256').update(new Uint8Array([97,98,99])).digest('hex');")
                  .as<std::string>(),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}

TEST_F(CryptoFixture, HmacVectors)
{
    // RFC 4231（key="key"，fox 文本）
    EXPECT_EQ(eval_ok(
                  "crypto.createHmac('sha256', 'key')"
                  ".update('The quick brown fox jumps over the lazy dog').digest('hex');")
                  .as<std::string>(),
              "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8");
    EXPECT_EQ(eval_ok(
                  "crypto.createHmac('sha1', 'key')"
                  ".update('The quick brown fox jumps over the lazy dog').digest('hex');")
                  .as<std::string>(),
              "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9");
}

TEST_F(CryptoFixture, Pbkdf2Vectors)
{
    // RFC 7914：PBKDF2-HMAC-SHA256("password", "salt", 1, 32)；默认 digest = sha256
    EXPECT_EQ(eval_ok("crypto.pbkdf2Sync('password', 'salt', 1, 32).toString('hex');")
                  .as<std::string>(),
              "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b");
    EXPECT_EQ(eval_ok(
                  "crypto.pbkdf2Sync('password', 'salt', 1, 32, 'sha256').toString('hex');")
                  .as<std::string>(),
              "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b");
    // RFC 6070：PBKDF2-HMAC-SHA1("password", "salt", 1, 20)
    EXPECT_EQ(eval_ok(
                  "crypto.pbkdf2Sync('password', 'salt', 1, 20, 'sha1').toString('hex');")
                  .as<std::string>(),
              "0c60c80f961f0e71f3a9b524af6012062fe037a6");
}

TEST_F(CryptoFixture, AesCbcVector)
{
    // node crypto 生成：AES-128-CBC PKCS7，key=0001..0f、iv=1011..1f、"hello"
    EXPECT_EQ(eval_async(
                  "crypto.aesCbcPkcs7Encrypt('hello',"
                  "'\\x00\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\\x09\\x0a\\x0b\\x0c\\x0d\\x0e\\x0f',"
                  "'\\x10\\x11\\x12\\x13\\x14\\x15\\x16\\x17\\x18\\x19\\x1a\\x1b\\x1c\\x1d\\x1e\\x1f')",
                  "Array.from(__crypto_r).join(',')"),
              "50,246,214,234,30,200,135,45,235,204,234,133,150,217,195,195");
}

TEST_F(CryptoFixture, AesGcmVector)
{
    // node crypto 生成：AES-128-GCM，key=0001..0f、nonce=0001..0b、
    // "hello world"、aad="aad-data" → 密文 || tag（本实现拼接约定）
    EXPECT_EQ(eval_async(
                  "crypto.aesGcmEncrypt('hello world',"
                  "'\\x00\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\\x09\\x0a\\x0b\\x0c\\x0d\\x0e\\x0f',"
                  "'\\x00\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\\x09\\x0a\\x0b',"
                  "'aad-data')",
                  "Array.from(__crypto_r).join(',')"),
              "251,9,203,162,9,59,128,59,57,190,5,16,85,229,183,162,227,236,118,90,81,181,44,19,191,211,44");
}

// ================= AES 往返与认证 =================

TEST_F(CryptoFixture, AesCbcRoundtrip)
{
    // ASCII 往返（两步嵌套：先结算 encrypt 存槽，再 decrypt 读槽）
    eval_ok("__settle(crypto.aesCbcPkcs7Encrypt('hello', '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesCbcPkcs7Decrypt(__crypto_r, '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    EXPECT_EQ(eval_ok("Array.from(__crypto_r).join(',');").as<std::string>(),
              "104,101,108,108,111"); // "hello"
    // 中文往返（UTF-8 字节：hello + 世(228,184,150) + 界(231,149,140)）
    eval_ok("__settle(crypto.aesCbcPkcs7Encrypt('hello 世界', '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesCbcPkcs7Decrypt(__crypto_r, '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    EXPECT_EQ(eval_ok("Array.from(__crypto_r).join(',');").as<std::string>(),
              "104,101,108,108,111,32,228,184,150,231,149,140");
}

TEST_F(CryptoFixture, AesCbcB64Variants)
{
    // deprecated B64 变体：payload base64 进、结果 base64 出（两步嵌套）
    eval_ok("__settle(crypto.aesCbcPkcs7EncryptB64('cGF5bG9hZC0xMjM=', '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesCbcPkcs7DecryptB64(__crypto_r, '0123456789abcdef', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    // 还原出明文的 base64："payload-123" → cGF5bG9hZC0xMjM=
    EXPECT_EQ(eval_ok("__crypto_r;").as<std::string>(), "cGF5bG9hZC0xMjM=");
    // DecryptB64 返回 Promise（签名对齐：Promise<string>）
    EXPECT_EQ(eval_ok("typeof crypto.aesCbcPkcs7DecryptB64('cGF5bG9hZC0xMjM=', '0123456789abcdef', '1234567890abcdef').then;")
                  .as<std::string>(),
              "function");
}

TEST_F(CryptoFixture, AesEcbPadding)
{
    // PKCS7：15 字节 → 16；16 字节 → 32
    EXPECT_EQ(eval_async(
                  "crypto.aesEcbPkcs7Encrypt('123456789012345', '0123456789abcdef')",
                  "String(__crypto_r.length)"),
              "16");
    EXPECT_EQ(eval_async(
                  "crypto.aesEcbPkcs7Encrypt('1234567890123456', '0123456789abcdef')",
                  "String(__crypto_r.length)"),
              "32");
    // 往返
    eval_ok("__settle(crypto.aesEcbPkcs7Encrypt('ecb test', '0123456789abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesEcbPkcs7Decrypt(__crypto_r, '0123456789abcdef'));");
    pump_until("globalThis.__crypto_r !== undefined");
    EXPECT_EQ(eval_ok("Array.from(__crypto_r).join(',');").as<std::string>(),
              "101,99,98,32,116,101,115,116"); // "ecb test"
}

TEST_F(CryptoFixture, AesGcmRoundtripAndAuth)
{
    // GCM 往返 + tag 长度（密文 = 明文 + 16）
    EXPECT_EQ(eval_async(
                  "crypto.aesGcmEncrypt('gcm payload', '0123456789abcdef', '0123456789ab', 'extra')",
                  "String(__crypto_r.length)"),
              "27"); // "gcm payload" 11 + tag 16
    eval_ok("__settle(crypto.aesGcmEncrypt('gcm payload', '0123456789abcdef', '0123456789ab', 'extra'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesGcmDecrypt(__crypto_r, '0123456789abcdef', '0123456789ab', 'extra'));");
    pump_until("globalThis.__crypto_r !== undefined");
    EXPECT_EQ(eval_ok("Array.from(__crypto_r).join(',');").as<std::string>(),
              "103,99,109,32,112,97,121,108,111,97,100"); // "gcm payload"
    // 篡改 tag → 认证失败（reject → __crypto_err）
    eval_ok("__settle(crypto.aesGcmEncrypt('x', '0123456789abcdef', '0123456789ab'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("const ct = __crypto_r; ct[ct.length - 1] ^= 0xff;"
            "__settle(crypto.aesGcmDecrypt(ct, '0123456789abcdef', '0123456789ab'));");
    pump_until("globalThis.__crypto_err === true");
    EXPECT_TRUE(eval_ok("globalThis.__crypto_err === true;").as<bool>());
    // aad 不匹配 → 认证失败
    eval_ok("__settle(crypto.aesGcmEncrypt('x', '0123456789abcdef', '0123456789ab', 'aad1'));");
    pump_until("globalThis.__crypto_r !== undefined");
    eval_ok("__settle(crypto.aesGcmDecrypt(__crypto_r, '0123456789abcdef', '0123456789ab', 'aad2'));");
    pump_until("globalThis.__crypto_err === true");
    EXPECT_TRUE(eval_ok("globalThis.__crypto_err === true;").as<bool>());
}

// ================= 异步 API（Promise） =================

TEST_F(CryptoFixture, AsyncDigestApis)
{
    EXPECT_EQ(eval_async("crypto.sha256('abc')", "__crypto_r"),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    EXPECT_EQ(eval_async("crypto.md5('abc')", "__crypto_r"),
              "900150983cd24fb0d6963f7d28e17f72");
    EXPECT_EQ(eval_async("crypto.sha1('abc')", "__crypto_r"),
              "a9993e364706816aba3e25717850c26c9cd0d89d");
    EXPECT_EQ(eval_async("crypto.hmacSha256('key', 'The quick brown fox jumps over the lazy dog')",
                         "__crypto_r"),
              "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8");
    // 二进制输入
    EXPECT_EQ(eval_async("crypto.sha256(new Uint8Array([97,98,99]))", "__crypto_r"),
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
}

// ================= random / UUID / timingSafeEqual =================

TEST_F(CryptoFixture, RandomBytesAndUuid)
{
    EXPECT_EQ(eval_ok("crypto.randomBytes(16).length;").as<int>(), 16);
    EXPECT_EQ(eval_ok("crypto.randomBytes(0).length;").as<int>(), 0);
    EXPECT_TRUE(eval_ok("Buffer.isBuffer(crypto.randomBytes(4));").as<bool>());
    EXPECT_TRUE(eval_ok(
        "(() => { const a = crypto.randomBytes(16); const b = crypto.randomBytes(16);"
        "return a.toString('hex') !== b.toString('hex'); })();").as<bool>());
    const std::string uuid = eval_ok("crypto.randomUUID();").as<std::string>();
    EXPECT_EQ(uuid.size(), 36u);
    EXPECT_EQ(uuid[14], '4'); // version 4
}

TEST_F(CryptoFixture, TimingSafeEqual)
{
    EXPECT_TRUE(eval_ok("crypto.timingSafeEqual('abc', 'abc');").as<bool>());
    EXPECT_FALSE(eval_ok("crypto.timingSafeEqual('abc', 'abd');").as<bool>());
    EXPECT_FALSE(eval_ok("crypto.timingSafeEqual('abc', 'abcd');").as<bool>()); // 不等长
    EXPECT_TRUE(eval_ok(
        "crypto.timingSafeEqual(new Uint8Array([1,2]), new Uint8Array([1,2]));").as<bool>());
}

// ================= pbkdf2 callback（真异步） =================

TEST_F(CryptoFixture, Pbkdf2Callback)
{
    // digest 可省略（默认 sha256）；真异步：后台线程计算，完成后异步调 callback
    eval_ok("globalThis.__got = null;"
            "crypto.pbkdf2('password', 'salt', 1, 32, (err, key) => {"
            "  globalThis.__got = err ? 'ERR' : key.toString('hex'); });");
    // 调用点同步返回：callback 尚未执行（异步）
    EXPECT_TRUE(eval_ok("globalThis.__got === null;").as<bool>());
    pump_until("globalThis.__got !== null");
    EXPECT_EQ(eval_ok("globalThis.__got;").as<std::string>(),
              "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b");
    // 非法参数（iterations=0）→ callback 异步收 err
    eval_ok("globalThis.__got = null;"
            "crypto.pbkdf2('password', 'salt', 0, 32, (err, key) => {"
            "  globalThis.__got = err ? 'ERR' : 'OK'; });");
    pump_until("globalThis.__got !== null");
    EXPECT_EQ(eval_ok("globalThis.__got;").as<std::string>(), "ERR");
}

// ================= 真异步：调用不阻塞 JS 线程 =================

TEST_F(CryptoFixture, AsyncDoesNotBlockLoop)
{
    // 关键验证：pbkdf2 高迭代（300k，~200ms）调用后，eval 内的同步 JS
    // 应立即继续执行（__syncWork ≈ 0ms）。若为同步实现，eval 会阻塞 ~200ms
    // 才返回，__syncWork 与 __done 相等。
    eval_ok("globalThis.__done = -1; globalThis.__syncWork = -1;"
            "const t0 = Date.now();"
            "crypto.pbkdf2('p', 's', 300000, 32, (e, k) => {"
            "  globalThis.__done = Date.now() - t0; });"
            "globalThis.__syncWork = Date.now() - t0;"); // 调用返回后的同步 JS
    // eval 立即返回：同步代码在 pbkdf2 调用后马上执行（后台计算未阻塞 JS）
    const int sync_work = eval_ok("globalThis.__syncWork;").as<int>();
    EXPECT_LT(sync_work, 50); // 远小于大迭代耗时（~200ms）
    // 后台计算最终完成
    pump_until("globalThis.__done !== -1");
    const int done = eval_ok("globalThis.__done;").as<int>();
    EXPECT_GT(done, 0);
    EXPECT_LT(sync_work, done);
}

// ================= 错误路径 =================

TEST_F(CryptoFixture, ErrorPaths)
{
    // 非法算法：digest 时抛
    EXPECT_TRUE(eval_ok(
        "(() => { try { crypto.createHash('sha999').update('a').digest(); return false; }"
        "catch (e) { return true; } })();").as<bool>());
    // AES key 长度非法（15 字节）→ reject
    eval_ok("__settle(crypto.aesCbcPkcs7Encrypt('x', '123456789012345', '1234567890abcdef'));");
    pump_until("globalThis.__crypto_err === true");
    EXPECT_TRUE(eval_ok("globalThis.__crypto_err === true;").as<bool>());
    // CBC IV 长度非法（15 字节）→ reject（防堆越界读）
    eval_ok("__settle(crypto.aesCbcPkcs7Encrypt('x', '0123456789abcdef', '1234567890abcde'));");
    pump_until("globalThis.__crypto_err === true");
    EXPECT_TRUE(eval_ok("globalThis.__crypto_err === true;").as<bool>());
    // pbkdf2Sync iterations 超上限（1000 万）→ 同步抛（callback 风格会吞异常）
    EXPECT_TRUE(eval_ok(
        "(() => { try { crypto.pbkdf2Sync('p', 's', 10000001, 16); return false; }"
        "catch (e) { return true; } })();").as<bool>());
    // 非法 hex 输入
    EXPECT_TRUE(eval_ok(
        "(() => { try { crypto.createHash('sha256').update('zz', 'hex'); return false; }"
        "catch (e) { return true; } })();").as<bool>());
    // 非二进制对象输入
    EXPECT_TRUE(eval_ok(
        "(() => { try { crypto.createHash('sha256').update({}); return false; }"
        "catch (e) { return true; } })();").as<bool>());
}

// ================= 全局挂载 =================

TEST_F(CryptoFixture, GlobalsMounted)
{
    EXPECT_EQ(eval_ok("typeof crypto;").as<std::string>(), "object");
    EXPECT_EQ(eval_ok("typeof hostCrypto;").as<std::string>(), "object");
    EXPECT_EQ(eval_ok("typeof nodeCryptoCompat;").as<std::string>(), "object");
    EXPECT_TRUE(eval_ok("crypto === hostCrypto && crypto === nodeCryptoCompat;").as<bool>());
}

} // namespace
