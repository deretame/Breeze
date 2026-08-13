// crypto.hpp —— Breeze 风格 crypto API 的 C++ native 层（BoringSSL EVP）
//
// 设计（docs/breeze_api_gap_analysis.md §4.1，用户指示"直接注册 API 即可"）：
//   - 同步版（__crypto_*）：字节进 → 字节出，供 createHash/createHmac 的
//     digest 使用（Node 同步语义）与 randomBytes/timingSafeEqual/pbkdf2Sync；
//   - 异步版（__crypto_*_async）：Promise 方法（kit 签名 Promise<...>）走
//     **项目既有 stdexec 模式**——协程自由函数（KI-001：无捕获、值形参），
//     co_await fetch::pool_scheduler（复用 fetchcore 全局线程池 fetch::file_pool）
//     切后台线程计算，co_await qjs::io_context_scheduler 切回 JS 线程构造
//     Uint8Array；function.hpp 检测 sender 返回类型自动经 promise_from_sender
//     转 Promise（链尾 continues_on(js_sched) 强制结算回 JS 线程）；
//   - 二进制全程直传（std::vector<std::byte> / Uint8Array），不转字符串。
//
// 实现约定（与 kit crypto.d.ts 签名对齐）：
//   - keyRaw / ivRaw / nonceRaw 为字符串参数时按 UTF-8 取字节（JS 侧转换）；
//   - AES key 字节长度决定算法：16 → AES-128、24 → AES-192、32 → AES-256，
//     其它长度抛异常；
//   - ECB/CBC 启用 PKCS7 padding（EVP_CIPHER_CTX_set_padding(1)）；CBC IV
//     长度必须恰为 16 字节（防 EVP 越界读，security-review 修复）；
//   - GCM：输出 = 密文 || 16 字节 tag（加密）；解密从尾部拆 16 字节 tag，
//     认证失败抛异常；nonce 长度任意（EVP_CTRL_GCM_SET_IVLEN，默认 12）；
//   - timingSafeEqual：等长恒时比较（CRYPTO_memcmp），不等长返回 false；
//   - randomBytes / pbkdf2 有合理长度上限防滥用。
#pragma once

#include <openssl/evp.h>
#include <openssl/hmac.h> // HMAC() 单发
#include <openssl/mem.h>
#include <openssl/rand.h>

#include <fetch/pool.hpp>     // fetch::file_pool()（进程级全局线程池）+ pool_scheduler
#include <fetch/scheduler.hpp> // fetch::io_scheduler

#include <qjsbind/binary.hpp> // qjs::Context::js_bytes / new_uint8_array
#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/function.hpp> // Object::set + qjs::func（异常边界自动；sender → Promise）
#include <qjsbind/promise.hpp>  // promise_from_sender（异步绑定骨架）
#include <qjsbind/std_exec.hpp> // std_exec::task（协程）
#include <qjsbind/value.hpp>
#include <qjsbind/web/encoding.hpp> // TextEncoder/TextDecoder（无条件安装，crypto.js 依赖）
#include <qjsbind/web/errors.hpp>   // throw_type_error（hex 解码错误 → JS TypeError）

#include <boost/algorithm/hex.hpp> // boost::algorithm::hex_lower / unhex（hex 编解码；
                                   // BoringSSL 3.6.3 已移除 OPENSSL_buf2hexstr/OPENSSL_hexstr2buf）

#include <qjsbind/polyfill/crypto_embedded.hpp> // 生成物（configure 期生成，不入库）

#include <cstddef>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace qjs {

