// opencc.hpp —— 简繁转换（OpenCC 官方数据 + 链式 MaxMatch 自实现）
//
// 为什么不用 vcpkg 官方 opencc 库：官方库运行时按相对路径（OPENCC_SYSTEM_CONFIG_PATH /
// 当前工作目录）加载 json 配置与 .ocd2 词典，Windows 嵌入场景定位不可靠；
// 本实现把 OpenCC 官方词典数据（scripts/bootstrap_opencc.py 下载生成
// opencc_data.hpp）直接嵌入二进制，运行时无外部文件依赖。
//
// 转换语义与官方 ver.1.1.9 一致（data/config/*.json 的转换链；+ 表示 group
// 合并词典，匹配取所有词典中的最长匹配；Rev = 反向词典）：
//   s2t.json  = [STPhrases + STCharacters]
//   t2s.json  = [TSPhrases + TSCharacters]
//   s2tw.json = [STPhrases + STCharacters] → [TWVariants]
//   tw2s.json = [TWVariantsRevPhrases + TWVariantsRev] → [TSPhrases + TSCharacters]
//   s2hk.json = [STPhrases + STCharacters] → [HKVariants]
//   hk2s.json = [HKVariantsRevPhrases + HKVariantsRev] → [TSPhrases + TSCharacters]
//   jp2t.json = [JPShinjitaiPhrases + JPShinjitaiCharacters + JPVariantsRev]
//               （日文新字体 → 旧字体/繁体）
//   t2jp.json = [JPVariants]（旧字体/繁体 → 日文新字体）
//
// MaxMatch：从每个位置起找词典中的最长匹配词并替换（词组因更长自然优先；
// 未命中保留原字符前进一位）；多候选（txt 中 value 空格分隔）取第一个。
//
// 纯 C++ 设施（无 quickjs 依赖），任何模块可直接调用 opencc::convert。
// JS 侧绑定见 qjsbind/polyfill/runtime_api.hpp（__opencc_convert + opencc 对象）。
#pragma once

#include <opencc/opencc_data.hpp> // 生成物（pixi run fetch-opencc，不入库）

#include <array>
#include <cstddef>
#include <stdexcept>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace opencc {

namespace detail {

// 按 UTF-8 字符边界拆分（返回指向原串的字符 view 序列；非法字节按 1 字节处理）
inline std::vector<std::string_view> split_chars(std::string_view s)
{
    std::vector<std::string_view> out;
    std::size_t i = 0;
    const std::size_t n = s.size();
    while (i < n) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        std::size_t len = 1;
        if ((c & 0xE0) == 0xC0)
            len = 2;
        else if ((c & 0xF0) == 0xE0)
            len = 3;
        else if ((c & 0xF8) == 0xF0)
            len = 4;
        if (i + len > n)
            len = 1; // 截断的多字节序列：按单字节透传
        out.emplace_back(s.data() + i, len);
        i += len;
    }
    return out;
}

// 词典：key（UTF-8 原文）→ value（转换结果，多候选取第一个）
struct Dict {
    std::unordered_map<std::string, std::string> map;
    std::size_t max_key_chars = 1; // 最长 key 的字符数（MaxMatch 枚举上限）
};

// 解析 OpenCC txt 词典（每行 KEY\tVALUE；空行/注释行跳过；多候选取第一个）
inline Dict parse_dict(std::string_view txt)
{
    Dict d;
    std::size_t pos = 0;
    const std::size_t n = txt.size();
    while (pos < n) {
        const std::size_t nl = txt.find('\n', pos);
        const std::string_view line = txt.substr(pos, nl == std::string_view::npos ? n - pos : nl - pos);
        pos = nl == std::string_view::npos ? n : nl + 1;
        if (line.empty() || line.front() == '#')
            continue;
        const std::size_t tab = line.find('\t');
        if (tab == std::string_view::npos)
            continue; // 无 tab 的行（如纯注释）忽略
        const std::string_view key = line.substr(0, tab);
        const std::string_view val = line.substr(tab + 1);
        if (key.empty() || val.empty())
            continue;
        const std::size_t sp = val.find(' ');
        const std::string_view first = sp == std::string_view::npos ? val : val.substr(0, sp);
        if (first.empty())
            continue;
        d.map.emplace(std::string(key), std::string(first));
        const std::size_t chars = split_chars(key).size();
        if (chars > d.max_key_chars)
            d.max_key_chars = chars;
    }
    return d;
}

// 合并两个词典（group 语义：取所有词典中的最长匹配，等价于合并后 MaxMatch）
inline Dict merge_dicts(const Dict& a, const Dict& b)
{
    Dict out = a;
    out.map.reserve(a.map.size() + b.map.size());
    for (const auto& [k, v] : b.map)
        out.map.emplace(k, v); // key 不重叠（词组 vs 单字），冲突保留 a
    out.max_key_chars = std::max(a.max_key_chars, b.max_key_chars);
    return out;
}

