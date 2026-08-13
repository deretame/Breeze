// qjsbind::web —— UTF-8 工具（基于 utf8cpp；TextEncoder/TextDecoder/URL 编码共用）
#pragma once

#include <utf8.h>

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace qjsbind::web {

// UTF-16 代码单元序列 → UTF-8（TextEncoder 语义：正确组合代理对，孤立代理 → U+FFFD）。
inline std::string utf16_to_utf8(const uint16_t* units, size_t len) {
    std::string out;
    out.reserve(len);
    size_t i = 0;
    while (i < len) {
        uint32_t cp = units[i];
        if (cp >= 0xD800 && cp <= 0xDBFF) {
            // 高代理：必须紧跟低代理，否则孤立 → U+FFFD
            if (i + 1 < len) {
                const uint32_t lo = units[i + 1];
                if (lo >= 0xDC00 && lo <= 0xDFFF) {
                    cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                    ++i;
                } else {
                    cp = 0xFFFD; // 孤立高代理（后随非低代理）
                }
            } else {
                cp = 0xFFFD; // 孤立高代理（末尾）
            }
        } else if (cp >= 0xDC00 && cp <= 0xDFFF) {
            cp = 0xFFFD; // 孤立低代理
        }
        utf8::append(cp, out);
        ++i;
    }
    return out;
}

// 字节序列 → 合法 UTF-8（TextDecoder 非 fatal 语义：无效序列 → U+FFFD）。
inline std::string bytes_to_valid_utf8(std::string_view bytes) {
    std::string out;
    out.reserve(bytes.size());
    utf8::replace_invalid(bytes.begin(), bytes.end(), std::back_inserter(out), 0xFFFD);
    return out;
}

// percent-encode：非 unreserved 字符编码。encode_space_as_plus 用于 form 编码。
inline std::string percent_encode(std::string_view input, bool encode_space_as_plus) {
    static constexpr const char* HEX = "0123456789ABCDEF";
    std::string out;
    for (const unsigned char c : input) {
        const bool alpha = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
        const bool digit = c >= '0' && c <= '9';
        const bool mark = c == '-' || c == '_' || c == '.' || c == '~';
        if (alpha || digit || mark) {
            out.push_back(static_cast<char>(c));
        } else if (c == ' ' && encode_space_as_plus) {
            out.push_back('+');
        } else {
            out.push_back('%');
            out.push_back(HEX[c >> 4]);
            out.push_back(HEX[c & 0xF]);
        }
    }
    return out;
}

} // namespace qjsbind::web