namespace crypto_detail {

// ---- 小工具 ----

// EVP_CIPHER_CTX RAII
struct CipherCtxDeleter {
    void operator()(EVP_CIPHER_CTX* p) const { EVP_CIPHER_CTX_free(p); }
};
using CipherCtxPtr = std::unique_ptr<EVP_CIPHER_CTX, CipherCtxDeleter>;

inline void throw_evp(const char* op)
{
    throw std::runtime_error(std::string("crypto: ") + op + " 失败");
}

// 摘要算法解析（md5/sha1/sha-1/sha256/sha-256/sha512/sha-512）
inline const EVP_MD* digest_for(std::string_view alg)
{
    if (alg == "md5")
        return EVP_md5();
    if (alg == "sha1" || alg == "sha-1")
        return EVP_sha1();
    if (alg == "sha256" || alg == "sha-256")
        return EVP_sha256();
    if (alg == "sha512" || alg == "sha-512")
        return EVP_sha512();
    throw std::invalid_argument("crypto: 未知摘要算法 " + std::string(alg));
}

// AES 分组密码按 key 长度选择（16/24/32 → 128/192/256）
inline const EVP_CIPHER* aes_cipher_for(std::string_view mode, std::size_t key_len)
{
    const bool ecb = mode == "ecb", cbc = mode == "cbc", gcm = mode == "gcm";
    if (!ecb && !cbc && !gcm)
        throw std::invalid_argument("crypto: 未知 AES 模式 " + std::string(mode));
    switch (key_len) {
    case 16:
        return ecb ? EVP_aes_128_ecb() : (cbc ? EVP_aes_128_cbc() : EVP_aes_128_gcm());
    case 24:
        return ecb ? EVP_aes_192_ecb() : (cbc ? EVP_aes_192_cbc() : EVP_aes_192_gcm());
    case 32:
        return ecb ? EVP_aes_256_ecb() : (cbc ? EVP_aes_256_cbc() : EVP_aes_256_gcm());
    default:
        throw std::invalid_argument("crypto: AES key 长度必须为 16/24/32 字节（当前 " +
                                    std::to_string(key_len) + "）");
    }
}

// ---- 哈希 / HMAC（单发）----

inline std::vector<std::byte> hash_one_shot(const EVP_MD* md, const std::byte* data,
                                            std::size_t len)
{
    std::vector<std::byte> out(EVP_MAX_MD_SIZE);
    unsigned int out_len = 0;
    if (EVP_Digest(data, len, reinterpret_cast<unsigned char*>(out.data()), &out_len, md,
                   nullptr) != 1)
        throw_evp("EVP_Digest");
    out.resize(out_len);
    return out;
}

inline std::vector<std::byte> hmac_one_shot(const EVP_MD* md, const std::byte* key,
                                            std::size_t key_len, const std::byte* data,
                                            std::size_t len)
{
    std::vector<std::byte> out(EVP_MAX_MD_SIZE);
    unsigned int out_len = 0;
    // BoringSSL HMAC 的 key_len/data_len 为 size_t（与 OpenSSL 1.1 的 int 不同）；
    // data 参数是 const uint8_t*（std::byte* 不能隐式转换，需显式 cast）
    if (HMAC(md, key, key_len, reinterpret_cast<const unsigned char*>(data), len,
             reinterpret_cast<unsigned char*>(out.data()), &out_len) == nullptr)
        throw_evp("HMAC");
    out.resize(out_len);
    return out;
}

// ---- AES ECB/CBC（PKCS7 padding）----

inline std::vector<std::byte> evp_block_crypt(bool encrypt, std::string_view mode,
                                              const std::byte* key, std::size_t key_len,
                                              const std::byte* iv, std::size_t iv_len,
                                              const std::byte* in, std::size_t in_len)
{
    // CBC IV 长度必须恰为 16 字节：EVP_CipherInit_ex 无 IV 长度参数，会按
    // cipher->iv_len(16) 从指针 memcpy——短 IV 会导致堆越界读（security-review
    // MEDIUM）。ECB 无 IV（iv 为 nullptr）。
    if (mode == "cbc" && iv_len != 16)
        throw std::invalid_argument("crypto: CBC IV 长度必须为 16 字节（当前 " +
                                    std::to_string(iv_len) + "）");

    CipherCtxPtr ctx(EVP_CIPHER_CTX_new());
    if (!ctx)
        throw_evp("EVP_CIPHER_CTX_new");
    const EVP_CIPHER* cipher = aes_cipher_for(mode, key_len);
    if (EVP_CipherInit_ex(ctx.get(), cipher, nullptr, nullptr, nullptr,
                          encrypt ? 1 : 0) != 1)
        throw_evp("EVP_CipherInit_ex");
    // ECB 无 IV：iv 传 nullptr（EVP 对 ECB 忽略 IV）
    const unsigned char* iv_ptr = iv ? reinterpret_cast<const unsigned char*>(iv) : nullptr;
    if (EVP_CipherInit_ex(ctx.get(), nullptr, nullptr,
                          reinterpret_cast<const unsigned char*>(key), iv_ptr,
                          encrypt ? 1 : 0) != 1)
        throw_evp("EVP_CipherInit_ex(key/iv)");
    EVP_CIPHER_CTX_set_padding(ctx.get(), 1); // PKCS7

    // 输出上界：加密 in_len + 一个分组；解密 in_len（padding 只会减小）
    std::vector<std::byte> out(in_len + 16);
    int out_len = 0, final_len = 0;
    if (EVP_CipherUpdate(ctx.get(), reinterpret_cast<unsigned char*>(out.data()), &out_len,
                         reinterpret_cast<const unsigned char*>(in),
                         static_cast<int>(in_len)) != 1)
        throw_evp("EVP_CipherUpdate");
    if (EVP_CipherFinal_ex(ctx.get(),
                           reinterpret_cast<unsigned char*>(out.data()) + out_len,
                           &final_len) != 1)
        throw_evp(encrypt ? "EVP_CipherFinal_ex(encrypt)" : "EVP_CipherFinal_ex(解密失败：padding 或密钥错误)");
    out.resize(static_cast<std::size_t>(out_len) + static_cast<std::size_t>(final_len));
    return out;
}

// ---- AES-GCM（输出 = 密文 || tag16；解密从尾部拆 tag）----

inline std::vector<std::byte> gcm_encrypt(std::string_view /*mode*/, const std::byte* key,
                                          std::size_t key_len, const std::byte* nonce,
                                          std::size_t nonce_len, const std::byte* aad,
                                          std::size_t aad_len, const std::byte* in,
                                          std::size_t in_len)
{
    CipherCtxPtr ctx(EVP_CIPHER_CTX_new());
    if (!ctx)
        throw_evp("EVP_CIPHER_CTX_new");
    const EVP_CIPHER* cipher = aes_cipher_for("gcm", key_len);
    if (EVP_EncryptInit_ex(ctx.get(), cipher, nullptr, nullptr, nullptr) != 1)
        throw_evp("EVP_EncryptInit_ex");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_IVLEN,
                            static_cast<int>(nonce_len), nullptr) != 1)
        throw_evp("EVP_CTRL_GCM_SET_IVLEN");
    if (EVP_EncryptInit_ex(ctx.get(), nullptr, nullptr,
                           reinterpret_cast<const unsigned char*>(key),
                           reinterpret_cast<const unsigned char*>(nonce)) != 1)
        throw_evp("EVP_EncryptInit_ex(key/nonce)");
    if (aad && aad_len > 0) {
        int n = 0;
        if (EVP_EncryptUpdate(ctx.get(), nullptr, &n,
                              reinterpret_cast<const unsigned char*>(aad),
                              static_cast<int>(aad_len)) != 1)
            throw_evp("EVP_EncryptUpdate(aad)");
    }
    std::vector<std::byte> out(in_len + 16); // 密文 + tag
    int out_len = 0, final_len = 0;
    if (EVP_EncryptUpdate(ctx.get(), reinterpret_cast<unsigned char*>(out.data()), &out_len,
                          reinterpret_cast<const unsigned char*>(in),
                          static_cast<int>(in_len)) != 1)
        throw_evp("EVP_EncryptUpdate");
    if (EVP_EncryptFinal_ex(ctx.get(),
                            reinterpret_cast<unsigned char*>(out.data()) + out_len,
                            &final_len) != 1)
        throw_evp("EVP_EncryptFinal_ex");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_GET_TAG, 16,
                            reinterpret_cast<unsigned char*>(out.data()) + out_len) != 1)
        throw_evp("EVP_CTRL_GCM_GET_TAG");
    out.resize(static_cast<std::size_t>(out_len) + static_cast<std::size_t>(final_len) + 16);
    return out;
}

