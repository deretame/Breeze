// tests/wpt_server.hpp —— wpt 精选子集用的 beast mini HTTP 测试服务器
//
// 对齐 fetch/api/resources/*.py 端点的最小语义（v1 精选子集所需）：
//   status.py?code=N&text=T&content=C&type=Y   → 状态码 N + X-Request-Method 头 + body C
//   redirect.py?location=U&redirect_status=N&simple=1
//                                              → 302（默认）/指定码 + Location 头
//                                                （无 simple 时附加原 query 参数 + count=N，
//                                                 模拟 wpt 的 stash 计数）
//   method.py?cors                              → x-request-* 头 + 请求体回显
//   inspect-headers.py?headers=A|B&cors         → x-request-A/x-request-B 头 + text/plain
//   echo-content.py                             → x-request-* 头 + Content-Type: text/plain + 体回显
//   其余路径                                    → third_party/wpt 下静态文件
//
// 实现：独立线程 + 同步 accept，每连接一个处理线程（测试负载小，够用且简单）。
#pragma once

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <brotli/encode.h>
#include <zlib.h>

#include <atomic>
#include <cctype>
#include <chrono>
#include <cstdio>
#include <map>
#include <sstream>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

namespace qjsbind::net::wpt {

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
using tcp = asio::ip::tcp;

// 极简 query 解析：k=v&k2=v2（percent-decode，重复键取首个）
inline std::map<std::string, std::string> parse_query(std::string_view q) {
    std::map<std::string, std::string> out;
    if (q.empty() || q.front() != '?')
        return out;
    q.remove_prefix(1);
    auto hex = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        if (c >= 'A' && c <= 'F') return c - 'A' + 10;
        return -1;
    };
    std::string key, val;
    bool in_key = true;
    for (size_t i = 0; i <= q.size(); ++i) {
        const char c = i < q.size() ? q[i] : '&';
        if (c == '&' || c == '=') {
            if (c == '=' && in_key) {
                in_key = false;
            } else if (i == q.size() || c == '&') {
                if (!key.empty() && !out.count(key))
                    out[key] = val;
                key.clear();
                val.clear();
                in_key = true;
            } else {
                val.push_back(c); // 值内的 '='：保留（如 location=/status.py?code=200）
            }
            continue;
        }
        std::string& dst = in_key ? key : val;
        if (c == '%' && i + 2 < q.size() + 1) {
            int h = hex(q[i + 1]), l = hex(q[i + 2]);
            if (h >= 0 && l >= 0) {
                dst.push_back(static_cast<char>((h << 4) | l));
                i += 2;
                continue;
            }
        }
        dst.push_back(c == '+' ? ' ' : c);
    }
    return out;
}

inline std::string url_encode(std::string_view s) {
    const char* hexd = "0123456789ABCDEF";
    std::string out;
    for (unsigned char c : s) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~' || c == '?' ||
            c == '=' || c == '&' || c == '%' || c == '/' || c == ':' || c == '#' || c == ',')
            out.push_back(static_cast<char>(c));
        else {
            out.push_back('%');
            out.push_back(hexd[c >> 4]);
            out.push_back(hexd[c & 0xF]);
        }
    }
    return out;
}

inline std::string mime_of(const std::string& path) {
    if (path.ends_with(".js")) return "text/javascript";
    if (path.ends_with(".html") || path.ends_with(".htm")) return "text/html";
    if (path.ends_with(".css")) return "text/css";
    if (path.ends_with(".json")) return "application/json";
    if (path.ends_with(".txt") || path.ends_with(".py")) return "text/plain";
    return "application/octet-stream";
}

class WptTestServer {
public:
    explicit WptTestServer(std::string wpt_root)
        : wpt_root_(std::move(wpt_root)), acceptor_(io_)
    {
        tcp::endpoint ep(tcp::v4(), 0); // 随机端口
        acceptor_.open(ep.protocol());
        acceptor_.set_option(tcp::acceptor::reuse_address(true));
        acceptor_.bind(ep);
        acceptor_.listen();
        port_ = acceptor_.local_endpoint().port();
        thread_ = std::thread([this] { run(); });
    }

    ~WptTestServer()
    {
        boost::system::error_code ec;
        acceptor_.close(ec);
        if (thread_.joinable())
            thread_.join();
    }

    WptTestServer(const WptTestServer&) = delete;
    WptTestServer& operator=(const WptTestServer&) = delete;