// 单步 MaxMatch：从每个位置起找词典中的最长匹配词并替换；未命中保留原字符
inline std::string max_match(std::string_view text, const Dict& d)
{
    if (text.empty())
        return std::string();
    const std::vector<std::string_view> chars = split_chars(text);
    const std::size_t n = chars.size();
    std::string out;
    out.reserve(text.size() + text.size() / 2);
    std::size_t i = 0;
    while (i < n) {
        // ASCII 单字节字符直接透传（词典 key 均为 CJK，不可能是 ASCII 词组）
        if (chars[i].size() == 1 && static_cast<unsigned char>(chars[i][0]) < 0x80) {
            out += chars[i];
            ++i;
            continue;
        }
        const std::size_t max_len = std::min(d.max_key_chars, n - i);
        bool matched = false;
        for (std::size_t len = max_len; len >= 1; --len) {
            std::string key;
            key.reserve(len * 3);
            for (std::size_t k = i; k < i + len; ++k)
                key += chars[k];
            const auto it = d.map.find(key);
            if (it != d.map.end()) {
                out += it->second;
                i += len;
                matched = true;
                break;
            }
        }
        if (!matched) {
            out += chars[i];
            ++i;
        }
    }
    return out;
}

} // namespace detail

// ---- 词典（懒加载；函数内 static 构造线程安全）----

// ST：简→繁（STPhrases + STCharacters 合并）
inline const detail::Dict& dict_st()
{
    static const detail::Dict d = detail::merge_dicts(
        detail::parse_dict(opencc_data::STPhrases_txt),
        detail::parse_dict(opencc_data::STCharacters_txt));
    return d;
}

// TS：繁→简（TSPhrases + TSCharacters 合并）
inline const detail::Dict& dict_ts()
{
    static const detail::Dict d = detail::merge_dicts(
        detail::parse_dict(opencc_data::TSPhrases_txt),
        detail::parse_dict(opencc_data::TSCharacters_txt));
    return d;
}

// 台湾字形变体（正向）
inline const detail::Dict& dict_tw()
{
    static const detail::Dict d = detail::parse_dict(opencc_data::TWVariants_txt);
    return d;
}

// 台湾字形变体（反向：TWVariantsRevPhrases + TWVariantsRev 合并）
inline const detail::Dict& dict_tw_rev()
{
    static const detail::Dict d = detail::merge_dicts(
        detail::parse_dict(opencc_data::TWVariantsRevPhrases_txt),
        detail::parse_dict(opencc_data::TWVariantsRev_txt));
    return d;
}

// 香港字形变体（正向）
inline const detail::Dict& dict_hk()
{
    static const detail::Dict d = detail::parse_dict(opencc_data::HKVariants_txt);
    return d;
}

// 香港字形变体（反向：HKVariantsRevPhrases + HKVariantsRev 合并）
inline const detail::Dict& dict_hk_rev()
{
    static const detail::Dict d = detail::merge_dicts(
        detail::parse_dict(opencc_data::HKVariantsRevPhrases_txt),
        detail::parse_dict(opencc_data::HKVariantsRev_txt));
    return d;
}

// 日文新字体 → 旧字体/繁体（jp2t：JPShinjitaiPhrases + JPShinjitaiCharacters
// + JPVariantsRev 合并）
inline const detail::Dict& dict_jp2t()
{
    static const detail::Dict d = detail::merge_dicts(
        detail::merge_dicts(detail::parse_dict(opencc_data::JPShinjitaiPhrases_txt),
                            detail::parse_dict(opencc_data::JPShinjitaiCharacters_txt)),
        detail::parse_dict(opencc_data::JPVariantsRev_txt));
    return d;
}

// 旧字体/繁体 → 日文新字体（t2jp：JPVariants）
inline const detail::Dict& dict_t2jp()
{
    static const detail::Dict d = detail::parse_dict(opencc_data::JPVariants_txt);
    return d;
}

// ---- 六种配置的转换链（官方 ver.1.1.9 data/config/*.json 组合）----
// 每个配置的词典表独立 static：只有被请求的配置才触发对应词典的解析（懒加载）
inline const std::vector<const detail::Dict*>& steps_for(std::string_view config)
{
    if (config == "s2t.json") {
        static const std::vector<const detail::Dict*> v = {&dict_st()};
        return v;
    }
    if (config == "t2s.json") {
        static const std::vector<const detail::Dict*> v = {&dict_ts()};
        return v;
    }
    if (config == "s2tw.json") {
        static const std::vector<const detail::Dict*> v = {&dict_st(), &dict_tw()};
        return v;
    }
    if (config == "tw2s.json") {
        static const std::vector<const detail::Dict*> v = {&dict_tw_rev(), &dict_ts()};
        return v;
    }
    if (config == "s2hk.json") {
        static const std::vector<const detail::Dict*> v = {&dict_st(), &dict_hk()};
        return v;
    }
    if (config == "hk2s.json") {
        static const std::vector<const detail::Dict*> v = {&dict_hk_rev(), &dict_ts()};
        return v;
    }
    if (config == "jp2t.json") {
        static const std::vector<const detail::Dict*> v = {&dict_jp2t()};
        return v;
    }
    if (config == "t2jp.json") {
        static const std::vector<const detail::Dict*> v = {&dict_t2jp()};
        return v;
    }
    throw std::invalid_argument("opencc: 未知配置 " + std::string(config));
}

// 配置名是否合法（不抛异常）
inline bool is_valid_config(std::string_view config)
{
    static const std::array<std::string_view, 8> kNames = {
        "s2t.json", "t2s.json", "s2tw.json", "tw2s.json",
        "s2hk.json", "hk2s.json", "jp2t.json", "t2jp.json"};
    for (const auto name : kNames)
        if (name == config)
            return true;
    return false;
}

// ---- 主入口：按配置的转换链依次 MaxMatch ----
inline std::string convert(std::string_view text, std::string_view config)
{
    const auto& steps = steps_for(config);
    std::string cur(text);
    for (const detail::Dict* step : steps)
        cur = detail::max_match(cur, *step);
    return cur;
}

} // namespace opencc