inline std::vector<std::byte> gcm_decrypt(std::string_view /*mode*/, const std::byte* key,
                                          std::size_t key_len, const std::byte* nonce,
                                          std::size_t nonce_len, const std::byte* aad,
                                          std::size_t aad_len, const std::byte* in,
                                          std::size_t in_len)
{
    if (in_len < 16)
        throw std::runtime_error("crypto: GCM 密文长度不足（缺少 16 字节 tag）");
    const std::size_t ct_len = in_len - 16;
    const std::byte* tag = in + ct_len;

    CipherCtxPtr ctx(EVP_CIPHER_CTX_new());
    if (!ctx)
        throw_evp("EVP_CIPHER_CTX_new");
    const EVP_CIPHER* cipher = aes_cipher_for("gcm", key_len);
    if (EVP_DecryptInit_ex(ctx.get(), cipher, nullptr, nullptr, nullptr) != 1)
        throw_evp("EVP_DecryptInit_ex");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_IVLEN,
                            static_cast<int>(nonce_len), nullptr) != 1)
        throw_evp("EVP_CTRL_GCM_SET_IVLEN");
    if (EVP_DecryptInit_ex(ctx.get(), nullptr, nullptr,
                           reinterpret_cast<const unsigned char*>(key),
                           reinterpret_cast<const unsigned char*>(nonce)) != 1)
        throw_evp("EVP_DecryptInit_ex(key/nonce)");
    if (aad && aad_len > 0) {
        int n = 0;
        if (EVP_DecryptUpdate(ctx.get(), nullptr, &n,
                              reinterpret_cast<const unsigned char*>(aad),
                              static_cast<int>(aad_len)) != 1)
            throw_evp("EVP_DecryptUpdate(aad)");
    }
    std::vector<std::byte> out(ct_len);
    int out_len = 0, final_len = 0;
    if (EVP_DecryptUpdate(ctx.get(), reinterpret_cast<unsigned char*>(out.data()), &out_len,
                          reinterpret_cast<const unsigned char*>(in),
                          static_cast<int>(ct_len)) != 1)
        throw_evp("EVP_DecryptUpdate");
    if (EVP_CIPHER_CTX_ctrl(ctx.get(), EVP_CTRL_GCM_SET_TAG, 16,
                            const_cast<unsigned char*>(
                                reinterpret_cast<const unsigned char*>(tag))) != 1)
        throw_evp("EVP_CTRL_GCM_SET_TAG");
    if (EVP_DecryptFinal_ex(ctx.get(),
                            reinterpret_cast<unsigned char*>(out.data()) + out_len,
                            &final_len) != 1)
        throw std::runtime_error("crypto: GCM 认证失败（tag 不匹配或密文被篡改）");
    out.resize(static_cast<std::size_t>(out_len) + static_cast<std::size_t>(final_len));
    return out;
}

