# Beast/Asio 的 SSL 后端自定义：以 BoringSSL 为例

本文回答两个问题：

1. **不换库**：如何在现有代码上自定义 TLS 行为（版本、cipher、ALPN、SNI、证书校验等）。
2. **换库**：如何把 beast/asio 底层使用的 SSL 实现从 OpenSSL 换成 BoringSSL（同样适用于 LibreSSL、AWS-LC 等 API 兼容实现）。

文中的兼容性结论已针对本仓库实际验证（boost 1.91 + BoringSSL master，`BORINGSSL_API_VERSION 42`；核查方法见附录，BoringSSL 源码已 clone 在 `third_party/boringssl/`）。

## 1. 架构事实：SSL 库是编译期选择，不是运行期选择

`boost::asio::ssl` 只是 OpenSSL API 的 C++ 薄封装：

- `ssl::context` ↔ `SSL_CTX*`（`ctx.native_handle()` 直接暴露）
- `ssl::stream<tcp::socket>` ↔ `SSL*`，内部 `detail::engine` 用 BIO pair 把 TLS 字节流桥接到下层 socket
- beast 本身**完全不接触** SSL API——它只要求 stream 满足 `AsyncReadStream`/`AsyncWriteStream` 概念

因此"用什么 SSL 库"在编译期由两件事决定：**include 路径指向谁的头文件、链接谁的 `ssl`/`crypto` 库**。任何 OpenSSL API 兼容实现都可以无缝替换，C++ 业务代码一行不用改。boost 的 asio/beast 是 header-only，不编译进 OpenSSL 符号，换库**不需要重新编译 boost**。

本项目直接使用 OpenSSL C API 的触点（换库时这些符号必须存在）：

| 位置 | 用到的 API |
|---|---|
| `src/fetch/beast_transport.cpp` `make_ssl_context` / `load_pem_into_store` / `shared_ca_store` | `BIO_new_mem_buf`、`PEM_read_bio_X509`、`X509_STORE_add_cert`、`X509_free`、`X509_STORE_up_ref`、`SSL_CTX_get_cert_store`、`SSL_CTX_set_cert_store`、`ERR_peek_last_error`、`ERR_GET_LIB`、`ERR_GET_REASON`、`ERR_clear_error` |
| `include/fetch/types.hpp` `sha_digest`（SRI） | `EVP_sha256/384/512`、`EVP_Digest`、`EVP_MAX_MD_SIZE` |
| `src/fetch/beast_transport.cpp` `TlsSessionCacheImpl`（M5 session 复用缓存，仅池化路径） | `SSL_CTX_set_session_cache_mode`、`SSL_CTX_sess_set_new_cb`、`SSL_get_ex_new_index`、`SSL_set/get_ex_data`、`SSL_set_session`、`SSL_get1_session`、`SSL_session_reused`、`SSL_SESSION_up_ref/free`、`SSL_SESSION_is_resumable`、`SSL_SESSION_get_timeout`、`SSL_SESSION_should_be_single_use` |
| `ssl::host_name_verification`（asio 内部） | X509 subjectAltName 解析（`GENERAL_NAME_*`、`ASN1_*`、`sk_*`） |

## 2. 不换库：运行期自定义 TLS 行为

通过 `native_handle()` 拿到原生句柄后，整个 OpenSSL/BoringSSL C API 都可用。常见自定义点：

```cpp
// ---- context 级（make_ssl_context 内，beast_transport.cpp:133）----
SSL_CTX* h = c.native_handle();
SSL_CTX_set_min_proto_version(h, TLS1_2_VERSION);
SSL_CTX_set_max_proto_version(h, TLS1_3_VERSION);
SSL_CTX_set_cipher_list(h, "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:..."); // TLS1.2 及以下
// keylog（配合 SSLKEYLOGFILE 用 Wireshark 解 TLS 流量）：
SSL_CTX_set_keylog_callback(h, [](const SSL*, const char* line) { /* 追加写文件 */ });

// ---- 连接级（request() 内 handshake 之前，beast_transport.cpp:350 附近）----
SSL* sh = stream->native_handle();
SSL_set_tlsext_host_name(sh, url.host.c_str());  // SNI
```

**注意：SNI 已在本仓库落地**（`beast_transport.cpp` `request()` / `request_via_socks5()`，`async_handshake` 之前调用 `SSL_set_tlsext_host_name`；IP 字面量按 RFC 6066 跳过）。asio 的 `ssl::stream` 不会自动从 Host 头发送 SNI——直连按 SNI 分证书的虚拟主机站点（如大部分 CDN）时必须有上面最后一行。这是运行期自定义最常见也最容易被忽略的一项。

