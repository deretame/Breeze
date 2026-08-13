// fetchcore —— FormData 值类型 + multipart/form-data 编解码（header-only）
//
// 本头是 fetchcore 的纯 C++ FormData 能力（原 qjsbind::web/formdata.hpp 的
// C++ 部分下沉）：条目表（append/set/delete/has 语义）、multipart 序列化
// （encode_multipart，供 Request body 使用）与解析（parse_multipart，失败
// → nullopt，由调用方决定如何报错）。JS 绑定层保留 JS ⇄ 条目转换与类注册。
//
// 依赖方向：本头只依赖标准库；禁止 include 任何 quickjs/qjsbind 头。
#pragma once

#include <algorithm>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace fetch {

// ---------- FormData ----------

// 条目表模型（WHATWG FormData entry list）：
//   - 值：string（bytes 为 UTF-8）或 blob/File（bytes 为原始字节 + type + filename）
//   - is_blob = true 表示 blob/File 值（get 返回 File 对象语义由绑定层决定）
struct FormData {
    struct Entry {
        std::string name;
        std::string bytes;    // 值字节（string 的 UTF-8 或 blob 的原始字节）
        std::string type;     // blob 值的 type（string 值空）
        std::string filename; // blob 值的文件名（File.name 或 append 的 filename；string 值空）
        bool is_blob = false; // true = blob/File 值（get 返回 File 对象）
    };
    std::vector<Entry> list;

    void append_entry(std::string name, std::string bytes, std::string type,
                      std::string filename, bool is_blob) {
        list.push_back({std::move(name), std::move(bytes), std::move(type),
                        std::move(filename), is_blob});
    }
    // set：替换同名（首个替换值，其余删除；无同名 → append）
    void set_entry(std::string name, std::string bytes, std::string type,
                   std::string filename, bool is_blob) {
        bool replaced = false;
        for (size_t i = 0; i < list.size();) {
            if (list[i].name == name) {
                if (!replaced) {
                    list[i] = {name, bytes, type, filename, is_blob};
                    replaced = true;
                    ++i;
                } else {
                    list.erase(list.begin() + static_cast<std::ptrdiff_t>(i));
                }
            } else {
                ++i;
            }
        }
        if (!replaced)
            append_entry(std::move(name), std::move(bytes), std::move(type),
                         std::move(filename), is_blob);
    }
    void erase_entry(const std::string& name) {
        std::erase_if(list, [&](const Entry& e) { return e.name == name; });
    }
    bool has_entry(const std::string& name) const {
        for (const auto& e : list)
            if (e.name == name)
                return true;
        return false;
    }
};

// multipart/form-data 序列化（fetch 规范 §multipart/form-data encoding）：
// --boundary\r\nContent-Disposition: form-data; name="n"[; filename="f"]\r\n
// [Content-Type: t\r\n]\r\nbytes\r\n--boundary--\r\n
inline std::string encode_multipart(const FormData& fd, const std::string& boundary) {
    std::string out;
    auto escape = [](const std::string& s) {
        std::string r;
        for (const char c : s) {
            if (c == '"' || c == '\\')
                r.push_back('\\');
            r.push_back(c);
        }
        return r;
    };
    for (const auto& e : fd.list) {
        out += "--" + boundary + "\r\n";
        out += "Content-Disposition: form-data; name=\"" + escape(e.name) + "\"";
        if (e.is_blob)
            out += "; filename=\"" + escape(e.filename) + "\"";
        out += "\r\n";
        if (e.is_blob && !e.type.empty())
            out += "Content-Type: " + e.type + "\r\n";
        out += "\r\n";
        out += e.bytes;
        out += "\r\n";
    }
    out += "--" + boundary + "--\r\n";
    return out;
}

// multipart/form-data 解析（fetch 规范 §multipart/form-data parsing；头名大小写不敏感）。
// boundary 参数按 MIME Sniffing "parse a MIME type" 的参数解析算法提取（RFC 2046 允许
// boundary 含空格）：
//   - 值以 '"' 开头 → quoted-string：读到未转义 '"' 为止（\" 解出 "、\\ 解出 \）
//   - 否则裸值 → 读到 ';' 或末尾，仅去尾随 HTTP whitespace（中间空格保留）
// CR/LF 在两种模式都视为异常终止（防御头值注入；正常 Headers 值不含 CR/LF）。
inline std::string extract_boundary(const std::string& content_type) {
    // 参数名大小写不敏感（MIME 语义）：用小写副本定位；boundary 值本身
    // 大小写敏感，从原文截取
    std::string lower = content_type;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    const std::string key = "boundary=";
    const size_t p = lower.find(key);
    if (p == std::string::npos)
        return "";
    size_t b = p + key.size();
    if (b < content_type.size() && content_type[b] == '"') {
        // quoted-string：到未转义 '"' 结束；'\' 转义下一字符
        std::string out;
        ++b;
        while (b < content_type.size()) {
            const char c = content_type[b];
            if (c == '\\' && b + 1 < content_type.size()) {
                // 转义：\X → X；但 \ 后跟 CR/LF 视为异常终止（与主循环防御一致，
                // 防止 \ 吞掉注入的换行）
                if (content_type[b + 1] == '\r' || content_type[b + 1] == '\n')
                    break;
                out.push_back(content_type[b + 1]);
                b += 2;
                continue;
            }
            if (c == '"' || c == '\r' || c == '\n')
                break;
            out.push_back(c);
            ++b;
        }
        return out;
    }
    // 裸值：到 ';'（或异常 CR/LF、末尾）为止，去尾随 HTTP whitespace
    size_t e = b;
    while (e < content_type.size() && content_type[e] != ';' && content_type[e] != '\r' &&
           content_type[e] != '\n')
        ++e;
    std::string out = content_type.substr(b, e - b);
    while (!out.empty() && (out.back() == ' ' || out.back() == '\t'))
        out.pop_back();
    return out;
}