// ---- 随机数 / PBKDF2 / 恒时比较 ----

inline std::vector<std::byte> random_bytes(std::size_t n)
{
    constexpr std::size_t kMax = 256 * 1024 * 1024; // 防滥用
    if (n > kMax)
        throw std::invalid_argument("crypto: randomBytes 长度超上限（256MB）");
    std::vector<std::byte> out(n);
    if (n > 0 && RAND_bytes(reinterpret_cast<unsigned char*>(out.data()),
                            static_cast<int>(n)) != 1)
        throw_evp("RAND_bytes");
    return out;
}

inline std::vector<std::byte> pbkdf2(const EVP_MD* md, const std::byte* password,
                                     std::size_t password_len, const std::byte* salt,
                                     std::size_t salt_len, int iterations, int key_len)
{
    constexpr int kMaxIterations = 10'000'000; // 防滥用：超大迭代数会长时间阻塞
    constexpr std::size_t kMaxSalt = 1024 * 1024;
    if (iterations <= 0 || iterations > kMaxIterations)
        throw std::invalid_argument("crypto: pbkdf2 iterations 超出范围 (1.." +
                                    std::to_string(kMaxIterations) + ")");
    if (key_len <= 0 || key_len > 1024 * 1024)
        throw std::invalid_argument("crypto: pbkdf2 keyLen 超出范围");
    if (salt_len > kMaxSalt)
        throw std::invalid_argument("crypto: pbkdf2 salt 长度超上限（1MB）");
    std::vector<std::byte> out(static_cast<std::size_t>(key_len));
    if (PKCS5_PBKDF2_HMAC(reinterpret_cast<const char*>(password), password_len,
                          reinterpret_cast<const unsigned char*>(salt), salt_len, iterations,
                          md, key_len, reinterpret_cast<unsigned char*>(out.data())) != 1)
        throw_evp("PKCS5_PBKDF2_HMAC");
    return out;
}

inline bool timing_safe_equal(const std::byte* a, std::size_t a_len, const std::byte* b,
                              std::size_t b_len)
{
    // 不等长直接 false（无信息泄露；长度本身不是机密）
    if (a_len != b_len)
        return false;
    return CRYPTO_memcmp(a, b, a_len) == 0;
}

} // namespace crypto_detail

