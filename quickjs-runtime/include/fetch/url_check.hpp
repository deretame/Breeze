// fetchcore —— URL 端口检查（fetch 规范 #port-blocking）
//
// 安全职责（security review sa_20260808_173002 MEDIUM 1）：blocked-port
// 清单与检查从绑定层下沉到核心层，fetch() 入口与 redirect 每跳都执行，
// 防止恶意 Location 把请求带向 127.0.0.1:22 等内网敏感端口（SSRF 端口绕过）。
#pragma once

#include <fetch/error.hpp>

#include <ada.h>

#include <string>

namespace fetch {

// fetch 规范 #port-blocking 清单（与浏览器一致）
inline bool is_blocked_port(int port)
{
    static const int kBad[] = {
        0,   1,   7,   9,   11,  13,  15,  17,  19,  20,  21,  22,  23,  25,  37,  42, 43,
        53,  69,  77,  79,  87,  95,  101, 102, 103, 104, 109, 110, 111, 113, 115, 117, 119,
        123, 135, 137, 139, 143, 161, 179, 389, 427, 465, 512, 513, 514, 515, 526, 530, 531,
        532, 540, 548, 554, 556, 563, 587, 601, 636, 989, 990, 993, 995, 1719, 1720, 1723,
        2049, 3659, 4045, 4190, 5060, 5061, 6000, 6566, 6665, 6666, 6667, 6668, 6669, 6679,
        6697, 10080,
    };
    for (int b : kBad)
        if (port == b)
            return true;
    return false;
}

// 解析 URL 端口；被禁止 → 返回端口号，否则 -1（解析失败/无端口/非法端口 → -1）
// ada（WHATWG 解析器）已规范化端口（去前导零、默认端口剥离）。
// 注：禁止表不含 80/443（默认端口已由 ada 剥离；显式 :80/:443 不拦截，
// 与浏览器 blocked ports 清单一致）。
// 注：输入必须是绝对 URL（fetch 入口与 redirect 每跳传入 resolve 后的 URL；
// 见 client.hpp）。相对引用（如 "//host:25/"）ada 无 base 解析失败 → 返回 -1
// 不拦截——但后续 parse_url 会拒绝非绝对 URL（fail-closed 兜底）。
inline int blocked_port_of(const std::string& url)
{
    auto r = ada::parse<ada::url_aggregator>(url);
    if (!r || !r->has_port())
        return -1;
    const std::string ps(r->get_port());
    // 端口必须是纯数字（ada 语法已保证，此处纵深防御：非数字 → 不拦截）
    if (ps.empty())
        return -1;
    for (const char c : ps)
        if (c < '0' || c > '9')
            return -1;
    try {
        const int p = std::stoi(ps);
        return is_blocked_port(p) ? p : -1;
    } catch (const std::exception&) { // invalid_argument / out_of_range（超长数字）
        return -1;
    }
}

// 检查并抛 fetch::Error（供核心层 fetch() 入口与 redirect 每跳调用）
inline void check_url_ports(const std::string& url)
{
    const int p = blocked_port_of(url);
    if (p != -1) // 含端口 0（is_blocked_port(0)==true，规范清单本含 0 防占位）
        throw Error("fetch: URL 端口 " + std::to_string(p) + " 被禁止");
}

// ada url_aggregator → HTTP origin-form 请求行 target（path[?query]）。
// 注意：ada 的 get_search() 对空 query 返回 ""（'?' 被丢），需按 has_search()
// 补回——HTTP 语义中 "/x?" 与 "/x" 不同（beast_transport 与测试代理服务器共用）。
inline std::string origin_form_target(const ada::url_aggregator& u)
{
    std::string t(u.get_pathname());
    if (u.has_search()) {
        t.push_back('?');
        const std::string q(u.get_search());
        if (!q.empty() && q.front() == '?')
            t += q.substr(1);
        else
            t += q;
    }
    return t;
}

} // namespace fetch
