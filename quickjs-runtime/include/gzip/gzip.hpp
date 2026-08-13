// gzip.hpp —— gzip 格式压缩/解压（zlib 封装，纯 C++ 设施）
//
// 设计约束（docs/breeze_api_gap_analysis.md §4.10）：
//   - 只接受二进制进、二进制出（std::byte* / std::vector<std::byte>），
//     不做任何格式收窄——多种输入格式（ArrayBuffer/TypedArray/DataView/number[]
//     等）由 JS 侧 polyfill（runtime_api.js 的 toBytes）负责；
//   - gzip 格式（RFC 1952）：deflateInit2 windowBits = 15+16 自动写 header/trailer
//     （含 CRC32）；解压用 15+32 自动探测 gzip/zlib；
//   - 错误（非法输入/内存分配失败）→ std::runtime_error，由调用方转 JS Error。
//
// 无 quickjs 依赖，任何模块可直接调用 gzip::compress / gzip::decompress。
// JS 侧绑定见 qjsbind/polyfill/runtime_api.hpp（__native_gzip_compress /
// __native_gzip_decompress）。
#pragma once

#include <zlib.h>

#include <algorithm> // std::min（解压起始容量不超上限）
#include <cstddef>
#include <stdexcept>
#include <string>
#include <vector>

namespace gzip {

namespace detail {

// 统一错误文本（zlib 错误码 → 可读信息）
inline void throw_zlib_error(const char* op, int rc)
{
    throw std::runtime_error(std::string(op) + " failed (zlib rc=" + std::to_string(rc) + ")");
}

} // namespace detail

// gzip 压缩（Z_DEFAULT_COMPRESSION）
inline std::vector<std::byte> compress(const std::byte* data, std::size_t len)
{
    z_stream strm{};
    // 15 + 16：gzip 包装（自动写 1f 8b header + CRC32 trailer）
    const int init_rc =
        deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
    if (init_rc != Z_OK)
        detail::throw_zlib_error("gzip::compress deflateInit2", init_rc);

    std::vector<std::byte> out(deflateBound(&strm, static_cast<uLong>(len)));
    strm.next_in = reinterpret_cast<Bytef*>(const_cast<std::byte*>(data));
    strm.avail_in = static_cast<uInt>(len);
    strm.next_out = reinterpret_cast<Bytef*>(out.data());
    strm.avail_out = static_cast<uInt>(out.size());

    const int rc = deflate(&strm, Z_FINISH);
    deflateEnd(&strm); // 无论成败都释放（deflate 失败时输出缓冲未填充，丢弃即可）
    if (rc != Z_STREAM_END)
        detail::throw_zlib_error("gzip::compress deflate", rc);

    out.resize(strm.total_out);
    return out;
}

// gzip 解压（自动探测 gzip/zlib；输出动态增长，起始 64KB 分块）。
// max_output_bytes 为输出上限（默认 256MB），防止解压炸弹（zip bomb）
// 放大内存占用；超限抛 std::runtime_error。
inline std::vector<std::byte> decompress(const std::byte* data, std::size_t len,
                                         std::size_t max_output_bytes = 256 * 1024 * 1024)
{
    z_stream strm{};
    // 15 + 32：自动探测 gzip / zlib / 裸 deflate
    const int init_rc = inflateInit2(&strm, 15 + 32);
    if (init_rc != Z_OK)
        detail::throw_zlib_error("gzip::decompress inflateInit2", init_rc);

    std::vector<std::byte> out;
    out.reserve(std::min(len * 2 + 64, max_output_bytes)); // 起始容量：不超上限
    std::vector<std::byte> chunk(64 * 1024);

    strm.next_in = reinterpret_cast<Bytef*>(const_cast<std::byte*>(data));
    strm.avail_in = static_cast<uInt>(len);

    int rc = Z_OK;
    do {
        strm.next_out = reinterpret_cast<Bytef*>(chunk.data());
        strm.avail_out = static_cast<uInt>(chunk.size());
        rc = inflate(&strm, Z_NO_FLUSH);
        if (rc != Z_OK && rc != Z_STREAM_END) {
            inflateEnd(&strm);
            detail::throw_zlib_error("gzip::decompress inflate", rc);
        }
        const std::size_t produced = chunk.size() - strm.avail_out;
        if (out.size() + produced > max_output_bytes) {
            inflateEnd(&strm);
            throw std::runtime_error("gzip::decompress: 解压输出超过上限 " +
                                     std::to_string(max_output_bytes) + " bytes");
        }
        out.insert(out.end(), chunk.data(), chunk.data() + produced);
    } while (rc != Z_STREAM_END);

    inflateEnd(&strm);
    return out;
}

// ---- 便捷重载：std::vector<std::byte> 进/出 ----
inline std::vector<std::byte> compress(const std::vector<std::byte>& data)
{
    return compress(data.data(), data.size());
}

inline std::vector<std::byte> decompress(const std::vector<std::byte>& data)
{
    return decompress(data.data(), data.size());
}

} // namespace gzip
