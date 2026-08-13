#pragma once

// 极简 MD5 实现（RFC 1321），仅用于计算 32 位小写十六进制摘要。

#include <cstddef>
#include <cstdint>
#include <string>

namespace jm_md5 {

/// 计算输入数据的 MD5，返回 32 字符的小写十六进制字符串。
std::string hex(const std::uint8_t* data, std::size_t len);

inline std::string hex(const std::string& s) {
  return hex(reinterpret_cast<const std::uint8_t*>(s.data()), s.size());
}

}  // namespace jm_md5