// ================= 异步层（项目既有 stdexec 模式） =================
// 协程自由函数（KI-001：协程禁止 lambda 捕获，值走形参；Value 拷贝 = dup，
// 进协程帧安全）。首段在 JS 线程同步执行（参数提取 + scheduler 构造），
// co_await pool_scheduler（fetch::file_pool 全局线程池）切后台线程计算，
// co_await io_scheduler 切回 JS 线程构造 Uint8Array 后 co_return。
// function.hpp 检测 sender 返回类型 → promise_from_sender 自动转 Promise，
// 链尾 continues_on(js_sched) 强制结算回 JS 线程（promise.hpp §5.3）。
namespace crypto_async {

// 后台计算 scheduler（复用 fetchcore 全局线程池，不另起线程池）
inline fetch::pool_scheduler pool_sched()
{
    return fetch::pool_scheduler{fetch::file_pool().get_executor()};
}

// 协程体内线程切换样板：先 JS 线程构造 js_sched（进帧），再切后台计算、
// 切回 JS 线程收尾。计算段抛异常 → task set_error → promise reject（JS 线程）。

inline std_exec::task<qjs::Value> hash_async(Ctx cx, Value alg_v, Value data_v)
{
    qjs::Context c(cx.ctx);
    const std::string alg = c.from_js<std::string>(alg_v.raw());
    const std::vector<std::byte> data = c.js_bytes(data_v.raw());
    const qjs::io_context_scheduler js_sched{qjs::current_io()}; // JS 线程
    co_await pool_sched().schedule(); // → 后台线程：计算
    const auto out = crypto_detail::hash_one_shot(crypto_detail::digest_for(alg),
                                                  data.data(), data.size());
    co_await js_sched.schedule(); // → 切回 JS 线程：构造结果
    co_return c.new_uint8_array(out.data(), out.size());
}

inline std_exec::task<qjs::Value> hmac_async(Ctx cx, Value alg_v, Value key_v, Value data_v)
{
    qjs::Context c(cx.ctx);
    const std::string alg = c.from_js<std::string>(alg_v.raw());
    const std::vector<std::byte> key = c.js_bytes(key_v.raw());
    const std::vector<std::byte> data = c.js_bytes(data_v.raw());
    const qjs::io_context_scheduler js_sched{qjs::current_io()};
    co_await pool_sched().schedule();
    const auto out = crypto_detail::hmac_one_shot(crypto_detail::digest_for(alg),
                                                  key.data(), key.size(), data.data(),
                                                  data.size());
    co_await js_sched.schedule();
    co_return c.new_uint8_array(out.data(), out.size());
}

inline std_exec::task<qjs::Value> block_crypt_async(Ctx cx, bool encrypt,
                                                    std::string_view mode, Value data_v,
                                                    Value key_v, Value iv_v, bool has_iv)
{
    qjs::Context c(cx.ctx);
    const std::vector<std::byte> data = c.js_bytes(data_v.raw());
    const std::vector<std::byte> key = c.js_bytes(key_v.raw());
    const std::vector<std::byte> iv =
        has_iv ? c.js_bytes(iv_v.raw()) : std::vector<std::byte>{};
    const qjs::io_context_scheduler js_sched{qjs::current_io()};
    co_await pool_sched().schedule();
    const auto out = crypto_detail::evp_block_crypt(
        encrypt, mode, key.data(), key.size(), has_iv ? iv.data() : nullptr, iv.size(),
        data.data(), data.size());
    co_await js_sched.schedule();
    co_return c.new_uint8_array(out.data(), out.size());
}

inline std_exec::task<qjs::Value> gcm_async(Ctx cx, bool encrypt, Value data_v, Value key_v,
                                            Value nonce_v, Value aad_v)
{
    qjs::Context c(cx.ctx);
    const std::vector<std::byte> data = c.js_bytes(data_v.raw());
    const std::vector<std::byte> key = c.js_bytes(key_v.raw());
    const std::vector<std::byte> nonce = c.js_bytes(nonce_v.raw());
    const std::vector<std::byte> aad =
        aad_v.is_null() ? std::vector<std::byte>{} : c.js_bytes(aad_v.raw());
    const qjs::io_context_scheduler js_sched{qjs::current_io()};
    co_await pool_sched().schedule();
    const auto out = encrypt
                         ? crypto_detail::gcm_encrypt("gcm", key.data(), key.size(),
                                                      nonce.data(), nonce.size(),
                                                      aad.data(), aad.size(), data.data(),
                                                      data.size())
                         : crypto_detail::gcm_decrypt("gcm", key.data(), key.size(),
                                                      nonce.data(), nonce.size(),
                                                      aad.data(), aad.size(), data.data(),
                                                      data.size());
    co_await js_sched.schedule();
    co_return c.new_uint8_array(out.data(), out.size());
}

inline std_exec::task<qjs::Value> pbkdf2_async(Ctx cx, Value alg_v, Value pass_v,
                                               Value salt_v, Value iter_v, Value key_len_v)
{
    qjs::Context c(cx.ctx);
    const std::string alg = c.from_js<std::string>(alg_v.raw());
    const std::vector<std::byte> password = c.js_bytes(pass_v.raw());
    const std::vector<std::byte> salt = c.js_bytes(salt_v.raw());
    const int iterations = c.from_js<int>(iter_v.raw());
    const int key_len = c.from_js<int>(key_len_v.raw());
    const qjs::io_context_scheduler js_sched{qjs::current_io()};
    co_await pool_sched().schedule();
    const auto out = crypto_detail::pbkdf2(crypto_detail::digest_for(alg),
                                           password.data(), password.size(), salt.data(),
                                           salt.size(), iterations, key_len);
    co_await js_sched.schedule();
    co_return c.new_uint8_array(out.data(), out.size());
}

} // namespace crypto_async

