// gzip_test.cpp —— gzip::compress / gzip::decompress 纯 C++ 单测
//
// 覆盖：往返（文本/二进制/空）、gzip 格式魔数（1f 8b）、标准 gzip 向量互操作
// （node zlib.gzipSync 产物）、非法输入抛异常、压缩率。
#include <gtest/gtest.h>

#include <gzip/gzip.hpp>

#include <cstddef>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

std::vector<std::byte> bytes_of(const std::string& s)
{
    std::vector<std::byte> out(s.size());
    for (std::size_t i = 0; i < s.size(); ++i)
        out[i] = static_cast<std::byte>(static_cast<unsigned char>(s[i]));
    return out;
}

std::string str_of(const std::vector<std::byte>& v)
{
    std::string out;
    out.reserve(v.size());
    for (std::byte b : v)
        out.push_back(static_cast<char>(b));
    return out;
}

} // namespace

TEST(GzipTest, Roundtrip)
{
    const std::string text = "hello world, 你好世界, 软件开发与头发护理";
    const auto compressed = gzip::compress(bytes_of(text));
    EXPECT_LT(compressed.size(), text.size() * 3); // 中文 utf-8 膨胀容忍
    EXPECT_EQ(str_of(gzip::decompress(compressed)), text);
}

TEST(GzipTest, RoundtripBinary)
{
    // 二进制（含 0x00 与高位字节）往返
    std::vector<std::byte> bin(300);
    for (std::size_t i = 0; i < bin.size(); ++i)
        bin[i] = static_cast<std::byte>(static_cast<unsigned char>(i * 7 + 3));
    EXPECT_EQ(gzip::decompress(gzip::compress(bin)), bin);
}

TEST(GzipTest, EmptyInput)
{
    const auto compressed = gzip::compress(std::vector<std::byte>{});
    EXPECT_GE(compressed.size(), 20u); // gzip header + trailer
    EXPECT_TRUE(gzip::decompress(compressed).empty());
}

TEST(GzipTest, GzipMagic)
{
    // gzip 格式：魔数 1f 8b（RFC 1952），证明输出是 gzip 而非裸 deflate/zlib
    const auto compressed = gzip::compress(bytes_of("hello"));
    ASSERT_GE(compressed.size(), 2u);
    EXPECT_EQ(compressed[0], std::byte{0x1f});
    EXPECT_EQ(compressed[1], std::byte{0x8b});
    // 方法字段 = 8（deflate）
    EXPECT_EQ(compressed[2], std::byte{0x08});
}

TEST(GzipTest, StandardVectorInterop)
{
    // 标准 gzip 向量：node zlib.gzipSync(Buffer.from("hello"), {mtime:0}) 的产物
    //（标准实现生成，验证本实现解压与标准 gzip 互操作）
    const std::vector<std::byte> hello_gzip = {
        std::byte{0x1f}, std::byte{0x8b}, std::byte{0x08}, std::byte{0x00},
        std::byte{0x00}, std::byte{0x00}, std::byte{0x00}, std::byte{0x00},
        std::byte{0x00}, std::byte{0x0a}, std::byte{0xcb}, std::byte{0x48},
        std::byte{0xcd}, std::byte{0xc9}, std::byte{0xc9}, std::byte{0x07},
        std::byte{0x00}, std::byte{0x86}, std::byte{0xa6}, std::byte{0x10},
        std::byte{0x36}, std::byte{0x05}, std::byte{0x00}, std::byte{0x00},
        std::byte{0x00},
    };
    EXPECT_EQ(str_of(gzip::decompress(hello_gzip)), "hello");
}

TEST(GzipTest, InvalidInputThrows)
{
    // 非 gzip 数据（纯文本）→ zlib 错误 → std::runtime_error
    EXPECT_THROW(gzip::decompress(bytes_of("this is not gzip data")), std::runtime_error);
    // 截断的 gzip
    const auto compressed = gzip::compress(bytes_of("some payload"));
    EXPECT_THROW(gzip::decompress(std::vector<std::byte>(compressed.begin(),
                                                         compressed.begin() + 10)),
                 std::runtime_error);
    // 空输入
    EXPECT_THROW(gzip::decompress(std::vector<std::byte>{}), std::runtime_error);
}

TEST(GzipTest, DecompressLimit)
{
    // 解压输出上限（防 zip bomb）：小上限触发异常，足够大的上限正常
    const auto compressed = gzip::compress(bytes_of("hello world"));
    EXPECT_THROW(gzip::decompress(compressed.data(), compressed.size(), 8),
                 std::runtime_error);
    EXPECT_EQ(str_of(gzip::decompress(compressed.data(), compressed.size(), 64)),
              "hello world");
    // 默认上限（256MB）不影响常规数据
    EXPECT_EQ(str_of(gzip::decompress(compressed)), "hello world");
}

TEST(GzipTest, CompressionRatio)
{
    // 高度重复文本：压缩率应显著（< 50%）
    std::string rep;
    for (int i = 0; i < 2000; ++i)
        rep += "abcdefghijklmnopqrstuvwxyz0123456789";
    const auto compressed = gzip::compress(bytes_of(rep));
    EXPECT_LT(compressed.size() * 2, rep.size());
    EXPECT_EQ(str_of(gzip::decompress(compressed)), rep);
}