    int port() const { return port_; }
    std::string base_url() const { return "http://127.0.0.1:" + std::to_string(port_); }

    // 已 accept 的连接总数（连接辨识钩子；测试断言用）
    uint64_t conn_count() const { return conn_seq_.load(); }

private:
    // accept 计数：连接辨识钩子（连接池测试用）。请求带 `X-Trace-Conn: 1`
    // 时响应回写 `X-Conn-Id: N`（N = 本连接的 accept 序号）：两次请求
    // X-Conn-Id 相同 = 同一连接（复用）；不同 = 新建连接。
    std::atomic<uint64_t> conn_seq_{0};

    void run()
    {
        for (;;) {
            boost::system::error_code ec;
            tcp::socket sock = acceptor_.accept(ec);
            if (ec)
                return; // acceptor 关闭（析构）→ 退出
            std::thread([this, s = std::move(sock)]() mutable { handle_connection(std::move(s)); })
                .detach();
        }
    }

    void handle_connection(tcp::socket sock)
    {
        const uint64_t conn_id = ++conn_seq_; // 本连接的 accept 序号（连接辨识钩子）
        beast::tcp_stream stream(std::move(sock));
        beast::flat_buffer buffer;
        for (;;) {
            // 每次操作前设超时：防客户端挂起（如 content-length 与实际 body 不符）
            stream.expires_after(std::chrono::seconds(5));
            http::request<http::string_body> req;
            boost::system::error_code ec;
            http::read(stream, buffer, req, ec);
            if (ec)
                return;
            const std::string target(req.target());

            // ---- slow-response.py?delay=MS&content=X：头立即发出、body 延迟 ----
            // 分片写（buffer_body）：第一段 only 头（content-length 已知），
            // sleep 后第二段写 body。验证 fetch 在响应头到达时即 resolve。
            if (target.starts_with("/slow-response.py")) {
                const size_t qpos = target.find('?');
                const auto q = parse_query(qpos == std::string::npos ? "" : target.substr(qpos));
                int delay = 300;
                try { delay = std::stoi(q.at("delay")); } catch (...) {}
                const std::string content = q.count("content") ? q.at("content") : "";
                // 手工分片写（beast 的 buffer_body 无法"只写头"）：
                // 头（content-length 已知）立即发出，body 延迟 delay ms 后发出。
                std::string head = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                                   "Content-Length: " +
                                   std::to_string(content.size()) + "\r\n"
                                   "Server: qjs-wpt/0.1\r\n"
                                   "Connection: close\r\n\r\n";
                stream.expires_after(std::chrono::seconds(5));
                boost::asio::write(stream, boost::asio::buffer(head), ec);
                if (ec)
                    return;
                std::this_thread::sleep_for(std::chrono::milliseconds(delay));
                stream.expires_after(std::chrono::seconds(5));
                boost::asio::write(stream, boost::asio::buffer(content), ec);
                return; // Connection: close：写完即断
            }

            http::response<http::string_body> res;
            handle_request(req, res, target);
            // HEAD 请求：响应不得含 body（规范）
            if (req.method() == http::verb::head)
                res.body().clear();
            // 连接辨识钩子：请求带 X-Trace-Conn: 1 → 回写本连接序号
            //（连接池测试；不影响其他请求/响应）
            if (const auto it = req.find("X-Trace-Conn");
                it != req.end() && it->value() == "1")
                res.set("X-Conn-Id", std::to_string(conn_id));
            // close-after.py?code=200&content=X：正常 keep-alive 响应，但服务端
            // 写完即断连接（连接池"陈旧连接"测试：客户端看到 keep-alive → 回池 →
            // 下次复用写失败 → 触发 retry_on_reused_failure）。
            // 用 SO_LINGER 0 发 RST 而非 FIN：Windows 上对 FIN 后连接写通常仍
            // 成功（写阶段不报错），无法触发"写失败"重试；RST 使复用写立即
            // ECONNRESET。延迟发 RST：先让客户端把响应 body 读完（否则 RST 会
            // 打断 content-length 的读取）。请求 2 的时序由测试侧保证
            //（等待超过本延迟，确保 RST 已在客户端就位）。
            const bool close_after = target.starts_with("/close-after.py");
            // fin-after.py：同 close-after，但**优雅关闭**（FIN，无 RST 无延迟）
            // ——复用写通常成功、读头零字节 EOF 的陈旧形态（H3 重试测试）。
            const bool fin_after = target.starts_with("/fin-after.py");
            // 端点显式设置过 content-length（bad-length.py 谎报长度）时不覆盖
            if (res.find(http::field::content_length) == res.end())
                res.prepare_payload();
            stream.expires_after(std::chrono::seconds(5));
            http::write(stream, res, ec);
            if (ec || req.keep_alive() == false || res.keep_alive() == false)
                return;
            if (close_after) {
                // 延迟 RST：先让客户端读完响应 body（否则 RST 打断 body 读取）
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                boost::asio::ip::tcp::socket::linger rst{true, 0};
                boost::system::error_code ec2;
                stream.socket().set_option(rst, ec2);
                return; // 析构 close → RST
            }
            if (fin_after)
                return; // 析构 close → FIN（优雅关闭；已写字节不受影响）
        }
    }