// Content-Disposition 参数（name/filename）：name="v"（支持 \" 转义）或裸值
inline std::string parse_disposition_param(const std::string& s, const char* key) {
    const std::string k = std::string(key) + "=";
    const size_t p = s.find(k);
    if (p == std::string::npos)
        return "";
    size_t i = p + k.size();
    if (i < s.size() && s[i] == '"') {
        ++i;
        std::string out;
        while (i < s.size() && s[i] != '"') {
            if (s[i] == '\\' && i + 1 < s.size())
                ++i;
            out.push_back(s[i++]);
        }
        return out;
    }
    size_t e = i;
    while (e < s.size() && s[e] != ';' && s[e] != ' ' && s[e] != '\r' && s[e] != '\n')
        ++e;
    return s.substr(i, e - i);
}

// multipart/form-data 解析（HTML 标准 §multipart/form-data parsing algorithm；头名大小写不敏感）。
// 结构不合法（缺 boundary、delimiter 后非 \r\n、part 无头体分隔等）返回 std::nullopt，
// 由调用方决定报错方式（绑定层 reject TypeError；wpt response-form-data.html invalidCases）。
// pos 每轮严格递增，循环保证终止。
inline std::optional<FormData> parse_multipart(const std::string& body,
                                               const std::string& boundary) {
    if (boundary.empty())
        return std::nullopt;
    // HTML 标准 multipart/form-data parsing：bytes 为空字节序列 → 返回空 entry list
    //（空 FormData 序列化为空 body 后 formData() 应得空 FormData；wpt formdata.any.js）
    if (body.empty())
        return FormData{};
    FormData fd;
    const std::string delim = "--" + boundary;
    // transport padding（RFC 2046）：delimiter 后允许若干 tab/space
    auto skip_padding = [&](size_t& p) {
        while (p < body.size() && (body[p] == ' ' || body[p] == '\t'))
            ++p;
    };
    size_t pos = 0;
    for (;;) {
        // 每个 part（含首个）都必须以 --boundary 起始
        if (body.compare(pos, delim.size(), delim) != 0)
            return std::nullopt;
        pos += delim.size();
        // 结束标记：--boundary "--" [padding] [\r\n] <end>
        if (body.compare(pos, 2, "--") == 0) {
            pos += 2;
            skip_padding(pos);
            if (body.compare(pos, 2, "\r\n") == 0)
                pos += 2;
            if (pos != body.size())
                return std::nullopt; // 结束标记后还有内容
            return fd;
        }
        // part 起始行：padding 之后必须是 \r\n
        skip_padding(pos);
        if (body.compare(pos, 2, "\r\n") != 0)
            return std::nullopt;
        pos += 2;
        // part 内容到下一段边界（\r\n--boundary）为止；不存在 → failure
        const size_t next = body.find("\r\n" + delim, pos);
        if (next == std::string::npos)
            return std::nullopt;
        const std::string part = body.substr(pos, next - pos);
        pos = next + 2; // 前进保证：pos 严格递增
        const size_t hdr_end = part.find("\r\n\r\n");
        if (hdr_end == std::string::npos)
            return std::nullopt;
        const std::string hdrs = part.substr(0, hdr_end);
        const std::string data = part.substr(hdr_end + 4);
        // 头行解析（大小写不敏感）
        std::string disposition, type;
        size_t hs = 0;
        while (hs <= hdrs.size()) {
            const size_t nl = hdrs.find("\r\n", hs);
            const std::string line =
                hdrs.substr(hs, nl == std::string::npos ? hdrs.size() - hs : nl - hs);
            const size_t colon = line.find(':');
            if (colon != std::string::npos) {
                std::string name = line.substr(0, colon);
                std::string value = line.substr(colon + 1);
                while (!value.empty() && (value.front() == ' ' || value.front() == '\t'))
                    value.erase(value.begin());
                for (auto& c : name)
                    c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
                if (name == "content-disposition")
                    disposition = value;
                else if (name == "content-type")
                    type = value;
            }
            if (nl == std::string::npos)
                break;
            hs = nl + 2;
        }
        FormData::Entry e;
        e.name = parse_disposition_param(disposition, "name");
        e.filename = parse_disposition_param(disposition, "filename");
        if (!e.filename.empty() || !type.empty()) {
            // blob 条目（Content-Disposition 带 filename 或显式 Content-Type）
            e.bytes = data;
            e.type = type;
            e.is_blob = true;
        } else {
            // string 条目：UTF-8 decode（去 BOM）
            std::string s = data;
            if (s.size() >= 3 && static_cast<uint8_t>(s[0]) == 0xEF &&
                static_cast<uint8_t>(s[1]) == 0xBB && static_cast<uint8_t>(s[2]) == 0xBF)
                s.erase(0, 3);
            e.bytes = s;
        }
        fd.list.push_back(std::move(e));
    }
}

} // namespace fetch
