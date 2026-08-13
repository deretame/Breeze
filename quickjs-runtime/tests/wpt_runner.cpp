// wpt_runner.cpp —— 运行精选 wpt 子集（清单由 scripts/analyze_wpt.py 生成）
//
// 流程（每个测试文件一个独立 Runtime，run_to_completion 是单向 shutdown 的）：
//   1. eval wpt_shim.js（testharness 最小兼容层，重置 __wpt_results）
//   2. 注入 location（base_url + 文件路径，供 fetch 相对 URL 解析）
//   3. 按序执行 meta_scripts 依赖（磁盘读取，路径相对测试文件目录）
//   4. 执行测试主体：.any.js/.window.js 直接 eval；.html 提取内嵌 <script> 块
//   5. run_to_completion 驱动 Promise/fetch 链，读 __wpt_summary() 汇总
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp>
#include <fetch/client.hpp>

#include "wpt_server.hpp"

#include <fstream>
#include <filesystem>
#include <sstream>
#include <string>
#include <vector>

namespace {

namespace wpt = qjsbind::net::wpt;

std::string root_dir()
{
    // 测试工作目录是 build/，源码根在上一级
    std::error_code ec;
    const std::string here = std::filesystem::current_path(ec).string();
    return here.ends_with("build") ? here.substr(0, here.size() - 6) : here;
}

std::string read_file(const std::string& path)
{
    // 用 std::fopen 而非 std::ifstream：MSVC 的 ifstream 对本项目
    // 混合分隔符路径（反斜杠盘符 + 正斜杠子目录）打开失败，fopen 正常。
    FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) {
        std::cerr << "[dbg] read_file 打开失败: " << path << " errno=" << errno
                  << " root=" << root_dir() << "\n";
        for (unsigned char c : path)
            std::cerr << std::hex << (int)c << " ";
        std::cerr << std::dec << "\n";
        return {};
    }
    std::string out;
    char buf[8192];
    size_t n;
    while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0)
        out.append(buf, n);
    std::fclose(f);
    return out;
}

// 路径规范化：解析 . 与 ..（不处理符号链接）
std::string normalize_path(const std::string& path)
{
    std::vector<std::string> parts;
    std::string cur;
    for (char c : path + "/") {
        if (c == '/') {
            if (cur == "..") {
                if (!parts.empty()) parts.pop_back();
            } else if (!cur.empty() && cur != ".") {
                parts.push_back(cur);
            }
            cur.clear();
        } else {
            cur.push_back(c);
        }
    }
    std::string out;
    for (const auto& p : parts)
        out += "/" + p;
    return out.empty() ? "/" : out;
}

// 提取 HTML 内嵌 <script>...</script> 内容（跳过带 src 的；剥掉 <!-- --> 包裹）
std::vector<std::string> extract_inline_scripts(const std::string& html)
{
    std::vector<std::string> out;
    size_t pos = 0;
    while ((pos = html.find("<script", pos)) != std::string::npos) {
        const size_t tag_end = html.find('>', pos);
        if (tag_end == std::string::npos) break;
        const std::string attrs = html.substr(pos + 7, tag_end - pos - 7);
        if (attrs.find("src") != std::string::npos) { // 外部脚本由运行器经 meta 处理
            pos = tag_end + 1;
            continue;
        }
        const size_t close = html.find("</script", tag_end);
        if (close == std::string::npos) break;
        std::string body = html.substr(tag_end + 1, close - tag_end - 1);
        // 剥掉 HTML 注释包裹（wpt 常见 <!-- ... // -->）
        if (body.starts_with("<!--")) {
            const size_t cend = body.find("-->");
            if (cend != std::string::npos)
                body = body.substr(cend + 3);
        }
        if (body.ends_with("// -->"))
            body = body.substr(0, body.size() - 6);
        if (body.ends_with("<!--"))
            body = body.substr(0, body.size() - 4);
        out.push_back(body);
        pos = close + 8;
    }
    return out;
}

struct WptRunner : ::testing::Test {
    std::string wpt_root;
    std::unique_ptr<wpt::WptTestServer> server;
    std::string base;

    WptRunner()
    {
        wpt_root = root_dir() + "/third_party/wpt";
        server = std::make_unique<wpt::WptTestServer>(wpt_root);
        base = server->base_url();
    }

