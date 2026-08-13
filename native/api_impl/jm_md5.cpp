#include "jm_md5.h"

#include <array>
#include <cstring>

namespace jm_md5 {
namespace {

class Md5 {
 public:
  Md5() { reset(); }

  void reset() {
    a_ = 0x67452301u;
    b_ = 0xefcdab89u;
    c_ = 0x98badcfeu;
    d_ = 0x10325476u;
    total_len_ = 0;
    buf_len_ = 0;
  }

  void update(const std::uint8_t* data, std::size_t len) {
    total_len_ += len;
    while (len > 0) {
      const std::size_t take = 64 - buf_len_ < len ? 64 - buf_len_ : len;
      std::memcpy(buf_.data() + buf_len_, data, take);
      buf_len_ += take;
      data += take;
      len -= take;
      if (buf_len_ == 64) {
        transform(buf_.data());
        buf_len_ = 0;
      }
    }
  }

  std::array<std::uint8_t, 16> final() {
    const std::uint64_t bit_len = static_cast<std::uint64_t>(total_len_) * 8;

    // 追加 0x80 然后补 0，直到剩余 8 字节放长度
    const std::uint8_t one = 0x80;
    update_padding(&one, 1);
    const std::uint8_t zero = 0x00;
    while (buf_len_ != 56) {
      update_padding(&zero, 1);
    }

    std::uint8_t len_bytes[8];
    for (int i = 0; i < 8; ++i) {
      len_bytes[i] = static_cast<std::uint8_t>((bit_len >> (8 * i)) & 0xff);
    }
    update_padding(len_bytes, 8);

    std::array<std::uint8_t, 16> out{};
    const std::uint32_t regs[4] = {a_, b_, c_, d_};
    for (int i = 0; i < 4; ++i) {
      out[i * 4 + 0] = static_cast<std::uint8_t>(regs[i] & 0xff);
      out[i * 4 + 1] = static_cast<std::uint8_t>((regs[i] >> 8) & 0xff);
      out[i * 4 + 2] = static_cast<std::uint8_t>((regs[i] >> 16) & 0xff);
      out[i * 4 + 3] = static_cast<std::uint8_t>((regs[i] >> 24) & 0xff);
    }
    return out;
  }

 private:
  // 同 update，但不累计 total_len_（用于 padding 阶段）
  void update_padding(const std::uint8_t* data, std::size_t len) {
    while (len > 0) {
      const std::size_t take = 64 - buf_len_ < len ? 64 - buf_len_ : len;
      std::memcpy(buf_.data() + buf_len_, data, take);
      buf_len_ += take;
      data += take;
      len -= take;
      if (buf_len_ == 64) {
        transform(buf_.data());
        buf_len_ = 0;
      }
    }
  }

  static std::uint32_t rotl(std::uint32_t x, std::uint32_t n) {
    return (x << n) | (x >> (32 - n));
  }

  void transform(const std::uint8_t* block) {
    static constexpr std::uint32_t kS[64] = {
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    };
    static constexpr std::uint32_t kK[64] = {
        0xd76aa478u, 0xe8c7b756u, 0x242070dbu, 0xc1bdceeeu,
        0xf57c0fafu, 0x4787c62au, 0xa8304613u, 0xfd469501u,
        0x698098d8u, 0x8b44f7afu, 0xffff5bb1u, 0x895cd7beu,
        0x6b901122u, 0xfd987193u, 0xa679438eu, 0x49b40821u,
        0xf61e2562u, 0xc040b340u, 0x265e5a51u, 0xe9b6c7aau,
        0xd62f105du, 0x02441453u, 0xd8a1e681u, 0xe7d3fbc8u,
        0x21e1cde6u, 0xc33707d6u, 0xf4d50d87u, 0x455a14edu,
        0xa9e3e905u, 0xfcefa3f8u, 0x676f02d9u, 0x8d2a4c8au,
        0xfffa3942u, 0x8771f681u, 0x6d9d6122u, 0xfde5380cu,
        0xa4beea44u, 0x4bdecfa9u, 0xf6bb4b60u, 0xbebfbc70u,
        0x289b7ec6u, 0xeaa127fau, 0xd4ef3085u, 0x04881d05u,
        0xd9d4d039u, 0xe6db99e5u, 0x1fa27cf8u, 0xc4ac5665u,
        0xf4292244u, 0x432aff97u, 0xab9423a7u, 0xfc93a039u,
        0x655b59c3u, 0x8f0ccc92u, 0xffeff47du, 0x85845dd1u,
        0x6fa87e4fu, 0xfe2ce6e0u, 0xa3014314u, 0x4e0811a1u,
        0xf7537e82u, 0xbd3af235u, 0x2ad7d2bbu, 0xeb86d391u,
    };

    std::uint32_t m[16];
    for (int i = 0; i < 16; ++i) {
      m[i] = static_cast<std::uint32_t>(block[i * 4 + 0]) |
             (static_cast<std::uint32_t>(block[i * 4 + 1]) << 8) |
             (static_cast<std::uint32_t>(block[i * 4 + 2]) << 16) |
             (static_cast<std::uint32_t>(block[i * 4 + 3]) << 24);
    }

    std::uint32_t a = a_, b = b_, c = c_, d = d_;
    for (int i = 0; i < 64; ++i) {
      std::uint32_t f;
      int g;
      if (i < 16) {
        f = (b & c) | (~b & d);
        g = i;
      } else if (i < 32) {
        f = (d & b) | (~d & c);
        g = (5 * i + 1) % 16;
      } else if (i < 48) {
        f = b ^ c ^ d;
        g = (3 * i + 5) % 16;
      } else {
        f = c ^ (b | ~d);
        g = (7 * i) % 16;
      }
      const std::uint32_t tmp = d;
      d = c;
      c = b;
      b = b + rotl(a + f + kK[i] + m[g], kS[i]);
      a = tmp;
    }
    a_ += a;
    b_ += b;
    c_ += c;
    d_ += d;
  }

  std::uint32_t a_, b_, c_, d_;
  std::uint64_t total_len_;
  std::array<std::uint8_t, 64> buf_{};
  std::size_t buf_len_;
};

}  // namespace

std::string hex(const std::uint8_t* data, std::size_t len) {
  Md5 md5;
  md5.update(data, len);
  const auto digest = md5.final();

  static constexpr char kHex[] = "0123456789abcdef";
  std::string out;
  out.reserve(32);
  for (const std::uint8_t byte : digest) {
    out.push_back(kHex[byte >> 4]);
    out.push_back(kHex[byte & 0x0f]);
  }
  return out;
}

}  // namespace jm_md5