// ================= 接入入口 =================
// 注册 11 个同步 __crypto_* + 9 个异步 __crypto_*_async（sender 返回 → 自动
// Promise），eval crypto.js（polyfill：crypto/hostCrypto/nodeCryptoCompat）。
// 幂等：重复 install 覆盖注册 + 重新 eval。
inline void install_crypto(qjs::Context& ctx)
{
    // TextEncoder/TextDecoder 无条件安装（幂等：class_ 走 registry.ensure；
    // enable_fetch_ 的 install_web_apis 重复安装无害）——crypto.js 的 utf8
    // 编解码只调原生，不设 JS 回退。
    qjsbind::web::install_text_encoder(ctx);
    qjsbind::web::install_text_decoder(ctx);

    Object global = ctx.globals();

    // ---- 同步版（createHash/createHmac 的 digest 与 random/timingSafeEqual）----

    // __crypto_hash(alg, bytes) → Uint8Array
    global.set("__crypto_hash", [](Ctx cx, Value alg_v, Value data_v) -> Value {
        qjs::Context c(cx.ctx);
        const std::string alg = c.from_js<std::string>(alg_v.raw());
        const std::vector<std::byte> data = c.js_bytes(data_v.raw());
        const std::vector<std::byte> out =
            crypto_detail::hash_one_shot(crypto_detail::digest_for(alg), data.data(),
                                         data.size());
        return c.new_uint8_array(out.data(), out.size());
    });

    // __crypto_hmac(alg, key, data) → Uint8Array
    global.set("__crypto_hmac", [](Ctx cx, Value alg_v, Value key_v, Value data_v) -> Value {
        qjs::Context c(cx.ctx);
        const std::string alg = c.from_js<std::string>(alg_v.raw());
        const std::vector<std::byte> key = c.js_bytes(key_v.raw());
        const std::vector<std::byte> data = c.js_bytes(data_v.raw());
        const std::vector<std::byte> out = crypto_detail::hmac_one_shot(
            crypto_detail::digest_for(alg), key.data(), key.size(), data.data(), data.size());
        return c.new_uint8_array(out.data(), out.size());
    });

    // AES ECB/CBC（PKCS7）：__crypto_aes_{ecb,cbc}_{encrypt,decrypt}(bytes, key[, iv])
    // 注意：lambda 参数个数 = 必填参数个数（ECB 2 参 / CBC 3 参，arity 自动检查）
    auto register_block_crypt = [&](const char* name, bool encrypt, std::string_view mode,
                                    bool has_iv) {
        if (has_iv) {
            global.set(name, [encrypt, mode](Ctx cx, Value data_v, Value key_v,
                                             Value iv_v) -> Value {
                qjs::Context c(cx.ctx);
                const std::vector<std::byte> data = c.js_bytes(data_v.raw());
                const std::vector<std::byte> key = c.js_bytes(key_v.raw());
                const std::vector<std::byte> iv = c.js_bytes(iv_v.raw());
                const std::vector<std::byte> out = crypto_detail::evp_block_crypt(
                    encrypt, mode, key.data(), key.size(), iv.data(), iv.size(),
                    data.data(), data.size());
                return c.new_uint8_array(out.data(), out.size());
            });
        } else {
            global.set(name, [encrypt, mode](Ctx cx, Value data_v, Value key_v) -> Value {
                qjs::Context c(cx.ctx);
                const std::vector<std::byte> data = c.js_bytes(data_v.raw());
                const std::vector<std::byte> key = c.js_bytes(key_v.raw());
                const std::vector<std::byte> out = crypto_detail::evp_block_crypt(
                    encrypt, mode, key.data(), key.size(), nullptr, 0, data.data(),
                    data.size());
                return c.new_uint8_array(out.data(), out.size());
            });
        }
    };
    register_block_crypt("__crypto_aes_ecb_encrypt", true, "ecb", false);
    register_block_crypt("__crypto_aes_ecb_decrypt", false, "ecb", false);
    register_block_crypt("__crypto_aes_cbc_encrypt", true, "cbc", true);
    register_block_crypt("__crypto_aes_cbc_decrypt", false, "cbc", true);

    // GCM：__crypto_aes_gcm_{encrypt,decrypt}(bytes, key, nonce, aad|null)
    auto register_gcm = [&](const char* name, bool encrypt) {
        global.set(name, [encrypt](Ctx cx, Value data_v, Value key_v, Value nonce_v,
                                   Value aad_v) -> Value {
            qjs::Context c(cx.ctx);
            const std::vector<std::byte> data = c.js_bytes(data_v.raw());
            const std::vector<std::byte> key = c.js_bytes(key_v.raw());
            const std::vector<std::byte> nonce = c.js_bytes(nonce_v.raw());
            const std::vector<std::byte> aad =
                aad_v.is_null() ? std::vector<std::byte>{} : c.js_bytes(aad_v.raw());
            const std::vector<std::byte> out =
                encrypt ? crypto_detail::gcm_encrypt("gcm", key.data(), key.size(),
                                                     nonce.data(), nonce.size(),
                                                     aad.data(), aad.size(), data.data(),
                                                     data.size())
                        : crypto_detail::gcm_decrypt("gcm", key.data(), key.size(),
                                                     nonce.data(), nonce.size(),
                                                     aad.data(), aad.size(), data.data(),
                                                     data.size());
            return c.new_uint8_array(out.data(), out.size());
        });
    };
    register_gcm("__crypto_aes_gcm_encrypt", true);
    register_gcm("__crypto_aes_gcm_decrypt", false);

    // __crypto_random_bytes(n) → Uint8Array
    global.set("__crypto_random_bytes", [](Ctx cx, Value n_v) -> Value {
        qjs::Context c(cx.ctx);
        const std::size_t n = c.from_js<std::size_t>(n_v.raw());
        const std::vector<std::byte> out = crypto_detail::random_bytes(n);
        return c.new_uint8_array(out.data(), out.size());
    });

    // __crypto_pbkdf2(alg, password, salt, iterations, key_len) → Uint8Array
    global.set("__crypto_pbkdf2", [](Ctx cx, Value alg_v, Value pass_v, Value salt_v,
                                     Value iter_v, Value key_len_v) -> Value {
        qjs::Context c(cx.ctx);
        const std::string alg = c.from_js<std::string>(alg_v.raw());
        const std::vector<std::byte> password = c.js_bytes(pass_v.raw());
        const std::vector<std::byte> salt = c.js_bytes(salt_v.raw());
        const int iterations = c.from_js<int>(iter_v.raw());
        const int key_len = c.from_js<int>(key_len_v.raw());
        const std::vector<std::byte> out = crypto_detail::pbkdf2(
            crypto_detail::digest_for(alg), password.data(), password.size(), salt.data(),
            salt.size(), iterations, key_len);
        return c.new_uint8_array(out.data(), out.size());
    });

    // __crypto_timing_safe_equal(a, b) → bool（等长恒时比较；不等长 false）
    global.set("__crypto_timing_safe_equal", [](Ctx cx, Value a_v, Value b_v) -> bool {
        qjs::Context c(cx.ctx);
        const std::vector<std::byte> a = c.js_bytes(a_v.raw());
        const std::vector<std::byte> b = c.js_bytes(b_v.raw());
        return crypto_detail::timing_safe_equal(a.data(), a.size(), b.data(), b.size());
    });

    // __crypto_hex_encode(bytes) → 小写 hex 字符串
    // boost::algorithm::hex_lower（查表 + 单次分配；encode_one 用 & 0x0F 掩码，
    // 对任意字节含 NUL / ≥0x80 安全）。BoringSSL 3.6.3 已移除
    // OPENSSL_buf2hexstr（无 hex 编码 API），故走 Boost.Algorithm。
    global.set("__crypto_hex_encode", [](Ctx cx, Value data_v) -> std::string {
        qjs::Context c(cx.ctx);
        const std::vector<std::byte> data = c.js_bytes(data_v.raw());
        if (data.empty())
            return {}; // 空输入：std::string(nullptr, 0) 是 UB
        return boost::algorithm::hex_lower(
            std::string(reinterpret_cast<const char*>(data.data()), data.size()));
    });

    // __crypto_hex_decode(str) → Uint8Array
    // boost::algorithm::unhex（接受大小写；非法字符 → non_hex_input）。
    // 先做奇偶检查：与旧 JS hexDecode 一致——奇数长度优先报"长度必须为偶数"
    //（即使同时含非法字符，JS 也是先查 length）。然后 unhex，字符非法 → TypeError。
    // 注：非 ASCII 输入按 UTF-8 字节数计奇偶，与 JS 的 UTF-16 单元数在极端情况
    // 下报错类别可能有差异（但均属非法 hex 输入，正常调用不会传）。
    global.set("__crypto_hex_decode", [](Ctx cx, Value str_v) -> Value {
        qjs::Context c(cx.ctx);
        const std::string str = c.from_js<std::string>(str_v.raw());
        if (str.size() % 2 != 0)
            qjsbind::web::throw_type_error(cx.ctx, "crypto: hex 字符串长度必须为偶数");
        try {
            const std::string bytes = boost::algorithm::unhex(str);
            return c.new_uint8_array(reinterpret_cast<const std::byte*>(bytes.data()),
                                     bytes.size());
        } catch (const boost::algorithm::non_hex_input&) {
            qjsbind::web::throw_type_error(cx.ctx, "crypto: 非法 hex 字符");
        } catch (const boost::algorithm::not_enough_input&) {
            // 防御：前置奇偶检查后不应触发；万一触发仍按长度错误报
            qjsbind::web::throw_type_error(cx.ctx, "crypto: hex 字符串长度必须为偶数");
        }
    });

    // ---- 异步版（stdexec 模式：协程自由函数 + promise_from_sender 自动转
    // Promise；后台线程池 fetch::file_pool；二进制直传不转字符串）----
    // 注册 lambda 非协程、无捕获：直接返回协程 task（sender），function.hpp
    // 检测返回类型自动 Promise 化。
    global.set("__crypto_hash_async",
               [](Ctx cx, Value alg_v, Value data_v) -> std_exec::task<qjs::Value> {
                   return crypto_async::hash_async(cx, alg_v, data_v);
               });
    global.set("__crypto_hmac_async",
               [](Ctx cx, Value alg_v, Value key_v, Value data_v)
                   -> std_exec::task<qjs::Value> {
                   return crypto_async::hmac_async(cx, alg_v, key_v, data_v);
               });
    auto register_block_crypt_async = [&](const char* name, bool encrypt,
                                          std::string_view mode, bool has_iv) {
        // lambda 参数个数 = 必填参数个数（ECB 2 参 / CBC 3 参）
        if (has_iv) {
            global.set(name, [encrypt, mode](Ctx cx, Value data_v, Value key_v,
                                             Value iv_v) -> std_exec::task<qjs::Value> {
                return crypto_async::block_crypt_async(cx, encrypt, mode, data_v, key_v,
                                                       iv_v, true);
            });
        } else {
            global.set(name, [encrypt, mode](Ctx cx, Value data_v,
                                             Value key_v) -> std_exec::task<qjs::Value> {
                return crypto_async::block_crypt_async(cx, encrypt, mode, data_v, key_v,
                                                       Value{}, false);
            });
        }
    };
    register_block_crypt_async("__crypto_aes_ecb_encrypt_async", true, "ecb", false);
    register_block_crypt_async("__crypto_aes_ecb_decrypt_async", false, "ecb", false);
    register_block_crypt_async("__crypto_aes_cbc_encrypt_async", true, "cbc", true);
    register_block_crypt_async("__crypto_aes_cbc_decrypt_async", false, "cbc", true);
    auto register_gcm_async = [&](const char* name, bool encrypt) {
        global.set(name, [encrypt](Ctx cx, Value data_v, Value key_v, Value nonce_v,
                                   Value aad_v) -> std_exec::task<qjs::Value> {
            return crypto_async::gcm_async(cx, encrypt, data_v, key_v, nonce_v, aad_v);
        });
    };
    register_gcm_async("__crypto_aes_gcm_encrypt_async", true);
    register_gcm_async("__crypto_aes_gcm_decrypt_async", false);
    global.set("__crypto_pbkdf2_async",
               [](Ctx cx, Value alg_v, Value pass_v, Value salt_v, Value iter_v,
                  Value key_len_v) -> std_exec::task<qjs::Value> {
                   return crypto_async::pbkdf2_async(cx, alg_v, pass_v, salt_v, iter_v,
                                                     key_len_v);
               });

    // JS polyfill：crypto / hostCrypto / nodeCryptoCompat 对象
    Value v = ctx.eval(polyfill::crypto_js, "<crypto>");
    if (v.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));
}

} // namespace qjs