    // 单个测试文件：独立 Runtime 跑完
    std::string run_one(const std::string& file, const std::string& mode,
                        const std::vector<std::string>& metas)
    {
        qjs::Runtime rt;
        fetch::Client client{}; // 先于 ctx 声明（client 引用被 fetch 全局持有）
        qjs::Context ctx = rt.main_context();
        qjsbind::web::install_web_apis(ctx, client);

        const std::string shim = read_file(root_dir() + "/tests/wpt_shim.js");
        qjs::Value r = ctx.eval(shim);
        if (r.is_exception())
            return "[shim eval 失败]";

        // location 注入（相对 fetch URL 的 base）
        ctx.eval("__wpt_set_location('" + base + "/" + file + "')");

        // meta_scripts（相对测试文件目录）
        const std::string dir = file.substr(0, file.find_last_of('/') + 1);
        for (const auto& meta : metas) {
            const std::string p = normalize_path(dir + meta);
            const std::string src = read_file(wpt_root + p);
            r = ctx.eval(src);
            if (r.is_exception())
                return "[meta script 执行失败: " + p + "]";
        }

        // 测试主体
        const std::string body = read_file(wpt_root + "/" + file);
        if (mode == "html") {
            for (const auto& script : extract_inline_scripts(body)) {
                r = ctx.eval(script);
                if (r.is_exception())
                    return "[html script 执行异常] " + exc_str(ctx, r);
            }
        } else {
            r = ctx.eval(body);
            if (r.is_exception())
                return "[测试主体执行异常] " + exc_str(ctx, r);
        }
        rt.run_to_completion();
        return ctx.eval("__wpt_summary()").as<std::string>();
    }

    static std::string exc_str(qjs::Context& ctx, const qjs::Value& r)
    {
        // r 是 exception 值：取回 current_exception 转字符串
        qjs::Value exc(ctx.raw(), JS_GetException(ctx.raw()));
        const char* s = JS_ToCString(ctx.raw(), exc.raw());
        std::string out = s ? s : "(null)";
        if (s)
            JS_FreeCString(ctx.raw(), s);
        return out;
    }
};

TEST_F(WptRunner, FetchApiSubset)
{
    const std::string tsv = root_dir() + "/build/wpt_tests.txt";
    const std::string data = read_file(tsv);
    std::istringstream in(data);
    std::string line;

    int total = 0, file_pass = 0;
    int cases_pass = 0, cases_fail = 0;
    std::vector<std::string> failed;
    std::vector<std::string> errored;

    while (std::getline(in, line)) {
        if (line.empty())
            continue;
        // 调试用：WPT_FILTER=子串 只跑匹配的文件
        if (const char* f = std::getenv("WPT_FILTER")) {
            if (line.find(f) == std::string::npos)
                continue;
        }
        const size_t t1 = line.find('\t');
        const size_t t2 = line.find('\t', t1 + 1);
        const std::string file = line.substr(0, t1);
        const std::string mode = line.substr(t1 + 1, t2 - t1 - 1);
        const std::string meta = t2 == std::string::npos ? "" : line.substr(t2 + 1);
        // 防御：剔除行尾 \r（CRLF 残留会把 meta 路径弄坏）
        std::string meta_clean = meta;
        while (!meta_clean.empty() && (meta_clean.back() == '\r' || meta_clean.back() == '\n'))
            meta_clean.pop_back();
        std::vector<std::string> metas;
        std::string cur;
        for (char c : meta_clean + ",") {
            if (c == ',') {
                if (!cur.empty()) metas.push_back(cur);
                cur.clear();
            } else {
                cur.push_back(c);
            }
        }

        ++total;
        std::cerr << "== wpt: " << file << "\n";
        const std::string summary = run_one(file, mode, metas);
        std::cerr << "   " << summary << "\n";

        // 解析 "N pass, M fail" 或错误标记
        if (summary.find("pass") == std::string::npos) {
            errored.push_back(file + ": " + summary);
            continue;
        }
        const size_t fp = summary.find(" pass");
        const size_t ff = summary.find(" fail");
        int p = 0, fl = 0;
        try {
            p = std::stoi(summary.substr(0, fp));
            fl = std::stoi(summary.substr(fp + 6, ff - fp - 6));
        } catch (...) {
            errored.push_back(file + ": 无法解析: " + summary);
            continue;
        }
        cases_pass += p;
        cases_fail += fl;
        if (fl == 0) {
            ++file_pass;
        } else {
            failed.push_back(file);
        }
    }

    std::cerr << "\n==== wpt 汇总 ====\n"
              << "文件: " << file_pass << "/" << total << " 全过\n"
              << "用例: " << cases_pass << " pass / " << cases_fail << " fail\n";
    for (const auto& f : failed)
        std::cerr << "  未全过: " << f << "\n";
    for (const auto& f : errored)
        std::cerr << "  错误: " << f << "\n";

    EXPECT_GT(total, 0) << "wpt_tests.txt 为空——先跑 scripts/analyze_wpt.py";
    EXPECT_EQ(0, cases_fail) << "有失败用例，见上方输出";
}

} // namespace