    void handle_request(const http::request<http::string_body>& req,
                        http::response<http::string_body>& res, const std::string& target)
    {
        res.version(req.version());
        res.keep_alive(req.keep_alive());
        res.set(http::field::server, "qjs-wpt/0.1");
        const size_t qpos = target.find('?');
        const std::string path = target.substr(0, qpos);
        const auto query = parse_query(qpos == std::string::npos ? "" : target.substr(qpos));

        // ---- 端点路由（fetch/api/resources/*.py）----
        if (path.ends_with("/status.py")) {
            int code = 200;
            try { code = std::stoi(query.at("code")); } catch (...) {}
            res.result(static_cast<http::status>(code));
            res.set(http::field::content_type, query.count("type") ? query.at("type") : "");
            res.set("X-Request-Method", std::string(req.method_string()));
            // 204/205/304 规范上无 body（beast 对"带 body 的 204"序列化会出错挂起）
            const bool no_body = code == 204 || code == 205 || code == 304;
            if (!no_body)
                res.body() = query.count("content") ? query.at("content") : "";
            return;
        }
        if (path.ends_with("/redirect.py")) {
            int status = 302;
            try { status = std::stoi(query.at("redirect_status")); } catch (...) {}
            res.result(static_cast<http::status>(status));
            res.set(http::field::content_type, "text/plain");
            res.set(http::field::cache_control, "no-cache");
            res.set(http::field::pragma, "no-cache");
            const auto origin = req.find(http::field::origin);
            if (origin != req.end())
                res.set(http::field::access_control_allow_origin, std::string(origin->value()));
            else
                res.set(http::field::access_control_allow_origin, "*");
            if (query.count("location")) {
                std::string loc = query.at("location");
                // wpt 语义：无 simple 参数时保留全部原 query 参数 + count（模拟 stash 计数）
                // 注意：与 wpt 原版 redirect.py 一致——location 参数本身也保留，
                // 使无限重定向循环成立（每次 Location 都带 location=/redirect.py）。
                if (!query.count("simple")) {
                    std::string suffix;
                    for (const auto& [k, v] : query)
                        suffix += (suffix.empty() ? (loc.find('?') != std::string::npos ? "&" : "?")
                                                  : "&") +
                                  url_encode(k) + "=" + url_encode(v);
                    loc += suffix + (suffix.empty() ? (loc.find('?') != std::string::npos ? "&" : "?")
                                                    : "&") +
                            "count=" + std::to_string(++redirect_count_);
                }
                res.set(http::field::location, loc);
            }
            res.body() = "";
            return;
        }
        if (path.ends_with("/method.py")) {
            if (query.count("cors")) {
                res.set(http::field::access_control_allow_origin, "*");
                res.set(http::field::access_control_allow_credentials, "true");
                res.set(http::field::access_control_allow_methods, "GET, POST, PUT, FOO");
                res.set(http::field::access_control_allow_headers, "x-test, x-foo");
                res.set(http::field::access_control_expose_headers, "x-request-method");
            }
            res.set("x-request-method", std::string(req.method_string()));
            res.set("x-request-content-type", header_or(req, http::field::content_type, "NO"));
            res.set("x-request-content-length", header_or(req, http::field::content_length, "NO"));
            res.set("x-request-content-encoding", header_or(req, http::field::content_encoding, "NO"));
            res.set("x-request-content-language", header_or(req, http::field::content_language, "NO"));
            res.set("x-request-content-location", header_or(req, http::field::content_location, "NO"));
            res.set(http::field::content_type, "text/plain");
            res.body() = req.body();
            return;
        }
        if (path.ends_with("/inspect-headers.py")) {
            std::string checked = query.count("headers") ? query.at("headers") : "";
            std::vector<std::string> names;
            std::string cur;
            for (char c : checked + "|") {
                if (c == '|') {
                    if (!cur.empty()) names.push_back(cur);
                    cur.clear();
                } else {
                    cur.push_back(c);
                }
            }
            if (query.count("cors")) {
                const auto origin = req.find(http::field::origin);
                res.set(http::field::access_control_allow_origin,
                        origin != req.end() ? std::string(origin->value()) : "*");
                res.set(http::field::access_control_allow_credentials, "true");
                res.set(http::field::access_control_allow_methods, "GET, POST, HEAD");
                std::string exposed;
                for (const auto& n : names)
                    exposed += (exposed.empty() ? "" : ", ") + std::string("x-request-") + n;
                res.set(http::field::access_control_expose_headers, exposed);
            }
            for (const auto& n : names) {
                const auto it = req.find(n);
                if (it != req.end())
                    res.set("x-request-" + n, std::string(it->value()));
            }
            res.set(http::field::content_type, "text/plain");
            res.body() = "";
            return;
        }
        if (path.ends_with("/echo-content.py")) {
            res.set("X-Request-Method", std::string(req.method_string()));
            res.set("X-Request-Target", std::string(req.target())); // 请求行 target（origin-form 断言）
            res.set("X-Request-Content-Length", header_or(req, http::field::content_length, "NO"));
            res.set("X-Request-Content-Type", header_or(req, http::field::content_type, "NO"));
            res.set("X-Request-Authorization", header_or(req, http::field::authorization, "NO"));
            res.set(http::field::content_type, "text/plain");
            res.body() = req.body();
            return;
        }
        // ---- compress.py?code=gzip|deflate|br：POST body 压缩回显（M3 解压测试）----
        // 响应 Content-Encoding + X-Req-Accept-Encoding（回显客户端自动头，验证拦截器）
        if (path.ends_with("/compress.py")) {
            std::string code = query.count("code") ? query.at("code") : "gzip";
            const std::string in = req.body();
            std::string out;
            if (code == "gzip") {
                z_stream zs{};
                deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8,
                             Z_DEFAULT_STRATEGY);
                out.resize(deflateBound(&zs, static_cast<uLong>(in.size())));
                zs.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(in.data()));
                zs.avail_in = static_cast<uInt>(in.size());
                zs.next_out = reinterpret_cast<Bytef*>(out.data());
                zs.avail_out = static_cast<uInt>(out.size());
                deflate(&zs, Z_FINISH);
                out.resize(zs.total_out);
                deflateEnd(&zs);
            } else if (code == "deflate") {
                z_stream zs{};
                deflateInit(&zs, Z_DEFAULT_COMPRESSION); // zlib 流（带头）
                out.resize(deflateBound(&zs, static_cast<uLong>(in.size())));
                zs.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(in.data()));
                zs.avail_in = static_cast<uInt>(in.size());
                zs.next_out = reinterpret_cast<Bytef*>(out.data());
                zs.avail_out = static_cast<uInt>(out.size());
                deflate(&zs, Z_FINISH);
                out.resize(zs.total_out);
                deflateEnd(&zs);
            } else { // br
                const size_t cap = BrotliEncoderMaxCompressedSize(in.size());
                out.resize(cap ? cap : 1);
                size_t n = out.size();
                BrotliEncoderCompress(4, 22, BROTLI_MODE_TEXT, in.size(),
                                      reinterpret_cast<const uint8_t*>(in.data()), &n,
                                      reinterpret_cast<uint8_t*>(out.data()));
                out.resize(n);
            }
            res.set(http::field::content_type, "text/plain");
            res.set("Content-Encoding", code);
            res.set("X-Req-Accept-Encoding", header_or(req, http::field::accept_encoding, "NO"));
            if (query.count("corrupt")) // 翻转末字节 → 客户端解码失败
                out.back() ^= 0xFF;
            if (query.count("trailing")) // 流尾追加垃圾字节（解压器应忽略）
                out.append("GARBAGE-TRAILING-BYTES");
            res.body() = std::move(out);
            return;
        }

        // ---- close-after.py / fin-after.py?code=200&content=X：正常 keep-alive
        // 响应，但服务端写完即断连接（连接池"陈旧连接"测试：客户端看到 keep-alive
        // → 回池 → 下次复用失败 → 触发 retry_on_reused_failure）。close-after 发
        // RST（写失败形态），fin-after 优雅 FIN（写成功读 EOF 形态）----
        if (path.ends_with("/close-after.py") || path.ends_with("/fin-after.py")) {
            int code = 200;
            try { code = std::stoi(query.at("code")); } catch (...) {}
            res.result(static_cast<http::status>(code));
            res.set(http::field::content_type, "text/plain");
            res.body() = query.count("content") ? query.at("content") : "";
            return; // keep_alive 保持（handle_connection 写完即断）
        }

        // ---- bad-length.py?length=N&content=X：谎报 content-length，发完即断（读取失败测试）----
        if (path.ends_with("/bad-length.py")) {
            int length = 100;
            try { length = std::stoi(query.at("length")); } catch (...) {}
            const std::string content = query.count("content") ? query.at("content") : "";
            res.result(http::status::ok);
            res.set(http::field::content_type, "text/plain");
            res.content_length(length);
            res.keep_alive(false); // 发完即关连接 → 客户端读到 content-length 未满即 EOF
            res.body() = content;
            return;
        }

        // ---- .asis 原样响应（wpt 多同名头测试）----
        if (path.ends_with(".asis")) {
            const std::string rel = path.substr(1);
            const std::string full = wpt_root_ + "/" + rel;
            FILE* f = std::fopen(full.c_str(), "rb");
            if (!f) {
                res.result(http::status::not_found);
                res.body() = "404: " + path;
                return;
            }
            std::string data;
            char buf[8192];
            size_t n;
            while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0)
                data.append(buf, n);
            std::fclose(f);
            // 首行: HTTP/1.x CODE REASON；头行（可同名多行）；空行；body
            size_t pos = 0;
            auto next_line = [&](std::string& line) {
                const size_t e = data.find('\n', pos);
                line = data.substr(pos, e == std::string::npos ? std::string::npos : e - pos);
                if (!line.empty() && line.back() == '\r')
                    line.pop_back();
                pos = e == std::string::npos ? data.size() : e + 1;
                return e != std::string::npos;
            };
            std::string line;
            if (next_line(line)) { // 状态行
                std::istringstream ss(line);
                std::string httpver;
                int code = 200;
                ss >> httpver >> code;
                res.result(static_cast<http::status>(code));
                std::string reason;
                std::getline(ss, reason);
                if (!reason.empty() && reason.front() == ' ')
                    reason.erase(0, 1);
                if (!reason.empty())
                    res.reason(reason);
            }
            while (next_line(line) && !line.empty()) {
                const size_t colon = line.find(':');
                if (colon == std::string::npos)
                    continue;
                std::string name = line.substr(0, colon);
                std::string value = line.substr(colon + 1);
                if (!value.empty() && value.front() == ' ')
                    value.erase(0, 1);
                res.base().insert(name, value); // 同名可多次 insert
            }
            res.body() = data.substr(pos);
            return;
        }

        // ---- 静态文件（third_party/wpt）----
        std::string rel = path;
        while (rel.starts_with('/'))
            rel.erase(0, 1);
        if (rel.empty())
            rel = "index.html";
        const std::string full = wpt_root_ + "/" + rel;
        FILE* f = std::fopen(full.c_str(), "rb");
        if (!f) {
            res.result(http::status::not_found);
            res.set(http::field::content_type, "text/plain");
            res.body() = "404 not found: " + path;
            return;
        }
        std::string data;
        char buf[8192];
        size_t n;
        while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0)
            data.append(buf, n);
        std::fclose(f);
        res.result(http::status::ok);
        res.set(http::field::content_type, mime_of(full));
        res.body() = std::move(data);
    }

    static std::string header_or(const http::request<http::string_body>& req,
                                 http::field f, const char* fallback)
    {
        const auto it = req.find(f);
        return it != req.end() ? std::string(it->value()) : std::string(fallback);
    }

    std::string wpt_root_;
    asio::io_context io_;
    tcp::acceptor acceptor_;
    std::thread thread_;
    int port_ = 0;
    std::atomic<int> redirect_count_{0};
};

} // namespace qjsbind::net::wpt