证书校验已经是自定义的：`stream->set_verify_callback(ssl::host_name_verification(url.host))`（beast_transport.cpp:351）。CA 信任源也是自定义的（嵌入 Mozilla bundle + `extra_trust_pem`，见 `make_ssl_context`）。

## 3. 换库：以 BoringSSL 为例

### 3.1 兼容性核查结论：asio 1.91 + BoringSSL 可直接编译，无需 patch

BoringSSL 在 `include/openssl/base.h` 中自报 `OPENSSL_VERSION_NUMBER 0x1010107f`（OpenSSL 1.1.1g 等价），第三方代码的所有版本分支因此走 OpenSSL 1.1.1 路径。对本仓库用到的接口面逐一核对 BoringSSL 头文件后的结果：

- **asio ssl 引用的 110 个函数符号：106 个直接存在**。缺的 4 个（`EVP_PKEY_is_a`、`PEM_read_bio_Parameters`、`SSL_CTX_set0_tmp_dh_pkey`、`ERR_SYSTEM_ERROR`）全部位于 asio `context.ipp` 的 `#if OPENSSL_VERSION_NUMBER >= 0x30000000L` 分支内（OpenSSL 3.0 专用），BoringSSL 编译时走 legacy 分支；legacy 分支需要的 `d2i_RSAPrivateKey_bio`、`PEM_read_bio_DHparams`、`SSL_CTX_set_tmp_dh` 在 BoringSSL 中都存在。
- **20 个宏常量全部存在**（`SSL_OP_*`、`SSL_MODE_*`、`SSL_VERIFY_*`、`SSL_ERROR_*`、`X509_V_*`、`GEN_*`、`NID_*`、`SSL_FILETYPE_*` 等）。
- asio 里 OpenSSL 1.0 时代的初始化/清理调用（`SSL_library_init`、`ERR_load_error_strings`、`CRYPTO_set_locking_callback`、`EVP_cleanup`、`CRYPTO_cleanup_all_ex_data` 等）BoringSSL 全部保留 no-op 兼容桩。
- 本项目自己用到的 API（第 1 节表格）在 BoringSSL 中全部存在（`ERR_GET_LIB`/`ERR_GET_REASON` 是 `OPENSSL_INLINE` 函数而非宏，行为相同）。

### 3.2 接入方式 A：vcpkg boringssl port（推荐，改动最小）

本仓库的 vcpkg（`third_party/vcpkg`）registry 自带 `boringssl` port（version-date 2025-08-18，REF `0.20250818.0`），且是 drop-in 设计：

- 安装时检查 `include/openssl/ssl.h`，与 `openssl` port 互斥（二选一）；
- debug 库自动加 `d` 后缀，专门配合 CMake 的 `FindOpenSSL` 模块；
- port 的 usage 明确写明用法就是 `find_package(OpenSSL REQUIRED)` + `OpenSSL::SSL` / `OpenSSL::Crypto`——与本项目 `CMakeLists.txt:20` 和 `CMakeLists.txt:47-48` 完全一致；
- portfile 自动获取 Perl/NASM/Go，不需要手工准备构建工具。

改动只有一行——`vcpkg.json`：

```jsonc
-    "openssl",
+    "boringssl",
```

`CMakeLists.txt` 不动，重新 configure 即可。当前依赖集（boost-*、quickjs-ng、zlib、brotli、spdlog 等）均不传递依赖 `openssl` port，替换不会产生冲突。

**实操注意（本仓库已按此流程完成换库并全量验证）**：

- 换库后必须**清理旧 build 目录的 CMake 缓存**再 configure。openssl → boringssl 切换后，`build/CMakeCache.txt` 中残留的 `OPENSSL_INCLUDE_DIR` 等 FindOpenSSL module 缓存变量会让重新 configure 找不到 `OpenSSL::SSL` target（报 “but the target was not found”，全新 build 目录则正常）。删除 `build/CMakeCache.txt` 与 `build/CMakeFiles/` 后重新 configure 即可。
- 换库后旧 openssl 的 `libssl-3-x64.dll` / `libcrypto-3-x64.dll` 不再被引用，可从 `build/` 删除避免混淆（链接的 DLL 变为 boringssl 的 `ssl.dll` / `crypto.dll`，debug 为 `ssld.dll` / `cryptod.dll`，与 port 的 `d` 后缀约定一致）。

### 3.3 接入方式 B：手动构建 BoringSSL + CMake 变量注入

适合需要跟踪 BoringSSL master 或定制构建选项的场景：

```bash
# 需要：CMake 3.22+、Go、Ninja；Windows 另需 NASM + VS2022 + Win10 SDK 2104+
cd third_party/boringssl
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build   # 产出 build/ssl/libssl.a 与 build/crypto/libcrypto.a（Windows: ssl.lib/crypto.lib）
```

然后 configure 本项目时注入（三选一）：

```bash
# 1) FindOpenSSL 变量注入（CMakeLists 不动）
cmake -DOPENSSL_INCLUDE_DIR=$PWD/third_party/boringssl/include \
      -DOPENSSL_SSL_LIBRARY=$PWD/third_party/boringssl/build/ssl/ssl.lib \
      -DOPENSSL_CRYPTO_LIBRARY=$PWD/third_party/boringssl/build/crypto/crypto.lib ...

# 2) 或在 CMakeLists.txt 里自建 imported target，替换 fetchcore 链接的
#    OpenSSL::SSL / OpenSSL::Crypto（CMakeLists.txt:47-48）
```

注意点：

- **CRT/运行时库必须一致**。vcpkg x64-windows 是动态 CRT（/MD）；BoringSSL 默认静态产出但同样用 /MD 编译即可混用。不要用 /MT 构建 BoringSSL 再链进 /MD 的工程。
- **同一进程只能链接一份 OpenSSL API 实现**。手动方式下若 vcpkg 仍装着 openssl port 并被其他库链入，会出现符号重复/行为错乱——应同时把 `vcpkg.json` 里的 `openssl` 移除。

### 3.4 注意事项与差异

- **BoringSSL 没有 API/ABI 稳定承诺**（官方明确不建议第三方使用，无 release 分支）。必须 pin 住 commit/tag；升级时按附录方法重新核查，并关注 `BORINGSSL_API_VERSION`（当前 42）的变化。
- `OPENSSL_VERSION_NUMBER` 恒为 `0x1010107f`：所有按版本分支的第三方代码都把 BoringSSL 当 OpenSSL 1.1.1 看待。对 asio 这是好事（规避 3.0 专用 API），但若将来某个依赖用 3.0 API 且无 fallback，就会编译失败。
- 行为差异：无 ENGINE；无 SSLv3；cipher 套件默认集不同；X.509 校验逻辑与 OpenSSL 有差异（对某些不合规证书更严格）；TLS 1.3 默认启用；错误队列/错误码语义略有差异。`tls.verify` 路径的 wpt/fetch 测试能覆盖到这些差异。
- 换库后必须验证：`scripts/test.py`（或 ctest）跑 `fetch_test`、`fetchcore_test`、`socks5_test`、`wpt_runner`；必要时在 `make_ssl_context` 临时打印 `SSL_get_version` 确认握手版本。

## 附录：兼容性核查方法（换 LibreSSL/AWS-LC 时复用）

```bash
# 1) 提取 asio ssl 引用的全部 OpenSSL 函数符号（在 boost 安装目录下）
cd build/vcpkg_installed/x64-windows/include/boost/asio/ssl
grep -rhoE '\b(SSL_CTX_[A-Za-z_0-9]+|SSL_[A-Za-z_0-9]+|X509[A-Z_0-9]*|BIO_[A-Za-z_0-9]+|ERR_[A-Za-z_0-9]+|PEM_[A-Za-z_0-9]+|EVP_[A-Za-z_0-9]+|d2i_[A-Za-z_0-9]+|sk_[A-Za-z_0-9]+|GENERAL_NAME_[A-Za-z_0-9]+|ASN1_[A-Za-z_0-9]+|CRYPTO_[A-Za-z_0-9]+|RSA_[A-Za-z_0-9]+|DH_[A-Za-z_0-9]+|TLS_[A-Za-z_0-9]+)\(' . | tr -d '(' | sort -u > /tmp/syms.txt

# 2) 提取宏常量（SSL_OP_*/SSL_MODE_*/SSL_VERIFY_*/SSL_ERROR_*/X509_V_* 等）
grep -rhoE '\b(SSL_OP_[A-Z_0-9]+|SSL_MODE_[A-Z_0-9]+|SSL_VERIFY_[A-Z_0-9]+|SSL_ERROR_[A-Z_0-9]+|SSL_FILETYPE_[A-Z_0-9]+|X509_V_[A-Z_0-9]+|GEN_[A-Z_0-9]+|NID_[A-Za-z_0-9]+)\b' . | sort -u > /tmp/macros.txt

# 3) 对照目标库头文件检查缺失项（以 third_party/boringssl 为例）
while read s; do grep -rqE "OPENSSL_EXPORT[^(]*\b$s\s*\(|#\s*define\s+$s\b" \
  third_party/boringssl/include/openssl/ || echo "MISSING: $s"; done < /tmp/syms.txt

# 4) 缺失项回到 asio 源码确认是否被版本守卫隔离（OPENSSL_VERSION_NUMBER >= 0x30000000L 等），
#    并查目标库自报的 OPENSSL_VERSION_NUMBER 决定实际走哪条分支
grep -n OPENSSL_VERSION_NUMBER third_party/boringssl/include/openssl/base.h
```
